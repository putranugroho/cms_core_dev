import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/network/network.dart';
import 'package:accounting_kantor_gl_useraccess/repository/SetupRepository.dart';

class PrintSetupRepository {
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

  static Future<List<FormatBukuModel>> listFormatBuku({String keyword = '', String statusData = 'A', int page = 1, int limit = 100}) async {
    final value = await Setuprepository.fetch(NetworkURL.formatBukuList(), {
      'kode_format': keyword.trim(),
      'nama_format': keyword.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat format buku'));
    return rows(value).whereType<Map>().map((e) => FormatBukuModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<FormatBukuModel> detailFormatBuku(String kodeFormat) async {
    final value = await Setuprepository.fetch(NetworkURL.formatBukuDetail(), {'kode_format': kodeFormat.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail format buku'));
    return FormatBukuModel.fromJson(map(value));
  }

  static Future<void> saveFormatBuku({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.formatBukuUpdate() : NetworkURL.formatBukuCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan format buku'));
  }

  static Future<void> deleteFormatBuku(String kodeFormat) async {
    final value = await Setuprepository.fetch(NetworkURL.formatBukuDelete(), {'kode_format': kodeFormat.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus format buku'));
  }

  static Future<List<FormatCoverModel>> listFormatCover({String keyword = '', String statusData = 'A', int page = 1, int limit = 100}) async {
    final value = await Setuprepository.fetch(NetworkURL.formatCoverList(), {
      'kode_format_cover': keyword.trim(),
      'nama_format_cover': keyword.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat format cover buku'));
    return rows(value).whereType<Map>().map((e) => FormatCoverModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<FormatCoverModel> detailFormatCover(String kodeFormatCover) async {
    final value = await Setuprepository.fetch(NetworkURL.formatCoverDetail(), {'kode_format_cover': kodeFormatCover.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail format cover buku'));
    return FormatCoverModel.fromJson(map(value));
  }

  static Future<void> saveFormatCover({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.formatCoverUpdate() : NetworkURL.formatCoverCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan format cover buku'));
  }

  static Future<void> deleteFormatCover(String kodeFormatCover) async {
    final value = await Setuprepository.fetch(NetworkURL.formatCoverDelete(), {'kode_format_cover': kodeFormatCover.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus format cover buku'));
  }

  static Future<List<FormatBilyetModel>> listFormatBilyet({String keyword = '', String statusData = 'A', int page = 1, int limit = 100}) async {
    final value = await Setuprepository.fetch(NetworkURL.formatBilyetList(), {
      'kode_format_bilyet': keyword.trim(),
      'nama_format_bilyet': keyword.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat format bilyet'));
    return rows(value).whereType<Map>().map((e) => FormatBilyetModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<FormatBilyetModel> detailFormatBilyet(String kodeFormatBilyet) async {
    final value = await Setuprepository.fetch(NetworkURL.formatBilyetDetail(), {'kode_format_bilyet': kodeFormatBilyet.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail format bilyet'));
    return FormatBilyetModel.fromJson(map(value));
  }

  static Future<void> saveFormatBilyet({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.formatBilyetUpdate() : NetworkURL.formatBilyetCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan format bilyet'));
  }

  static Future<void> deleteFormatBilyet(String kodeFormatBilyet) async {
    final value = await Setuprepository.fetch(NetworkURL.formatBilyetDelete(), {'kode_format_bilyet': kodeFormatBilyet.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus format bilyet'));
  }

  static Future<List<KodeTransaksiTabunganModel>> listKodeTransaksiTabungan({String kodeBuku = '01'}) async {
    final value = await Setuprepository.fetch(NetworkURL.setupKodeTransaksiTabungan(), {
      'action': 'list',
      'kode_buku': kodeBuku.trim().isEmpty ? '01' : kodeBuku.trim(),
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat kode transaksi tabungan'));
    return rows(value).whereType<Map>().map((e) => KodeTransaksiTabunganModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<List<SandiTransaksiBukuModel>> listSandiTransaksiBuku({String keyword = '', String statusData = 'A', int page = 1, int limit = 100}) async {
    final value = await Setuprepository.fetch(NetworkURL.sandiTransaksiBukuList(), {
      'kode_sandi_transaksi': keyword.trim(),
      'nama_sandi_transaksi': keyword.trim(),
      'status_data': statusData.trim(),
      'page': page,
      'limit': limit,
    });
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal memuat sandi transaksi buku'));
    return rows(value).whereType<Map>().map((e) => SandiTransaksiBukuModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<SandiTransaksiBukuModel> detailSandiTransaksiBuku(String kode) async {
    final value = await Setuprepository.fetch(NetworkURL.sandiTransaksiBukuDetail(), {'kode_sandi_transaksi': kode.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal mengambil detail sandi transaksi buku'));
    return SandiTransaksiBukuModel.fromJson(map(value));
  }

  static Future<void> saveSandiTransaksiBuku({required bool isEdit, required Map<String, dynamic> body}) async {
    final value = await Setuprepository.fetch(isEdit ? NetworkURL.sandiTransaksiBukuUpdate() : NetworkURL.sandiTransaksiBukuCreate(), body);
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menyimpan sandi transaksi buku'));
  }

  static Future<void> deleteSandiTransaksiBuku(String kode) async {
    final value = await Setuprepository.fetch(NetworkURL.sandiTransaksiBukuDelete(), {'kode_sandi_transaksi': kode.trim()});
    if (!isSuccess(value)) throw Exception(message(value, 'Gagal menghapus sandi transaksi buku'));
  }
}
