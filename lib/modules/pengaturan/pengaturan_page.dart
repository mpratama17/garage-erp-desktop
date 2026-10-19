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
  'invoice_note': 'Pesan di nota',
  'gmaps_review_url': 'Link review Google Maps',
};

/// Field angka: key -> (label, min, max).
const _numFields = {
  'next_invoice_no': ('No. invoice berikutnya', 1, 99999),
  'next_so_no': ('No. pemesanan berikutnya', 1, 99999),
  'payroll_start_day': ('Tgl mulai periode gaji', 1, 28),
  'sales_commission_pct': ('Komisi sales (%)', 0, 100),
};

class PengaturanController extends GetxController {
  PengaturanController(this.db);
  final AppDb db;
  final ctrl = {
    for (final k in [..._textFields.keys, ..._numFields.keys]) k: TextEditingController(),
  };
  final logoPath = ''.obs; // logo penuh, untuk nota
  final iconPath = ''.obs; // ikon kecil, untuk sidebar
  final backupDir = ''.obs;
  final backupSchedule = 'close'.obs;
  final exportDir = ''.obs;
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
    iconPath.value = s['logo_icon_path']!;
    backupDir.value = await db.backupDir();
    backupSchedule.value = s['backup_schedule']!;
    exportDir.value = await db.exportDir();
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

  /// Pilih gambar untuk setting [key] (`logo_path` / `logo_icon_path`); [target] = nilai yang tampil.
  Future<void> pickImage(String key, RxString target) async {
    final f = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Gambar', extensions: ['png', 'jpg', 'jpeg']),
      ],
    );
    if (f == null) return;
    // Salin ke folder app (nama unik) supaya logo tetap ada walau file asli dipindah.
    final dir = (await getApplicationSupportDirectory()).path;
    final dest = p.join(
      dir,
      '${key.replaceAll('_path', '')}-${DateTime.now().millisecondsSinceEpoch}${p.extension(f.path)}',
    );
    await File(f.path).copy(dest);
    final old = target.value;
    await db.setSetting(key, dest);
    target.value = dest;
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

  Future<void> setBackupSchedule(String v) async {
    await db.setSetting('backup_schedule', v);
    backupSchedule.value = v;
  }

  Future<void> pickExportDir() async {
    final dir = await getDirectoryPath(confirmButtonText: 'Pilih folder');
    if (dir == null) return;
    await db.setSetting('export_dir', dir);
    exportDir.value = await db.exportDir();
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
        const PageHeader(title: 'Pengaturan', subtitle: 'Data bengkel, nota, file, backup, PIN.'),
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
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kiri: isian yang disimpan tombol Simpan. Kanan: pengaturan yang langsung tersimpan.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Card('Data bengkel', [
                      Row(
                        children: [
                          _ImagePick('Logo nota', c.logoPath, () => c.pickImage('logo_path', c.logoPath)),
                          const SizedBox(width: S.xl),
                          _ImagePick('Ikon sidebar', c.iconPath, () => c.pickImage('logo_icon_path', c.iconPath)),
                        ],
                      ),
                      const SizedBox(height: S.sm),
                      Text('PNG tanpa latar paling rapi.', style: T.label),
                      const SizedBox(height: S.lg),
                      for (final e in _textFields.entries)
                        field(e.key, e.value, lines: e.key == 'shop_address' || e.key == 'invoice_note' ? 4 : 1),
                      Text('Tampil di nota PDF. Pesan nota: rekening & syarat garansi.', style: T.label),
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
                  ],
                ),
              ),
              const SizedBox(width: S.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Card('Folder file', [
                      Obx(() => _PathRow(c.exportDir.value)),
                      const SizedBox(height: S.sm),
                      Text(
                        'Nota PDF tersimpan di subfolder Nota; export Excel dimulai di subfolder Export.',
                        style: T.label,
                      ),
                      const SizedBox(height: S.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(onPressed: c.pickExportDir, child: const Text('Ganti folder')),
                      ),
                    ]),
                    _Card('Backup', [
                      Obx(
                        () => Labeled(
                          'Backup otomatis',
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: c.backupSchedule.value,
                            items: [
                              for (final e in backupSchedules.entries)
                                DropdownMenuItem(value: e.key, child: Text(e.value)),
                            ],
                            onChanged: (v) => v == null ? null : c.setBackupSchedule(v),
                          ),
                        ),
                      ),
                      const SizedBox(height: S.lg),
                      Text('Folder backup', style: T.fieldLabel),
                      const SizedBox(height: 6),
                      Obx(() => _PathRow(c.backupDir.value)),
                      const SizedBox(height: S.sm),
                      Obx(
                        () => Text(
                          c.backupSchedule.value == 'off'
                              ? 'Backup otomatis mati — data hanya aman bila Backup sekarang ditekan rutin.'
                              : '60 file terbaru disimpan. Folder bisa di flashdisk.',
                          style: T.label.copyWith(color: c.backupSchedule.value == 'off' ? C.danger : null),
                        ),
                      ),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: () => _changePin(context, c.db),
                          child: const Text('Ganti PIN'),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
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

/// Path folder dalam kotak abu (bisa diseleksi/disalin).
class _PathRow extends StatelessWidget {
  const _PathRow(this.path);
  final String path;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.md),
    decoration: BoxDecoration(color: C.field, borderRadius: BorderRadius.circular(S.rInput)),
    child: Row(
      children: [
        const Icon(Icons.folder_outlined, size: 18, color: C.inkMuted),
        const SizedBox(width: S.sm),
        Expanded(child: SelectableText(path, style: T.body)),
      ],
    ),
  );
}

/// Pratinjau gambar + tombol ganti.
class _ImagePick extends StatelessWidget {
  const _ImagePick(this.label, this.path, this.onPick);
  final String label;
  final RxString path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Obx(
        () => Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(S.xs),
          decoration: BoxDecoration(color: C.field, borderRadius: BorderRadius.circular(S.rInput)),
          child: path.value.isNotEmpty && File(path.value).existsSync()
              ? Image.file(File(path.value), fit: BoxFit.contain)
              : const Icon(Icons.image_outlined, color: C.inkMuted),
        ),
      ),
      const SizedBox(width: S.md),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: T.fieldLabel),
          const SizedBox(height: S.xs),
          OutlinedButton(onPressed: onPick, child: const Text('Pilih')),
        ],
      ),
    ],
  );
}
