import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000/api/v1',
  );
  final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  ApiClient() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        return handler.next(error);
      },
    ));
  }

  // ================= AUTH METHODS =================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    if (response.data['success'] == true && response.data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', response.data['token']);
    }
    return response.data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await dio.get('/auth/me');
    return response.data;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await dio.post('/auth/forgot-password', data: {
      'email': email,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyResetToken(String token) async {
    final response = await dio.get('/auth/verify-reset-token', queryParameters: {
      'token': token,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    final response = await dio.post('/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
    return response.data;
  }

  // ================= SUPER ADMIN METHODS =================
  Future<List<dynamic>> getAdmins() async {
    final response = await dio.get('/auth/admins');
    return response.data['admins'] ?? [];
  }

  Future<Map<String, dynamic>> createAdmin(String name, String email, String password) async {
    final response = await dio.post('/auth/admins', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateAdmin(String id, {String? name, String? status, String? password}) async {
    final response = await dio.patch('/auth/admins/$id', data: {
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (password != null) 'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> deleteAdmin(String id) async {
    final response = await dio.delete('/auth/admins/$id');
    return response.data;
  }

  // ================= CLIENT & STAFF METHODS =================
  Future<List<dynamic>> getClients() async {
    final response = await dio.get('/clients');
    return response.data['clients'] ?? [];
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> data) async {
    final response = await dio.post('/clients', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateClient(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/clients/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteClient(String id) async {
    final response = await dio.delete('/clients/$id');
    return response.data;
  }

  Future<List<dynamic>> getStaff() async {
    final response = await dio.get('/clients/staff');
    return response.data['staff'] ?? [];
  }

  Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    final response = await dio.post('/clients/staff', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteStaff(String id) async {
    final response = await dio.delete('/clients/staff/$id');
    return response.data;
  }

  // ================= CONTENT / STUDIO METHODS =================
  Future<List<dynamic>> getContents({String? clientId, String? status, String? platform}) async {
    final response = await dio.get('/contents', queryParameters: {
      if (clientId != null) 'client_id': clientId,
      if (status != null) 'status': status,
      if (platform != null) 'platform': platform,
    });
    return response.data['contents'] ?? [];
  }

  Future<Map<String, dynamic>> createContent(Map<String, dynamic> data) async {
    final response = await dio.post('/contents', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateContent(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/contents/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteContent(String id, {bool permanent = false}) async {
    final response = await dio.delete('/contents/$id', queryParameters: {
      if (permanent) 'permanent': 'true',
    });
    return response.data;
  }

  Future<Map<String, dynamic>> approveContent(String id) async {
    final response = await dio.post('/contents/$id/approve');
    return response.data;
  }

  Future<Map<String, dynamic>> requestChanges(String id, String feedback) async {
    final response = await dio.post('/contents/$id/request-changes', data: {'feedback': feedback});
    return response.data;
  }

  Future<List<dynamic>> getComments(String id) async {
    final response = await dio.get('/contents/$id/comments');
    return response.data['comments'] ?? [];
  }

  Future<Map<String, dynamic>> addComment(String id, String comment) async {
    final response = await dio.post('/contents/$id/comments', data: {'comment': comment});
    return response.data;
  }

  // ================= ACTIVITY & METRICS METHODS =================
  Future<List<dynamic>> getActivities() async {
    final response = await dio.get('/activity');
    return response.data['activities'] ?? [];
  }

  Future<List<dynamic>> getActivityStats() async {
    final response = await dio.get('/activity/stats');
    return response.data['stats'] ?? [];
  }

  // ================= TASKS METHODS =================
  Future<List<dynamic>> getTasks({String? clientId, String? status, String? priority}) async {
    final response = await dio.get('/tasks', queryParameters: {
      if (clientId != null) 'client_id': clientId,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
    });
    return response.data['tasks'] ?? [];
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await dio.post('/tasks', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateTask(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/tasks/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteTask(String id, {bool permanent = false}) async {
    final response = await dio.delete('/tasks/$id', queryParameters: {
      if (permanent) 'permanent': 'true',
    });
    return response.data;
  }

  // ================= FILES & ASSET LIBRARY METHODS =================
  Future<List<dynamic>> getFiles({String? clientId, String? category}) async {
    final response = await dio.get('/files', queryParameters: {
      if (clientId != null) 'client_id': clientId,
      if (category != null) 'category': category,
    });
    return response.data['files'] ?? [];
  }

  Future<Map<String, dynamic>> createFile(Map<String, dynamic> data) async {
    final response = await dio.post('/files', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteFile(String id, {bool permanent = false}) async {
    final response = await dio.delete('/files/$id', queryParameters: {
      if (permanent) 'permanent': 'true',
    });
    return response.data;
  }

  // ================= EMAIL TEMPLATES METHODS =================
  Future<List<dynamic>> getEmailTemplates() async {
    final response = await dio.get('/emails/templates');
    return response.data['templates'] ?? [];
  }

  Future<Map<String, dynamic>> createEmailTemplate(Map<String, dynamic> data) async {
    final response = await dio.post('/emails/templates', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateEmailTemplate(String id, Map<String, dynamic> data) async {
    final response = await dio.put('/emails/templates/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteEmailTemplate(String id) async {
    final response = await dio.delete('/emails/templates/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> sendTestEmail(Map<String, dynamic> data) async {
    final response = await dio.post('/emails/send-test', data: data);
    return response.data;
  }

  // ================= TRASH & 30-DAY RETENTION =================
  Future<List<dynamic>> getTrashItems() async {
    final response = await dio.get('/trash');
    return response.data['items'] ?? [];
  }

  Future<Map<String, dynamic>> restoreTrashItem(String type, String id) async {
    final response = await dio.post('/trash/restore/$type/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> permanentlyDeleteTrashItem(String type, String id) async {
    final response = await dio.delete('/trash/permanent/$type/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> emptyTrash() async {
    final response = await dio.delete('/trash/empty');
    return response.data;
  }

  // ================= WORKSPACE SETTINGS METHODS =================
  Future<Map<String, dynamic>> getSettingsProfile() async {
    final response = await dio.get('/settings/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> updateSettingsProfile(Map<String, dynamic> data) async {
    final response = await dio.put('/settings/profile', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> changeSettingsPassword(String currentPassword, String newPassword) async {
    final response = await dio.post('/settings/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    return response.data;
  }

  Future<List<dynamic>> getSettingsTeam() async {
    final response = await dio.get('/settings/team');
    return response.data['members'] ?? [];
  }

  // ================= CHAT HUB & DIRECT MESSAGES =================
  Future<List<dynamic>> getChatPeers() async {
    final response = await dio.get('/chat/eligible-peers');
    return response.data['peers'] ?? [];
  }

  Future<List<dynamic>> getChannels() async {
    final response = await dio.get('/chat/channels');
    return response.data['channels'] ?? [];
  }

  Future<Map<String, dynamic>> createChannel(String name, {String type = 'PUBLIC', String? clientId}) async {
    final response = await dio.post('/chat/channels', data: {
      'name': name,
      'type': type,
      'client_id': clientId,
    });
    return response.data;
  }

  Future<List<dynamic>> getMessages(String channelId) async {
    final response = await dio.get('/chat/channels/$channelId/messages');
    return response.data['messages'] ?? [];
  }

  Future<Map<String, dynamic>> sendMessage(String channelId, String text) async {
    final response = await dio.post('/chat/channels/$channelId/messages', data: {
      'text': text,
    });
    return response.data;
  }

  Future<List<dynamic>> getDirectMessages(String peerId) async {
    final response = await dio.get('/chat/direct/$peerId/messages');
    return response.data['messages'] ?? [];
  }

  Future<Map<String, dynamic>> sendDirectMessage(String peerId, String text) async {
    final response = await dio.post('/chat/direct/$peerId/messages', data: {
      'text': text,
    });
    return response.data;
  }
}
