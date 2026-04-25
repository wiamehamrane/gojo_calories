import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    // Set immersive status bar so the splash fills the entire screen
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2400), () async {
      if (!mounted) return;
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
            throw Exception('Auth check failed');
          }
        } catch (_) {
          if (prefs.getBool('is_onboarded') == true) {
            router.go('/home');
          } else {
            router.go('/auth');
          }
        }
      } else {
        router.go('/auth');
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Subtle radial glow behind logo ──────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Center content ──────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mark — monochrome squircle icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.12),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'GJ',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.75, 0.75),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fade(duration: 400.ms),

                const SizedBox(height: 28),

                // App name
                const Text(
                  'GojoCalories',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                )
                    .animate()
                    .fade(delay: 350.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 350.ms,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 8),

                // Tagline
                const Text(
                  'Track smarter. Eat better.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white38,
                    letterSpacing: 0.2,
                  ),
                )
                    .animate()
                    .fade(delay: 550.ms, duration: 400.ms),
              ],
            ),
          ),

          // ── Loading indicator at bottom ─────────────────────────────────
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Animated dot-row loader
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (_, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final phase = ((_shimmerController.value * 3) - i).clamp(0.0, 1.0);
                        final scale = 0.5 + 0.5 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 6 * scale,
                          height: 6 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.3 + 0.5 * scale.clamp(0.0, 1.0)),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Powered by Gemini AI',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white24,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            )
                .animate()
                .fade(delay: 700.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}
