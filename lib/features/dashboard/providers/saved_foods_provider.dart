import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final savedFoodsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiClient.instance.get('food/saved');
    if (res.statusCode == 200) {
      return res.data as List<dynamic>;
    }
    return [];
  } catch (e) {
    return [];
  }
});
