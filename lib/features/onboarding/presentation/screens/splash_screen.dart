import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    Future.delayed(const Duration(milliseconds: 2000), () async {
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
