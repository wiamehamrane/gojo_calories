import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gojocalories/core/network/api_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/theme/app_colors.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _browserOpened = false; // tracks if user already opened Stripe browser
  bool _isVerifying = false;   // tracks if we're polling backend for payment

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
      // Auto-verify if they just returned and the flag is set
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

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get user ID for reference
      final res = await ApiClient.instance.get('auth/me');
      if (res.statusCode != 200) throw Exception('Failed to get user info');
      final userId = res.data['user_id'].toString();
      final userEmail = res.data['email']?.toString() ?? '';

      // 2. Build Pricing Table HTML
      final pricingTableHtml = """
<!DOCTYPE html>
<html>
<head>
  <title>Pricing Table</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script async src="https://js.stripe.com/v3/pricing-table.js"></script>
  <style>
    body { background-color: #0A0A0A; margin: 0; padding: 0; }
  </style>
</head>
<body>
  <stripe-pricing-table 
    pricing-table-id="prctbl_1TTAg4GkYdm9mdqzTV8XQisQ"
    publishable-key="pk_live_51SxSM6GkYdm9mdqzm28mrh81g9APbvlhQc06fBUKac3ZDiM6gRTWKP5b0XoT7MyWZ8B95u0eZa26Ct2atQ08Dth900ovPfEVB7"
    client-reference-id="$userId"
    customer-email="$userEmail"
  >
  </stripe-pricing-table>
</body>
</html>
""";

      // 3. Open HTML in WebView
      if (mounted) {
        final result = await context.push('/stripe-checkout', extra: {
          'htmlContent': pricingTableHtml,
        });
        
        // 3. If they returned, check state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('stripe_browser_opened', true);
        setState(() => _browserOpened = true);

        // If result was true (completed), auto-verify
        if (result == true) {
          _verifyPayment();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Polls auth/me up to 5 times (every 2s) checking has_paid == true.
  /// Only navigates to /home if the backend confirms the payment.
  Future<void> _verifyPayment() async {
    setState(() => _isVerifying = true);
    try {
      for (int attempt = 1; attempt <= 5; attempt++) {
        await Future.delayed(const Duration(seconds: 2));
        final res = await ApiClient.instance.get('auth/me');
        if (res.statusCode == 200 && res.data['has_paid'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_onboarded', true);
          await prefs.remove('stripe_browser_opened'); // Clear the flag on success
          if (!mounted) return;
          context.go('/home');
          return;
        }
      }
      // Payment not confirmed after 5 attempts (~10 seconds)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment not confirmed yet — it may take a moment. Please try again.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppColors.textPrimary),
          onPressed: (_isLoading || _isVerifying) ? null : () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
            await prefs.remove('stripe_browser_opened'); // clear flag on logout
            if (context.mounted) context.go('/auth');
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Icon / Hero Image
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('🥑', style: TextStyle(fontSize: 40)),
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              
              // Headline
              const Text(
                'Unlock GojoCalories Pro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),
              const SizedBox(height: 16),
              
              // Subtitle
              const Text(
                'Get full access to personalized AI nutrition tracking and advanced stats.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 48),

              // Feature List
              _buildFeatureRow('AI-Powered Food Logging', 200),
              _buildFeatureRow('Advanced Macro Analytics', 250),
              _buildFeatureRow('Personalized Meal Plans', 300),
              _buildFeatureRow('Priority Support', 350),
              
              const Spacer(),

              // Pricing Text
              const Text(
                '3 Days Free, then \$4.20/month',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),

              // CTA Button — changes to "I've Completed Payment" after browser opens
              if (!_browserOpened)
                ElevatedButton(
                  onPressed: _isLoading ? null : _subscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Start 3-Day Free Trial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )
              else ...[
                // Step 1: Reopen Stripe (in case user closed it)
                OutlinedButton(
                  onPressed: _isVerifying ? null : _subscribe,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Reopen Payment Page'),
                ),
                const SizedBox(height: 12),
                // Step 2: Confirm payment after completing checkout in browser
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "I've Completed Payment ✓",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],

              const SizedBox(height: 16),
              
              // Terms/Privacy
              const Text(
                'Cancel anytime. Secure checkout via Stripe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPlaceholder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, int delayMs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.check, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ).animate().slideX(begin: 0.1, duration: 400.ms).fadeIn(delay: delayMs.ms),
    );
  }
}
