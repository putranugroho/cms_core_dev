import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/network/network.dart';
import 'package:accounting_kantor_gl_useraccess/repository/SetupRepository.dart';

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
    final value = await Setuprepository.fetch(NetworkURL.savingProductList(), {
      'kode_produk': keyword.trim(),
      'nama_produk': keyword.trim(),
      'jenis_tabungan': jenisTabungan.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat produk tabungan'));
    return rows(value).whereType<Map>().map((e) => SavingProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
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
}
