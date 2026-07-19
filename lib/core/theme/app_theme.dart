import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'soft_haptic_splash.dart';

class AppTheme {
  static const _buttonAnim = Duration(milliseconds: 180);

  static const pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  static ButtonStyle _filledStyle({required Color bg, required Color fg}) =>
      FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: AppColors.lightInactive.withValues(alpha: 0.35),
        disabledForegroundColor: fg.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        animationDuration: _buttonAnim,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return fg.withValues(alpha: 0.14);
          }
          if (states.contains(WidgetState.hovered)) {
            return fg.withValues(alpha: 0.08);
          }
          return null;
        }),
      );

  static ButtonStyle _elevatedStyle({required Color bg, required Color fg}) =>
      ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: AppColors.lightInactive.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        animationDuration: _buttonAnim,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return fg.withValues(alpha: 0.14);
          }
          return null;
        }),
      );

  static ButtonStyle _outlinedStyle({
    required Color fg,
    required Color press,
  }) =>
      OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: fg, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        animationDuration: _buttonAnim,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return press.withValues(alpha: 0.12);
          }
          return null;
        }),
      );

  static ButtonStyle _textStyle({required Color fg, required Color press}) =>
      TextButton.styleFrom(
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        animationDuration: _buttonAnim,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return press.withValues(alpha: 0.12);
          }
          return null;
        }),
      );

  static ButtonStyle _iconStyle({required Color fg, required Color press}) =>
      IconButton.styleFrom(
        foregroundColor: fg,
        animationDuration: _buttonAnim,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return press.withValues(alpha: 0.14);
          }
          return null;
        }),
      );

  static ThemeData get lightTheme {
    const primary = AppColors.lightPrimary;
    const primaryDark = AppColors.lightPrimaryDark;
    const surface = AppColors.lightSurface;
    const background = AppColors.lightBackground;
    const text = AppColors.lightTextPrimary;

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(),
      splashFactory: const SoftHapticSplashFactory(),
      splashColor: primary.withValues(alpha: 0.14),
      highlightColor: primary.withValues(alpha: 0.06),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: surface,
        error: AppColors.danger,
      ),
      pageTransitionsTheme: pageTransitions,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        foregroundColor: text,
        iconTheme: IconThemeData(color: text),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      dividerColor: AppColors.lightBorder,
      cardColor: surface,
      canvasColor: background,
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryDark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledStyle(bg: primaryDark, fg: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedStyle(bg: primaryDark, fg: Colors.white),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(fg: primaryDark, press: primary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textStyle(fg: primaryDark, press: primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _iconStyle(fg: text, press: primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 2,
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return primaryDark;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.45);
          }
          return null;
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    const primary = AppColors.darkPrimary;
    const primaryDark = AppColors.darkPrimaryDark;
    const surface = AppColors.darkSurface;
    const background = AppColors.darkBackground;
    const text = AppColors.darkTextPrimary;

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      splashFactory: const SoftHapticSplashFactory(),
      splashColor: primary.withValues(alpha: 0.18),
      highlightColor: primary.withValues(alpha: 0.08),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        surface: surface,
        error: Color(0xFFEF5350),
        onPrimary: Color(0xFF041014),
        onSurface: text,
      ),
      pageTransitionsTheme: pageTransitions,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        foregroundColor: text,
        iconTheme: IconThemeData(color: text),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      dividerColor: AppColors.darkBorder,
      cardColor: surface,
      canvasColor: background,
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledStyle(bg: primaryDark, fg: const Color(0xFF041014)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedStyle(bg: primaryDark, fg: const Color(0xFF041014)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(fg: primary, press: primary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textStyle(fg: primary, press: primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _iconStyle(fg: text, press: primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 2,
        backgroundColor: primaryDark,
        foregroundColor: Color(0xFF041014),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.4);
          }
          return null;
        }),
      ),
    );
  }
}
