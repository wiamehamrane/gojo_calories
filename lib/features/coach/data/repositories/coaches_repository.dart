import '../../../../core/network/api_client.dart';
import '../../domain/models/coach.dart';

class CoachesRepository {
  Future<CoachSearchPage> search({
    required double lat,
    required double lng,
    double radiusKm = 25,
    String? specialty,
    String? gender,
    int page = 1,
    int pageSize = 5,
  }) async {
    final res = await ApiClient.instance.get(
      'coaches/search',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius_km': radiusKm,
        'page': page,
        'page_size': pageSize,
        if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
      },
    );
    return CoachSearchPage.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Coach> getPublic(String coachId) async {
    final res = await ApiClient.instance.get('coaches/$coachId');
    return Coach.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CoachContact> contact(String coachId) async {
    final res = await ApiClient.instance.post('coaches/$coachId/contact');
    return CoachContact.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}

class CoachContact {
  final String coachId;
  final String? phone;
  final String? callUri;
  final String? whatsappUrl;

  const CoachContact({
    required this.coachId,
    this.phone,
    this.callUri,
    this.whatsappUrl,
  });

  factory CoachContact.fromJson(Map<String, dynamic> json) {
    return CoachContact(
      coachId: json['coach_id'] as String,
      phone: json['phone'] as String?,
      callUri: json['call_uri'] as String?,
      whatsappUrl: json['whatsapp_url'] as String?,
    );
  }
}
