// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:cms_core/models/index.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/repository/hris_repository.dart';
import 'package:cms_core/utils/currency_formatted.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';

import '../../../utils/button_custom.dart';

class CoaNotifier extends ChangeNotifier {
  final BuildContext context;

  CoaNotifier({required this.context}) {
    getMasterGl();
    getMasterGlSubtree();
    getKantor();
  }

  var isLoading = true;
  bool dialog = false;
  bool dialogotorisasi = false;
  bool editData = false;
  bool perantara = false;
  bool seluruhKantor = false;

  final keyForm = GlobalKey<FormState>();
  final TextEditingController limitdebet = TextEditingController(text: '0');
  final TextEditingController limitkredit = TextEditingController(text: '0');
  final TextEditingController resulttext = TextEditingController();
  final TextEditingController noBb = TextEditingController();
  final TextEditingController noKantor = TextEditingController();
  final TextEditingController noHeader = TextEditingController();
  final TextEditingController noSbb = TextEditingController();
  final TextEditingController namaSbb = TextEditingController();

  String result = '0000000000';
  String? golongan;
  String? jnsAcc;
  String? hutangPiutang;
  String? typePosting = 'I';

  CoaModel? bukuBesar;
  CoaModel? header;
  CoaModel? coaModel;

  List<KantorModel> listKantor = [];
  List<dynamic> listJson = [];
  List<MasterglSubtreModel> listSubtree = [];
  List<CoaModel> list = [];
  List<CoaModel> listAdd = [];
  List<String> listSbbTambahanKhusus = [];

  List<String> listGol = const [
    'Aktiva',
    'Pasiva',
    'Pendapatan',
    'Biaya',
    'Pos Administrative',
  ];

  List<String> listJns = const [
    'Header',
    'Buku Besar',
    'Sub Buku Besar',
  ];

  List<String> listHutang = const [
    'HUTANG',
    'PIUTANG',
  ];

  List<String> listSBBKhusus = const [
    'Kas',
    'Kas ATM',
    'Kas EDC',
    'Bank',
    'Rak',
    'Pend. RAK',
    'LR Berjalan',
    'LR Tahun Lalu',
    'Biaya RAK',
  ];

  List<String> listSBBKhusus2 = const [
    'Modal',
    'ATMR',
    'Biaya Ops',
    'Pendapatan Ops',
    'Dana Pihak III',
    'Proof Sheet',
    'Loan',
    'Rupa-rupa',
  ];

  bool _success(dynamic value) {
    if (value is! Map) return false;
    final code = value['code']?.toString();
    final status = value['status']?.toString().toLowerCase() ?? '';
    return code == '000' || status.contains('success');
  }

  String _message(dynamic value) {
    if (value is Map) return value['message']?.toString() ?? 'Request selesai';
    return 'Request selesai';
  }

  List<Map<String, dynamic>> _extractRows(dynamic response) {
    dynamic data = response is Map ? response['data'] : response;
    if (data is Map && data['data'] != null) data = data['data'];
    if (data is Map && data['rows'] != null) data = data['rows'];
    if (data is Map && data['items'] != null) data = data['items'];
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  String _s(dynamic value, [String def = '']) => value == null ? def : value.toString();
  int _i(dynamic value, [int def = 0]) => int.tryParse(_s(value)) ?? def;

  String _legacyLevel(dynamic levelCoa, dynamic jnsAcc) {
    final old = _s(jnsAcc);
    if (old == 'A' || old == 'B' || old == 'C') return old;
    switch (_i(levelCoa, 3)) {
      case 1:
        return 'A';
      case 2:
        return 'B';
      default:
        return 'C';
    }
  }

  String _legacyType(dynamic tipeCoa, dynamic golAcc) {
    final old = _s(golAcc);
    if (old.isNotEmpty && old != 'null') return old;
    final value = _i(tipeCoa, 1);
    return value.toString();
  }

  Map<String, dynamic> _toLegacyMap(Map<String, dynamic> row) {
    final kodeCoa = _s(row['kode_coa'], _s(row['nosbb']));
    final level = _legacyLevel(row['level_coa'], row['jns_acc']);
    final parentCoa = _s(row['parent_coa'], _s(row['nobb']));
    final nobb = level == 'A' ? _s(row['nobb'], kodeCoa) : parentCoa;
    final posting = _s(row['posting_type'], _s(row['type_posting'], level == 'C' ? 'I' : 'N'));
    return {
      ...row,
      'gol_acc': _legacyType(row['tipe_coa'], row['gol_acc']),
      'jns_acc': level,
      'nobb': nobb,
      'nosbb': kodeCoa,
      'nama_sbb': _s(row['nama_coa'], _s(row['nama_sbb'])),
      'type_posting': posting == 'Y' ? 'I' : posting,
      'sbb_khusus': _s(row['special_type'], _s(row['sbb_khusus'])),
      'akun_perantara': _s(row['akun_perantara'], 'N'),
      'hutang': _s(row['hutang'], 'N'),
      'piutang': _s(row['piutang'], 'N'),
      'nonaktif': _s(row['status_data']) == 'D' || _s(row['is_deleted']) == 'Y' ? 'Y' : 'N',
      'limit_debet': _s(row['limit_debet'], '0'),
      'limit_kredit': _s(row['limit_kredit'], '0'),
      'children': <Map<String, dynamic>>[],
    };
  }

  List<Map<String, dynamic>> _buildLegacyTree(List<Map<String, dynamic>> source) {
    final rows = source.map(_toLegacyMap).toList()
      ..sort((a, b) => _s(a['nosbb']).compareTo(_s(b['nosbb'])));
    final byCode = {for (final row in rows) _s(row['nosbb']): row};
    final roots = <Map<String, dynamic>>[];

    for (final row in rows) {
      final level = _s(row['jns_acc']);
      if (level == 'A') {
        roots.add(row);
        continue;
      }
      final parent = byCode[_s(row['nobb'])];
      if (parent == null) {
        roots.add(row);
      } else {
        (parent['children'] as List).add(row);
      }
    }
    return roots;
  }

  Future getKantor() async {
    listKantor.clear();
    listKantor.addAll(await HrisRepository.listKantor());
    notifyListeners();
  }

  Future getMasterGl() async {
    isLoading = true;
    list.clear();
    notifyListeners();
    final body = {'page': 1, 'limit': 1000, 'status_data': 'A'};
    final value = await Setuprepository.fetch(NetworkURL.getMasterGl(), body);
    if (_success(value)) {
      final rows = _extractRows(value);
      list = rows.map((e) => CoaModel.fromJson(_toLegacyMap(e))).toList()
        ..sort((a, b) => a.nosbb.compareTo(b.nosbb));
      listJson = _buildLegacyTree(rows);
    }
    isLoading = false;
    notifyListeners();
  }

  Future getMasterGlSubtree() async {
    isLoading = true;
    listSubtree.clear();
    notifyListeners();
    final body = {'page': 1, 'limit': 1000, 'status_data': 'A'};
    final value = await Setuprepository.fetch(NetworkURL.getMasterGlSubtree(), body);
    if (_success(value)) {
      final rows = _extractRows(value);
      listJson = _buildLegacyTree(rows);
      for (final item in rows) {
        try {
          listSubtree.add(MasterglSubtreModel.fromJson(_toLegacyMap(item)));
        } catch (_) {}
      }
      if (list.isEmpty) {
        list = rows.map((e) => CoaModel.fromJson(_toLegacyMap(e))).toList()
          ..sort((a, b) => a.nosbb.compareTo(b.nosbb));
      }
    }
    isLoading = false;
    notifyListeners();
  }

  void pilihHeader(CoaModel value) {
    header = value;
    noHeader.text = header!.nosbb;
    if (noBb.text.isNotEmpty) updatebb();
    notifyListeners();
  }

  void pilihBB(CoaModel value) {
    bukuBesar = value;
    noBb.text = value.nosbb;
    hutangPiutang = value.hutang == 'Y' && value.piutang == 'N'
        ? 'HUTANG'
        : value.piutang == 'Y' && value.hutang == 'N'
            ? 'PIUTANG'
            : null;
    perantara = value.akunPerantara == 'Y';
    if (noSbb.text.isNotEmpty) updateSbb();
    notifyListeners();
  }

  void tambah() {
    clear();
    dialog = true;
    notifyListeners();
  }

  void tutup() {
    dialog = false;
    dialogotorisasi = false;
    notifyListeners();
  }

  void pilihGolongan(String value) {
    golongan = value;
    notifyListeners();
  }

  void pilihJenis(String value) {
    resulttext.clear();
    header = null;
    noHeader.clear();
    noBb.clear();
    bukuBesar = null;
    noSbb.clear();
    jnsAcc = value;
    typePosting = value == 'Sub Buku Besar' ? 'I' : 'N';
    notifyListeners();
  }

  void updateHeader() {
    result = '${noHeader.text}000000000';
    resulttext.text = result;
    notifyListeners();
  }

  void updatebb() {
    final head = header?.nosbb ?? noHeader.text;
    result = '${head.length >= 3 ? head.substring(0, 3) : head}${noBb.text.trim()}000000';
    resulttext.text = result;
    notifyListeners();
  }

  void updateSbb() {
    final bb = bukuBesar?.nosbb ?? noBb.text;
    result = '${bb.length >= 6 ? bb.substring(0, 6) : bb}${noSbb.text.trim()}';
    resulttext.text = result;
    notifyListeners();
  }

  void gantiHutangPiutang(String value) {
    hutangPiutang = hutangPiutang == value ? null : value;
    notifyListeners();
  }

  void gantiperantara() {
    perantara = !perantara;
    notifyListeners();
  }

  void gantiPosting(String value) {
    typePosting = value;
    notifyListeners();
  }

  void pilihSbbKhusus(String value) {
    if (listSbbTambahanKhusus.contains(value)) {
      listSbbTambahanKhusus.remove(value);
    } else {
      listSbbTambahanKhusus.add(value);
    }
    notifyListeners();
  }

  void pilihCoa(CoaModel value) {
    if (listAdd.contains(value)) {
      listAdd.remove(value);
    } else {
      listAdd.add(value);
    }
    notifyListeners();
  }

  void pilihSemua() {
    listAdd = List.of(list);
    notifyListeners();
  }

  void gantiseluruh() {
    seluruhKantor = !seluruhKantor;
    if (seluruhKantor) {
      pilihSemua();
    } else {
      listAdd.clear();
    }
    notifyListeners();
  }

  String _typeCode() {
    switch (golongan) {
      case 'Aktiva':
        return '1';
      case 'Pasiva':
        return '2';
      case 'Pendapatan':
        return '3';
      case 'Biaya':
        return '4';
      default:
        return '5';
    }
  }

  int _levelCode() {
    switch (jnsAcc) {
      case 'Header':
        return 1;
      case 'Buku Besar':
        return 2;
      default:
        return 3;
    }
  }

  String _legacyJnsAcc() {
    switch (jnsAcc) {
      case 'Header':
        return 'A';
      case 'Buku Besar':
        return 'B';
      default:
        return 'C';
    }
  }

  String _parentCoa() {
    if (jnsAcc == 'Header') return '';
    if (jnsAcc == 'Buku Besar') return header?.nosbb ?? noHeader.text;
    return bukuBesar?.nosbb ?? noBb.text;
  }

  String _posting() {
    if (jnsAcc == 'Header' || jnsAcc == 'Buku Besar') return 'N';
    final posting = (typePosting ?? 'I').toUpperCase();
    return posting == 'Y' ? 'I' : posting;
  }

  String _money(String value) => cleanCurrencyInput(value).isEmpty ? '0' : cleanCurrencyInput(value);

  Map<String, dynamic> _buildSaveBody() {
    final kodeCoa = resulttext.text.trim();
    final type = int.tryParse(_typeCode()) ?? 1;
    final level = _levelCode();
    final parent = _parentCoa();
    final posting = _posting();
    final legacyJns = _legacyJnsAcc();
    final special = listSbbTambahanKhusus.join(',');
    final oldParent = legacyJns == 'A' ? kodeCoa : parent;

    return {
      'kode_coa': kodeCoa,
      'nama_coa': namaSbb.text.trim(),
      'tipe_coa': type,
      'level_coa': level,
      'parent_coa': parent,
      'posting_type': posting,
      'special_type': special,
      'status_data': 'A',
      'limit_debet': double.tryParse(_money(limitdebet.text)) ?? 0,
      'limit_kredit': double.tryParse(_money(limitkredit.text)) ?? 0,
      // field lama tetap dikirim supaya endpoint/gateway yang masih membaca style ACT MTD tetap aman.
      'kode_pt': '001',
      'kode_kantor': '001',
      'kode_induk': '001',
      'userinput': 'admin',
      'userterm': 'web',
      'gol_acc': type.toString(),
      'jns_acc': legacyJns,
      'nobb': oldParent,
      'nosbb': kodeCoa,
      'nama_sbb': namaSbb.text.trim(),
      'type_posting': posting,
      'sbb_khusus': special,
      'akun_perantara': jnsAcc == 'Sub Buku Besar'
          ? (bukuBesar?.akunPerantara ?? 'N')
          : perantara
              ? 'Y'
              : 'N',
      'hutang': jnsAcc == 'Sub Buku Besar'
          ? (bukuBesar?.hutang ?? 'N')
          : hutangPiutang == 'HUTANG'
              ? 'Y'
              : 'N',
      'piutang': jnsAcc == 'Sub Buku Besar'
          ? (bukuBesar?.piutang ?? 'N')
          : hutangPiutang == 'PIUTANG'
              ? 'Y'
              : 'N',
    };
  }

  Future<void> cek() async {
    if (!(keyForm.currentState?.validate() ?? false)) return;
    DialogCustom().showLoading(context);
    final data = _buildSaveBody();
    final url = editData ? NetworkURL.editMasterGl() : NetworkURL.addMasterGl();
    final value = await Setuprepository.fetch(url, data);
    if (context.mounted) Navigator.pop(context);
    if (_success(value)) {
      informationDialog(context, 'Information', _message(value));
      clear();
      await getMasterGl();
      await getMasterGlSubtree();
    } else {
      informationDialog(context, 'Warning', _message(value));
    }
  }

  void edit(String id) {
    final matches = list.where((e) => e.nosbb == id).toList();
    if (matches.isEmpty) return;
    coaModel = matches.first;
    dialog = true;
    editData = true;
    golongan = coaModel!.golAcc == '1'
        ? 'Aktiva'
        : coaModel!.golAcc == '2'
            ? 'Pasiva'
            : coaModel!.golAcc == '3'
                ? 'Pendapatan'
                : coaModel!.golAcc == '4'
                    ? 'Biaya'
                    : 'Pos Administrative';
    jnsAcc = coaModel!.jnsAcc == 'A'
        ? 'Header'
        : coaModel!.jnsAcc == 'B'
            ? 'Buku Besar'
            : 'Sub Buku Besar';

    if (coaModel!.jnsAcc == 'A') {
      noHeader.text = coaModel!.nosbb.length >= 3 ? coaModel!.nosbb.substring(0, 3) : coaModel!.nosbb;
      resulttext.text = coaModel!.nosbb;
      namaSbb.text = coaModel!.namaSbb;
    } else if (coaModel!.jnsAcc == 'B') {
      header = _findByCode(coaModel!.nobb);
      noHeader.text = header?.nosbb ?? coaModel!.nobb;
      noBb.text = coaModel!.nosbb.length >= 6 ? coaModel!.nosbb.substring(3, 6) : '';
      resulttext.text = coaModel!.nosbb;
      namaSbb.text = coaModel!.namaSbb;
      hutangPiutang = coaModel!.hutang == 'Y' && coaModel!.piutang == 'N'
          ? 'HUTANG'
          : coaModel!.piutang == 'Y' && coaModel!.hutang == 'N'
              ? 'PIUTANG'
              : null;
      perantara = coaModel!.akunPerantara == 'Y';
    } else {
      bukuBesar = _findByCode(coaModel!.nobb);
      noBb.text = bukuBesar?.nosbb ?? coaModel!.nobb;
      noSbb.text = coaModel!.nosbb.length >= 12 ? coaModel!.nosbb.substring(6, 12) : '';
      resulttext.text = coaModel!.nosbb;
      typePosting = coaModel!.typePosting == 'Y' ? 'I' : (coaModel!.typePosting.isEmpty ? 'I' : coaModel!.typePosting);
      namaSbb.text = coaModel!.namaSbb;
      limitdebet.text = coaModel!.limitDebet;
      limitkredit.text = coaModel!.limitKredit;
      hutangPiutang = bukuBesar?.hutang == 'Y' && bukuBesar?.piutang == 'N'
          ? 'HUTANG'
          : bukuBesar?.piutang == 'Y' && bukuBesar?.hutang == 'N'
              ? 'PIUTANG'
              : null;
      perantara = bukuBesar?.akunPerantara == 'Y';
    }
    listSbbTambahanKhusus = coaModel!.sbbKhusus.isEmpty ? [] : coaModel!.sbbKhusus.split(',').where((e) => e.trim().isNotEmpty).toList();
    notifyListeners();
  }

  CoaModel? _findByCode(String code) {
    final matches = list.where((e) => e.nosbb == code).toList();
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> remove() async {
    if (coaModel == null) return;
    DialogCustom().showLoading(context);
    final value = await Setuprepository.fetch(NetworkURL.deleteMasterGl(), {'kode_coa': coaModel!.nosbb, 'nosbb': coaModel!.nosbb});
    if (context.mounted) Navigator.pop(context);
    if (_success(value)) {
      informationDialog(context, 'Information', _message(value));
      clear();
      await getMasterGl();
      await getMasterGlSubtree();
    } else {
      informationDialog(context, 'Warning', _message(value));
    }
  }

  Future<void> removetutup() async {
    if (coaModel == null) return;
    DialogCustom().showLoading(context);
    final value = await Setuprepository.fetch(NetworkURL.editMasterGl(), {
      ...coaModel!.toJson(),
      'kode_coa': coaModel!.nosbb,
      'nama_coa': coaModel!.namaSbb,
      'tipe_coa': int.tryParse(coaModel!.golAcc) ?? 1,
      'level_coa': coaModel!.jnsAcc == 'A' ? 1 : coaModel!.jnsAcc == 'B' ? 2 : 3,
      'parent_coa': coaModel!.jnsAcc == 'A' ? '' : coaModel!.nobb,
      'posting_type': coaModel!.typePosting == 'Y' ? 'I' : coaModel!.typePosting,
      'status_data': 'D',
    });
    if (context.mounted) Navigator.pop(context);
    if (_success(value)) {
      informationDialog(context, 'Information', _message(value));
      clear();
      await getMasterGl();
      await getMasterGlSubtree();
    } else {
      informationDialog(context, 'Warning', _message(value));
    }
  }

  void clear() {
    dialog = false;
    editData = false;
    hutangPiutang = null;
    jnsAcc = null;
    perantara = false;
    resulttext.clear();
    header = null;
    noHeader.clear();
    noBb.clear();
    bukuBesar = null;
    noSbb.clear();
    namaSbb.clear();
    limitdebet.text = '0';
    limitkredit.text = '0';
    golongan = null;
    typePosting = 'I';
    coaModel = null;
    listSbbTambahanKhusus.clear();
    notifyListeners();
  }

  void confirm() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Anda yakin menghapus ${coaModel?.namaSbb ?? ''}?', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ButtonSecondary(onTap: () => Navigator.pop(context), name: 'Tidak')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ButtonPrimary(
                      onTap: () {
                        Navigator.pop(context);
                        remove();
                      },
                      name: 'Ya',
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void confirmtutup() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Anda yakin tutup ${coaModel?.namaSbb ?? ''}?', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ButtonSecondary(onTap: () => Navigator.pop(context), name: 'Tidak')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ButtonPrimary(
                      onTap: () {
                        Navigator.pop(context);
                        removetutup();
                      },
                      name: 'Ya',
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void confirmotorisasi() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Anda yakin menjalankan otorisasi Master GL ke semua kantor?', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ButtonSecondary(onTap: () => Navigator.pop(context), name: 'Tidak')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ButtonPrimary(
                      onTap: () {
                        Navigator.pop(context);
                        otorisasiSemua();
                      },
                      name: 'Ya',
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> otorisasiSemua() async {
    informationDialog(context, 'Informasi', 'Otorisasi semua kantor belum diperlukan untuk endpoint Core saat ini.');
  }

  List<Map<String, dynamic>> data = const [
    {'gol_acc': '1', 'jns_acc': 'A', 'nobb': '10000000', 'nosbb': '10000000', 'nama_sbb': 'Kas', 'type_posting': 'N', 'sbb_khusus': 'kas'},
  ];
}
