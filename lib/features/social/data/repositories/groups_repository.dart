import '../../../../core/network/api_client.dart';

class GroupsRepository {
  final _dio = ApiClient.instance;

  Future<List<dynamic>> getMyGroups() async {
    final res = await _dio.get('groups/my');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> discoverGroups() async {
    final res = await _dio.get('groups/discover');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getCommunityFeed() async {
    final res = await _dio.get('groups/feed');
    return res.data as List<dynamic>;
  }

  Future<void> joinGroup(String groupId) async {
    await _dio.post('groups/$groupId/join');
  }
}
