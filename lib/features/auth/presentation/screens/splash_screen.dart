import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../core/routing/route_paths.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      final auth = ref.read(authRepositoryProvider);
      final router = GoRouter.of(context);

      if (await auth.hasStoredToken()) {
        try {
          final data = await auth.getMe();

          if (data['is_email_verified'] != true) {
            final email = data['email'] as String? ?? '';
            router.go(
              '${RoutePaths.verifyOtp}?email=${Uri.encodeComponent(email)}',
            );
            return;
          }

          if (data['current_weight'] == null) {
            router.go(RoutePaths.weightSetup);
          } else if (data['has_paid'] != true) {
            router.go(RoutePaths.paywall);
          } else {
            await auth.setOnboarded(true);
            router.go(RoutePaths.home);
          }
        } catch (_) {
          await auth.clearSession();
          router.go(RoutePaths.auth);
        }
      } else {
        router.go(RoutePaths.auth);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}
