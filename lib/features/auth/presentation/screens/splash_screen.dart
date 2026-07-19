import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/routing/app_navigation.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), _bootstrap);
    });
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    final auth = ref.read(authRepositoryProvider);

    try {
      final hasToken = await auth.hasStoredToken();
      if (!hasToken) {
        debugPrint('[Splash] No token → auth');
        if (!mounted) return;
        AppNavigation.go(RoutePaths.auth, context: context);
        return;
      }

      debugPrint('[Splash] Token found, fetching profile…');
      final data = await auth.getMe().timeout(const Duration(seconds: 12));
      if (!mounted) return;

      debugPrint(
        '[Splash] Profile loaded: verified=${data['is_email_verified']}, '
        'weight=${data['current_weight']}, paid=${data['has_paid']}',
      );

      if (data['is_email_verified'] != true) {
        final email = data['email'] as String? ?? '';
        AppNavigation.go(
          '${RoutePaths.verifyOtp}?email=${Uri.encodeComponent(email)}',
          context: context,
        );
        return;
      }

      if (data['current_weight'] == null) {
        debugPrint('[Splash] → weight setup');
        AppNavigation.go(RoutePaths.weightSetup, context: context);
      } else if (data['has_paid'] != true) {
        debugPrint('[Splash] → paywall');
        AppNavigation.go(RoutePaths.paywall, context: context);
      } else {
        await auth.setOnboarded(true);
        debugPrint('[Splash] → home');
        if (!mounted) return;
        AppNavigation.go(RoutePaths.home, context: context);
      }
    } catch (e, st) {
      debugPrint('[Splash] Bootstrap failed: $e\n$st');
      await auth.clearSession();
      if (!mounted) return;
      AppNavigation.go(RoutePaths.auth, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    AppColors.applyBrightness(brightness);
    final overlay = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Image.asset(
            ImageAsset.logoHeader,
            width: 120,
            height: 120,
          ),
        ),
      ),
    );
  }
}
