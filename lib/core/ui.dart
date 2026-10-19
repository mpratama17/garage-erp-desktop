import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Value;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../db/database.dart';
import 'format.dart';

import 'owner.dart';
import 'theme.dart';

/// Judul halaman + subjudul di kiri, aksi di kanan (design.md §5). Tombol owner ada di topbar.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(S.xxl, S.xl, S.xxl, S.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: T.pageTitle),
              if (subtitle != null) ...[const SizedBox(height: S.xs), Text(subtitle!, style: T.pageSubtitle)],
            ],
          ),
        ),
        for (final a in actions)
          Padding(
            padding: const EdgeInsets.only(left: S.sm),
            child: a,
          ),
      ],
    ),
  );
}

/// Label di atas field (design.md §3). Field-nya sendiri berlatar abu tanpa garis (tema).
class Labeled extends StatelessWidget {
  const Labeled(this.label, this.child, {super.key});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => label.isEmpty
      ? child // mis. sel tabel baris invoice: judul kolom sudah jadi labelnya
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: T.fieldLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            child,
          ],
        );
}

/// Label status berbentuk pil, selalu berisi teks (bukan warna saja).
class Pill extends StatelessWidget {
  const Pill(this.text, this.tone, {super.key});
  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: T.label.copyWith(color: tone.fg)),
  );
}

/// Indikator & tombol mode owner di header.
class OwnerLockButton extends StatelessWidget {
  const OwnerLockButton({super.key});

  @override
  Widget build(BuildContext context) {
    final owner = Get.find<OwnerController>();
    return Obx(
      () => owner.isOwner.value
          ? OutlinedButton.icon(
              onPressed: owner.lock,
              icon: const Icon(Icons.lock_open, size: 18, color: C.primary),
              label: const Text('Owner'),
            )
          : OutlinedButton.icon(
              onPressed: () => owner.ensure(context),
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Terkunci'),
            ),
    );
  }
}

/// Nilai khusus owner: tampil •••• + gembok saat terkunci; klik = minta PIN.
class OwnerOnly extends StatelessWidget {
  const OwnerOnly({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final owner = Get.find<OwnerController>();
    return Obx(
      () => owner.isOwner.value
          ? child
          : InkWell(
              onTap: () => owner.ensure(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: C.inkMuted),
                  const SizedBox(width: S.xs),
                  Text('••••', style: T.body.copyWith(color: C.inkMuted)),
                ],
              ),
            ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.action});
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(S.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: T.pageSubtitle),
          if (action != null) ...[const SizedBox(height: S.lg), action!],
        ],
      ),
    ),
  );
}

/// Jenis pesan hasil aksi (design.md §6 Notifikasi). Bentuk & warna beda, bukan hanya teks.
enum Notice {
  success('Berhasil', Icons.check_circle_rounded, Tone.success, Duration(seconds: 3)),
  warning('Periksa lagi', Icons.info_rounded, Tone.warning, Duration(seconds: 5)),
  error('Gagal', Icons.error_rounded, Tone.danger, Duration(seconds: 8)),
  info('Info', Icons.info_outline_rounded, Tone.info, Duration(seconds: 4));

  const Notice(this.title, this.icon, this.tone, this.duration);
  final String title;
  final IconData icon;
  final Tone tone;
  final Duration duration;
}

/// Tampilkan hasil aksi: kartu kecil di bawah tengah layar dengan ikon & warna sesuai [kind], bisa ditutup.
/// success = aksi berhasil; warning = isian/aturan perlu diperbaiki user; error = gagal karena sistem.
/// Dipasang di overlay paling atas → tetap terang & terbaca walau ada dialog terbuka.
void notify(BuildContext context, String message, {Notice kind = Notice.success, String? title}) {
  _notice?.remove();
  _noticeTimer?.cancel();
  late final OverlayEntry entry;
  void close() {
    if (_notice != entry) return;
    entry.remove();
    _notice = null;
    _noticeTimer?.cancel();
  }

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      right: 0,
      bottom: S.xl,
      child: Center(
        child: _NoticeCard(kind: kind, title: title ?? kind.title, message: message, onClose: close),
      ),
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  _notice = entry;
  _noticeTimer = Timer(kind.duration, close);
}

OverlayEntry? _notice;
Timer? _noticeTimer;

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.kind, required this.title, required this.message, required this.onClose});
  final Notice kind;
  final String title, message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 150),
    builder: (_, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
    ),
    child: Material(
      color: C.surface,
      elevation: 8,
      shadowColor: const Color(0x33101828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(S.rCard),
        side: BorderSide(color: kind.tone.fg.withValues(alpha: 0.35)),
      ),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(S.md, S.md, S.xs, S.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: kind.tone.bg, shape: BoxShape.circle),
                child: Icon(kind.icon, color: kind.tone.fg, size: 22),
              ),
              const SizedBox(width: S.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: T.fieldLabel.copyWith(color: kind.tone.fg)),
                    const SizedBox(height: 2),
                    Text(message, style: T.body),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18, color: C.inkMuted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Isian/aturan yang perlu diperbaiki user (bukan error sistem).
void warn(BuildContext context, String message) => notify(context, message, kind: Notice.warning);

/// Konfirmasi sebelum aksi penting. Tombol memakai kata kerja jelas ([confirmLabel]), bukan "Ya/Tidak".
/// [destructive] = aksi yang menghapus/membatalkan: ikon peringatan & tombol merah.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          destructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
          color: destructive ? C.danger : C.primary,
          size: 32,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: T.body.copyWith(color: C.inkMuted),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: C.danger) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ==
    true;

/// Tombol aksi destruktif di form/panel (hapus, batalkan): garis merah, ditaruh terpisah di kiri
/// — tidak bersebelahan dengan Simpan, dan selalu didahului [confirmAction].
class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.label, required this.onPressed, this.icon = Icons.delete_outline});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: C.danger,
      side: BorderSide(color: C.danger.withValues(alpha: 0.4)),
    ),
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label),
  );
}

/// Format angka saat diketik: 2250000 -> 2.250.000 (design.md §6, input Rupiah).
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > 15) return oldValue; // di atas 999 triliun: tolak ketikan
    final text = rp(int.parse(digits));
    // Kursor tetap setelah jumlah digit yang sama, supaya edit di tengah angka tidak melompat.
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    var digitsBefore = newValue.text.substring(0, cursor).replaceAll(RegExp(r'\D'), '').length;
    var offset = 0;
    while (offset < text.length && digitsBefore > 0) {
      if (text[offset] != '.') digitsBefore--;
      offset++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Input angka/Rupiah. Baca nilainya dengan [parseRupiah].
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.prefix = 'Rp ',
    this.hint,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final String prefix;
  final String? hint; // teks samar saat kosong, mis. 'kosong = lunas'
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Labeled(
    label,
    TextField(
      controller: controller,
      textAlign: TextAlign.right,
      style: T.money,
      inputFormatters: [ThousandsFormatter()],
      onChanged: onChanged,
      decoration: InputDecoration(hintText: hint, prefixText: prefix.isEmpty ? null : prefix),
    ),
  );
}

// ------------------------------------------------------------------ form & aksi

/// Jalankan aksi repo dan tampilkan hasilnya:
/// berhasil → [done] (sukses); [ArgumentError] = aturan bisnis → pesan untuk diperbaiki user;
/// error lain = masalah sistem → pesan ramah + detail teknis dicatat di log (bukan ditampilkan mentah).
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, [
  String? done,
  String failed = 'Terjadi kesalahan, aksi tidak selesai. Coba sekali lagi; bila tetap gagal, kirim file log ke admin.',
]) async {
  try {
    await action();
    if (done != null && context.mounted) notify(context, done);
    return true;
  } catch (e, st) {
    // ArgumentError = aturan bisnis dari repo → user bisa memperbaiki. RangeError/IndexError (turunannya) = bug.
    if (e is ArgumentError && e is! RangeError && e is! IndexError) {
      if (context.mounted) warn(context, '${e.message}');
    } else {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st, library: 'runAction'));
      if (context.mounted) notify(context, failed, kind: Notice.error);
    }
  }
  return false;
}

Widget dateField(BuildContext ctx, DateTime value, ValueChanged<DateTime> onPick) => InkWell(
  onTap: () async {
    final d = await showDatePicker(
      context: ctx,
      initialDate: value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) onPick(d);
  },
  child: Labeled('Tanggal', InputDecorator(decoration: const InputDecoration(), child: Text(tgl(value)))),
);

Widget proofRow(String proof, VoidCallback onPick) => Row(
  children: [
    OutlinedButton.icon(
      onPressed: onPick,
      icon: const Icon(Icons.attach_file, size: 18),
      label: const Text('Lampirkan bukti'),
    ),
    const SizedBox(width: S.sm),
    Expanded(
      child: Text(
        proof.isEmpty ? 'Belum ada bukti' : path.basename(proof),
        style: T.label,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
);

Widget accountField(String label, int? value, List<Account> items, ValueChanged<int?> onChanged) => Labeled(
  label,
  DropdownButtonFormField<int>(
    isExpanded: true,
    initialValue: value,
    items: [for (final a in items) DropdownMenuItem(value: a.id, child: Text(a.name))],
    onChanged: onChanged,
  ),
);

/// ‹ Oktober 2026 › — pindah bulan dengan [onShift](-1 / +1).
class MonthNav extends StatelessWidget {
  const MonthNav({super.key, required this.month, required this.onShift});
  final DateTime month;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(tooltip: 'Bulan sebelumnya', onPressed: () => onShift(-1), icon: const Icon(Icons.chevron_left)),
      SizedBox(
        width: 130,
        child: Text(DateFormat('MMMM y', 'id').format(month), textAlign: TextAlign.center, style: T.section),
      ),
      IconButton(tooltip: 'Bulan berikutnya', onPressed: () => onShift(1), icon: const Icon(Icons.chevron_right)),
    ],
  );
}

/// Halaman khusus owner: terkunci → pesan + tombol PIN; terbuka → [builder].
class OwnerGate extends StatelessWidget {
  const OwnerGate({super.key, required this.message, required this.builder});
  final String message;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final owner = Get.find<OwnerController>();
    return Obx(
      () => owner.isOwner.value
          ? builder(context)
          : EmptyState(
              message: message,
              action: FilledButton(onPressed: () => owner.ensure(context), child: const Text('Buka dengan PIN')),
            ),
    );
  }
}

/// Kartu ringkasan angka (design.md §6): ikon di kotak pastel + label + angka besar + keterangan.
/// [ownerOnly] = angka disembunyikan (••••) sampai PIN owner dimasukkan.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    this.hint,
    this.hintColor,
    this.ownerOnly = false,
  });
  final IconData icon;
  final Tone tone;
  final String label, value;
  final String? hint;
  final Color? hintColor;
  final bool ownerOnly;

  @override
  Widget build(BuildContext context) {
    final number = Text(value, style: T.kpi.copyWith(fontSize: 22), maxLines: 1, overflow: TextOverflow.ellipsis);
    // Seperti referensi: seluruh kartu pastel, ikon di kotak pastel yang sedikit lebih tua.
    return Card(
      color: Color.lerp(tone.bg, C.surface, 0.25),
      child: Padding(
        padding: const EdgeInsets.all(S.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color.lerp(tone.bg, tone.fg, 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tone.fg, size: 22),
            ),
            const SizedBox(width: S.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: T.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  ownerOnly ? OwnerOnly(child: number) : number,
                  if (hint != null)
                    Text(
                      hint!,
                      style: T.label.copyWith(color: hintColor, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deretan kartu KPI sama lebar (maks. 4, design.md §6), dengan jarak antarkartu dan bawah.
class KpiRow extends StatelessWidget {
  const KpiRow(this.cards, {super.key, this.padding = const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.lg)});
  final List<Widget> cards;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: IntrinsicHeight(
      // semua kartu setinggi kartu tertinggi
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, k) in cards.indexed) ...[if (i > 0) const SizedBox(width: S.lg), Expanded(child: k)],
        ],
      ),
    ),
  );
}

/// Tombol dialog (design.md §6): aksi destruktif di KIRI terpisah, Batal + aksi utama di kanan
/// (aksi utama paling kanan). Pakai bersama `actionsAlignment: MainAxisAlignment.spaceBetween`.
List<Widget> dialogActions({Widget? danger, required List<Widget> children}) => [
  danger ?? const SizedBox.shrink(),
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, w) in children.indexed) ...[if (i > 0) const SizedBox(width: S.sm), w],
    ],
  ),
];
