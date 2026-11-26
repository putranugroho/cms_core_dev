import 'package:cms_core/models/banking_setup_models.dart';
import 'package:cms_core/models/core_coa_model.dart';
import 'package:cms_core/models/new_menu_models.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/repository/saving_product_repository.dart';

class NewMenuRepository {
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
    if (data is Map) return [data];
    return [];
  }

  static Map<String, dynamic> map(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    return <String, dynamic>{};
  }

  static Future<List<CoreCoaModel>> searchCoa({String keyword = '', int limit = 30}) {
    return SavingProductRepository.searchCoa(keyword: keyword, limit: limit);
  }

  static Future<List<BankProfileModel>> searchBankProfile({String keyword = '', int limit = 100}) async {
    final term = keyword.trim();
    if (term.isEmpty) return <BankProfileModel>[];
    final value = await Setuprepository.fetch(NetworkURL.bprProfile(), {
      'action': 'search_bank',
      'term': term,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mencari sandi bank'));
    final list = rows(value).whereType<Map>().map((e) => BankProfileModel.fromJson(Map<String, dynamic>.from(e))).where((e) => e.kodeBank.isNotEmpty || e.displayName.isNotEmpty).toList();
    list.sort((a, b) {
      final nameCompare = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      if (nameCompare != 0) return nameCompare;
      return a.kodeBank.compareTo(b.kodeBank);
    });
    if (limit > 0 && list.length > limit) return list.take(limit).toList();
    return list;
  }

  // =========================================================
  // Setup Inventaris
  // =========================================================
  static Future<List<SetupInventarisModel>> setupInventarisList({
    String keyword = '',
    String kode = '',
    String statusData = '',
    int page = 1,
    int limit = 100,
  }) async {
    final value = await Setuprepository.fetch(NetworkURL.setupInventarisList(), {
      'group_inventaris': keyword.trim(),
      'kode': kode.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat jenis inventaris'));

    final byGroup = <String, SetupInventarisModel>{};
    for (final item in rows(value).whereType<Map>()) {
      final model = SetupInventarisModel.fromJson(Map<String, dynamic>.from(item));
      if (model.groupInventaris.isEmpty) continue;
      byGroup.putIfAbsent(model.groupInventaris, () => model);
    }
    final list = byGroup.values.toList();
    list.sort((a, b) => a.groupInventaris.compareTo(b.groupInventaris));
    return list;
  }

  static Future<List<SetupInventarisModel>> setupInventarisDetailRows(String groupInventaris) async {
    final value = await Setuprepository.fetch(NetworkURL.setupInventarisList(), {
      'group_inventaris': groupInventaris.trim(),
      'kode': '',
      'status_data': '',
      'page': 1,
      'limit': 100,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail jenis inventaris'));
    final list = rows(value).whereType<Map>().map((e) => SetupInventarisModel.fromJson(Map<String, dynamic>.from(e))).toList();
    if (list.isNotEmpty) return list;

    final detail = await Setuprepository.fetch(NetworkURL.setupInventarisDetail(), {'group_inventaris': groupInventaris.trim()});
    if (!isSuccess(detail)) throw Exception(message(detail, 'Gagal mengambil detail jenis inventaris'));
    return rows(detail).whereType<Map>().map((e) => SetupInventarisModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> setupInventarisSave({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.setupInventarisUpdate() : NetworkURL.setupInventarisCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan jenis inventaris'));
  }

  static Future<void> setupInventarisDelete(String groupInventaris) async {
    final value = await Setuprepository.fetch(NetworkURL.setupInventarisDelete(), {'group_inventaris': groupInventaris.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus jenis inventaris'));
  }

  // =========================================================
  // Pajak Agregat
  // =========================================================
  static Future<Map<String, dynamic>?> pajakAgregatActive() async {
    final value = await Setuprepository.fetch(NetworkURL.pajakAgregatList(), {'page': 1, 'limit': 1});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat Pajak Agregat'));
    final data = rows(value).whereType<Map>().toList();
    return data.isEmpty ? null : Map<String, dynamic>.from(data.first);
  }

  static Future<Map<String, dynamic>> pajakAgregatDetail() async {
    final value = await Setuprepository.fetch(NetworkURL.pajakAgregatDetail(), <String, dynamic>{});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail Pajak Agregat'));
    return map(value);
  }

  static Future<Map<String, dynamic>> pajakAgregatUpsert({required double nominal, required double rate}) async {
    final value = await Setuprepository.fetch(NetworkURL.pajakAgregatUpsert(), {'nominal': nominal, 'rate': rate});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan Pajak Agregat'));
    return map(value);
  }

  // =========================================================
  // ABA
  // =========================================================
  static Future<List<AbaModel>> abaList({
    String keyword = '',
    String jenisRekening = '',
    String statusData = '',
    int page = 1,
    int limit = 100,
  }) async {
    final q = keyword.trim();
    final value = await Setuprepository.fetch(NetworkURL.masterAbaList(), {
      'nomor_rekening': q,
      'nomor_sbb': '',
      'jenis_rekening': jenisRekening.trim(),
      'nama_bank': q,
      'sandi_bank': q,
      'status_rekening': '',
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat ABA'));
    final list = rows(value).whereType<Map>().map((e) => AbaModel.fromJson(Map<String, dynamic>.from(e))).toList();
    list.sort((a, b) => a.nomorRekening.compareTo(b.nomorRekening));
    return list;
  }

  static Future<AbaModel> abaDetail(String nomorRekening) async {
    final value = await Setuprepository.fetch(NetworkURL.masterAbaDetail(), {'nomor_rekening': nomorRekening.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail ABA'));
    return AbaModel.fromJson(map(value));
  }

  static Future<void> abaSave({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.masterAbaUpdate() : NetworkURL.masterAbaCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan ABA'));
  }

  static Future<void> abaDelete(String nomorRekening) async {
    final value = await Setuprepository.fetch(NetworkURL.masterAbaDelete(), {'nomor_rekening': nomorRekening.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus ABA'));
  }

  // =========================================================
  // Mitra Bisnis
  // =========================================================
  static Future<List<MitraBisnisModel>> mitraList({
    String keyword = '',
    String kelompok = '',
    int page = 1,
    int limit = 100,
  }) async {
    final q = keyword.trim();
    final value = await Setuprepository.fetch(NetworkURL.masterMitraBisnisSearch(), {
      'kode_mitra': q,
      'kelompok': kelompok.trim(),
      'nama_mitra': q,
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat Mitra Bisnis'));
    final list = rows(value).whereType<Map>().map((e) => MitraBisnisModel.fromJson(Map<String, dynamic>.from(e))).toList();
    list.sort((a, b) => a.kodeMitra.compareTo(b.kodeMitra));
    return list;
  }

  static Future<MitraBisnisModel> mitraDetail(String kodeMitra) async {
    final value = await Setuprepository.fetch(NetworkURL.masterMitraBisnisDetail(), {'kode_mitra': kodeMitra.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail Mitra Bisnis'));
    return MitraBisnisModel.fromJson(map(value));
  }

  static Future<void> mitraSave({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.masterMitraBisnisUpdate() : NetworkURL.masterMitraBisnisCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan Mitra Bisnis'));
  }

  static Future<void> mitraDelete(String kodeMitra) async {
    final value = await Setuprepository.fetch(NetworkURL.masterMitraBisnisDelete(), {'kode_mitra': kodeMitra.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus Mitra Bisnis'));
  }

  // =========================================================
  // Master Inventaris
  // =========================================================
  static Future<List<MasterInventarisAsetModel>> inventarisList({
    String keyword = '',
    String kelompokAset = '',
    String groupAset = '',
    String statusData = '',
    int page = 1,
    int limit = 100,
  }) async {
    final q = keyword.trim();
    final value = await Setuprepository.fetch(NetworkURL.masterInventarisList(), {
      'kode_inventaris': q,
      'nama_inventaris': q,
      'kelompok_aset': kelompokAset.trim(),
      'group_aset': groupAset.trim(),
      'status_aset': '',
      'kode_kantor': '',
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat Inventaris'));
    final list = rows(value).whereType<Map>().map((e) => MasterInventarisAsetModel.fromJson(Map<String, dynamic>.from(e))).toList();
    list.sort((a, b) => a.kodeInventaris.compareTo(b.kodeInventaris));
    return list;
  }

  static Future<BankingPage<MasterInventarisAsetModel>> inventarisPage({
    String keyword = '',
    String searchField = 'code',
    String kelompokAset = '',
    String groupAset = '',
    String statusData = '',
    int page = 1,
    int limit = 100,
  }) async {
    final q = keyword.trim();
    final value = await Setuprepository.fetch(NetworkURL.masterInventarisList(), {
      'kode_inventaris': searchField == 'code' ? q : '',
      'nama_inventaris': searchField == 'name' ? q : '',
      'kelompok_aset': kelompokAset.trim(),
      'group_aset': groupAset.trim(),
      'status_aset': '',
      'kode_kantor': '',
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat Inventaris'));
    final list = rows(value).whereType<Map>().map((e) => MasterInventarisAsetModel.fromJson(Map<String, dynamic>.from(e))).toList();
    list.sort((a, b) => a.kodeInventaris.compareTo(b.kodeInventaris));
    final data = value['data'];
    final totalRaw = data is Map ? data['total'] : value['total'];
    final total = int.tryParse(totalRaw?.toString() ?? '') ?? ((page - 1) * limit + list.length);
    return BankingPage(items: list, total: total, page: page, limit: limit);
  }

  static Future<MasterInventarisAsetModel> inventarisDetail(String kodeInventaris) async {
    final value = await Setuprepository.fetch(NetworkURL.masterInventarisDetail(), {'kode_inventaris': kodeInventaris.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail Inventaris'));
    return MasterInventarisAsetModel.fromJson(map(value));
  }

  static Future<void> inventarisSave({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.masterInventarisUpdate() : NetworkURL.masterInventarisCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan Inventaris'));
  }

  static Future<void> inventarisDelete(String kodeInventaris) async {
    final value = await Setuprepository.fetch(NetworkURL.masterInventarisDelete(), {'kode_inventaris': kodeInventaris.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus Inventaris'));
  }
}
