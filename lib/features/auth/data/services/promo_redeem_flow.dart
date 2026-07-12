import 'package:url_launcher/url_launcher.dart';

import 'iap_service.dart';
import 'promo_service.dart';
import 'promo_store_redemption_stub.dart'
    if (dart.library.io) 'promo_store_redemption_io.dart';

/// Result of a hybrid promo redemption attempt.
class PromoRedeemOutcome {
  const PromoRedeemOutcome({
    required this.action,
    required this.platform,
    this.instructions,
    this.redeemUrl,
  });

  final String action;
  final String platform;
  final String? instructions;
  final String? redeemUrl;

  bool get isInstantGrant => action == 'granted';
  bool get needsStoreRedeem => action == 'store_redeem';
}

class PromoRedeemFlow {
  static final PromoService _promo = PromoService();

  static Future<PromoRedeemOutcome> redeem(String code) async {
    final data = await _promo.redeem(code);
    return PromoRedeemOutcome(
      action: data['action'] as String? ?? 'granted',
      platform: data['platform'] as String? ?? 'internal',
      instructions: data['instructions'] as String?,
      redeemUrl: data['redeem_url'] as String?,
    );
  }

  /// Opens the platform store UI after backend links the code to this user.
  static Future<void> openStoreRedemption(PromoRedeemOutcome outcome) async {
    if (!outcome.needsStoreRedeem) return;

    if (outcome.platform == 'apple') {
      await presentAppleCodeRedemptionSheet();
      await IAPService().restorePurchases();
      return;
    }

    if (outcome.platform == 'google') {
      final url = outcome.redeemUrl;
      if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  static Future<void> redeemAndOpenStore(String code) async {
    final outcome = await redeem(code);
    if (outcome.needsStoreRedeem) {
      await openStoreRedemption(outcome);
    }
  }
}
