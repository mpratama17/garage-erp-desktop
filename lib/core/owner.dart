import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../db/database.dart';
import 'ui.dart';

/// Mode owner: membuka harga modal, laba, gaji, pembelian stok, void.
/// Terkunci lagi saat app ditutup atau 15 menit tanpa aktivitas.
class OwnerController extends GetxController {
  OwnerController(this.db);
  final AppDb db;
  final isOwner = false.obs;
  Timer? _idle;

  static const idleLimit = Duration(minutes: 15);

  bool _onKey(KeyEvent _) {
    touch();
    return false; // jangan telan event keyboard
  }

  @override
  void onInit() {
    super.onInit();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void touch() {
    if (!isOwner.value) return;
    _idle?.cancel();
    _idle = Timer(idleLimit, lock);
  }

  void lock() {
    _idle?.cancel();
    isOwner.value = false;
    db.ownerUnlocked = false;
  }

  /// true bila sudah/berhasil masuk mode owner. Minta PIN (atau buat PIN pertama kali).
  Future<bool> ensure(BuildContext context) async {
    if (isOwner.value) return true;
    final firstTime = !await db.hasPin();
    if (!context.mounted) return false;
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => _PinDialog(create: firstTime),
    );
    if (pin == null) return false;
    if (firstTime) {
      await db.setPin(pin);
    } else if (!await db.checkPin(pin)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN salah')));
      }
      return false;
    }
    isOwner.value = true;
    db.ownerUnlocked = true;
    touch();
    return true;
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _idle?.cancel();
    super.onClose();
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.create});
  final bool create;
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  void _submit() {
    final pin = _pin.text.trim();
    if (pin.length < 4) return setState(() => _error = 'PIN minimal 4 digit');
    if (widget.create && pin != _confirm.text.trim()) {
      return setState(() => _error = 'Konfirmasi PIN tidak sama');
    }
    Navigator.pop(context, pin);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.create ? 'Buat PIN owner' : 'Masukkan PIN owner'),
    content: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.create)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('PIN ini dipakai untuk membuka harga modal, laba, gaji, dan aksi sensitif.'),
            ),
          Labeled(
            'PIN',
            TextField(
              controller: _pin,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (widget.create) ...[
            const SizedBox(height: 12),
            Labeled(
              'Ulangi PIN',
              TextField(
                controller: _confirm,
                obscureText: true,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    ),
    actions: [
      OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
      FilledButton(onPressed: _submit, child: const Text('Buka')),
    ],
  );
}
