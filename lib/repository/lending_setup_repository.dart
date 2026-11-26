import 'package:cms_core/models/index.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/repository/hris_repository.dart';

class LendingSetupRepository {
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

  static Future<List<KantorModel>> listKantor({String keyword = '', int page = 1, int limit = 500}) async {
    final all = await HrisRepository.listKantor();
    final q = keyword.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all.where((item) => item.kodeKantor.toLowerCase().contains(q) || item.namaKantor.toLowerCase().contains(q)).toList();
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 500 : limit;
    final start = (safePage - 1) * safeLimit;
    if (start >= filtered.length) return [];
    final end = start + safeLimit > filtered.length ? filtered.length : start + safeLimit;
    return filtered.sublist(start, end);
  }

  static Future<List<AgunanSetupModel>> listAgunan({String keyword = '', String statusData = 'A', int page = 1, int limit = 100}) async {
    final value = await Setuprepository.fetch(NetworkURL.agunanList(), {
      'kode_agunan': keyword.trim(),
      'keterangan': keyword.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat agunan'));
    return rows(value).whereType<Map>().map((e) => AgunanSetupModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<AgunanSetupModel> detailAgunan(String kodeAgunan) async {
    final value = await Setuprepository.fetch(NetworkURL.agunanDetail(), {'kode_agunan': kodeAgunan.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail agunan'));
    return AgunanSetupModel.fromJson(map(value));
  }

  static Future<void> saveAgunan({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.agunanUpdate() : NetworkURL.agunanCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan agunan'));
  }

  static Future<void> deleteAgunan(String kodeAgunan) async {
    final value = await Setuprepository.fetch(NetworkURL.agunanDelete(), {'kode_agunan': kodeAgunan.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus agunan'));
  }

  static Future<List<BobotPpapModel>> listBobotPpap({String keyword = '', String statusData = 'A', int page = 1, int limit = 100}) async {
    final value = await Setuprepository.fetch(NetworkURL.bobotPpapList(), {
      'coll': keyword.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat bobot PPAP'));
    return rows(value).whereType<Map>().map((e) => BobotPpapModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<BobotPpapModel> detailBobotPpap(String coll) async {
    final value = await Setuprepository.fetch(NetworkURL.bobotPpapDetail(), {'coll': coll.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail PPAP'));
    return BobotPpapModel.fromJson(map(value));
  }

  static Future<void> saveBobotPpap({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.bobotPpapUpdate() : NetworkURL.bobotPpapCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan bobot PPAP'));
  }

  static Future<void> deleteBobotPpap(String coll) async {
    final value = await Setuprepository.fetch(NetworkURL.bobotPpapDelete(), {'coll': coll.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus bobot PPAP'));
  }

  static Future<Map<String, dynamic>> saveRakOffice({required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(NetworkURL.rakSetupOffice(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan RAK kantor'));
    return map(value);
  }

  static Future<Map<String, dynamic>?> detailRakOffice(String kodeKantor) async {
    final value = await Setuprepository.fetch(NetworkURL.rakOfficeDetail(), {'kode_kantor': kodeKantor.trim()});
    if (value is Map && value['code']?.toString() == '009') return null;
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat setup SBB RAK'));
    return map(value);
  }

  static Future<Map<String, dynamic>> saveRakRate({required String rate}) async {
    final value = await Setuprepository.fetch(NetworkURL.rakSetupRate(), {
      'rate': rate.trim().replaceAll(',', '.'),
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan Rate RAK'));
    return map(value);
  }

  static Future<Map<String, dynamic>?> detailRakRate() async {
    final value = await Setuprepository.fetch(NetworkURL.rakRateDetail(), <String, dynamic>{});
    if (value is Map && value['code']?.toString() == '009') return null;
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat Rate RAK'));
    return map(value);
  }

  static Future<List<RakRelasiModel>> listRakRelasi(
      {String kodeKantor = '', String kodeKantorLawan = '', String statusData = '', int page = 1, int limit = 100}) async {
    final value = await Setuprepository.fetch(NetworkURL.rakRelasiList(), {
      'kode_kantor': kodeKantor.trim(),
      'kode_kantor_lawan': kodeKantorLawan.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat rate RAK'));
    return rows(value).whereType<Map>().map((e) => RakRelasiModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> saveRakRelasi({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.rakRelasiUpdate() : NetworkURL.rakRelasiCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan rate RAK'));
  }

  static Future<void> deleteRakRelasi({required String kodeKantor, required String kodeKantorLawan}) async {
    final value = await Setuprepository.fetch(NetworkURL.rakRelasiDelete(), {
      'kode_kantor': kodeKantor.trim(),
      'kode_kantor_lawan': kodeKantorLawan.trim(),
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus rate RAK'));
  }
}
