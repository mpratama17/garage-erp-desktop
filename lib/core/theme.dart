import 'package:flutter/material.dart';

/// Token desain — sumber: docs/design.md. Layar tidak boleh menulis warna/ukuran mentah.
abstract final class C {
  static const bg = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E7EC);
  static const field = Color(0xFFF2F4F7); // latar input
  static const ink = Color(0xFF111318);
  static const inkMuted = Color(0xFF5B6170);
  static const primary = Color(0xFFC2410C);
  static const primarySoft = Color(0xFFFFF1E8);
  static const brandOrange = Color(0xFFF07A1E);
  static const danger = Color(0xFFB42318);
}

/// Pasangan latar/teks untuk pill status.
enum Tone {
  success(Color(0xFFE7F6EC), Color(0xFF1B6B3A)),
  warning(Color(0xFFFFF4DB), Color(0xFF8A5A00)),
  danger(Color(0xFFFDECEC), Color(0xFFB42318)),
  info(Color(0xFFEAF1FF), Color(0xFF1D4ED8)),
  neutral(Color(0xFFEEF0F3), Color(0xFF475467));

  const Tone(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

abstract final class S {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
  static const rCard = 14.0, rInput = 8.0;
  static const sidebar = 232.0, formMax = 720.0, row = 48.0;
}

abstract final class T {
  static const _base = TextStyle(fontFamily: 'Inter', color: C.ink);
  static final pageTitle = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700);
  static final pageSubtitle = _base.copyWith(fontSize: 14, color: C.inkMuted);
  static final section = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static final body = _base.copyWith(fontSize: 14);
  static final label = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: C.inkMuted);
  static final fieldLabel = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600);
  static final kpi = _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700);
  static final money = body.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

ThemeData buildTheme() {
  final inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(S.rInput), borderSide: BorderSide.none);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(S.rInput));
  const btnSize = Size(64, 40);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.primary, primary: C.primary, surface: C.surface, error: C.danger),
    scaffoldBackgroundColor: C.bg,
    fontFamily: 'Inter',
    // Input & teks isi = 14 (design.md §3), bukan 16 bawaan Material.
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 14),
      bodyMedium: TextStyle(fontSize: 14),
      titleMedium: TextStyle(fontSize: 14), // teks terpilih di dropdown
    ),
    dividerColor: C.border,
    dividerTheme: const DividerThemeData(color: C.border, space: 1, thickness: 1),
    cardTheme: CardThemeData(
      color: C.surface,
      elevation: 1,
      shadowColor: const Color(0x1F101828), // bayangan lembut seperti referensi
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(S.rCard),
        side: const BorderSide(color: Color(0xFFEEF0F3)),
      ),
    ),
    // Label ada DI ATAS field (widget Labeled); field = latar abu tanpa garis, fokus = garis oranye.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.field,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.md),
      border: inputBorder,
      enabledBorder: inputBorder,
      disabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: C.primary, width: 1.5)),
      errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: C.danger)),
      focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: C.danger, width: 1.5)),
      hintStyle: T.body.copyWith(color: C.inkMuted),
      prefixStyle: T.body.copyWith(color: C.inkMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: btnSize, shape: shape, backgroundColor: C.primary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: btnSize,
        shape: shape,
        foregroundColor: C.ink,
        side: const BorderSide(color: C.border),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: btnSize, shape: shape),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(S.rCard)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, width: 480),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
