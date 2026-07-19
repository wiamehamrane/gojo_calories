import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../core/localization/locale_provider.dart';
import '../core/localization/translations.dart';
import 'router.dart';

class GojoCaloriesApp extends ConsumerWidget {
  const GojoCaloriesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isRtl = Translations.isRtl(lang);
    final flutterLocale = toFlutterLocale(lang);

    final lightBase = AppTheme.lightTheme;
    final darkBase = AppTheme.darkTheme;
    final lightText = isRtl
        ? GoogleFonts.cairoTextTheme(lightBase.textTheme)
        : lightBase.textTheme;
    final darkText = isRtl
        ? GoogleFonts.cairoTextTheme(darkBase.textTheme)
        : darkBase.textTheme;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: MaterialApp.router(
        title: 'GojoCalories',
        debugShowCheckedModeBanner: false,
        theme: lightBase.copyWith(textTheme: lightText),
        darkTheme: darkBase.copyWith(textTheme: darkText),
        themeMode: themeMode,
        routerConfig: appRouter,
        locale: flutterLocale,
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
          Locale('ar'),
          Locale('es'),
          Locale('nl'),
          Locale('pt'),
          Locale('zh'),
          Locale('ru'),
          Locale('de'),
          Locale('ja'),
          Locale('ko'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final brightness = Theme.of(context).brightness;
          AppColors.applyBrightness(brightness);
          final overlay = brightness == Brightness.dark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: AppColors.darkBackground,
                  systemNavigationBarIconBrightness: Brightness.light,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: AppColors.lightBackground,
                  systemNavigationBarIconBrightness: Brightness.dark,
                );
          // AppColors uses static brightness — force the routed tree to rebuild
          // so every screen re-reads the palette (animated widgets already did).
          return KeyedSubtree(
            key: ValueKey(brightness),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlay,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
