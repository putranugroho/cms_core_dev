import 'dart:convert';

import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/network/network.dart';
import 'package:accounting_kantor_gl_useraccess/repository/SetupRepository.dart';

class AoRepository {
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


  static Future<List<KantorModel>> listKantor({
    String keyword = '',
    String statusAktif = '',
    String statusData = '',
    int page = 1,
    int limit = 500,
  }) async {
    final body = <String, dynamic>{
      'kode_kantor': keyword.trim(),
      'nama': keyword.trim(),
      'alamat': '',
      'kota': '',
      'telp': '',
      'nomor_fax': '',
      'kode_pos': '',
      'bprid': '',
      'status_kantor': null,
      'status_aktif': statusAktif.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    };

    final value = await Setuprepository.fetch(NetworkURL.getKantor(), body);
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal memuat data kantor'));
    }

    return _extractRows(value)
        .whereType<Map>()
        .map((e) => KantorModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<AoModel>> list({
    String keyword = '',
    int? roleAo,
    String kodeKantor = '',
    String statusData = '',
    int page = 1,
    int limit = 100,
  }) async {
    final body = <String, dynamic>{
      'kode_ao': keyword.trim(),
      'nama_ao': keyword.trim(),
      'no_hp': keyword.trim(),
      'role_ao': roleAo,
      'kode_kantor': kodeKantor.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    };

    final value = await Setuprepository.fetch(NetworkURL.aoList(), body);
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal memuat data AO'));
    }

    return _extractRows(value)
        .whereType<Map>()
        .map((e) => AoModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<AoModel> detail(String kodeAo) async {
    final value = await Setuprepository.fetch(
      NetworkURL.aoDetail(),
      {'kode_ao': kodeAo.trim()},
    );
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal mengambil detail AO'));
    }
    return AoModel.fromJson(_extractMap(value));
  }

  static Future<AoModel?> save({
    required bool isEdit,
    required String kodeAo,
    required String namaAo,
    required String noHp,
    required int roleAo,
    required String kodeKantor,
  }) async {
    final body = <String, dynamic>{
      'kode_ao': kodeAo.trim().toUpperCase(),
      'nama_ao': namaAo.trim().toUpperCase(),
      'no_hp': noHp.trim(),
      'role_ao': roleAo,
      'kode_kantor': kodeKantor.trim(),
    };

    final value = await Setuprepository.fetch(
      isEdit ? NetworkURL.aoUpdate() : NetworkURL.aoCreate(),
      body,
    );
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal menyimpan AO'));
    }

    final data = _extractMap(value);
    if (data.isEmpty) return null;
    return AoModel.fromJson(data);
  }

  static Future<Map<String, dynamic>> delete(String kodeAo) async {
    final value = await Setuprepository.fetch(
      NetworkURL.aoDelete(),
      {'kode_ao': kodeAo.trim()},
    );
    if (!isSuccess(value)) {
      throw Exception(message(value, 'Gagal menghapus AO'));
    }
    return _extractMap(value);
  }

  static String prettyJson(dynamic value) => const JsonEncoder.withIndent('  ').convert(value);
}
