import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
