import 'dart:convert';

import 'package:accounting_kantor_gl_useraccess/models/core_coa_model.dart';
import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/network/network.dart';
import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:accounting_kantor_gl_useraccess/repository/SetupRepository.dart';
import 'package:accounting_kantor_gl_useraccess/utils/dialog_loading.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
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
  CoreCoaModel? selected;

  final keyForm = GlobalKey<FormState>();
  final TextEditingController keyword = TextEditingController();
  final TextEditingController kodeCoa = TextEditingController();
  final TextEditingController namaCoa = TextEditingController();
  final TextEditingController parentCoa = TextEditingController();
  final TextEditingController specialType = TextEditingController();
  final TextEditingController ojkCode = TextEditingController();

  int? tipeCoa = 1;
  int? levelCoa = 1;
  String postingType = 'I';

  static const tipeOptions = <int>[1, 2, 3, 4, 5, 6];
  static const levelOptions = <int>[1, 2, 3];

  Future<void> _init() async {
    users = await Pref().getUsers();
    await getCoa();
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

  List<CoreCoaModel> get headerOptions => list
      .where((e) => e.levelCoa == 1 && (tipeCoa == null || e.tipeCoa == tipeCoa))
      .toList()
    ..sort((a, b) => a.kodeCoa.compareTo(b.kodeCoa));

  List<CoreCoaModel> get bukuBesarOptions => list
      .where((e) => e.levelCoa == 2 && (tipeCoa == null || e.tipeCoa == tipeCoa))
      .toList()
    ..sort((a, b) => a.kodeCoa.compareTo(b.kodeCoa));

  List<CoreCoaModel> get parentOptions {
    if (levelCoa == 2) return headerOptions;
    if (levelCoa == 3) return bukuBesarOptions;
    return [];
  }

  String? get parentDropdownValue {
    final code = parentCoa.text.trim();
    if (code.isEmpty) return null;
    if (parentOptions.any((e) => e.kodeCoa == code)) return code;
    return null;
  }

  bool get parentRequired => levelCoa == 2 || levelCoa == 3;

  String get parentLabel {
    if (levelCoa == 2) return 'Header Induk';
    if (levelCoa == 3) return 'Buku Besar Induk';
    return 'Parent COA';
  }

  Future<void> getCoa() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final body = {
      ..._authBody(),
      'kode_coa': keyword.text.trim(),
      'nama_coa': keyword.text.trim(),
      'tipe_coa': null,
      'level_coa': null,
      'parent_coa': '',
      'posting_type': '',
      'special_type': '',
      'ojk_code': '',
      'status_data': '',
      'page': 1,
      'limit': 1000,
    };

    final value = await Setuprepository.setup(
      token,
      NetworkURL.getMasterGl(),
      jsonEncode(body),
    );

    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || status.contains('sukses') || value?['code'] == '000') {
      final raw = value['data'];
      final rawList = raw is Map ? (raw['data'] ?? []) : raw;
      final rows = (rawList as List? ?? [])
          .whereType<Map>()
          .map((e) => CoreCoaModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      list = _sortHierarchical(rows);
    } else {
      list = [];
      errorMessage = value?['message']?.toString() ?? 'Gagal memuat data COA';
    }

    isLoading = false;
    notifyListeners();
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

  String levelText(int? value) => CoreCoaModel.levelText(value);
  String tipeText(int? value) => CoreCoaModel.tipeText(value);

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
    kodeCoa.clear();
    namaCoa.clear();
    parentCoa.clear();
    specialType.clear();
    ojkCode.clear();
    tipeCoa = 1;
    levelCoa = 1;
    postingType = 'I';
  }

  void _clearParentIfInvalid() {
    if (!parentRequired) {
      parentCoa.clear();
      return;
    }
    final code = parentCoa.text.trim();
    if (code.isNotEmpty && !parentOptions.any((e) => e.kodeCoa == code)) {
      parentCoa.clear();
    }
  }

  void pilihTipeCoa(int? value) {
    tipeCoa = value;
    _clearParentIfInvalid();
    notifyListeners();
  }

  void pilihLevelCoa(int? value) {
    levelCoa = value;
    parentCoa.clear();
    notifyListeners();
  }

  void pilihParentCoa(String? value) {
    parentCoa.text = value ?? '';
    notifyListeners();
  }

  void pilihPostingType(String? value) {
    postingType = value ?? 'I';
    notifyListeners();
  }

  void edit(CoreCoaModel value) {
    selected = value;
    editData = true;
    dialog = true;

    kodeCoa.text = value.kodeCoa;
    namaCoa.text = value.namaCoa;
    parentCoa.text = value.parentCoa;
    specialType.text = value.specialType;
    ojkCode.text = value.ojkCode;
    tipeCoa = value.tipeCoa ?? 1;
    levelCoa = value.levelCoa ?? 1;
    postingType = value.postingType.isNotEmpty ? value.postingType : 'I';

    notifyListeners();
  }

  Map<String, dynamic> _coaPayload() => {
        ..._authBody(),
        'kode_coa': kodeCoa.text.trim(),
        'nama_coa': namaCoa.text.trim(),
        'tipe_coa': tipeCoa,
        'level_coa': levelCoa,
        'parent_coa': parentRequired ? parentCoa.text.trim() : '',
        'posting_type': postingType,
      };

  Future<void> cek() async {
    if (!(keyForm.currentState?.validate() ?? false)) return;

    if (parentRequired && parentCoa.text.trim().isEmpty) {
      informationDialog(context, 'Validasi', '$parentLabel wajib dipilih.');
      return;
    }

    DialogCustom().showLoading(context);
    final url = editData ? NetworkURL.editMasterGl() : NetworkURL.addMasterGl();
    final value = await Setuprepository.setup(
      token,
      url,
      jsonEncode(_coaPayload()),
    );
    if (context.mounted) Navigator.pop(context);

    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || value?['code'] == '000') {
      informationDialog(context, 'Information', value?['message']?.toString() ?? 'success');
      dialog = false;
      clear();
      await getCoa();
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
      }),
    );
    if (context.mounted) Navigator.pop(context);

    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || value?['code'] == '000') {
      informationDialog(context, 'Information', value?['message']?.toString() ?? 'success');
      dialog = false;
      clear();
      await getCoa();
    } else {
      informationDialog(context, 'Warning', value?['message']?.toString() ?? 'Gagal menghapus data');
    }
  }

  @override
  void dispose() {
    keyword.dispose();
    kodeCoa.dispose();
    namaCoa.dispose();
    parentCoa.dispose();
    specialType.dispose();
    ojkCode.dispose();
    super.dispose();
  }
}
