import 'package:cms_core/models/core_coa_model.dart';
import 'package:cms_core/models/loan_product_model.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/repository/saving_product_repository.dart';

class LoanProductRepository {
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

  static int total(dynamic value) {
    if (value is! Map) return 0;
    final data = value['data'];
    if (data is Map && data['total'] != null) {
      if (data['total'] is num) return (data['total'] as num).toInt();
      return int.tryParse(data['total'].toString()) ?? 0;
    }
    return rows(value).length;
  }

  static Future<LoanProductListResult> list({
    String keyword = '',
    String jenisLoan = '',
    String statusData = 'A',
    int page = 1,
    int limit = 50,
  }) async {
    final q = keyword.trim();
    final body = {
      'kode_produk': q,
      'nama_produk': q,
      'jenis_loan': jenisLoan.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    };

    final value = await Setuprepository.fetch(NetworkURL.setupLoanList(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat produk kredit'));
    final items = rows(value).whereType<Map>().map((e) => LoanProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
    items.sort((a, b) => a.kodeProduk.compareTo(b.kodeProduk));
    return LoanProductListResult(items: items, total: total(value));
  }

  static Future<LoanProductModel> detail(String kodeProduk) async {
    final value = await Setuprepository.fetch(NetworkURL.setupLoanDetail(), {'kode_produk': kodeProduk.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail produk kredit'));
    return LoanProductModel.fromJson(map(value));
  }

  static Future<void> save({required bool isEdit, required Map<String, dynamic> body}) async {
    final endpoint = isEdit ? NetworkURL.setupLoanUpdate() : NetworkURL.setupLoanCreate();
    final value = await Setuprepository.fetch(endpoint, body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan produk kredit'));
  }

  static Future<void> delete(String kodeProduk) async {
    final value = await Setuprepository.fetch(NetworkURL.setupLoanDelete(), {'kode_produk': kodeProduk.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus produk kredit'));
  }

  static Future<List<CoreCoaModel>> searchCoa({String keyword = '', int limit = 30}) {
    return SavingProductRepository.searchCoa(keyword: keyword, limit: limit);
  }
}
