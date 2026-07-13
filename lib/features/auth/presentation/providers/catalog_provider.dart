import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final subscriptionCatalogProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get('payments/catalog');
  return Map<String, dynamic>.from(response.data as Map);
});
