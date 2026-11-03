import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../models/api_record.dart';
import '../models/app_user.dart';

class SigapService {
  SigapService(this.api, this.tokens);
  final ApiClient api;
  final TokenStore tokens;

  // Autentikasi
  Future<AppUser> login(String email, String password) async =>
      _authenticate('login', {'email': email, 'password': password});

  Future<AppUser> register(String name, String email, String password) async =>
      _authenticate('register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

  Future<AppUser> _authenticate(String path, Map<String, dynamic> body) async {
    final data = await api.post(path, body);
    if (data is! Map || data['token'] == null || data['user'] is! Map) {
      throw const ApiException('Respons autentikasi server tidak lengkap.');
    }
    await tokens.save(data['token'].toString());
    return AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<AppUser> currentUser() async {
    final data = await api.get('user');
    if (data is! Map) throw const ApiException('Profil pengguna tidak valid.');
    return AppUser.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> logout() async {
    try {
      await api.post('logout');
    } finally {
      await tokens.clear();
    }
  }

  // Pengambilan Daftar Data Umum
  Future<List<ApiRecord>> list(String path) async =>
      recordsFrom(await api.get(path));

  // Laporan Darurat (SOS)
  Future<Map<String, dynamic>> sendEmergency({
    required String incidentType,
    required String description,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final data = await api.post('emergency-reports', {
      'incident_type': incidentType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      if (address?.trim().isNotEmpty == true) 'address': address!.trim(),
    });
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return <String, dynamic>{};
  }

  Future<List<ApiRecord>> myReports() => list('emergency-reports');

  // Status Keselamatan
  Future<void> sendSafety({
    required String status,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    await api.post('safety-statuses', body);
  }

  // Dashboard & Fitur Petugas BPBD/SAR
  Future<Map<String, dynamic>> staffDashboard() async {
    final data = await api.get('petugas/dashboard');
    final wrapped = data is Map ? data['data'] : null;
    return wrapped is Map
        ? Map<String, dynamic>.from(wrapped)
        : <String, dynamic>{};
  }

  Future<List<ApiRecord>> allReportsForStaff() => list('emergency-reports');

  Future<void> updateReportStatus(String reportId, String status) async {
    await api.patch('emergency-reports/$reportId/status', {'status': status});
  }

  Future<void> createAlert({
    required String title,
    required String message,
    required String type,
    required String severity,
    required String affectedArea,
    required String source,
  }) async {
    await api.post('alerts', {
      'title': title,
      'message': message,
      'type': type,
      'severity': severity,
      'affected_area': affectedArea,
      'source': source,
      'status': 'aktif',
    });
  }

  Future<void> createReliefTask({
    required int volunteerId,
    required String title,
    required String description,
    required String location,
    String priority = 'sedang',
  }) async {
    await api.post('relief-tasks', {
      'volunteer_id': volunteerId,
      'title': title,
      'description': description,
      'location': location,
      'priority': priority,
    });
  }

  // Fitur Relawan
  Future<List<ApiRecord>> volunteerTasks() => list('relawan/tasks');

  Future<void> updateVolunteerTask(String id, String status) async {
    await api.patch('relawan/tasks/$id/status', {'status': status});
  }

  // Fitur Administrator
  Future<Map<String, dynamic>> adminStats() async {
    final data = await api.get('admin/stats');
    final wrapped = data is Map ? data['data'] : null;
    return wrapped is Map
        ? Map<String, dynamic>.from(wrapped)
        : <String, dynamic>{};
  }

  Future<List<dynamic>> adminUsers({String? role, String? search}) async {
    final params = <String>[];
    if (role != null && role.isNotEmpty) params.add('role=$role');
    if (search != null && search.isNotEmpty) params.add('search=$search');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final data = await api.get('admin/users$query');
    if (data is Map && data['data'] is Map && data['data']['data'] is List) {
      return data['data']['data'] as List;
    }
    return const [];
  }

  Future<void> updateUserRole(int userId, String newRole) async {
    await api.patch('admin/users/$userId/role', {'role': newRole});
  }
}
