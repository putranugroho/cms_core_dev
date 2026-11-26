import 'package:cms_core/models/banking_setup_models.dart';
import 'package:cms_core/models/new_menu_models.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';

class BankingApiException implements Exception {
  final String message;
  const BankingApiException(this.message);
  @override
  String toString() => message;
}

class BankingSetupRepository {
  static Map<String, dynamic> _checked(dynamic value, String fallback) {
    if (value is! Map) throw BankingApiException(fallback);
    final code = bankingText(value['code']);
    final status = bankingText(value['status']).toLowerCase();
    if (code.isNotEmpty ? code != '000' : status != 'success') {
      var message = bankingText(value['message']);
      final errors = value['errors'] ?? (code == '001' ? value['data'] : null);
      if (errors is List && errors.isNotEmpty) {
        final details = errors
            .whereType<Map>()
            .map((e) => bankingText(e['message'] ?? e['error']))
            .where((e) => e.isNotEmpty)
            .join('\n');
        if (details.isNotEmpty) message = details;
      }
      throw BankingApiException(message.isEmpty ? fallback : message);
    }
    return Map<String, dynamic>.from(value);
  }

  static int _int(dynamic value, int fallback) =>
      int.tryParse(value?.toString() ?? '') ?? fallback;

  static BankingPage<T> _page<T>(
    dynamic value,
    T Function(Map<String, dynamic>) parse,
    int page,
    int limit,
  ) {
    final checked = _checked(value, 'Gagal memuat data');
    final data = checked['data'];
    final rows = data is Map ? data['data'] : data;
    if (rows is! List || rows.any((row) => row is! Map)) {
      throw const BankingApiException(
        'Format daftar dari layanan tidak valid.',
      );
    }
    final responseLimit = data is Map ? _int(data['limit'], limit) : limit;
    return BankingPage(
      items: rows
          .map((row) => parse(Map<String, dynamic>.from(row as Map)))
          .toList(),
      total: data is Map ? _int(data['total'], rows.length) : rows.length,
      page: data is Map ? _int(data['page'], page) : page,
      limit: responseLimit > 0 ? responseLimit : limit,
    );
  }

  static Future<Map<String, dynamic>> _detail(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final value = _checked(
      await Setuprepository.fetch(endpoint, body),
      'Gagal mengambil detail',
    );
    if (value['data'] is! Map)
      throw const BankingApiException(
        'Format detail dari layanan tidak valid.',
      );
    final detail = Map<String, dynamic>.from(value['data'] as Map);
    final key = body.keys.single;
    if (bankingText(detail[key]) != bankingText(body[key])) {
      throw const BankingApiException(
        'Detail yang diterima tidak sesuai dengan data yang dipilih.',
      );
    }
    return detail;
  }

  static Future<void> _write(String endpoint, Map<String, dynamic> body) async {
    _checked(
      await Setuprepository.fetch(endpoint, body),
      'Data belum berhasil disimpan',
    );
  }

  static Future<BankingPage<AbaModel>> abaList({
    String keyword = '',
    String searchField = 'nomor_rekening',
    String jenis = '',
    String status = '',
    int page = 1,
    int limit = 10,
  }) async {
    const fields = ['nomor_rekening', 'nomor_sbb', 'nama_bank', 'sandi_bank'];
    if (!fields.contains(searchField))
      throw ArgumentError('Invalid ABA search field');
    final body = <String, dynamic>{
      for (final field in fields)
        field: field == searchField ? keyword.trim() : '',
      'jenis_rekening': jenis,
      'status_rekening': status,
      'status_data': '',
      'page': page,
      'limit': limit,
    };
    return _page(
      await Setuprepository.fetch(NetworkURL.masterAbaList(), body),
      AbaModel.fromJson,
      page,
      limit,
    );
  }

  static Future<AbaModel> abaDetail(String key) async => AbaModel.fromJson(
    await _detail(NetworkURL.masterAbaDetail(), {'nomor_rekening': key}),
  );
  static Future<void> abaSave(bool edit, Map<String, dynamic> body) => _write(
    edit ? NetworkURL.masterAbaUpdate() : NetworkURL.masterAbaCreate(),
    body,
  );
  static Future<void> abaDelete(String key) =>
      _write(NetworkURL.masterAbaDelete(), {'nomor_rekening': key});

  static Future<bool> partyAvailable({required bool group}) async {
    final value = _checked(
      await Setuprepository.fetch(
        NetworkURL.thirdPartyCapabilities(),
        <String, dynamic>{},
      ),
      'Gagal memeriksa layanan pihak ketiga',
    );
    final data = value['data'];
    if (data is! Map)
      throw const BankingApiException('Status layanan tidak valid.');
    return data[group ? 'kelompok_pihak_ketiga' : 'data_pihak_ketiga'] == true;
  }

  static Future<BankingPage<PartyGroupModel>> groupList({
    String keyword = '',
    String searchField = 'nama_kelompok',
    int page = 1,
    int limit = 10,
  }) async {
    if (!['kode_kelompok', 'nama_kelompok'].contains(searchField))
      throw ArgumentError('Invalid group search field');
    return _page(
      await Setuprepository.fetch(NetworkURL.partyGroupEndpoint('list'), {
        'kode_kelompok': searchField == 'kode_kelompok' ? keyword.trim() : '',
        'nama_kelompok': searchField == 'nama_kelompok' ? keyword.trim() : '',
        'page': page,
        'limit': limit,
      }),
      PartyGroupModel.new,
      page,
      limit,
    );
  }

  static Future<PartyGroupModel> groupDetail(String key) async =>
      PartyGroupModel(
        await _detail(NetworkURL.partyGroupEndpoint('detail'), {
          'kode_kelompok': key,
        }),
      );
  static Future<void> groupSave(bool edit, Map<String, dynamic> body) =>
      _write(NetworkURL.partyGroupEndpoint(edit ? 'update' : 'create'), body);
  static Future<void> groupDelete(String key) =>
      _write(NetworkURL.partyGroupEndpoint('delete'), {'kode_kelompok': key});

  static Future<BankingPage<ThirdPartyModel>> partyList({
    String keyword = '',
    String searchField = 'nama_perusahaan',
    int page = 1,
    int limit = 10,
  }) async {
    if (!['kode_pihak_ketiga', 'nama_perusahaan'].contains(searchField))
      throw ArgumentError('Invalid party search field');
    return _page(
      await Setuprepository.fetch(NetworkURL.masterMitraBisnisSearch(), {
        'kode_mitra': searchField == 'kode_pihak_ketiga'
            ? keyword.trim()
            : '',
        'nama_mitra': searchField == 'nama_perusahaan'
            ? keyword.trim()
            : '',
        'kelompok': '',
        'page': page,
        'limit': limit,
      }),
      mitraFormModel,
      page,
      limit,
    );
  }

  static Future<ThirdPartyModel> partyDetail(String key) async =>
      mitraFormModel(
        await _detail(NetworkURL.masterMitraBisnisDetail(), {
          'kode_mitra': key,
        }),
      );
  static Future<void> partySave(bool edit, Map<String, dynamic> body) =>
      _write(edit ? NetworkURL.masterMitraBisnisUpdate() : NetworkURL.masterMitraBisnisCreate(), mitraFormPayload(body));
  static Future<void> partyDelete(String key) => _write(
    NetworkURL.masterMitraBisnisDelete(),
    {'kode_mitra': key},
  );
}
