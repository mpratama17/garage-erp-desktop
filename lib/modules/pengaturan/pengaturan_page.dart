import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/owner.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';

/// Field teks yang diedit di halaman ini: key setting -> label.
const _textFields = {
  'shop_name': 'Nama bengkel *',
  'shop_address': 'Alamat',
  'shop_phone': 'Telepon',
  'shop_email': 'Email',
  'invoice_note': 'Pesan di nota (rekening, syarat garansi)',
  'gmaps_review_url': 'Link review Google Maps',
};

/// Field angka: key -> (label, min, max).
const _numFields = {
  'next_invoice_no': ('Nomor invoice berikutnya (INV/…)', 1, 99999),
  'next_so_no': ('Nomor pemesanan berikutnya (SO/…)', 1, 99999),
  'payroll_start_day': ('Tanggal mulai periode gaji', 1, 28),
  'sales_commission_pct': ('Tunjangan kerja sales (% omzet)', 0, 100),
};

class PengaturanController extends GetxController {
  PengaturanController(this.db);
  final AppDb db;
  final ctrl = {
    for (final k in [..._textFields.keys, ..._numFields.keys]) k: TextEditingController(),
  };
  final logoPath = ''.obs;
  final backupDir = ''.obs;
  final lastBackup = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final s = await db.allSettings();
    for (final e in ctrl.entries) {
      e.value.text = s[e.key]!;
    }
    logoPath.value = s['logo_path']!;
    backupDir.value = await db.backupDir();
    lastBackup.value = s['last_backup_at']!;
  }

  /// null = tersimpan; selain itu pesan error.
  Future<String?> save() async {
    if (ctrl['shop_name']!.text.trim().isEmpty) return 'Nama bengkel wajib diisi';
    for (final e in _numFields.entries) {
      final v = int.tryParse(ctrl[e.key]!.text.trim());
      final (label, min, max) = e.value;
      if (v == null || v < min || v > max) return '$label harus angka $min–$max';
    }
    await db.transaction(() async {
      for (final e in ctrl.entries) {
        await db.setSetting(e.key, e.value.text.trim());
      }
    });
    return null;
  }

  Future<void> pickLogo() async {
    final f = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Gambar', extensions: ['png', 'jpg', 'jpeg']),
      ],
    );
    if (f == null) return;
    // Salin ke folder app (nama unik) supaya logo tetap ada walau file asli dipindah.
    final dir = (await getApplicationSupportDirectory()).path;
    final dest = p.join(dir, 'logo-${DateTime.now().millisecondsSinceEpoch}${p.extension(f.path)}');
    await File(f.path).copy(dest);
    final old = logoPath.value;
    await db.setSetting('logo_path', dest);
    logoPath.value = dest;
    if (old.isNotEmpty && p.isWithin(dir, old)) {
      try {
        await File(old).delete();
      } on FileSystemException {
        // logo lama sudah tidak ada — tidak masalah
      }
    }
  }

  Future<void> pickBackupDir() async {
    final dir = await getDirectoryPath(confirmButtonText: 'Pilih folder');
    if (dir == null) return;
    await db.setSetting('backup_dir', dir);
    backupDir.value = dir;
  }

  Future<String> backupNow() async {
    final f = await db.backupTo(backupDir.value);
    lastBackup.value = await db.setting('last_backup_at');
    return p.basename(f.path);
  }

  @override
  void onClose() {
    for (final c in ctrl.values) {
      c.dispose();
    }
    super.onClose();
  }
}

class PengaturanPage extends StatelessWidget {
  const PengaturanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final owner = Get.find<OwnerController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(title: 'Pengaturan', subtitle: 'Data bengkel, nota, gaji, backup, dan PIN owner.'),
        Expanded(
          child: Obx(
            () => owner.isOwner.value
                ? const _Form()
                : EmptyState(
                    message: 'Pengaturan hanya bisa dibuka owner.',
                    action: FilledButton(onPressed: () => owner.ensure(context), child: const Text('Masukkan PIN')),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Dibuat ulang setiap mode owner dibuka, jadi data selalu dimuat segar dari DB
/// (mencegah nomor nota lama tertulis balik saat Simpan).
class _Form extends StatefulWidget {
  const _Form();
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final c = Get.put(PengaturanController(Get.find<AppDb>()));

  @override
  void dispose() {
    Get.delete<PengaturanController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label, {int lines = 1}) => Padding(
      padding: const EdgeInsets.only(bottom: S.lg),
      child: Labeled(label, TextField(controller: c.ctrl[key], minLines: lines, maxLines: lines)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xxl),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: S.formMax),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Card('Data bengkel (tampil di nota)', [
                Row(
                  children: [
                    Obx(
                      () => Container(
                        width: 72,
                        height: 72,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: C.bg,
                          border: Border.all(color: C.border),
                          borderRadius: BorderRadius.circular(S.rInput),
                        ),
                        child: c.logoPath.value.isNotEmpty && File(c.logoPath.value).existsSync()
                            ? Image.file(File(c.logoPath.value), fit: BoxFit.contain)
                            : const Icon(Icons.image_outlined, color: C.inkMuted),
                      ),
                    ),
                    const SizedBox(width: S.lg),
                    OutlinedButton(onPressed: c.pickLogo, child: const Text('Pilih logo')),
                  ],
                ),
                const SizedBox(height: S.lg),
                for (final e in _textFields.entries)
                  field(e.key, e.value, lines: e.key == 'shop_address' || e.key == 'invoice_note' ? 4 : 1),
              ]),
              _Card('Nomor nota & gaji', [for (final e in _numFields.entries) field(e.key, e.value.$1)]),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () async {
                    final err = await c.save();
                    if (context.mounted) toast(context, err ?? 'Pengaturan tersimpan');
                  },
                  child: const Text('Simpan'),
                ),
              ),
              const SizedBox(height: S.xl),
              _Card('Backup', [
                const Text(
                  'Backup otomatis dibuat sekali sehari dan setiap app ditutup (60 file terbaru disimpan). '
                  'Folder bisa diganti, mis. ke flashdisk.',
                ),
                const SizedBox(height: S.lg),
                Obx(() => SelectableText(c.backupDir.value, style: T.body)),
                const SizedBox(height: S.md),
                Row(
                  children: [
                    OutlinedButton(onPressed: c.pickBackupDir, child: const Text('Ganti folder')),
                    const SizedBox(width: S.sm),
                    FilledButton(
                      onPressed: () async {
                        try {
                          final name = await c.backupNow();
                          if (context.mounted) toast(context, 'Backup tersimpan: $name');
                        } catch (e) {
                          if (context.mounted) toast(context, 'Backup gagal: $e');
                        }
                      },
                      child: const Text('Backup sekarang'),
                    ),
                  ],
                ),
              ]),
              _Card('PIN owner', [
                const Text('Ganti PIN yang dipakai untuk membuka data owner.'),
                const SizedBox(height: S.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(onPressed: () => _changePin(context, c.db), child: const Text('Ganti PIN')),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePin(BuildContext context, AppDb db) async {
    final a = TextEditingController(), b = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti PIN'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Labeled('PIN baru', TextField(controller: a, obscureText: true)),
              const SizedBox(height: S.md),
              Labeled('Ulangi PIN baru', TextField(controller: b, obscureText: true)),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, a.text.trim() == b.text.trim() ? a.text.trim() : ''),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (pin == null) return;
    if (pin.length < 4) {
      if (context.mounted) toast(context, 'PIN minimal 4 digit dan kedua isian harus sama');
      return;
    }
    await db.setPin(pin);
    if (context.mounted) toast(context, 'PIN diganti');
  }
}

class _Card extends StatelessWidget {
  const _Card(this.title, this.children);
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: S.lg),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(S.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: T.section),
            const SizedBox(height: S.lg),
            ...children,
          ],
        ),
      ),
    ),
  );
}
