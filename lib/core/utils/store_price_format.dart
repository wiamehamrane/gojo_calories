import 'package:intl/intl.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Helpers for showing App Store / Play Billing prices in the user's local currency.
///
/// Always prefer [ProductDetails.price] from the store — Apple and Google already
/// localize amount + currency based on the customer's storefront / Play country
/// (e.g. MAD for a Moroccan App Store / Play account).
class StorePriceFormat {
  StorePriceFormat._();

  /// Full localized price string from the store (e.g. "MAD 59.00", "€5.99").
  static String display(ProductDetails product) => product.price;

  static String _formatAmount(ProductDetails product, double amount) {
    final code = product.currencyCode.trim();
    final symbol = product.currencySymbol.trim();
    try {
      return NumberFormat.currency(
        name: code.isNotEmpty ? code : null,
        symbol: symbol.isNotEmpty ? symbol : null,
      ).format(amount);
    } catch (_) {
      if (symbol.isNotEmpty) {
        return '$symbol${amount.toStringAsFixed(2)}';
      }
      if (code.isNotEmpty) {
        return '${amount.toStringAsFixed(2)} $code';
      }
      return amount.toStringAsFixed(2);
    }
  }

  /// Localized referral discount using the store's currency + rawPrice.
  static String referralDisplay(ProductDetails product, int payPercent) {
    final percent = payPercent.clamp(1, 100);
    final discounted = product.rawPrice * percent / 100.0;
    return _formatAmount(product, discounted);
  }

  /// Per-month equivalent in local currency (for yearly / multi-month plans).
  static String? equivalentMonthly(
    ProductDetails product, {
    required int intervalCount,
    String interval = 'month',
  }) {
    if (intervalCount <= 1 && interval == 'month') return null;
    final months = interval == 'year' ? 12 * intervalCount : intervalCount;
    if (months <= 1) return null;
    return _formatAmount(product, product.rawPrice / months);
  }
}
