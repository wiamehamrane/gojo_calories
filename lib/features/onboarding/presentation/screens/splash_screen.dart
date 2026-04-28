import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Gentle floating animation
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Glow pulse animation
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2800), () async {
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

            // Log in to RevenueCat using internal user ID
            try {
              final String userId = data['id'].toString();
              await Purchases.logIn(userId);
            } catch (e) {
              debugPrint('RevenueCat login failed: $e');
            }

            // Check entitlement locally
            bool hasPro = false;
            try {
              final customerInfo = await Purchases.getCustomerInfo();
              final entitlement =
                  customerInfo.entitlements.all['gojocalories Pro'];
              if (entitlement != null && entitlement.isActive) {
                hasPro = true;
              }
            } catch (e) {
              debugPrint('Failed to get customer info: $e');
            }

            if (data['current_weight'] == null) {
              router.go('/onboarding/weight');
            } else if (!hasPro && data['has_paid'] != true) {
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
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF0),
      body: Stack(
        children: [
          // Soft gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFFE8F5D8),
                  Color(0xFFF5FAF0),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),

          // Decorative circles in background
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8BC34A).withValues(alpha: 0.06),
              ),
            ),
          ),

          // Main centered content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avocado icon with glow + float
                AnimatedBuilder(
                  animation: Listenable.merge([_floatCtrl, _glowCtrl]),
                  builder: (context, child) {
                    final floatOffset = -8.0 * _floatCtrl.value;
                    final glowOpacity = 0.25 + 0.15 * _glowCtrl.value;
                    final glowRadius = 28.0 + 12.0 * _glowCtrl.value;
                    return Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5AAD30)
                                  .withValues(alpha: glowOpacity),
                              blurRadius: glowRadius,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/icons/avocado.svg',
                    width: 140,
                    height: 140,
                  ),
                )
                    .animate()
                    .fade(duration: 700.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 36),

                // App name
                const Text(
                  'GojoCalories',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A1A),
                    letterSpacing: -0.5,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fade(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0.0, duration: 600.ms),

                const SizedBox(height: 10),

                // Tagline
                const Text(
                  'Eat smart. Live well.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6A9B5A),
                    letterSpacing: 0.3,
                  ),
                )
                    .animate(delay: 600.ms)
                    .fade(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0.0, duration: 600.ms),

                const SizedBox(height: 80),

                // Loading dots
                _LoadingDots()
                    .animate(delay: 900.ms)
                    .fade(duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _controllers.add(ctrl);
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  const Color(0xFF8BC34A).withValues(alpha: 0.3),
                  const Color(0xFF4CAF50),
                  _controllers[i].value,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
