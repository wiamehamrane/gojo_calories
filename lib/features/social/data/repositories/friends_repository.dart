import '../../../../core/network/api_client.dart';

class FriendsRepository {
  final _dio = ApiClient.instance;

  Future<List<dynamic>> getFriends() async {
    final res = await _dio.get('friends');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final res = await _dio.get(
      'friends/search',
      queryParameters: {'query': query},
    );
    return res.data as List<dynamic>;
  }

  Future<void> addFriend(String userId) async {
    await _dio.post('friends/add/$userId');
  }

  Future<void> removeFriend(String userId) async {
    await _dio.delete('friends/remove/$userId');
  }
}
