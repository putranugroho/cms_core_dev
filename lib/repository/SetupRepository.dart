import 'dart:convert';

import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class Setuprepository {
  static Future<Dio> _dio() async {
    final pref = Pref();
    final sessionToken = await pref.getSessionToken();
    final users = await pref.getUsers();

    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (sessionToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $sessionToken';
      headers['X-Session-Token'] = sessionToken;
    }

    if (users.userid.isNotEmpty) {
      headers['X-Username'] = users.userid;
    }
    if (users.kodeKantor.isNotEmpty) {
      headers['X-Kode-Kantor'] = users.kodeKantor;
    }

    return Dio(BaseOptions(headers: headers));
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
    if (e.response?.data != null) {
      return _decode(e.response!.data);
    }
    return {
      'status': 'error',
      'message': e.message ?? 'Request failed',
      'status_code': e.response?.statusCode,
    };
  }

  static Future<dynamic> _post(String url, dynamic body) async {
    final dio = await _dio();
    if (kDebugMode) {
      print('ENDPOINT URL : $url');
      print('REQUEST : $body');
    }

    try {
      final response = await dio.post(url, data: body);
      if (kDebugMode) {
        print('RESPONSE STATUS CODE : ${response.statusCode}');
        print('RESPONSE DATA : ${response.data}');
      }
      return _decode(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DIO ERROR STATUS : ${e.response?.statusCode}');
        print('DIO ERROR DATA : ${e.response?.data}');
      }
      return _decodeError(e);
    }
  }

  static Future<dynamic> _put(String url, dynamic body) async {
    final dio = await _dio();
    if (kDebugMode) {
      print('ENDPOINT URL : $url');
      print('REQUEST : $body');
    }

    try {
      final response = await dio.put(url, data: body);
      if (kDebugMode) {
        print('RESPONSE STATUS CODE : ${response.statusCode}');
        print('RESPONSE DATA : ${response.data}');
      }
      return _decode(response.data);
    } on DioException catch (e) {
      return _decodeError(e);
    }
  }

  static Future<dynamic> getPerusahaan(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> getKantor(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> insertKantor(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> editKantor(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> deleteKantor(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> setup(String token, String url, String json) async => _post(url, json);
  static Future<dynamic> fetch(String url, Map<String, dynamic> body) async => _post(url, jsonEncode(body));
  static Future<dynamic> updatesetup(String token, String url, String json) async => _put(url, json);
}
