import 'package:cms_core/models/index.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';

class SavingProductRepository {
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

  static Future<List<SavingProductModel>> list({
    String keyword = '',
    String jenisTabungan = '',
    String statusData = 'A',
    int page = 1,
    int limit = 100,
  }) async {
    final q = keyword.trim();
    final merged = <String, SavingProductModel>{};

    Future<void> fetch(Map<String, dynamic> body) async {
      final value = await Setuprepository.fetch(NetworkURL.savingProductList(), body);
      if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat produk tabungan'));
      for (final item in rows(value).whereType<Map>()) {
        final model = SavingProductModel.fromJson(Map<String, dynamic>.from(item));
        merged[model.kodeProduk] = model;
      }
    }

    if (q.isEmpty) {
      await fetch({
        'kode_produk': '',
        'nama_produk': '',
        'jenis_tabungan': jenisTabungan.trim(),
        'status_data': statusData.trim(),
        'page': page,
        'limit': limit,
      });
    } else {
      await fetch({
        'kode_produk': q,
        'nama_produk': '',
        'jenis_tabungan': jenisTabungan.trim(),
        'status_data': statusData.trim(),
        'page': page,
        'limit': limit,
      });
      await fetch({
        'kode_produk': '',
        'nama_produk': q,
        'jenis_tabungan': jenisTabungan.trim(),
        'status_data': statusData.trim(),
        'page': page,
        'limit': limit,
      });
    }

    return merged.values.toList();
  }

  static Future<SavingProductModel> detail(String kodeProduk) async {
    final value = await Setuprepository.fetch(NetworkURL.savingProductDetail(), {'kode_produk': kodeProduk.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail produk tabungan'));
    return SavingProductModel.fromJson(map(value));
  }

  static Future<void> save({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.savingProductUpdate() : NetworkURL.savingProductCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan produk tabungan'));
  }

  static Future<void> delete(String kodeProduk) async {
    final value = await Setuprepository.fetch(NetworkURL.savingProductDelete(), {'kode_produk': kodeProduk.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus produk tabungan'));
  }

  static Future<List<CoreCoaModel>> searchCoa({String keyword = '', int limit = 30}) async {
    final q = keyword.trim();
    final merged = <String, CoreCoaModel>{};

    Future<void> fetch(Map<String, dynamic> body) async {
      final value = await Setuprepository.fetch(NetworkURL.getMasterGl(), body);
      if (!isSuccess(value)) throw Exception(message(value, 'Gagal mencari COA'));
      for (final item in rows(value).whereType<Map>()) {
        final model = CoreCoaModel.fromJson(Map<String, dynamic>.from(item));
        if (model.statusData.toUpperCase() == 'D') continue;
        merged[model.kodeCoa] = model;
      }
    }

    final baseBody = <String, dynamic>{
      'tipe_coa': null,
      'level_coa': null,
      'parent_coa': '',
      'posting_type': '',
      'special_type': '',
      'ojk_code': '',
      'status_data': 'A',
      'page': 1,
      'limit': limit,
    };

    if (q.isEmpty) {
      await fetch({
        ...baseBody,
        'kode_coa': '',
        'nama_coa': '',
      });
    } else {
      await fetch({
        ...baseBody,
        'kode_coa': q,
        'nama_coa': '',
      });
      await fetch({
        ...baseBody,
        'kode_coa': '',
        'nama_coa': q,
      });
    }

    final result = merged.values.toList();
    result.sort((a, b) => a.kodeCoa.compareTo(b.kodeCoa));
    return result;
  }
}
