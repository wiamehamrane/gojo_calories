import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gojocalories/features/auth/presentation/providers/iap_provider.dart';
import 'package:gojocalories/features/auth/data/services/iap_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selectedProductId;
  late final IAPService _iapService;

  @override
  void initState() {
    super.initState();
    _iapService = ref.read(iapServiceProvider);
    _iapService.status.addListener(_onIAPStatusChanged);
  }

  @override
  void dispose() {
    _iapService.status.removeListener(_onIAPStatusChanged);
    super.dispose();
  }

  void _onIAPStatusChanged() {
    final iapStatus = _iapService.status.value;

    if (!mounted) return;

    switch (iapStatus.state) {
      case IAPState.success:
      case IAPState.restored:
        _onPurchaseSuccess(iapStatus.state == IAPState.restored);
        break;
      case IAPState.error:
        if (iapStatus.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(iapStatus.errorMessage!),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        break;
      default:
        break;
    }

    // Trigger rebuild for loading states
    if (mounted) setState(() {});
  }

  Future<void> _onPurchaseSuccess(bool isRestore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRestore
              ? 'Purchase restored successfully!'
              : 'Subscription activated! 🎉',
        ),
        backgroundColor: const Color(0xFF1E3A1A),
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/home');
  }

  Future<void> _handlePurchase() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a plan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final product = _iapService.products.firstWhere(
      (p) => p.id == _selectedProductId,
    );
    await _iapService.buySubscription(product);
  }

  Future<void> _handleRestore() async {
    await _iapService.restorePurchases();
  }

  bool get _isProcessing {
    final state = _iapService.status.value.state;
    return state == IAPState.purchasing ||
        state == IAPState.verifying ||
        state == IAPState.loading;
  }

  @override
  Widget build(BuildContext context) {
    // Design Tokens
    const Color background = Colors.white;
    const Color primaryDark = Color(0xFF1E3A1A);
    const Color primaryMedium = Color(0xFF6B8B67);
    const Color featureBg = Color(0xFFF8FDF7);

    final productsAsync = ref.watch(iapProductsProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: primaryDark),
          onPressed: _isProcessing
              ? null
              : () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('access_token');
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon
                      const Center(
                        child: Text('🥑', style: TextStyle(fontSize: 48)),
                      ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
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
                      )
                          .animate()
                          .slideY(begin: 0.1, duration: 400.ms)
                          .fadeIn(),
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
                      _buildFeatureRow(
                        'AI Food Scanner',
                        'Snap a photo, get instant calories & macros',
                        featureBg,
                        primaryMedium,
                        200,
                      ),
                      _buildFeatureRow(
                        'Smart Daily Tracking',
                        'Stay on target with personalized goals',
                        featureBg,
                        primaryMedium,
                        250,
                      ),
                      _buildFeatureRow(
                        'Unlimited Meal History',
                        'Track your journey, day by day',
                        featureBg,
                        primaryMedium,
                        300,
                      ),

                      const SizedBox(height: 32),

                      // Plan Selection Cards
                      productsAsync.when(
                        data: (products) {
                          if (products.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Subscription plans are loading...\nPlease try again shortly.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF6B8B67),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }

                          // Auto-select yearly if nothing selected
                          if (_selectedProductId == null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedProductId =
                                      products.any(
                                            (p) => p.id == kYearlyProductId,
                                          )
                                          ? kYearlyProductId
                                          : products.first.id;
                                });
                              }
                            });
                          }

                          return Column(
                            children: products.map((product) {
                              return _buildPlanCard(
                                product: product,
                                isSelected:
                                    _selectedProductId == product.id,
                                primaryDark: primaryDark,
                                primaryMedium: primaryMedium,
                                onTap: () {
                                  setState(() {
                                    _selectedProductId = product.id;
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF1E3A1A),
                            ),
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.circleAlert,
                                  color: Colors.redAccent,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Could not load plans.\n${e.toString()}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () =>
                                      ref.refresh(iapProductsProvider),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CTA Button
              ElevatedButton(
                onPressed: _isProcessing ? null : _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _iapService.status.value.state == IAPState.verifying
                            ? 'Verifying...'
                            : 'Start Your Journey',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Footer
              const Text(
                'Cancel anytime. No commitment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // Restore & Legal Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isProcessing ? null : _handleRestore,
                    child: const Text(
                      'Restore Purchase',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(
                    '  |  ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://gojocalories.com/privacy')),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline),
                    ),
                  ),
                  const Text(
                    '  |  ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://gojocalories.com/tos')),
                    child: const Text(
                      'Terms of Use (EULA)',
                      style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required ProductDetails product,
    required bool isSelected,
    required Color primaryDark,
    required Color primaryMedium,
    required VoidCallback onTap,
  }) {
    final isYearly = product.id == kYearlyProductId;
    final label = isYearly ? 'Yearly' : 'Monthly';
    final subtitle = isYearly ? 'Best Value — Save 57%' : 'Flexible month-to-month';

    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryDark.withValues(alpha: 0.06)
              : const Color(0xFFF8FDF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryDark : const Color(0xFFE8E8E8),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryDark : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryDark,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primaryDark : Colors.black87,
                        ),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: primaryMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Text(
              product.price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected ? primaryDark : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (isYearly ? 350 : 400).ms);
  }

  Widget _buildFeatureRow(
    String title,
    String subtitle,
    Color bgColor,
    Color textColor,
    int delayMs,
  ) {
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
