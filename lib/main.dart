import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/router.dart';
import 'core/providers/locale_provider.dart';
import 'core/localization/translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Could not load .env file: $e");
  }

  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  // Load persisted locale before creating the widget tree
  final container = ProviderContainer();
  await container.read(localeProvider.notifier).loadSaved();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const GojoCaloriesApp(),
  ));
}

class GojoCaloriesApp extends ConsumerWidget {
  const GojoCaloriesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final isRtl = Translations.isRtl(lang);
    final flutterLocale = toFlutterLocale(lang);

    // Use Cairo font for Arabic (supports Arabic script beautifully)
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
