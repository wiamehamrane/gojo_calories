
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/localization/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("60019fa3-3a1b-4c1e-a4dc-22ac49dc32de");
  OneSignal.Notifications.requestPermission(true);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Could not load .env file: $e");
  }
  await EnvConfig.prepare();
  debugPrint(
    'APP_ENV=${EnvConfig.appEnv} target=${EnvConfig.runtimeTarget} '
    'API_URL=${EnvConfig.apiBaseUrl}',
  );

  final container = ProviderContainer();
  await container.read(localeProvider.notifier).loadSaved();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GojoCaloriesApp(),
    ),
  );
}
