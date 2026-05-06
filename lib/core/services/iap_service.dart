import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:gojocalories/core/network/api_client.dart';

/// Product identifiers — must match App Store Connect configuration.
const String kMonthlyProductId = 'gojo_pro_monthly';
const String kYearlyProductId = 'gojo_pro_yearly';
const Set<String> kProductIds = {kMonthlyProductId, kYearlyProductId};

/// Possible states for the IAP purchase flow.
enum IAPState {
  idle,
  loading,
  purchasing,
  verifying,
  success,
  error,
  restored,
}

/// Wraps the current state with an optional error message.
class IAPStatus {
  final IAPState state;
  final String? errorMessage;

  const IAPStatus({this.state = IAPState.idle, this.errorMessage});

  IAPStatus copyWith({IAPState? state, String? errorMessage}) {
    return IAPStatus(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Singleton service managing the entire In-App Purchase lifecycle.
///
/// Responsibilities:
/// - Fetching available products from the App Store
/// - Initiating purchases
/// - Listening to the purchase stream
/// - Forwarding receipts to the backend for server-side validation
/// - Restoring purchases across devices
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Available products fetched from the App Store.
  List<ProductDetails> products = [];

  /// Current purchase flow state.
  final ValueNotifier<IAPStatus> status = ValueNotifier(
    const IAPStatus(),
  );

  /// Whether the service has been initialized.
  bool _initialized = false;

  /// Initialize the service — call once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('IAPService: Store not available');
      return;
    }

    // Listen to the global purchase stream
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('IAPService: Purchase stream error: $error');
        status.value = IAPStatus(
          state: IAPState.error,
          errorMessage: error.toString(),
        );
      },
    );
  }

  /// Fetch available subscription products from the App Store.
  Future<List<ProductDetails>> loadProducts() async {
    status.value = const IAPStatus(state: IAPState.loading);

    try {
      final response = await _iap.queryProductDetails(kProductIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'IAPService: Products not found: ${response.notFoundIDs}',
        );
      }

      if (response.error != null) {
        debugPrint('IAPService: Query error: ${response.error}');
        status.value = IAPStatus(
          state: IAPState.error,
          errorMessage: response.error?.message ?? 'Failed to load products',
        );
        return [];
      }

      // Sort so yearly comes first (better value, typical paywall layout)
      products = response.productDetails.toList()
        ..sort((a, b) {
          if (a.id == kYearlyProductId) return -1;
          if (b.id == kYearlyProductId) return 1;
          return 0;
        });

      status.value = const IAPStatus(state: IAPState.idle);
      return products;
    } catch (e) {
      debugPrint('IAPService: loadProducts error: $e');
      status.value = IAPStatus(
        state: IAPState.error,
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Initiate a subscription purchase.
  Future<void> buySubscription(ProductDetails product) async {
    status.value = const IAPStatus(state: IAPState.purchasing);

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('IAPService: buySubscription error: $e');
      status.value = IAPStatus(
        state: IAPState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Restore previous purchases (e.g., after reinstall or new device).
  Future<void> restorePurchases() async {
    status.value = const IAPStatus(state: IAPState.loading);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAPService: restorePurchases error: $e');
      status.value = IAPStatus(
        state: IAPState.error,
        errorMessage: 'Failed to restore purchases: ${e.toString()}',
      );
    }
  }

  /// Handle purchase stream events.
  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        status.value = const IAPStatus(state: IAPState.purchasing);
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        status.value = const IAPStatus(state: IAPState.verifying);
        await _verifyAndDeliver(purchase);
        break;

      case PurchaseStatus.error:
        final errorMsg = purchase.error?.message ?? 'Purchase failed';
        debugPrint('IAPService: Purchase error: $errorMsg');
        // Don't show error for user cancellation
        if (purchase.error?.code == 'purchase_error' ||
            errorMsg.toLowerCase().contains('cancel')) {
          status.value = const IAPStatus(state: IAPState.idle);
        } else {
          status.value = IAPStatus(
            state: IAPState.error,
            errorMessage: errorMsg,
          );
        }
        break;

      case PurchaseStatus.canceled:
        status.value = const IAPStatus(state: IAPState.idle);
        break;
    }

    // Complete pending purchases to avoid re-delivery
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Send the receipt to our backend for server-side validation.
  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      // On iOS, verificationData.serverVerificationData is the Base64 receipt
      final receiptData = purchase.verificationData.serverVerificationData;

      final response = await ApiClient.instance.post(
        'payments/apple/verify-receipt',
        data: {
          'receipt_data': receiptData,
          'product_id': purchase.productID,
        },
      );

      if (response.statusCode == 200 &&
          response.data['status'] == 'success' &&
          response.data['subscription_active'] == true) {
        if (purchase.status == PurchaseStatus.restored) {
          status.value = const IAPStatus(state: IAPState.restored);
        } else {
          status.value = const IAPStatus(state: IAPState.success);
        }
      } else {
        final detail = response.data['detail'] ?? 'Verification failed';
        status.value = IAPStatus(
          state: IAPState.error,
          errorMessage: detail.toString(),
        );
      }
    } catch (e) {
      debugPrint('IAPService: _verifyAndDeliver error: $e');
      status.value = IAPStatus(
        state: IAPState.error,
        errorMessage: 'Receipt verification failed. Please try again.',
      );
    }
  }

  /// Clean up resources.
  void dispose() {
    _subscription?.cancel();
    status.dispose();
  }
}
