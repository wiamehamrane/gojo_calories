import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/locale_provider.dart';
import '../core/localization/translations.dart';
import 'router.dart';

class GojoCaloriesApp extends ConsumerWidget {
  const GojoCaloriesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final isRtl = Translations.isRtl(lang);
    final flutterLocale = toFlutterLocale(lang);

    final textTheme = isRtl
        ? GoogleFonts.cairoTextTheme(AppTheme.lightTheme.textTheme)
        : AppTheme.lightTheme.textTheme;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: MaterialApp.router(
        title: 'GojoCalories',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(textTheme: textTheme),
        routerConfig: appRouter,
        locale: flutterLocale,
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
          Locale('ar'),
          Locale('es'),
          Locale('nl'),
          Locale('pt'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
