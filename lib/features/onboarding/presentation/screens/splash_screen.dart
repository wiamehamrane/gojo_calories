import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 2600), () async {
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
    _pulseController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background: large radial glow (lime) centred high ───────────
          Positioned(
            top: size.height * 0.1,
            left: size.width * 0.5 - 180,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF97FF5A).withValues(alpha: 0.14),
                        const Color(0xFF97FF5A).withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Second smaller teal glow bottom-right ───────────────────────
          Positioned(
            bottom: size.height * 0.1,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00B4CC).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Centre content ──────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo container with neon lime border glow ─────────────
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF97FF5A)
                            .withValues(alpha: 0.35 * _pulseAnim.value),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF97FF5A)
                              .withValues(alpha: 0.20 * _pulseAnim.value),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/avocado.svg',
                      width: 56,
                      height: 56,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      duration: 650.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fade(duration: 450.ms),

                const SizedBox(height: 30),

                // ── App name ───────────────────────────────────────────────
                const Text(
                  'GojoCalories',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.2,
                    height: 1.0,
                  ),
                )
                    .animate()
                    .fade(delay: 380.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.18,
                      end: 0,
                      delay: 380.ms,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 10),

                // ── Tagline ────────────────────────────────────────────────
                const Text(
                  'Track smarter. Eat better.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                    letterSpacing: 0.3,
                  ),
                ).animate().fade(delay: 580.ms, duration: 400.ms),
              ],
            ),
          ),

          // ── Loading dots at bottom ──────────────────────────────────────
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: _PulsingDots(controller: _pulseController),
          )
              .animate()
              .fade(delay: 750.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing three-dot loader
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingDots extends StatelessWidget {
  final AnimationController controller;
  const _PulsingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.33 of the cycle
            final phase = ((controller.value * 3) - i).clamp(0.0, 1.0);
            final brightness = (0.5 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
            final size = 5.0 + 3.0 * brightness;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  const Color(0xFF333333),
                  const Color(0xFF97FF5A),
                  brightness,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
