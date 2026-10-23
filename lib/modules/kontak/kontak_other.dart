import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../core/owner.dart';
import '../../core/table.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import '../gaji/gaji_page.dart' show employeeDialog;
import '../gaji/gaji_repo.dart' show employeeRoles;
import 'kontak_controller.dart';
import 'kontak_repo.dart';

/// Tab Vendor di Kontak: pemasok barang. Dipilih/diketik namanya di form pembelian stok.
class VendorTable extends StatelessWidget {
  const VendorTable(this.c, {super.key});
  final KontakController c;

  @override
  Widget build(BuildContext context) => Obx(
    () => AppTable<Vendor>(
      rows: c.vendors.toList(),
      searchHint: 'Cari nama, no. HP, alamat…',
      searchText: (v) => '${v.name} ${v.phone} ${v.address} ${v.note}',
      onTap: (v) => vendorDialog(context, c.db, v),
      emptyMessage: 'Belum ada vendor. Tambah di sini, atau otomatis dari form pembelian stok.',
      columns: [
        Col('Nama', (v) => Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)), flex: 4),
        Col('No. HP', (v) => Text(v.phone.isEmpty ? '—' : v.phone), flex: 3),
        Col('Alamat', (v) => Text(v.address.isEmpty ? '—' : v.address), flex: 5),
        Col('Catatan', (v) => Text(v.note, style: T.body.copyWith(color: C.inkMuted)), flex: 4),
      ],
    ),
  );
}

/// Tab Pegawai di Kontak: data kontak karyawan (tanpa gaji). Tambah/ubah butuh PIN owner.
class PegawaiTable extends StatelessWidget {
  const PegawaiTable(this.c, {super.key});
  final KontakController c;

  @override
  Widget build(BuildContext context) => Obx(
    () => AppTable<Employee>(
      rows: c.employees.toList(),
      searchHint: 'Cari nama, no. HP…',
      searchText: (e) => '${e.name} ${e.phone} ${employeeRoles[e.role] ?? e.role}',
      onTap: (e) async {
        if (await Get.find<OwnerController>().ensure(context) && context.mounted) {
          await employeeDialog(context, c.db, e);
        }
      },
      emptyMessage: 'Belum ada pegawai.',
      columns: [
        Col('Nama', (e) => Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)), flex: 4),
        Col('Peran', (e) => Text(employeeRoles[e.role] ?? e.role), flex: 2),
        Col('No. HP', (e) => Text(e.phone.isEmpty ? '—' : e.phone), flex: 3),
        Col('Catatan', (e) => Text(e.note, style: T.body.copyWith(color: C.inkMuted)), flex: 4),
        Col('Status', (e) => Pill(e.active ? 'Aktif' : 'Nonaktif', e.active ? Tone.success : Tone.neutral), flex: 2),
      ],
    ),
  );
}

/// Tambah/ubah/hapus vendor. Tambah & ubah siapa saja; hapus owner (dan hanya bila belum dipakai pembelian).
Future<void> vendorDialog(BuildContext context, AppDb db, Vendor? v) async {
  final name = TextEditingController(text: v?.name),
      phone = TextEditingController(text: v?.phone),
      address = TextEditingController(text: v?.address),
      note = TextEditingController(text: v?.note);
  var busy = false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(v == null ? 'Vendor baru' : 'Ubah vendor'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Labeled('Nama *', TextField(controller: name, autofocus: v == null)),
              const SizedBox(height: S.md),
              Labeled('No. HP / telepon', TextField(controller: phone, keyboardType: TextInputType.phone)),
              const SizedBox(height: S.md),
              Labeled('Alamat', TextField(controller: address, maxLines: 2)),
              const SizedBox(height: S.md),
              Labeled('Catatan', TextField(controller: note, maxLines: 2)),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: dialogActions(
          danger: v == null
              ? null
              : DangerButton(
                  label: 'Hapus',
                  onPressed: () async {
                    if (!await Get.find<OwnerController>().ensure(ctx) || !ctx.mounted) return;
                    final ok = await confirmAction(
                      ctx,
                      title: 'Hapus ${v.name}?',
                      message: 'Vendor yang sudah punya pembelian tidak bisa dihapus.',
                      confirmLabel: 'Hapus vendor',
                      destructive: true,
                    );
                    if (!ok || !ctx.mounted) return;
                    if (await runAction(ctx, () => db.deleteVendor(v.id), 'Vendor dihapus') && ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                ),
          children: [
            OutlinedButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      final ok = await runAction(
                        ctx,
                        () => db.saveVendor(
                          VendorsCompanion(
                            id: v == null ? const Value.absent() : Value(v.id),
                            name: Value(name.text),
                            phone: Value(phone.text),
                            address: Value(address.text),
                            note: Value(note.text),
                          ),
                        ),
                        'Vendor tersimpan',
                      );
                      if (!ctx.mounted) return;
                      if (ok) {
                        Navigator.pop(ctx);
                      } else {
                        setState(() => busy = false);
                      }
                    },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    ),
  );
  for (final t in [name, phone, address, note]) {
    t.dispose();
  }
}
