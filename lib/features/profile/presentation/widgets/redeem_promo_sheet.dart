import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../auth/data/services/promo_redeem_flow.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';

void showRedeemPromoSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RedeemPromoSheet(),
  );
}

class _RedeemPromoSheet extends ConsumerStatefulWidget {
  const _RedeemPromoSheet();

  @override
  ConsumerState<_RedeemPromoSheet> createState() => _RedeemPromoSheetState();
}

class _RedeemPromoSheetState extends ConsumerState<_RedeemPromoSheet> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final lang = ref.read(localeProvider);
    final code = _controller.text.trim();
    if (code.isEmpty || _loading) return;

    setState(() => _loading = true);
    try {
      final outcome = await PromoRedeemFlow.redeem(code);
      if (!mounted) return;

      if (outcome.isInstantGrant) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.t(lang, 'promo_redeemed')),
            backgroundColor: AppColors.primaryDark,
          ),
        );
        return;
      }

      if (outcome.needsStoreRedeem) {
        await PromoRedeemFlow.openStoreRedemption(outcome);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              outcome.platform == 'apple'
                  ? Translations.t(lang, 'promo_apple_continue')
                  : Translations.t(lang, 'promo_google_continue'),
            ),
            backgroundColor: AppColors.primaryDark,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHandler.message(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHandler.message(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.ticket, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t('redeem_promo_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              t('redeem_promo_subtitle'),
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppColors.primaryDark,
              ),
              decoration: InputDecoration(
                hintText: 'WIAM10',
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _redeem(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _redeem,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(t('redeem_promo')),
            ),
          ],
        ),
      ),
    );
  }
}
