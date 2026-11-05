import 'package:flutter/material.dart';

/// 부드러운 초록·크림 톤, 둥근 모서리, 큰 글씨. (CLAUDE.md 7절 디자인 톤)
class AppColors {
  AppColors._();

  static const sprout = Color(0xFF6DB65F); // 새싹 초록 (species.json 기본 잎색과 맞춤)
  static const leafDeep = Color(0xFF3F7D3A);
  static const cream = Color(0xFFFBF7EC);
  static const creamDeep = Color(0xFFF3ECD9);
  static const soil = Color(0xFF8A6A4F);
  static const ink = Color(0xFF2F3A2C);

  static const nightBg = Color(0xFF171C16);
  static const nightSurface = Color(0xFF222A20);
  static const nightLeaf = Color(0xFF9BD08C);
}

const double kRadius = 20;

ThemeData buildLightTheme() => _build(
      ColorScheme.fromSeed(
        seedColor: AppColors.sprout,
        primary: AppColors.leafDeep,
        surface: AppColors.cream,
        onSurface: AppColors.ink,
        surfaceContainerLow: AppColors.creamDeep,
      ),
    );

ThemeData buildDarkTheme() => _build(
      ColorScheme.fromSeed(
        seedColor: AppColors.sprout,
        brightness: Brightness.dark,
        primary: AppColors.nightLeaf,
        surface: AppColors.nightBg,
        surfaceContainerLow: AppColors.nightSurface,
      ),
    );

ThemeData _build(ColorScheme scheme) {
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius));
  // 기본보다 한 단계 큰 본문 글씨.
  final text = base.textTheme.copyWith(
    bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.5),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
  );
  const minTap = Size(64, 56);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text,
    cardTheme: CardThemeData(
      shape: shape,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minTap,
        shape: shape,
        textStyle: text.titleMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: minTap, shape: shape, textStyle: text.titleMedium),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: text.titleMedium),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadius), borderSide: BorderSide.none),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
  );
}
