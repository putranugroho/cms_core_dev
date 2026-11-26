import 'dart:convert';

import 'package:cms_core/models/core_coa_model.dart';
import 'package:cms_core/models/index.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';

class GlNotifier extends ChangeNotifier {
  final BuildContext context;

  GlNotifier({required this.context}) {
    _init();
  }

  UserModel? users;
  bool isLoading = true;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;

  List<CoreCoaModel> list = [];
  List<CoreCoaModel> headerParentOptions = [];
  List<CoreCoaModel> bukuBesarParentOptions = [];
  CoreCoaModel? selected;
  CoreCoaModel? header;
  CoreCoaModel? bukuBesar;
  bool isLoadingParentOptions = false;

  int currentPage = 1;
  final int pageLimit = 50;
  int totalRows = 0;
  int totalPages = 1;
  bool hasNextPage = false;
  bool hasPrevPage = false;

  final keyForm = GlobalKey<FormState>();
  final TextEditingController keyword = TextEditingController();
  final TextEditingController noHeader = TextEditingController();
  final TextEditingController noBb = TextEditingController();
  final TextEditingController noSbb = TextEditingController();
  final TextEditingController resulttext = TextEditingController();
  final TextEditingController namaSbb = TextEditingController();

  String? golongan;
  String? jnsAcc;
  String? hutangPiutang;
  String labaRugi = 'NONE';
  bool perantara = false;
  bool sbbKhusus = false;
  String postingType = 'I';

  final List<String> listGol = const [
    'Aktiva',
    'Pasiva',
    'Pendapatan',
    'Biaya',
    'Pos Adm Debet',
    'Pos Adm Kredit',
  ];

  final List<String> listJns = const [
    'Header',
    'Buku Besar',
    'Sub Buku Besar',
  ];

  Future<void> _init() async {
    users = await Pref().getUsers();
    await getMasterGl();
  }

  String get _username {
    if (users?.userid.isNotEmpty == true) return users!.userid;
    if (users?.namauser.isNotEmpty == true) return users!.namauser;
    return 'admin';
  }

  String get _kodeKantorLogin {
    if (users?.kodeKantor.isNotEmpty == true) return users!.kodeKantor;
    return '001';
  }

  Map<String, dynamic> _authBody() => {
        'userlogin': _username,
        'kode_kantor_login': _kodeKantorLogin,
      };

  Map<String, CoreCoaModel> get coaByKode => {
        for (final item in list) item.kodeCoa: item,
      };

  List<CoreCoaModel> get headerOptions {
    final tipe = _tipeFromGolongan(golongan);
    final source = headerParentOptions.isNotEmpty ? headerParentOptions : list;
    return source.where((e) => e.levelCoa == 1 && (tipe == null || e.tipeCoa == tipe)).toList()..sort((a, b) => a.kodeCoa.compareTo(b.kodeCoa));
  }

  List<CoreCoaModel> get bukuBesarOptions {
    final tipe = _tipeFromGolongan(golongan);
    final source = bukuBesarParentOptions.isNotEmpty ? bukuBesarParentOptions : list;
    return source.where((e) => e.levelCoa == 2 && (tipe == null || e.tipeCoa == tipe)).toList()..sort((a, b) => a.kodeCoa.compareTo(b.kodeCoa));
  }

  Future<void> getMasterGl({int? page}) async {
    isLoading = true;
    errorMessage = null;
    if (page != null) currentPage = page < 1 ? 1 : page;
    notifyListeners();

    final q = keyword.text.trim();
    final body = {
      ..._authBody(),
      'kode_coa': q,
      'nama_coa': q,
      'tipe_coa': null,
      'level_coa': null,
      'parent_coa': '',
      'posting_type': '',
      'labarugi_berjalan': null,
      'labarugi_tahun_lalu': null,
      'hutang': null,
      'piutang': null,
      'perantara': null,
      'sbb_khusus': '',
      'status_data': '',
      'page': currentPage,
      'limit': pageLimit,
    };

    final value = await Setuprepository.setup(token, NetworkURL.getMasterGl(), jsonEncode(body));
    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || status.contains('sukses') || value?['code'] == '000') {
      final rows = _rows(value).whereType<Map>().map((e) => CoreCoaModel.fromJson(Map<String, dynamic>.from(e))).toList();
      list = _sortHierarchical(rows);
      _applyPaginationMeta(value, rows.length);
    } else {
      list = [];
      totalRows = 0;
      totalPages = 1;
      hasNextPage = false;
      hasPrevPage = currentPage > 1;
      errorMessage = value?['message']?.toString() ?? 'Gagal memuat data GL / COA';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> searchMasterGl() async {
    currentPage = 1;
    await getMasterGl(page: 1);
  }

  Future<void> nextPage() async {
    if (!hasNextPage || isLoading) return;
    await getMasterGl(page: currentPage + 1);
  }

  Future<void> previousPage() async {
    if (!hasPrevPage || isLoading) return;
    await getMasterGl(page: currentPage - 1);
  }

  List<dynamic> _rows(dynamic value) {
    if (value is! Map) return [];
    final data = value['data'];
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is List) return data;
    return [];
  }

  Map<String, dynamic> _meta(dynamic value) {
    if (value is! Map) return {};
    final data = value['data'];
    if (data is Map && data['meta'] is Map) return Map<String, dynamic>.from(data['meta'] as Map);
    if (data is Map) {
      final direct = <String, dynamic>{};
      for (final key in ['total', 'page', 'limit', 'total_pages', 'has_next_page', 'has_prev_page']) {
        if (data.containsKey(key)) direct[key] = data[key];
      }
      if (direct.isNotEmpty) return direct;
    }
    if (value['meta'] is Map) return Map<String, dynamic>.from(value['meta'] as Map);
    return {};
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  bool _asBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    final text = (value ?? '').toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'y' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'n' || text == 'no') return false;
    return fallback;
  }

  void _applyPaginationMeta(dynamic value, int rowCount) {
    final meta = _meta(value);
    final pageFromMeta = _asInt(meta['page'], currentPage);
    final limitFromMeta = _asInt(meta['limit'], pageLimit);

    currentPage = pageFromMeta < 1 ? currentPage : pageFromMeta;
    totalRows = _asInt(meta['total'], rowCount);
    totalPages = _asInt(meta['total_pages'], totalRows > 0 ? ((totalRows + limitFromMeta - 1) ~/ limitFromMeta) : 1);
    if (totalPages < 1) totalPages = 1;

    hasPrevPage = _asBool(meta['has_prev_page'], currentPage > 1);
    hasNextPage = _asBool(
      meta['has_next_page'],
      totalRows > 0 ? currentPage < totalPages : rowCount >= pageLimit,
    );
  }


  Future<List<CoreCoaModel>> _fetchCoaOptions({
    required int tipeCoa,
    required int levelCoa,
  }) async {
    final body = {
      ..._authBody(),
      'kode_coa': '',
      'nama_coa': '',
      'tipe_coa': tipeCoa,
      'level_coa': levelCoa,
      'parent_coa': '',
      'posting_type': '',
      'labarugi_berjalan': null,
      'labarugi_tahun_lalu': null,
      'hutang': null,
      'piutang': null,
      'perantara': null,
      'sbb_khusus': '',
      'status_data': 'A',
      'page': 1,
      'limit': 100,
    };

    final value = await Setuprepository.setup(token, NetworkURL.getMasterGl(), jsonEncode(body));
    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (!(status.contains('success') || status.contains('sukses') || value?['code'] == '000')) {
      return [];
    }

    final rows = _rows(value).whereType<Map>().map((e) => CoreCoaModel.fromJson(Map<String, dynamic>.from(e))).where((e) {
      return e.tipeCoa == tipeCoa && e.levelCoa == levelCoa && e.statusData.toUpperCase() != 'D';
    }).toList()
      ..sort((a, b) => a.kodeCoa.compareTo(b.kodeCoa));

    return rows;
  }

  Future<void> loadParentOptions() async {
    final tipe = _tipeFromGolongan(golongan);
    if (tipe == null || jnsAcc == null || jnsAcc == 'Header') {
      headerParentOptions = [];
      bukuBesarParentOptions = [];
      notifyListeners();
      return;
    }

    isLoadingParentOptions = true;
    notifyListeners();

    try {
      if (jnsAcc == 'Buku Besar') {
        headerParentOptions = await _fetchCoaOptions(tipeCoa: tipe, levelCoa: 1);
        bukuBesarParentOptions = [];
        if (header != null && !headerParentOptions.any((e) => e.kodeCoa == header!.kodeCoa)) {
          header = null;
          noHeader.clear();
          resulttext.clear();
        }
      } else if (jnsAcc == 'Sub Buku Besar') {
        bukuBesarParentOptions = await _fetchCoaOptions(tipeCoa: tipe, levelCoa: 2);
        headerParentOptions = [];
        if (bukuBesar != null && !bukuBesarParentOptions.any((e) => e.kodeCoa == bukuBesar!.kodeCoa)) {
          bukuBesar = null;
          noBb.clear();
          resulttext.clear();
        }
      }
    } finally {
      isLoadingParentOptions = false;
      notifyListeners();
    }
  }

  List<CoreCoaModel> _sortHierarchical(List<CoreCoaModel> rows) {
    final byKode = {for (final row in rows) row.kodeCoa: row};

    String path(CoreCoaModel row) {
      final tipe = (row.tipeCoa ?? 0).toString().padLeft(2, '0');
      if (row.levelCoa == 1) return '$tipe/${row.kodeCoa}';
      if (row.levelCoa == 2) return '$tipe/${row.parentCoa}/${row.kodeCoa}';
      if (row.levelCoa == 3) {
        final parent = byKode[row.parentCoa];
        final headerCode = parent?.parentCoa ?? row.parentCoa;
        return '$tipe/$headerCode/${row.parentCoa}/${row.kodeCoa}';
      }
      return '$tipe/${row.kodeCoa}';
    }

    rows.sort((a, b) {
      final byPath = path(a).compareTo(path(b));
      if (byPath != 0) return byPath;
      return a.kodeCoa.compareTo(b.kodeCoa);
    });
    return rows;
  }

  String headerName(CoreCoaModel row) {
    if (row.levelCoa == 1) return row.namaCoa;
    final parent = coaByKode[row.parentCoa];
    if (row.levelCoa == 2) return parent?.namaCoa ?? '';
    if (row.levelCoa == 3) {
      final header = parent == null ? null : coaByKode[parent.parentCoa];
      return header?.namaCoa ?? '';
    }
    return '';
  }

  String bukuBesarName(CoreCoaModel row) {
    if (row.levelCoa == 2) return row.namaCoa;
    if (row.levelCoa == 3) return coaByKode[row.parentCoa]?.namaCoa ?? '';
    return '';
  }

  String subBukuBesarName(CoreCoaModel row) {
    if (row.levelCoa == 3) return row.namaCoa;
    return '';
  }

  void tambah() {
    clear();
    dialog = true;
    notifyListeners();
  }

  void tutup() {
    dialog = false;
    notifyListeners();
  }

  void clear() {
    selected = null;
    editData = false;
    header = null;
    bukuBesar = null;
    headerParentOptions = [];
    bukuBesarParentOptions = [];
    isLoadingParentOptions = false;
    noHeader.clear();
    noBb.clear();
    noSbb.clear();
    resulttext.clear();
    namaSbb.clear();
    golongan = null;
    jnsAcc = null;
    hutangPiutang = null;
    labaRugi = 'NONE';
    perantara = false;
    sbbKhusus = false;
    postingType = 'I';
  }

  void pilihGolongan(String? value) {
    golongan = value;
    header = null;
    bukuBesar = null;
    headerParentOptions = [];
    bukuBesarParentOptions = [];
    noHeader.clear();
    noBb.clear();
    noSbb.clear();
    resulttext.clear();
    notifyListeners();
    loadParentOptions();
  }

  void pilihJenis(String? value) {
    jnsAcc = value;
    header = null;
    bukuBesar = null;
    headerParentOptions = [];
    bukuBesarParentOptions = [];
    noHeader.clear();
    noBb.clear();
    noSbb.clear();
    resulttext.clear();
    hutangPiutang = null;
    labaRugi = 'NONE';
    perantara = false;
    sbbKhusus = false;
    postingType = value == 'Sub Buku Besar' ? 'I' : 'N';
    notifyListeners();
    loadParentOptions();
  }

  void pilihHeader(CoreCoaModel? value) {
    header = value;
    noHeader.text = value == null ? '' : value.kodeCoa;
    noBb.clear();
    resulttext.clear();
    notifyListeners();
  }

  void pilihBB(CoreCoaModel? value) {
    bukuBesar = value;
    if (value == null) {
      noBb.clear();
      hutangPiutang = null;
      labaRugi = 'NONE';
      perantara = false;
      sbbKhusus = false;
    } else {
      noBb.text = value.kodeCoa;
      hutangPiutang = value.hutang == 'Y'
          ? 'HUTANG'
          : value.piutang == 'Y'
              ? 'PIUTANG'
              : null;
      perantara = value.akunPerantara == 'Y';
      labaRugi = 'NONE';
    }
    noSbb.clear();
    resulttext.clear();
    notifyListeners();
  }

  void updateHeader() {
    final raw = _digits(noHeader.text);
    if (raw.isEmpty) {
      resulttext.clear();
    } else {
      final part = raw.padRight(3, '0');
      resulttext.text = '${part.substring(0, 3)}000000000';
    }
    notifyListeners();
  }

  void updatebb() {
    final raw = _digits(noBb.text);
    if (header == null || raw.isEmpty || header!.kodeCoa.length < 3) {
      resulttext.clear();
    } else {
      final part = raw.padLeft(3, '0');
      resulttext.text = '${header!.kodeCoa.substring(0, 3)}${part.substring(part.length - 3)}000000';
    }
    notifyListeners();
  }

  void updateSbb() {
    final raw = _digits(noSbb.text);
    if (bukuBesar == null || raw.isEmpty || bukuBesar!.kodeCoa.length < 6) {
      resulttext.clear();
    } else {
      final part = raw.padLeft(6, '0');
      resulttext.text = '${bukuBesar!.kodeCoa.substring(0, 6)}${part.substring(part.length - 6)}';
    }
    notifyListeners();
  }

  void gantiHutangPiutang(String value) {
    hutangPiutang = hutangPiutang == value ? null : value;
    notifyListeners();
  }

  void pilihLabaRugi(String value) {
    final next = value.toUpperCase();
    labaRugi = ['BERJALAN', 'TAHUN_LALU'].contains(next) ? next : 'NONE';
    notifyListeners();
  }

  void togglePerantara(bool value) {
    perantara = value;
    notifyListeners();
  }

  void pilihSbbKhusus(String? value) {
    sbbKhusus = (value ?? 'N').toUpperCase() == 'Y';
    notifyListeners();
  }

  void edit(CoreCoaModel value) {
    selected = value;
    editData = true;
    dialog = true;

    golongan = _golonganFromTipe(value.tipeCoa);
    jnsAcc = CoreCoaModel.levelText(value.levelCoa);
    resulttext.text = value.kodeCoa;
    namaSbb.text = value.namaCoa;
    hutangPiutang = value.hutang == 'Y'
        ? 'HUTANG'
        : value.piutang == 'Y'
            ? 'PIUTANG'
            : null;
    perantara = value.akunPerantara == 'Y';
    if (value.labarugiBerjalan == 'Y') {
      labaRugi = 'BERJALAN';
    } else if (value.labarugiTahunLalu == 'Y') {
      labaRugi = 'TAHUN_LALU';
    } else {
      labaRugi = 'NONE';
    }
    sbbKhusus = value.sbbKhusus == 'Y' || value.specialType.toUpperCase() == 'Y';
    postingType = _normalizePostingType(value.postingType);

    if (value.levelCoa == 1) {
      noHeader.text = value.kodeCoa.length >= 3 ? value.kodeCoa.substring(0, 3) : value.kodeCoa;
    } else if (value.levelCoa == 2) {
      header = coaByKode[value.parentCoa];
      if (header != null) headerParentOptions = [header!];
      noHeader.text = header?.kodeCoa ?? value.parentCoa;
      noBb.text = value.kodeCoa.length >= 6 ? value.kodeCoa.substring(3, 6) : value.kodeCoa;
    } else if (value.levelCoa == 3) {
      bukuBesar = coaByKode[value.parentCoa];
      if (bukuBesar != null) bukuBesarParentOptions = [bukuBesar!];
      header = bukuBesar == null ? null : coaByKode[bukuBesar!.parentCoa];
      noHeader.text = header?.kodeCoa ?? '';
      noBb.text = bukuBesar?.kodeCoa ?? value.parentCoa;
      noSbb.text = value.kodeCoa.length >= 12 ? value.kodeCoa.substring(6, 12) : value.kodeCoa;
    }

    notifyListeners();
    loadParentOptions();
  }

  int? _tipeFromGolongan(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'aktiva':
        return 1;
      case 'pasiva':
        return 2;
      case 'pendapatan':
        return 3;
      case 'biaya':
        return 4;
      case 'pos adm debet':
        return 5;
      case 'pos adm kredit':
        return 6;
      case 'pos administrative':
        return 5;
      default:
        return null;
    }
  }

  String? _golonganFromTipe(int? value) {
    switch (value) {
      case 1:
        return 'Aktiva';
      case 2:
        return 'Pasiva';
      case 3:
        return 'Pendapatan';
      case 4:
        return 'Biaya';
      case 5:
        return 'Pos Adm Debet';
      case 6:
        return 'Pos Adm Kredit';
      default:
        return null;
    }
  }

  int? _levelFromJenis(String? value) {
    switch (value) {
      case 'Header':
        return 1;
      case 'Buku Besar':
        return 2;
      case 'Sub Buku Besar':
        return 3;
      default:
        return null;
    }
  }

  String _digits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String _normalizePostingType(String? value) {
    final text = (value ?? '').trim().toUpperCase();
    if (text == 'N' || text == 'NON-INTERAKTIF' || text == 'NON_INTERAKTIF') return 'N';
    return 'I';
  }

  void pilihPostingType(String? value) {
    postingType = _normalizePostingType(value);
    notifyListeners();
  }

  String _postingType() {
    // Header and Buku Besar are grouping accounts. Sub Buku Besar can be
    // configured as Interaktif or Non-Interaktif from the form.
    return jnsAcc == 'Sub Buku Besar' ? postingType : 'N';
  }

  String _parentCoa() {
    if (jnsAcc == 'Buku Besar') return header?.kodeCoa ?? '';
    if (jnsAcc == 'Sub Buku Besar') return bukuBesar?.kodeCoa ?? '';
    return '';
  }

  Map<String, dynamic> _coaPayload() {
    final kode = resulttext.text.trim();
    final level = _levelFromJenis(jnsAcc);
    final tipe = _tipeFromGolongan(golongan);
    final posting = _postingType();

    return {
      ..._authBody(),
      'kode_coa': kode,
      'nama_coa': namaSbb.text.trim(),
      'tipe_coa': tipe,
      'level_coa': level,
      'parent_coa': _parentCoa(),
      'posting_type': posting,
      'labarugi_berjalan': labaRugi == 'BERJALAN',
      'labarugi_tahun_lalu': labaRugi == 'TAHUN_LALU',
      'hutang': false,
      'piutang': false,
      'perantara': false,
      'sbb_khusus': '',
      'status_data': 'A',
    };
  }

  Future<void> cek() async {
    if (!(keyForm.currentState?.validate() ?? false)) return;
    if (resulttext.text.trim().isEmpty) {
      informationDialog(context, 'Validasi', 'Nomor COA wajib diisi.');
      return;
    }
    if (jnsAcc == 'Buku Besar' && header == null) {
      informationDialog(context, 'Validasi', 'Header wajib dipilih.');
      return;
    }
    if (jnsAcc == 'Sub Buku Besar' && bukuBesar == null) {
      informationDialog(context, 'Validasi', 'Buku Besar wajib dipilih.');
      return;
    }

    DialogCustom().showLoading(context);
    final url = editData ? NetworkURL.editMasterGl() : NetworkURL.addMasterGl();
    final value = await Setuprepository.setup(token, url, jsonEncode(_coaPayload()));
    if (context.mounted) Navigator.pop(context);

    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || status.contains('sukses') || value?['code'] == '000') {
      informationDialog(context, 'Information', value?['message']?.toString() ?? 'success');
      dialog = false;
      clear();
      await getMasterGl();
    } else {
      informationDialog(context, 'Warning', value?['message']?.toString() ?? 'Gagal menyimpan data');
    }
  }

  void confirm() {
    if (selected == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Anda yakin menghapus ${selected!.kodeCoa} - ${selected!.namaCoa}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              remove();
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  Future<void> remove() async {
    if (selected == null) return;
    DialogCustom().showLoading(context);
    final value = await Setuprepository.setup(
      token,
      NetworkURL.deleteMasterGl(),
      jsonEncode({
        ..._authBody(),
        'kode_coa': selected!.kodeCoa,
        'nosbb': selected!.kodeCoa,
      }),
    );
    if (context.mounted) Navigator.pop(context);

    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || status.contains('sukses') || value?['code'] == '000') {
      informationDialog(context, 'Information', value?['message']?.toString() ?? 'success');
      dialog = false;
      clear();
      await getMasterGl();
    } else {
      informationDialog(context, 'Warning', value?['message']?.toString() ?? 'Gagal menghapus data');
    }
  }

  void confirmotorisasi() {
    informationDialog(context, 'Informasi', 'Proses otorisasi COA belum tersedia di endpoint CMS-Core.');
  }

  @override
  void dispose() {
    keyword.dispose();
    noHeader.dispose();
    noBb.dispose();
    noSbb.dispose();
    resulttext.dispose();
    namaSbb.dispose();
    super.dispose();
  }
}
