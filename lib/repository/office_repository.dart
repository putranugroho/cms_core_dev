import 'package:cms_core/models/kantor_model.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/SetupRepository.dart';

class OfficeRepository {
  static String get _base => url;

  static bool isSuccess(dynamic value) {
    if (value is! Map) return false;
    final code = (value['code'] ?? '').toString();
    final status = (value['status'] ?? '').toString().toLowerCase();
    return code == '000' || status.contains('success') || status.contains('sukses');
  }

  static String message(dynamic value, [String fallback = '']) {
    if (value is Map && value['message'] != null) return value['message'].toString();
    return fallback;
  }

  static List<dynamic> rows(dynamic value) {
    if (value is! Map) return [];
    final data = value['data'];
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is List) return data;
    return [];
  }

  static Map<String, dynamic> map(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    return <String, dynamic>{};
  }

  static int total(dynamic value) {
    if (value is! Map) return 0;
    final data = value['data'];
    if (data is Map && data['total'] != null) {
      if (data['total'] is num) return (data['total'] as num).toInt();
      return int.tryParse(data['total'].toString()) ?? 0;
    }
    return rows(value).length;
  }

  static Future<String> effectiveBprId() async {
    final users = await Pref().getUsers();
    final bprId = users.kodePt.trim();
    if (bprId.isEmpty) throw Exception('BPR user login belum diisi. Periksa data user lalu login kembali.');
    return bprId;
  }

  static Future<OfficeListResult> list({
    String keyword = '',
    String statusAktif = '',
    String statusData = 'A',
    int page = 1,
    int limit = 50,
    String bprId = '',
  }) async {
    final q = keyword.trim();
    final effectiveBpr = bprId.trim().isNotEmpty ? bprId.trim() : await effectiveBprId();
    final body = {
      'kode_kantor': q,
      'nama_kantor': q,
      'status_kantor': null,
      'status_aktif': statusAktif.trim(),
      'kode_induk': '',
      'alamat': '',
      'kelurahan': '',
      'kecamatan': '',
      'kota': '',
      'provinsi': '',
      'kode_pos': '',
      'bpr_id': effectiveBpr,
      'telp': '',
      'nomor_fax': '',
      'pimpinan_cabang': '',
      'manager_operasional': '',
      'manager_marketing': '',
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    };

    final value = await Setuprepository.fetch('$_base/setup/office/list', body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat data kantor'));
    final items = rows(value).whereType<Map>().map((e) => KantorModel.fromJson(Map<String, dynamic>.from(e))).toList()
      ..sort((a, b) => a.kodeKantor.compareTo(b.kodeKantor));
    return OfficeListResult(items: items, total: total(value));
  }

  static Future<KantorModel> detail(String kodeKantor) async {
    final value = await Setuprepository.fetch('$_base/setup/office/detail', {'kode_kantor': kodeKantor.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail kantor'));
    return KantorModel.fromJson(map(value));
  }

  static Future<void> save({required bool isEdit, required Map<String, dynamic> body}) async {
    final endpoint = isEdit ? 'update' : 'create';
    final value = await Setuprepository.fetch('$_base/setup/office/$endpoint', body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan data kantor'));
  }

  static Future<void> delete(String kodeKantor) async {
    final value = await Setuprepository.fetch('$_base/setup/office/delete', {'kode_kantor': kodeKantor.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus data kantor'));
  }
}

class OfficeListResult {
  final List<KantorModel> items;
  final int total;

  const OfficeListResult({required this.items, required this.total});
}
