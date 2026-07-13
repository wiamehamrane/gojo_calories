import '../../../../core/network/api_client.dart';

class ClanRepository {
  Future<Map<String, dynamic>> getMyClan() async {
    final response = await ApiClient.instance.get('clan/me');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> inviteMember(String email) async {
    final response = await ApiClient.instance.post(
      'clan/invite',
      data: {'email': email},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> acceptInvite(String token) async {
    final response = await ApiClient.instance.post(
      'clan/accept',
      data: {'token': token},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> removeMember(String userId) async {
    await ApiClient.instance.delete('clan/members/$userId');
  }

  Future<void> cancelInvite(String inviteId) async {
    await ApiClient.instance.delete('clan/invites/$inviteId');
  }
}
