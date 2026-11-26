import 'dart:convert';

import 'package:cms_core/models/index.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';

class SandiRepository {
  static bool isSuccess(dynamic value) {
    if (value is! Map) return false;
    final code = (value['code'] ?? '').toString();
    final status = (value['status'] ?? '').toString().toLowerCase();
    return code == '000' || status.contains('success');
  }

  static String message(dynamic value, [String fallback = '']) {
    if (value is Map && value['message'] != null) return value['message'].toString();
    return fallback;
  }

  static List<dynamic> _extractRows(dynamic value) {
    if (value is! Map) return [];
    final data = value['data'];
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is List) return data;
    return [];
  }

  static Map<String, dynamic> _extractMap(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    return <String, dynamic>{};
  }

  static Future<List<SandiGroupModel>> groupList({
    String kategori = '',
    String sumber = '',
    int page = 1,
    int limit = 500,
  }) async {
    final body = <String, dynamic>{
      'kategori': kategori.trim(),
      'sumber': sumber.trim(),
      'page': page,
      'limit': limit,
    };

    final value = await Setuprepository.fetch(NetworkURL.sandiGroupList(), body);
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal memuat group sandi'));
    }

    return _extractRows(value)
        .whereType<Map>()
        .map((e) => SandiGroupModel.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.group.trim().isNotEmpty)
        .toList();
  }

  static Future<List<SandiModel>> list({
    String group = '',
    String keyword = '',
    String status = '',
    int page = 1,
    int limit = 100,
  }) async {
    final body = <String, dynamic>{
      'group': group.trim(),
      'kode': keyword.trim(),
      'nama': keyword.trim(),
      'status': status.trim(),
      'page': page,
      'limit': limit,
    };

    final value = await Setuprepository.fetch(NetworkURL.sandiList(), body);
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal memuat data sandi'));
    }

    return _extractRows(value).whereType<Map>().map((e) => SandiModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<SandiModel> detail({required String group, required String kode}) async {
    final value = await Setuprepository.fetch(
      NetworkURL.sandiDetail(),
      {'group': group.trim(), 'kode': kode.trim()},
    );
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal mengambil detail sandi'));
    }
    return SandiModel.fromJson(_extractMap(value));
  }

  static Future<SandiModel?> save({
    required bool isEdit,
    required String group,
    required String kode,
    required String nama,
    required bool pavorit,
    String status = 'A',
  }) async {
    final body = <String, dynamic>{
      'group': group.trim().toUpperCase(),
      'kode': kode.trim(),
      'nama': nama.trim(),
      'pavorit': pavorit,
    };

    if (isEdit) {
      body['status'] = status.trim().isEmpty ? 'A' : status.trim().toUpperCase();
    }

    final value = await Setuprepository.fetch(
      isEdit ? NetworkURL.sandiUpdate() : NetworkURL.sandiCreate(),
      body,
    );
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal menyimpan sandi'));
    }

    final data = _extractMap(value);
    if (data.isEmpty) return null;
    return SandiModel.fromJson(data);
  }

  static Future<Map<String, dynamic>> delete({required String group, required String kode}) async {
    final value = await Setuprepository.fetch(
      NetworkURL.sandiDelete(),
      {'group': group.trim(), 'kode': kode.trim()},
    );
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal menghapus sandi'));
    }
    return _extractMap(value);
  }

  static String prettyJson(dynamic value) => const JsonEncoder.withIndent('  ').convert(value);
}
