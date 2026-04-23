import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (!mounted) return;
        final router = GoRouter.of(context);
        if (token != null && token.isNotEmpty) {
          try {
            final res = await ApiClient.instance.get('auth/me');
            if (res.statusCode == 200) {
              final data = res.data;
              if (data['current_weight'] == null) {
                router.go('/onboarding/weight');
              } else if (data['has_paid'] != true) {
                router.go('/onboarding/paywall');
              } else {
                await prefs.setBool('is_onboarded', true);
                router.go('/home');
              }
            } else {
              throw Exception("Auth check failed");
            }
          } catch (e) {
            // Offline or API error fallback
            if (prefs.getBool('is_onboarded') == true) {
              router.go('/home');
            } else {
              router.go('/auth'); // Safe fallback if state is unknown
            }
          }
        } else {
          router.go('/auth');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/avocado.svg',
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'GojoCalories',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: AppColors.textPrimary),
            ).animate().fade(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Track your calories with just a picture',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ).animate().fade(delay: 500.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
