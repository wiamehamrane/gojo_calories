import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gojocalories/features/auth/presentation/providers/iap_provider.dart';
import 'package:gojocalories/features/auth/presentation/providers/catalog_provider.dart';
import 'package:gojocalories/features/auth/data/services/iap_service.dart';
import 'package:gojocalories/core/localization/locale_provider.dart';
import 'package:gojocalories/core/localization/translations.dart';
import 'package:gojocalories/core/utils/store_price_format.dart';

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
        final msg = iapStatus.errorMessage;
        if (msg != null &&
            !msg.toLowerCase().contains('cancel') &&
            !(kDebugMode && msg.toLowerCase().contains('storekit'))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
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
    final lang = ref.read(localeProvider);
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'please_select_plan')),
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

  Widget _buildPlansUnavailable({
    required String message,
    required VoidCallback onRetry,
    required String lang,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              LucideIcons.circleAlert,
              color: Colors.redAccent,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(Translations.t(lang, 'retry')),
            ),
          ],
        ),
      ),
    );
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
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    // Design Tokens
    const Color background = Colors.white;
    const Color primaryDark = Color(0xFF1E3A1A);
    const Color primaryMedium = Color(0xFF6B8B67);
    const Color featureBg = Color(0xFFF8FDF7);

    final productsAsync = ref.watch(iapProductsProvider);
    final catalogAsync = ref.watch(subscriptionCatalogProvider);
    final plansFailed = productsAsync.hasError;
    final hasProducts = productsAsync.maybeWhen(
      data: (products) => products.isNotEmpty,
      orElse: () => false,
    );

    final catalogPlans = catalogAsync.maybeWhen(
      data: (c) => (c['plans'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      orElse: () => <Map<String, dynamic>>[],
    );
    final referralOffer = catalogAsync.maybeWhen(
      data: (c) => c['referral_offer'] as Map<String, dynamic>?,
      orElse: () => null,
    );
    final defaultPlanId = catalogAsync.maybeWhen(
      data: (c) => c['default_plan_id'] as String? ?? 'yearly',
      orElse: () => 'yearly',
    );

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
                'Your Personal Nutrition Coach',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: primaryMedium,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 32),

              if (referralOffer?['eligible'] == true) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00B4CC).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.gift, color: Color(0xFF007D8F), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          referralOffer?['headline'] as String? ??
                              t('referral_discount_banner'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF007D8F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!plansFailed) ...[
                _buildFeatureRow(
                  'Smart Food Scanner',
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
                const SizedBox(height: 24),
              ],

              // Plan Selection Cards
              productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Subscription plans are loading...\nPlease try again shortly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B8B67),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  final productById = {
                    for (final p in products) p.id: p,
                  };

                  final displayPlans = catalogPlans.isNotEmpty
                      ? catalogPlans
                      : products
                          .map(
                            (p) => {
                              'store_product_id': p.id,
                              'name': p.id,
                              'tagline': '',
                              'display_price': p.price,
                            },
                          )
                          .toList();

                  if (_selectedProductId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      String? defaultProductId;
                      for (final plan in displayPlans) {
                        if (plan['id'] == defaultPlanId) {
                          defaultProductId =
                              plan['store_product_id'] as String?;
                          break;
                        }
                      }
                      setState(() {
                        _selectedProductId = defaultProductId ??
                            (products.any((p) => p.id == kYearlyProductId)
                                ? kYearlyProductId
                                : products.first.id);
                      });
                    });
                  }

                  return Column(
                    children: displayPlans.map((plan) {
                      final storeId = plan['store_product_id'] as String?;
                      final product = storeId != null
                          ? productById[storeId]
                          : null;
                      if (product == null && storeId != null) {
                        return const SizedBox.shrink();
                      }
                      if (product == null) return const SizedBox.shrink();

                      final payPercent =
                          (referralOffer?['pay_percent'] as num?)?.toInt();

                      return _buildPlanCard(
                        product: product,
                        planMeta: plan,
                        isSelected: _selectedProductId == product.id,
                        primaryDark: primaryDark,
                        primaryMedium: primaryMedium,
                        referralPayPercent: payPercent,
                        onTap: () {
                          setState(() => _selectedProductId = product.id);
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E3A1A),
                    ),
                  ),
                ),
                error: (e, _) => _buildPlansUnavailable(
                  message: e.toString().replaceFirst('Exception: ', ''),
                  onRetry: () => ref.refresh(iapProductsProvider),
                  lang: lang,
                ),
              ),

              if (hasProducts) ...[
                const SizedBox(height: 16),
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
              ],

              if (hasProducts) ...[
                const SizedBox(height: 12),
                const Text(
                  'Cancel anytime. No commitment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    GestureDetector(
                      onTap: _isProcessing ? null : _handleRestore,
                      child: Text(
                        t('restore_purchases'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse('https://gojocalories.com/privacy'),
                      ),
                      child: Text(
                        t('privacy_policy'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          launchUrl(Uri.parse('https://gojocalories.com/tos')),
                      child: const Text(
                        'Terms of Use (EULA)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required ProductDetails product,
    required Map<String, dynamic> planMeta,
    required bool isSelected,
    required Color primaryDark,
    required Color primaryMedium,
    required VoidCallback onTap,
    int? referralPayPercent,
  }) {
    final label = planMeta['name'] as String? ?? product.title;
    // Always show Apple/Google localized price for this user's storefront.
    final storePrice = StorePriceFormat.display(product);
    final interval = planMeta['interval'] as String? ?? 'month';
    final intervalCount = (planMeta['interval_count'] as num?)?.toInt() ?? 1;
    final monthlyEq = StorePriceFormat.equivalentMonthly(
      product,
      intervalCount: intervalCount,
      interval: interval,
    );
    final subtitle = monthlyEq != null
        ? '$monthlyEq / mo'
        : (planMeta['tagline'] as String? ?? product.description);
    final badge = planMeta['badge'] as String?;

    final hasReferral = referralPayPercent != null &&
        referralPayPercent > 0 &&
        referralPayPercent < 100 &&
        planMeta['referral_price_cents'] != null;
    final displayPrice = hasReferral
        ? StorePriceFormat.referralDisplay(product, referralPayPercent)
        : storePrice;
    final showReferralStrikethrough = hasReferral;

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
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? primaryDark : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
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
                          child: Text(
                            badge,
                            style: const TextStyle(
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
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showReferralStrikethrough)
                    Text(
                      storePrice,
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  Text(
                    displayPrice,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? primaryDark : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 350.ms);
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
