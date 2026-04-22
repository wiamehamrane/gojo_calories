import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  // Guard: tracks if the sheet was initialized but not completed.
  // Prevents bypassing payment when user re-opens the app after dismissing.
  bool _isPaymentSheetInitialized = false;

  void _startTrial() async {
    setState(() => _isLoading = true);
    try {
      // 1. Only fetch a new SetupIntent if we don't have one pending already.
      if (!_isPaymentSheetInitialized) {
        final paymentRes = await ApiClient.instance.post('payments/create-checkout-session', data: {});
        if (paymentRes.statusCode != 200) {
          throw Exception("Payment Initialization Failed");
        }
        final data = paymentRes.data;

        // 2. Initialize Stripe Payment Sheet for a SetupIntent (Free Trial)
        Stripe.publishableKey = data['publishableKey'];
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            setupIntentClientSecret: data['setupIntent'],
            merchantDisplayName: 'GojoCalories VIP',
            customerId: data['customer'],
            customerEphemeralKeySecret: data['ephemeralKey'],
            style: ThemeMode.light,
            billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
              address: AddressCollectionMode.full,
              name: CollectionMode.always,
            ),
          ),
        );
        if (!mounted) return;
        setState(() => _isPaymentSheetInitialized = true);
      }

      // 3. Present the Payment Sheet UI
      if (!mounted) return;
      await Stripe.instance.presentPaymentSheet();

      // 4. Card saved — call backend to create the trial subscription
      if (!mounted) return;
      final confirmRes = await ApiClient.instance.post('payments/confirm-setup', data: {});
      if (confirmRes.statusCode != 200) {
        throw Exception("Failed to confirm subscription setup.");
      }

      // 5. Success — reset guard, mark onboarded, and navigate to home.
      if (!mounted) return;
      setState(() => _isPaymentSheetInitialized = false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarded', true);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Free trial started! Welcome to Pro.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } on StripeException catch (e) {
      // User dismissed the sheet or card failed — reset so they can try again.
      if (mounted) {
        setState(() => _isPaymentSheetInitialized = false);
        final msg = e.error.localizedMessage ?? 'Payment cancelled.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange),
        );
      }
      debugPrint('Stripe error: ${e.error.localizedMessage}');
    } catch (e) {
      if (mounted) {
        setState(() => _isPaymentSheetInitialized = false);
        String errMsg = 'Something went wrong. Please check your connection and try again.';
        if (e is DioException && e.response?.data != null) {
          final errData = e.response!.data;
          if (errData is Map && errData.containsKey('detail')) {
            errMsg = errData['detail'].toString();
          }
        }
        _showErrorDialog(errMsg);
      }
      debugPrint('Payment error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: _isLoading ? null : () => context.go('/onboarding/weight'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Unlock Pro.',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ).animate().slideY(begin: 0.1, duration: 500.ms).fadeIn(),

              const SizedBox(height: 8),

              const Text(
                'Experience the full power of AI nutrition tracking. Risk-free.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 48),

              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 30, spreadRadius: 0)
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Monthly VIP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    const Text(
                      '\$7.99',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -2),
                    ),
                    const SizedBox(height: 4),
                    const Text('per month after trial', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 32),
                    _buildFeatureRow('3 Days Free Access'),
                    _buildFeatureRow('AI Semantic Estimations'),
                    _buildFeatureRow('Barcode Snap Engine'),
                    _buildFeatureRow('Advanced Metabolic Trends'),
                  ],
                ),
              ).animate().scale(delay: 300.ms, duration: 500.ms, begin: const Offset(0.95, 0.95), curve: Curves.easeOutCubic).fadeIn(),

              const Spacer(),

              // Primary CTA
              GestureDetector(
                onTap: _isLoading ? null : _startTrial,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? AppColors.primaryDark.withValues(alpha: 0.7)
                        : AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Start 3-Day Free Trial',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ).animate().slideY(begin: 0.3, delay: 500.ms, duration: 400.ms).fadeIn(),

              const SizedBox(height: 12),

              Center(
                child: const Text(
                  'Cancel anytime in Settings before trial ends.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 600.ms),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
