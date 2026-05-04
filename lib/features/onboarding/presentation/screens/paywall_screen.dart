import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gojocalories/core/network/api_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _browserOpened = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBrowserOpenedState();
  }

  Future<void> _checkBrowserOpenedState() async {
    final prefs = await SharedPreferences.getInstance();
    final opened = prefs.getBool('stripe_browser_opened') ?? false;
    if (opened && mounted) {
      setState(() => _browserOpened = true);
      _verifyPayment();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _browserOpened && !_isVerifying) {
      _verifyPayment();
    }
  }

  Future<void> _openPricingTable() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.get('auth/me');
      final userId = res.data['user_id']?.toString() ?? '';
      final email = res.data['email']?.toString() ?? '';

      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body { margin: 0; padding: 0; background-color: #FFFFFF; }
  </style>
</head>
<body>
  <script async src="https://js.stripe.com/v3/pricing-table.js"></script>
  <stripe-pricing-table 
    pricing-table-id="prctbl_1TTAg4GkYdm9mdqzTV8XQisQ"
    publishable-key="pk_live_51SxSM6GkYdm9mdqzm28mrh81g9APbvlhQc06fBUKac3ZDiM6gRTWKP5b0XoT7MyWZ8B95u0eZa26Ct2atQ08Dth900ovPfEVB7"
    client-reference-id="$userId"
    customer-email="$email">
  </stripe-pricing-table>
</body>
</html>
''';

      if (mounted) {
        final result = await context.push('/stripe-checkout', extra: {
          'htmlContent': htmlContent,
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('stripe_browser_opened', true);
        setState(() => _browserOpened = true);

        if (result is String && result.isNotEmpty) {
          _completeCheckout(result);
        } else if (result == true) {
          _verifyPayment();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: \${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeCheckout(String sessionId) async {
    setState(() => _isVerifying = true);
    try {
      final res = await ApiClient.instance.post('payments/complete-checkout', data: {
        'session_id': sessionId,
      });

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_onboarded', true);
        await prefs.remove('stripe_browser_opened');
        if (!mounted) return;
        context.go('/home');
        return;
      } else {
        throw Exception(res.data['detail'] ?? 'Failed to complete checkout');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: \${e.toString()}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _verifyPayment() async {
    setState(() => _isVerifying = true);
    try {
      for (int attempt = 1; attempt <= 5; attempt++) {
        await Future.delayed(const Duration(seconds: 2));
        final res = await ApiClient.instance.get('auth/me');
        if (res.statusCode == 200 && res.data['has_paid'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_onboarded', true);
          await prefs.remove('stripe_browser_opened');
          if (!mounted) return;
          context.go('/home');
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment not confirmed yet. Please try again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Verification error: \${e.toString()}'),
            backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Design Tokens
    const Color background = Colors.white;
    const Color primaryDark = Color(0xFF1E3A1A); // Very dark green
    const Color primaryMedium = Color(0xFF6B8B67); // Medium muted green
    const Color featureBg = Color(0xFFF8FDF7); // Very light green

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: primaryDark),
          onPressed: (_isLoading || _isVerifying)
              ? null
              : () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('access_token');
                  await prefs.remove('stripe_browser_opened');
                  if (context.mounted) context.go('/auth');
                },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        const Center(
                          child: Text('🥑', style: TextStyle(fontSize: 48)),
                        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 24),
                        
                        // Headline
                        const Text(
                          'GojoCalories',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: primaryDark,
                            letterSpacing: -0.5,
                          ),
                        ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        const Text(
                          'Your AI-Powered Nutrition Coach',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: primaryMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(delay: 150.ms),
                        const SizedBox(height: 40),

                        // Feature List
                        _buildFeatureRow('AI Food Scanner', 'Snap a photo, get instant calories & macros', featureBg, primaryMedium, 200),
                        _buildFeatureRow('Smart Daily Tracking', 'Stay on target with personalized goals', featureBg, primaryMedium, 250),
                        _buildFeatureRow('Unlimited Meal History', 'Track your journey, day by day', featureBg, primaryMedium, 300),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CTA Button
              if (!_browserOpened)
                ElevatedButton(
                  onPressed: _isLoading ? null : _openPricingTable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'View Pricing & Start Journey',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                )
              else ...[
                OutlinedButton(
                  onPressed: _isVerifying ? null : _openPricingTable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryDark,
                    side: const BorderSide(color: primaryDark),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Reopen Payment Page',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("I've Completed Payment ✓",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],

              const SizedBox(height: 16),

              // Footer
              const Text(
                'Cancel anytime. No commitment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Restore Purchase | Privacy Policy | Terms of Use',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String title, String subtitle, Color bgColor,
      Color textColor, int delayMs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.check, color: textColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.1, duration: 400.ms).fadeIn(delay: delayMs.ms);
  }
}
