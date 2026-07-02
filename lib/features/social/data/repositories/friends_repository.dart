import '../../../../core/network/api_client.dart';

class FriendsRepository {
  final _dio = ApiClient.instance;

  Future<List<dynamic>> getFriends() async {
    final res = await _dio.get('social/friends');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final res = await _dio.get(
      'connections/search',
      queryParameters: {'query': query},
    );
    final data = res.data;
    if (data is List) return data;
    return [];
  }

  Future<void> addFriend(String userId) async {
    await _dio.post(
      'social/friends/request',
      data: {'friend_id': userId},
    );
  }

  /// Production API has no dedicated unfriend endpoint yet.
  Future<void> removeFriend(String userId) async {
    throw UnsupportedError(
      'Removing friends is not supported by the current API.',
    );
  }
}
