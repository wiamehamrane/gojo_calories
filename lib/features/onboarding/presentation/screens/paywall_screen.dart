import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:gojocalories/core/network/api_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      // 1. Fetch user info to pass to Stripe
      final res = await ApiClient.instance.get('auth/me');
      if (res.statusCode == 200) {
        final userId = res.data['id'].toString();
        final userEmail = res.data['email'].toString();

        // 2. Build Stripe URL safely — Uri.https constructor handles all encoding
        //    This prevents malformed URLs from breaking the Stripe checkout page.
        final Uri stripeUrl = Uri.https(
          'pay.gojocalories.com',
          '/b/4gM00j7278bA4jMfyW0co00',
          {
            'client_reference_id': userId,
            'prefilled_email': userEmail,
          },
        );

        // 3. Open URL in external browser
        final launched = await launchUrl(
          stripeUrl,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          throw Exception('Could not launch Stripe URL');
        }

        // 4. Show "I've completed payment" button — do NOT redirect yet.
        //    Payment is only confirmed when the Stripe webhook fires and
        //    sets has_paid = true on the backend.
        if (mounted) {
          setState(() => _browserOpened = true);
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
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: (_isLoading || _isVerifying) ? null : () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.crown,
                    size: 64,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Headline
              const Text(
                'Unlock GojoCalories Pro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Get full access to personalized AI nutrition tracking and advanced stats.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Feature List
              _buildFeatureRow('AI-Powered Food Logging'),
              _buildFeatureRow('Advanced Macro Analytics'),
              _buildFeatureRow('Personalized Meal Plans'),
              _buildFeatureRow('Priority Support'),
              
              const Spacer(),

              // Pricing Text
              Text(
                '3 Days Free, then \$9.99/month',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),

              // CTA Button — changes to "I've Completed Payment" after browser opens
              if (!_browserOpened)
                ElevatedButton(
                  onPressed: _isLoading ? null : _subscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
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
              Text(
                'Cancel anytime. Secure checkout via Stripe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
