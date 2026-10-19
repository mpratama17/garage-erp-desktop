import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Value;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../db/database.dart';
import 'format.dart';

import 'owner.dart';
import 'theme.dart';

/// Judul halaman + subjudul di kiri, aksi di kanan (design.md §5).
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
        const Padding(
          padding: EdgeInsets.only(left: S.sm),
          child: OwnerLockButton(),
        ),
      ],
    ),
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

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

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
  const MoneyField({super.key, required this.controller, required this.label, this.prefix = 'Rp ', this.onChanged});
  final TextEditingController controller;
  final String label;
  final String prefix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textAlign: TextAlign.right,
    style: T.money,
    inputFormatters: [ThousandsFormatter()],
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label, prefixText: prefix.isEmpty ? null : prefix),
  );
}

// ------------------------------------------------------------------ form & aksi

/// Jalankan aksi repo: [ArgumentError] = pesan aturan untuk user, error lain = "Gagal".
Future<void> runAction(BuildContext context, Future<void> Function() action, [String? done]) async {
  try {
    await action();
    if (done != null && context.mounted) toast(context, done);
  } on ArgumentError catch (e) {
    if (context.mounted) toast(context, '${e.message}');
  } catch (e) {
    if (context.mounted) toast(context, 'Gagal: $e');
  }
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
  child: InputDecorator(
    decoration: const InputDecoration(labelText: 'Tanggal'),
    child: Text(tgl(value)),
  ),
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

DropdownButtonFormField<int> accountField(
  String label,
  int? value,
  List<Account> items,
  ValueChanged<int?> onChanged,
) => DropdownButtonFormField<int>(
  isExpanded: true,
  initialValue: value,
  decoration: InputDecoration(labelText: label),
  items: [for (final a in items) DropdownMenuItem(value: a.id, child: Text(a.name))],
  onChanged: onChanged,
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
