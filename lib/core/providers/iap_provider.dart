import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:gojocalories/core/services/iap_service.dart';

/// Singleton provider for the IAP service.
final iapServiceProvider = Provider<IAPService>((ref) {
  final service = IAPService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Fetches available products from the App Store.
/// Call `ref.refresh(iapProductsProvider)` to reload.
final iapProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final service = ref.read(iapServiceProvider);
  await service.initialize();
  return service.loadProducts();
});
