import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF28344D);
  static const forest = Color(0xFF55B9A8);
  static const leaf = Color(0xFFDDF4CE);
  static const coral = Color(0xFFFF817B);
  static const butter = Color(0xFFFFD978);
  static const cream = Color(0xFFFFF9F2);
  static const white = Color(0xFFFFFEFC);
  static const muted = Color(0xFF718095);
  static const line = Color(0xFFE9E1D7);
  static const sky = Color(0xFFDFF3FF);
  static const lavender = Color(0xFFEAE4FF);
  static const sand = Color(0xFFF7E5BF);
  static const field = Color(0xFFBCE8D1);
  static const scoreboard = Color(0xFFEAF2F5);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: Brightness.light,
      primary: AppColors.forest,
      secondary: AppColors.coral,
      tertiary: AppColors.butter,
      surface: AppColors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'GowunDodum',
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
            fontFamily: 'Jua',
            color: AppColors.ink,
            fontSize: 33,
            height: 1.1,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.8),
        headlineSmall: const TextStyle(
            fontFamily: 'Jua',
            color: AppColors.ink,
            fontSize: 24,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.4),
        titleLarge: const TextStyle(
            fontFamily: 'Jua',
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2),
        titleMedium: const TextStyle(
            fontFamily: 'Jua', color: AppColors.ink, fontSize: 17),
        bodyLarge: const TextStyle(
            fontFamily: 'GowunDodum',
            color: AppColors.ink,
            height: 1.45,
            fontWeight: FontWeight.w600),
        bodyMedium: const TextStyle(
            fontFamily: 'GowunDodum',
            color: AppColors.muted,
            height: 1.42,
            fontWeight: FontWeight.w600),
        labelLarge: const TextStyle(
            fontFamily: 'GowunDodum', fontWeight: FontWeight.w800),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
            fontFamily: 'Jua',
            color: AppColors.ink,
            fontSize: 23,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white.withValues(alpha: .97),
        elevation: 0,
        shadowColor: AppColors.ink.withValues(alpha: .08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: AppColors.line)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFCF7),
        labelStyle: const TextStyle(
          color: AppColors.muted,
          fontFamily: 'GowunDodum',
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: AppColors.forest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.forest, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(
              fontFamily: 'Jua', fontSize: 17, fontWeight: FontWeight.w400),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          textStyle: const TextStyle(
            fontFamily: 'GowunDodum',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        side: BorderSide.none,
        backgroundColor: AppColors.scoreboard,
        selectedColor: AppColors.leaf,
        labelStyle: const TextStyle(
          fontFamily: 'GowunDodum',
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.muted,
        indicatorColor: AppColors.coral,
        labelStyle: TextStyle(fontFamily: 'Jua', fontSize: 16),
        unselectedLabelStyle:
            TextStyle(fontFamily: 'GowunDodum', fontWeight: FontWeight.w800),
        dividerColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.line,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'GowunDodum',
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.forest,
        linearTrackColor: AppColors.line,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(
          fontFamily: 'GowunDodum',
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(
          fontFamily: 'GowunDodum',
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line),
    );
  }
}
