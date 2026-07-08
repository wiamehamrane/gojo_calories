import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../../../core/network/api_client.dart';

/// Product identifiers — must match App Store Connect / Google Play Console.
const String kMonthlyProductId = 'gojo_pro_monthly';
const String kYearlyProductId = 'gojo_pro_yearly';
const Set<String> kProductIds = {kMonthlyProductId, kYearlyProductId};

const String kAndroidPackageName = 'com.gojocalories.gojocalories';

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
/// - Fetching available products from the App Store / Google Play
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

  /// Available products fetched from the store.
  List<ProductDetails> products = [];

  /// Current purchase flow state.
  final ValueNotifier<IAPStatus> status = ValueNotifier(
    const IAPStatus(),
  );

  /// Whether the service has been initialized.
  bool _initialized = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  String get _storeName => _isAndroid ? 'Google Play' : 'App Store';

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

  /// Fetch available subscription products from the store (with retries).
  Future<List<ProductDetails>> loadProducts() async {
    status.value = const IAPStatus(state: IAPState.loading);

    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final products = await _queryProductsOnce();
        status.value = const IAPStatus(state: IAPState.idle);
        return products;
      } catch (e) {
        lastError = e;
        debugPrint('IAPService: loadProducts attempt $attempt/3 failed: $e');
        final retryable = _isRetryableLoadError(e);
        if (!retryable || attempt == 3) break;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    status.value = const IAPStatus(state: IAPState.idle);
    throw lastError ?? Exception('Failed to load subscription plans');
  }

  bool _isRetryableLoadError(Object error) {
    final message = error.toString().toLowerCase();
    if (_isIOS) {
      return message.contains('storekit');
    }
    return message.contains('billing') || message.contains('play');
  }

  Future<List<ProductDetails>> _queryProductsOnce() async {
    final available = await _iap.isAvailable();
    debugPrint('IAPService: Store available = $available');
    if (!available) {
      throw Exception(
        '$_storeName is not available on this device.',
      );
    }

    final response = await _iap.queryProductDetails(kProductIds);
    debugPrint(
      'IAPService: found=${response.productDetails.map((p) => p.id).toList()} '
      'notFound=${response.notFoundIDs} error=${response.error}',
    );

    if (response.error != null) {
      throw Exception(
        _storeErrorMessage(
          response.error!.message,
          response.notFoundIDs,
        ),
      );
    }

    if (response.notFoundIDs.isNotEmpty) {
      throw Exception(_productNotFoundMessage(response.notFoundIDs));
    }

    if (response.productDetails.isEmpty) {
      throw Exception(_emptyProductsMessage());
    }

    products = response.productDetails.toList()
      ..sort((a, b) {
        if (a.id == kYearlyProductId) return -1;
        if (b.id == kYearlyProductId) return 1;
        return 0;
      });

    return products;
  }

  /// Initiate a subscription purchase.
  Future<void> buySubscription(ProductDetails product) async {
    status.value = const IAPStatus(state: IAPState.purchasing);

    try {
      if (_isAndroid) {
        final purchaseParam = GooglePlayPurchaseParam(
          productDetails: product,
        );
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        final purchaseParam = PurchaseParam(productDetails: product);
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
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
      if (_isAndroid) {
        final androidAddition =
            _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        final response = await androidAddition.queryPastPurchases();
        if (response.error != null) {
          throw Exception(response.error!.message);
        }

        final purchases = response.pastPurchases
            .where((purchase) => kProductIds.contains(purchase.productID))
            .toList();

        if (purchases.isEmpty) {
          status.value = IAPStatus(
            state: IAPState.error,
            errorMessage: 'No previous purchases found for this account.',
          );
          return;
        }

        for (final purchase in purchases) {
          await _handlePurchase(purchase);
        }
        return;
      }

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

  /// Send purchase data to our backend for server-side validation.
  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      final Response<dynamic> response;
      if (_isGooglePurchase(purchase)) {
        response = await ApiClient.instance.post(
          'payments/google/verify-purchase',
          data: {
            'purchase_token': purchase.verificationData.serverVerificationData,
            'product_id': purchase.productID,
            'package_name': kAndroidPackageName,
          },
        );
      } else {
        response = await ApiClient.instance.post(
          'payments/apple/verify-receipt',
          data: {
            'receipt_data': purchase.verificationData.serverVerificationData,
            'product_id': purchase.productID,
          },
        );
      }

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
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final detail = responseData is Map
          ? responseData['detail']?.toString()
          : null;
      debugPrint(
        'IAPService: _verifyAndDeliver error: status=${e.response?.statusCode} '
        'detail=$detail message=${e.message}',
      );
      status.value = IAPStatus(
        state: IAPState.error,
        errorMessage: detail ??
            e.message ??
            'Purchase verification failed. Please try again.',
      );
    } catch (e) {
      debugPrint('IAPService: _verifyAndDeliver error: $e');
      status.value = IAPStatus(
        state: IAPState.error,
        errorMessage: 'Purchase verification failed. Please try again.',
      );
    }
  }

  bool _isGooglePurchase(PurchaseDetails purchase) {
    if (_isAndroid) return true;
    return purchase.verificationData.source.toLowerCase().contains('google');
  }

  /// Clean up resources.
  void dispose() {
    _subscription?.cancel();
    status.dispose();
  }

  String _productNotFoundMessage(List<String> notFoundIds) {
    if (_isAndroid) {
      return 'Google Play could not find: ${notFoundIds.join(", ")}. '
          'Confirm subscriptions are active in Play Console for '
          '$kAndroidPackageName and linked to your testing track.';
    }
    return 'App Store could not find: ${notFoundIds.join(", ")}. '
        'Confirm the bundle ID $kAndroidPackageName matches App Store '
        'Connect and that both products are in the "GojoCalories Pro" group.';
  }

  String _emptyProductsMessage() {
    if (_isAndroid) {
      return 'No subscription plans returned from Google Play.\n\n'
          'For testing:\n'
          '• Upload a signed build to Internal testing\n'
          '• Add your Google account as a license tester\n'
          '• Create subscriptions with IDs gojo_pro_monthly and gojo_pro_yearly\n'
          '• Wait a few hours after creating products in Play Console';
    }
    return 'No subscription plans returned. Sign in with a Sandbox Apple ID '
        '(Settings → Developer → Sandbox Apple Account) when testing debug builds.';
  }

  String _storeErrorMessage(
    String message,
    List<String> notFoundIds,
  ) {
    if (_isIOS) {
      return _storeKitErrorMessage(message, notFoundIds);
    }

    final lower = message.toLowerCase();
    if (lower.contains('billing') || lower.contains('play')) {
      return 'Google Play could not load subscription plans.\n\n'
          'For testing:\n'
          '• Install the app from an Internal testing track\n'
          '• Sign in with a license tester Google account\n'
          '• Confirm subscriptions are active in Play Console\n\n'
          'Tap Retry or Restore Purchase below.';
    }

    if (notFoundIds.isNotEmpty) {
      return _productNotFoundMessage(notFoundIds);
    }

    return message;
  }

  static String _storeKitErrorMessage(
    String message,
    List<String> notFoundIds,
  ) {
    if (message.contains('storekit') || message.contains('StoreKit')) {
      if (kDebugMode) {
        return 'StoreKit could not reach Apple\'s servers (storekit_no_response).\n\n'
            'Xcode + GojoCalories.storekit only works for local debug builds.\n\n'
            'For TestFlight / real App Store testing:\n'
            '1. Sandbox Apple ID on device (Settings → Developer → Sandbox Account)\n'
            '2. App Store Connect → Agreements → Paid Apps is Active\n'
            '3. Link subscriptions to your app version (App → Version → In-App Purchases)\n'
            '4. Wait up to 24h after first TestFlight upload\n\n'
            'Tap Retry or Restore Purchase below.';
      }
      return 'We couldn\'t load subscription plans right now.\n\n'
          'If you\'re testing via TestFlight:\n'
          '• Sign in with a Sandbox Apple ID (Settings → Developer → Sandbox Account)\n'
          '• Subscriptions must be linked to your app version in App Store Connect\n'
          '• Paid Apps agreement must be Active under Agreements\n'
          '• New builds can take up to 24 hours before plans appear\n\n'
          'Tap Retry or Restore Purchase below.';
    }
    if (notFoundIds.isNotEmpty) {
      return 'Subscription plans are not available yet (${notFoundIds.join(", ")}). '
          'Confirm they are linked to your app version in App Store Connect, '
          'then try again in a few hours.';
    }
    return message;
  }
}
