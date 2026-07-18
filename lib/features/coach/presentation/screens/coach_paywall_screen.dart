import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../auth/data/services/iap_service.dart';
import '../../../auth/presentation/providers/iap_provider.dart';

class CoachPaywallScreen extends ConsumerStatefulWidget {
  const CoachPaywallScreen({super.key});

  @override
  ConsumerState<CoachPaywallScreen> createState() => _CoachPaywallScreenState();
}

class _CoachPaywallScreenState extends ConsumerState<CoachPaywallScreen> {
  late final IAPService _iap;
  List<ProductDetails> _products = [];
  String? _selectedId;
  String? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _iap = ref.read(iapServiceProvider);
    _iap.status.addListener(_onIapStatus);
    _load();
  }

  @override
  void dispose() {
    _iap.status.removeListener(_onIapStatus);
    super.dispose();
  }

  void _onIapStatus() {
    if (!mounted) return;
    final status = _iap.status.value;
    switch (status.state) {
      case IAPState.success:
      case IAPState.restored:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('coach_paywall_success'))),
        );
        context.pop(true);
        break;
      case IAPState.error:
        final msg = status.errorMessage;
        if (msg != null &&
            !msg.toLowerCase().contains('cancel') &&
            !(kDebugMode && msg.toLowerCase().contains('storekit'))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        setState(() {});
        break;
      default:
        setState(() {});
    }
  }

  String _t(String key) => Translations.t(ref.read(localeProvider), key);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final products = await _iap.loadCoachProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _selectedId = products.isNotEmpty
            ? (products.any((p) => p.id == kCoachYearlyProductId)
                ? kCoachYearlyProductId
                : products.first.id)
            : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _buy() async {
    final id = _selectedId;
    if (id == null || _products.isEmpty) return;
    HapticFeedback.selectionClick();
    final product = _products.firstWhere((p) => p.id == id);
    await _iap.buySubscription(product);
  }

  bool get _busy {
    final state = _iap.status.value.state;
    return state == IAPState.purchasing ||
        state == IAPState.verifying ||
        state == IAPState.loading;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('coach_paywall_title')),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: Text(t('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    LucideIcons.dumbbell,
                                    color: AppColors.primaryDark,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  t('coach_paywall_headline'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  t('coach_paywall_body'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._products.map((product) {
                            final selected = product.id == _selectedId;
                            final isYearly =
                                product.id == kCoachYearlyProductId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                  onTap: () => setState(
                                    () => _selectedId = product.id,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.lg),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primaryDark
                                            : AppColors.border,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          selected
                                              ? LucideIcons.circleCheck
                                              : LucideIcons.circle,
                                          color: selected
                                              ? AppColors.primaryDark
                                              : AppColors.textSecondary,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isYearly
                                                    ? t('coach_paywall_yearly')
                                                    : t(
                                                        'coach_paywall_monthly',
                                                      ),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              if (isYearly)
                                                Text(
                                                  t('coach_paywall_yearly_save'),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.primaryDark,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          product.price,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                _busy || _selectedId == null ? null : _buy,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(t('coach_paywall_subscribe')),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
