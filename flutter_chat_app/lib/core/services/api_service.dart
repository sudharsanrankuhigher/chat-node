import 'package:dio/dio.dart';

import '../models/api_exception.dart';
import '../models/chat_message.dart';
import '../models/connection_request.dart';
import '../models/user_profile.dart';
import '../utils/app_constants.dart';
import 'session_service.dart';

class ApiService {
  ApiService(this._sessionService)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: AppConstants.requestTimeout,
            receiveTimeout: AppConstants.requestTimeout,
            sendTimeout: AppConstants.requestTimeout,
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final bool includeAuthToken = options.extra['includeAuthToken'] != false;
          final String? token = _sessionService.authToken;
          if (includeAuthToken && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          handler.reject(error);
        },
      ),
    );
  }

  final SessionService _sessionService;
  final Dio _dio;

  Future<UserProfile> getProfile() async {
    final Map<String, dynamic> json = await _get('/profile');
    return UserProfile.fromJson(Map<String, dynamic>.from(json['data'] as Map));
  }

  Future<Map<String, dynamic>> sendOtp({
    required String mobile,
    String? name,
  }) {
    return _post(
      '/auth/send-otp',
      <String, dynamic>{
        'mobile': mobile,
        if (name != null && name.isNotEmpty) 'name': name,
      },
      includeAuthToken: false,
    );
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    final Map<String, dynamic> json = await _post(
      '/auth/verify-otp',
      <String, dynamic>{
        'mobile': mobile,
        'otp': otp,
      },
      includeAuthToken: false,
    );

    final Map<String, dynamic> data = Map<String, dynamic>.from(json['data'] as Map);
    final String token = (data['token'] ?? '').toString();
    if (token.isNotEmpty) {
      _sessionService.setAuthToken(token);
    }

    final UserProfile user = UserProfile.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    _sessionService.setCurrentUser(user);

    return json;
  }

  Future<List<UserProfile>> getUsers() async {
    final Map<String, dynamic> json = await _get('/users');
    return _parseUserList(json['data']);
  }

  Future<List<UserProfile>> getConnections() async {
    final Map<String, dynamic> json = await _get('/connections');
    return _parseUserList(json['data']);
  }

  Future<List<ConnectionRequest>> getPendingRequests() async {
    final Map<String, dynamic> json = await _get('/connections/pending');
    return _parseConnectionRequests(json['data']);
  }

  Future<List<ConnectionRequest>> getInvitedRequests() async {
    final Map<String, dynamic> json = await _get('/connections/invited');
    return _parseConnectionRequests(json['data']);
  }

  Future<ConnectionRequest> sendConnectionRequest(String receiverId) async {
    final Map<String, dynamic> json = await _post(
      '/connections/send-request',
      <String, dynamic>{'receiverId': receiverId},
    );
    return ConnectionRequest.fromJson(
      Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  Future<ConnectionRequest> acceptConnectionRequest(String connectionId) async {
    final Map<String, dynamic> json = await _post(
      '/connections/respond',
      <String, dynamic>{
        'connectionId': connectionId,
        'status': 'accepted',
      },
    );
    return ConnectionRequest.fromJson(
      Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  Future<ConnectionRequest> cancelConnectionRequest(String connectionId) async {
    final Map<String, dynamic> json = await _post(
      '/connections/cancel',
      <String, dynamic>{'connectionId': connectionId},
    );
    return ConnectionRequest.fromJson(
      Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  Future<List<ChatMessage>> getChatHistory(String userId) async {
    final Map<String, dynamic> json = await _get('/chat/history/$userId');
    final List<dynamic> rawMessages = (json['data'] as List<dynamic>? ?? <dynamic>[]);
    return rawMessages
        .map(
          (dynamic item) =>
              ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<num> getWalletBalance() async {
    final Map<String, dynamic> json = await _get('/wallet');
    final Map<String, dynamic> data = Map<String, dynamic>.from(json['data'] as Map);
    return data['walletBalance'] as num? ?? 0;
  }

  Future<num> addMoney(num amount) async {
    final Map<String, dynamic> json = await _post(
      '/wallet/add-money',
      <String, dynamic>{'amount': amount},
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(json['data'] as Map);
    return data['walletBalance'] as num? ?? 0;
  }

  Future<UserProfile> updateProfile({
    required String name,
  }) async {
    final Map<String, dynamic> json = await _patch(
      '/profile',
      <String, dynamic>{'name': name},
    );
    final UserProfile user = UserProfile.fromJson(
      Map<String, dynamic>.from(json['data'] as Map),
    );
    _sessionService.setCurrentUser(user);
    return user;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      return Map<String, dynamic>.from((response.data ?? <String, dynamic>{}) as Map);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
    {bool includeAuthToken = true}
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(
          extra: <String, dynamic>{'includeAuthToken': includeAuthToken},
        ),
      );
      return Map<String, dynamic>.from((response.data ?? <String, dynamic>{}) as Map);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        path,
        data: body,
      );
      return Map<String, dynamic>.from((response.data ?? <String, dynamic>{}) as Map);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final dynamic data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString());
    }

    if (error.message != null && error.message!.isNotEmpty) {
      return ApiException(error.message!);
    }

    return ApiException('Request failed');
  }

  List<UserProfile> _parseUserList(dynamic rawData) {
    final List<dynamic> items = rawData as List<dynamic>? ?? <dynamic>[];
    return items
        .map(
          (dynamic item) =>
              UserProfile.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  List<ConnectionRequest> _parseConnectionRequests(dynamic rawData) {
    final List<dynamic> items = rawData as List<dynamic>? ?? <dynamic>[];
    return items
        .map(
          (dynamic item) => ConnectionRequest.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
