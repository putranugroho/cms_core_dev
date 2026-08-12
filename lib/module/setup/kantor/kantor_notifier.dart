import 'dart:convert';

import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/network/network.dart';
import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:accounting_kantor_gl_useraccess/repository/SetupRepository.dart';
import 'package:accounting_kantor_gl_useraccess/utils/dialog_loading.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
import 'package:flutter/material.dart';

class KantorNotifier extends ChangeNotifier {
  final BuildContext context;

  KantorNotifier({required this.context}) {
    _init();
  }

  UserModel? users;
  bool isLoading = true;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;

  List<KantorModel> list = [];
  KantorModel? kantor;

  final keyForm = GlobalKey<FormState>();
  final TextEditingController kode = TextEditingController();
  final TextEditingController nama = TextEditingController();
  final TextEditingController alamat = TextEditingController();
  final TextEditingController kota = TextEditingController();
  final TextEditingController kodepos = TextEditingController();
  final TextEditingController notelp = TextEditingController();
  final TextEditingController fax = TextEditingController();
  final TextEditingController bprid = TextEditingController();
  final TextEditingController keyword = TextEditingController();

  int statusKantor = 2;
  String statusAktif = 'A';

  Future<void> _init() async {
    users = await Pref().getUsers();
    bprid.text = users?.kodePt.isNotEmpty == true ? users!.kodePt : '609999';
    await getKantor();
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

  Future<void> getKantor() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final body = {
      ..._authBody(),
      'kode_kantor': keyword.text.trim(),
      'nama': keyword.text.trim(),
      'alamat': '',
      'kota': '',
      'telp': '',
      'nomor_fax': '',
      'kode_pos': '',
      'bprid': '',
      'status_kantor': null,
      'status_aktif': '',
      'status_data': 'A',
      'page': 1,
      'limit': 100,
    };

    final value = await Setuprepository.getKantor(
      token,
      NetworkURL.getKantor(),
      jsonEncode(body),
    );

    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || status.contains('sukses')) {
      final raw = value['data'];
      final rawList = raw is Map ? (raw['data'] ?? []) : raw;
      list = (rawList as List? ?? [])
          .whereType<Map>()
          .map((e) => KantorModel.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.statusData.trim().isEmpty || e.statusData.trim().toUpperCase() == 'A')
          .toList();
      list.sort((a, b) => a.kodeKantor.compareTo(b.kodeKantor));
    } else {
      list = [];
      errorMessage = value?['message']?.toString() ?? 'Gagal memuat data kantor';
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
    kantor = null;
    editData = false;
    kode.clear();
    nama.clear();
    alamat.clear();
    kota.clear();
    kodepos.clear();
    notelp.clear();
    fax.clear();
    bprid.text = users?.kodePt.isNotEmpty == true ? users!.kodePt : '609999';
    statusKantor = 2;
    statusAktif = 'A';
  }

  void pilihStatusKantor(int? value) {
    statusKantor = value ?? 2;
    notifyListeners();
  }

  void pilihStatusAktif(String? value) {
    statusAktif = value ?? 'A';
    notifyListeners();
  }

  void edit(KantorModel value) {
    kantor = value;
    editData = true;
    dialog = true;

    kode.text = value.kodeKantor;
    nama.text = value.namaKantor;
    alamat.text = value.alamat;
    kota.text = value.kota;
    kodepos.text = value.kodePos;
    notelp.text = value.telp?.toString() ?? '';
    fax.text = value.fax?.toString() ?? '';
    bprid.text = value.kodePt;
    statusKantor = value.statusKantorCore;
    statusAktif = value.statusAktif.isNotEmpty ? value.statusAktif : 'A';

    notifyListeners();
  }

  Map<String, dynamic> _officePayload() => {
        ..._authBody(),
        'kode_kantor': kode.text.trim(),
        'nama': nama.text.trim(),
        'alamat': alamat.text.trim(),
        'kota': kota.text.trim(),
        'telp': notelp.text.trim(),
        'nomor_fax': fax.text.trim(),
        'kode_pos': kodepos.text.trim(),
        'bprid': bprid.text.trim(),
        'status_kantor': statusKantor,
        'status_aktif': statusAktif,
      };

  Future<void> cek() async {
    if (!(keyForm.currentState?.validate() ?? false)) return;

    DialogCustom().showLoading(context);
    final url = editData ? NetworkURL.updateKantor() : NetworkURL.addKantor();
    final value = await Setuprepository.insertKantor(
      token,
      url,
      jsonEncode(_officePayload()),
    );
    Navigator.pop(context);

    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || value?['code'] == '000') {
      informationDialog(context, 'Information', value?['message']?.toString() ?? 'success');
      dialog = false;
      clear();
      await getKantor();
    } else {
      informationDialog(context, 'Warning', value?['message']?.toString() ?? 'Gagal menyimpan data');
    }
  }

  void confirm() {
    if (kantor == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Anda yakin menghapus ${kantor!.namaKantor}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
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
    if (kantor == null) return;
    DialogCustom().showLoading(context);
    final value = await Setuprepository.deleteKantor(
      token,
      NetworkURL.deletedKantor(),
      jsonEncode({
        ..._authBody(),
        'kode_kantor': kantor!.kodeKantor,
      }),
    );
    Navigator.pop(context);

    final status = value?['status']?.toString().toLowerCase() ?? '';
    if (status.contains('success') || value?['code'] == '000') {
      informationDialog(context, 'Information', value?['message']?.toString() ?? 'success');
      dialog = false;
      clear();
      await getKantor();
    } else {
      informationDialog(context, 'Warning', value?['message']?.toString() ?? 'Gagal menghapus data');
    }
  }
}
