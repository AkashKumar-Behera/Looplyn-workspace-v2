import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiClient() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        return handler.next(error);
      },
    ));
  }

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    if (response.data['success'] == true) {
      await storage.write(key: 'jwt_token', value: response.data['token']);
    }
    return response.data;
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
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

  // Super Admin Management Methods
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

  // Content & Studio Methods
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

  Future<Map<String, dynamic>> deleteContent(String id) async {
    final response = await dio.delete('/contents/$id');
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

  // Chat Hub Methods
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
}
