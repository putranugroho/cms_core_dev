import 'dart:convert';

import 'package:cms_core/pref/pref.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class Setuprepository {
  static const String trxSource = 'CBS_TELLER';
  static final ValueNotifier<String?> sessionFailure = ValueNotifier<String?>(null);

  static bool isSessionFailure(dynamic value) {
    if (value is! Map) return false;
    final source = (value['error_source'] ?? '').toString();
    final code = (value['code'] ?? '').toString();
    if (code == '000') return false;
    return source == 'cms_session' ||
        (source.isEmpty && (code == '401' || code == '440'));
  }

  static Future<Dio> _dio() async {
    final pref = Pref();
    final sessionToken = await pref.getSessionToken();
    final users = await pref.getUsers();
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Trx-Source': trxSource,
    };
    if (sessionToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $sessionToken';
      headers['X-Session-Token'] = sessionToken;
    }
    if (users.userid.trim().isNotEmpty) {
      headers['X-Username'] = users.userid.trim();
      headers['X-User-Id'] = users.userid.trim();
    }
    if (users.kodeKantor.trim().isNotEmpty) {
      headers['X-Kode-Kantor'] = users.kodeKantor.trim();
    }
    if (users.kodePt.trim().isNotEmpty) {
      headers['X-Bpr-Id'] = users.kodePt.trim();
    }
    // JWT, API key and HMAC signing stay in the middleware.
    return Dio(BaseOptions(
      headers: headers,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ));
  }

  static dynamic _decode(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return {'status': 'error', 'message': data};
      }
    }
    return jsonDecode(jsonEncode(data));
  }

  static dynamic _decodeError(DioException e) {
    if (e.response?.data != null) return _decode(e.response!.data);
    return {
      'code': '088',
      'status': 'error',
      'message': e.message ?? 'Koneksi ke middleware gagal. Silakan coba kembali.',
      'status_code': e.response?.statusCode,
      'error_source': 'transport',
      'data': null,
    };
  }

  static Future<dynamic> _processResponse(String url, dynamic value, String requestSession) async {
    final path = Uri.tryParse(url)?.path ?? '';
    if (path == '/auth/login' || path == '/csr/auth/login') {
      if (value is Map && value['code']?.toString() == '000') {
        sessionFailure.value = null;
      }
      return value;
    }
    if (isSessionFailure(value)) {
      // An old request must not log out a session created by a later login.
      final currentSession = await Pref().getSessionToken();
      if (currentSession == requestSession) {
        sessionFailure.value = value['message']?.toString() ?? 'Session berakhir. Silakan login kembali.';
      }
    }
    return value;
  }

  static Future<dynamic> _request(String url, dynamic body, {bool put = false}) async {
    final dio = await _dio();
    final requestSession = (dio.options.headers['X-Session-Token'] ?? '').toString();
    final path = Uri.tryParse(url)?.path ?? '';
    if ((path.startsWith('/setup/') || path.startsWith('/master/')) && requestSession.isEmpty) {
      return _processResponse(url, {
        'code': '401',
        'status': 'failed',
        'message': 'Session login tidak tersedia. Silakan login kembali.',
        'error_source': 'cms_session',
        'data': null,
      }, requestSession);
    }
    if (kDebugMode) print('ENDPOINT URL : $url');
    try {
      final response = put
          ? await dio.put(url, data: body)
          : await dio.post(url, data: body);
      if (kDebugMode) print('RESPONSE STATUS CODE : ${response.statusCode}');
      return _processResponse(url, _decode(response.data), requestSession);
    } on DioException catch (e) {
      if (kDebugMode) print('DIO ERROR STATUS : ${e.response?.statusCode}');
      return _processResponse(url, _decodeError(e), requestSession);
    }
  }

  static Future<dynamic> _post(String url, dynamic body) => _request(url, body);
  static Future<dynamic> _put(String url, dynamic body) => _request(url, body, put: true);

  static Future<dynamic> getPerusahaan(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> getKantor(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> insertKantor(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> editKantor(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> deleteKantor(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> setup(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> fetch(String url, Map<String, dynamic> body) async => _post(url, jsonEncode(body));
  static Future<dynamic> updatesetup(String token, String url, String json) async => _put(url, json);
}
