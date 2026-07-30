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
      'limit': 100,
    };

    final value = await Setuprepository.setup(
      token,
      NetworkURL.getMasterGl(),
      jsonEncode(body),
    );

    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || status.contains('sukses')) {
      final raw = value['data'];
      final rawList = raw is Map ? (raw['data'] ?? []) : raw;
      list = (rawList as List? ?? [])
          .whereType<Map>()
          .map((e) => CoreCoaModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      list.sort((a, b) => a.kodeCoa.compareTo(b.kodeCoa));
    } else {
      list = [];
      errorMessage = value?['message']?.toString() ?? 'Gagal memuat data COA';
    }

    isLoading = false;
    notifyListeners();
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
    kodeCoa.clear();
    namaCoa.clear();
    parentCoa.clear();
    specialType.clear();
    ojkCode.clear();
    tipeCoa = 1;
    levelCoa = 1;
    postingType = 'I';
  }

  void pilihTipeCoa(int? value) {
    tipeCoa = value;
    notifyListeners();
  }

  void pilihLevelCoa(int? value) {
    levelCoa = value;
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
        'parent_coa': parentCoa.text.trim(),
        'posting_type': postingType,
      };

  Future<void> cek() async {
    if (!(keyForm.currentState?.validate() ?? false)) return;

    DialogCustom().showLoading(context);
    final url = editData ? NetworkURL.editMasterGl() : NetworkURL.addMasterGl();
    final value = await Setuprepository.setup(
      token,
      url,
      jsonEncode(_coaPayload()),
    );
    Navigator.pop(context);

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
    Navigator.pop(context);

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
}
