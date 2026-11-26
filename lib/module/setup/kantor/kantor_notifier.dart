import 'package:cms_core/models/index.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/hris_repository.dart';
import 'package:cms_core/repository/office_repository.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';

class KantorNotifier extends ChangeNotifier {
  final BuildContext context;

  KantorNotifier({required this.context}) {
    _init();
  }

  UserModel? users;
  bool isLoading = true;
  bool isSyncLoading = false;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;

  final List<KantorModel> _hrisSource = [];
  List<KantorModel> list = [];
  KantorModel? selectedHris;

  int page = 1;
  final int limit = 50;
  int total = 0;

  final TextEditingController keyword = TextEditingController();
  final keyForm = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};

  /// Field yang terisi dari endpoint kantor HRIS akan readonly.
  /// Field yang kosong dari HRIS tetap editable agar wajib backend bisa dilengkapi manual.
  final Set<String> hrisReadonlyKeys = <String>{};

  Future<void> _init() async {
    users = await Pref().getUsers();
    _initControllers();
    await getKantor(page: 1);
  }

  void _initControllers() {
    for (final key in const [
      'kode_kantor',
      'nama_kantor',
      'status_kantor',
      'status_aktif',
      'kode_induk',
      'alamat',
      'kelurahan',
      'kecamatan',
      'kota',
      'provinsi',
      'kode_pos',
      'kode_kantor_bi',
      'bpr_id',
      'telp',
      'nomor_fax',
      'pimpinan_cabang',
      'manager_operasional',
      'manager_marketing',
    ]) {
      controllers.putIfAbsent(key, () => TextEditingController());
    }
  }

  TextEditingController c(String key) {
    return controllers.putIfAbsent(key, () => TextEditingController());
  }

  String get bprIdLogin {
    final value = users?.kodePt.trim() ?? '';
    return value.isNotEmpty ? value : '609999';
  }

  bool get hasPrev => page > 1;
  bool get hasNext => page * limit < total;

  int get fromRow => list.isEmpty ? 0 : ((page - 1) * limit) + 1;
  int get toRow => list.isEmpty ? 0 : fromRow + list.length - 1;

  Future<void> getKantor({int? page}) async {
    isLoading = true;
    errorMessage = null;
    if (page != null) this.page = page < 1 ? 1 : page;
    notifyListeners();

    try {
      _hrisSource
        ..clear()
        ..addAll(await HrisRepository.listKantor(bprId: bprIdLogin));
      _applyLocalFilter();
    } catch (e) {
      _hrisSource.clear();
      list = [];
      total = 0;
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void _applyLocalFilter() {
    final q = keyword.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? List<KantorModel>.from(_hrisSource)
        : _hrisSource.where((item) {
            return item.kodeKantor.toLowerCase().contains(q) ||
                item.namaKantor.toLowerCase().contains(q) ||
                item.namaStatusKantor.toLowerCase().contains(q) ||
                item.alamat.toLowerCase().contains(q) ||
                item.kota.toLowerCase().contains(q) ||
                item.kodePt.toLowerCase().contains(q);
          }).toList();

    total = filtered.length;
    final start = (this.page - 1) * limit;
    if (start >= filtered.length && this.page > 1) {
      this.page = 1;
    }
    final correctedStart = (this.page - 1) * limit;
    final end = (correctedStart + limit) > filtered.length ? filtered.length : correctedStart + limit;
    list = correctedStart >= filtered.length ? [] : filtered.sublist(correctedStart, end);
  }

  void searchLocal() {
    page = 1;
    _applyLocalFilter();
    notifyListeners();
  }

  Future<void> refreshHris() async {
    await getKantor(page: 1);
  }

  Future<void> nextPage() async {
    if (!hasNext || isLoading) return;
    page++;
    _applyLocalFilter();
    notifyListeners();
  }

  Future<void> prevPage() async {
    if (!hasPrev || isLoading) return;
    page--;
    _applyLocalFilter();
    notifyListeners();
  }

  Future<void> sinkronisasi(KantorModel kantor) async {
    _clearForm();
    selectedHris = kantor;
    dialog = true;
    editData = false;
    isSyncLoading = true;
    _fillFromHris(kantor);
    notifyListeners();

    try {
      final detail = await OfficeRepository.detail(kantor.kodeKantor);
      if (detail.kodeKantor.trim().isNotEmpty) {
        _fillFromCore(detail);
        editData = true;
      }
    } catch (_) {
      // Jika belum ada di core, form tetap memakai data awal dari HRIS untuk proses create.
      editData = false;
    }

    isSyncLoading = false;
    notifyListeners();
  }

  void tutup() {
    dialog = false;
    notifyListeners();
  }

  void _clearForm() {
    selectedHris = null;
    editData = false;
    isSyncLoading = false;
    hrisReadonlyKeys.clear();
    for (final controller in controllers.values) {
      controller.clear();
    }
  }

  bool isHrisReadonly(String key) => hrisReadonlyKeys.contains(key);

  void _setHrisField(String key, dynamic raw, {bool readonlyWhenFilled = true}) {
    final text = (raw ?? '').toString().trim();
    c(key).text = text;
    if (text.isNotEmpty && readonlyWhenFilled) {
      hrisReadonlyKeys.add(key);
    } else {
      hrisReadonlyKeys.remove(key);
    }
  }

  void _setEditableField(String key, dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isNotEmpty) c(key).text = text;
  }

  void _fillFromHris(KantorModel kantor) {
    hrisReadonlyKeys.clear();
    _setHrisField('kode_kantor', kantor.kodeKantor);
    _setHrisField('nama_kantor', kantor.namaKantor);

    if (kantor.statusKantor.trim().isNotEmpty) {
      _setHrisField('status_kantor', '${kantor.statusKantorCore} - ${kantor.namaStatusKantor}');
    } else {
      _setHrisField('status_kantor', '', readonlyWhenFilled: false);
    }

    _setHrisField('status_aktif', '', readonlyWhenFilled: false);
    _setHrisField('kode_induk', kantor.kodeInduk, readonlyWhenFilled: false);
    _setHrisField('alamat', kantor.alamat);
    _setHrisField('kelurahan', kantor.kelurahan);
    _setHrisField('kecamatan', kantor.kecamatan);
    _setHrisField('kota', kantor.kota);
    _setHrisField('provinsi', kantor.provinsi);
    _setHrisField('kode_pos', kantor.kodePos);
    _setHrisField('kode_kantor_bi', kantor.kodeKantorBi);

    final bpr = kantor.kodePt.isNotEmpty ? kantor.kodePt : bprIdLogin;
    _setHrisField('bpr_id', bpr, readonlyWhenFilled: kantor.kodePt.isNotEmpty);
    _setHrisField('telp', kantor.telp);
    _setHrisField('nomor_fax', kantor.fax);
    _setHrisField('pimpinan_cabang', kantor.pimpinanCabang, readonlyWhenFilled: false);
    _setHrisField('manager_operasional', kantor.managerOperasional, readonlyWhenFilled: false);
    _setHrisField('manager_marketing', kantor.managerMarketing, readonlyWhenFilled: false);
  }

  void _fillFromCore(KantorModel detail) {
    _setEditableField('nama_kantor', detail.namaKantor);
    _setEditableField('status_aktif', detail.statusAktif.isEmpty ? 'A - Aktif' : '${detail.statusAktif} - ${statusAktifLabel(detail.statusAktif)}');
    _setEditableField('kode_induk', detail.kodeInduk);
    _setEditableField('alamat', detail.alamat);
    _setEditableField('kelurahan', detail.kelurahan);
    _setEditableField('kecamatan', detail.kecamatan);
    _setEditableField('kota', detail.kota);
    _setEditableField('provinsi', detail.provinsi);
    _setEditableField('kode_pos', detail.kodePos);
    _setEditableField('kode_kantor_bi', detail.kodeKantorBi);
    _setEditableField('bpr_id', detail.kodePt);
    _setEditableField('telp', detail.telp);
    _setEditableField('nomor_fax', detail.fax);
    _setEditableField('pimpinan_cabang', detail.pimpinanCabang);
    _setEditableField('manager_operasional', detail.managerOperasional);
    _setEditableField('manager_marketing', detail.managerMarketing);
  }

  int? statusKantorCodeFromForm() {
    final text = c('status_kantor').text.trim();
    if (text.isEmpty) return null;
    final first = text.split(RegExp(r'\s|-')).where((e) => e.trim().isNotEmpty).firstOrNull;
    final parsed = int.tryParse(first ?? '');
    if (parsed != null && parsed >= 1 && parsed <= 4) return parsed;
    final upper = text.toUpperCase();
    if (upper.contains('PUSAT')) return 1;
    if (upper.contains('CAB. PEMBANTU') || upper.contains('CABANG PEMBANTU')) return 3;
    if (upper.contains('CABANG')) return 2;
    if (upper.contains('KAS')) return 4;
    return null;
  }

  String? statusAktifCodeFromForm() {
    final text = c('status_aktif').text.trim();
    if (text.isEmpty) return null;
    final first = text.split(RegExp(r'\s|-')).where((e) => e.trim().isNotEmpty).firstOrNull?.toUpperCase();
    if (first == 'A' || first == 'N' || first == 'C') return first;
    final upper = text.toUpperCase();
    if (upper.contains('NONAKTIF')) return 'N';
    if (upper.contains('AKTIF')) return 'A';
    if (upper.contains('TUTUP')) return 'C';
    return null;
  }

  bool get kodeIndukRequired {
    final status = statusKantorCodeFromForm();
    return status == 3 || status == 4;
  }

  bool get showKodeIndukField => kodeIndukRequired;

  List<MapEntry<String, String>> get kantorIndukOptions {
    final currentKode = c('kode_kantor').text.trim();
    final selectedKode = c('kode_induk').text.trim();
    final seen = <String>{};
    final result = <MapEntry<String, String>>[];

    for (final kantor in _hrisSource) {
      final kode = kantor.kodeKantor.trim();
      if (kode.isEmpty || kode == currentKode || seen.contains(kode)) continue;
      seen.add(kode);
      final label = kantor.namaKantor.trim().isEmpty ? kode : '$kode - ${kantor.namaKantor.trim()}';
      result.add(MapEntry(kode, label));
    }

    if (selectedKode.isNotEmpty && !seen.contains(selectedKode)) {
      seen.add(selectedKode);
      result.insert(0, MapEntry(selectedKode, '$selectedKode - Data existing'));
    }

    result.sort((a, b) => a.key.compareTo(b.key));
    return result;
  }

  String? get kodeIndukDropdownValue {
    final selected = c('kode_induk').text.trim();
    if (selected.isEmpty) return null;
    return kantorIndukOptions.any((item) => item.key == selected) ? selected : null;
  }

  void setKodeInduk(String? value) {
    c('kode_induk').text = value ?? '';
    hrisReadonlyKeys.remove('kode_induk');
    notifyListeners();
  }

  bool isRequiredField(String key) {
    if (key == 'kode_kantor' || key == 'nama_kantor' || key == 'status_kantor' || key == 'status_aktif' || key == 'bpr_id') {
      return true;
    }
    if (key == 'kode_induk') return kodeIndukRequired;
    return false;
  }

  String? validateField(String key, String? raw) {
    final value = (raw ?? '').trim();
    if (isRequiredField(key) && value.isEmpty) return 'Wajib diisi';
    if (key == 'kode_kantor' && value.length > 7) return 'Maksimal 7 karakter';
    if (key == 'nama_kantor' && value.length > 200) return 'Maksimal 200 karakter';
    if (key == 'bpr_id' && value.length > 10) return 'Maksimal 10 karakter';
    if (key == 'kode_induk' && kodeIndukRequired && value.isNotEmpty) {
      final options = kantorIndukOptions;
      if (options.isNotEmpty && !options.any((item) => item.key == value)) {
        return 'Pilih kantor induk dari list HRIS';
      }
    }
    return null;
  }

  void setStatusKantor(int? value) {
    if (value == null) {
      c('status_kantor').clear();
    } else {
      c('status_kantor').text = '$value - ${statusKantorLabel(value)}';
    }

    if (value != 3 && value != 4) {
      c('kode_induk').clear();
      hrisReadonlyKeys.remove('kode_induk');
    }

    notifyListeners();
  }

  void setStatusAktif(String? value) {
    if (value == null || value.isEmpty) {
      c('status_aktif').clear();
    } else {
      c('status_aktif').text = '$value - ${statusAktifLabel(value)}';
    }
    notifyListeners();
  }

  String statusKantorLabel(int value) {
    switch (value) {
      case 1:
        return 'Pusat';
      case 2:
        return 'Cabang';
      case 3:
        return 'Cab. Pembantu';
      case 4:
        return 'Kas';
      default:
        return '';
    }
  }

  String statusAktifLabel(String value) {
    switch (value.toUpperCase()) {
      case 'A':
        return 'Aktif';
      case 'N':
        return 'Nonaktif';
      case 'C':
        return 'Tutup';
      default:
        return '';
    }
  }

  Future<List<HrisEmployeeModel>> searchEmployee(String keyword) async {
    final query = keyword.trim();
    if (query.length < 2) {
      throw Exception('Masukkan minimal 2 karakter nama / employee no / no HP.');
    }
    return HrisRepository.searchEmployee(bprId: bprIdLogin, search: query);
  }

  void pilihEmployeeUntukJabatan(String key, HrisEmployeeModel employee) {
    final name = employee.name.trim();
    if (name.isEmpty) return;
    c(key).text = name.toUpperCase();
    hrisReadonlyKeys.remove(key);
    notifyListeners();
  }

  Map<String, dynamic> _officePayloadFromForm() {
    return {
      'kode_kantor': c('kode_kantor').text.trim(),
      'nama_kantor': c('nama_kantor').text.trim(),
      'status_kantor': statusKantorCodeFromForm(),
      'status_aktif': statusAktifCodeFromForm(),
      'kode_induk': kodeIndukRequired ? c('kode_induk').text.trim() : '',
      'alamat': c('alamat').text.trim(),
      'kelurahan': c('kelurahan').text.trim(),
      'kecamatan': c('kecamatan').text.trim(),
      'kota': c('kota').text.trim(),
      'provinsi': c('provinsi').text.trim(),
      'kode_pos': c('kode_pos').text.trim(),
      'kode_kantor_bi': c('kode_kantor_bi').text.trim(),
      'bpr_id': c('bpr_id').text.trim().isNotEmpty ? c('bpr_id').text.trim() : bprIdLogin,
      'telp': c('telp').text.trim(),
      'nomor_fax': c('nomor_fax').text.trim(),
      'pimpinan_cabang': c('pimpinan_cabang').text.trim(),
      'manager_operasional': c('manager_operasional').text.trim(),
      'manager_marketing': c('manager_marketing').text.trim(),
    };
  }

  Future<void> simpan() async {
    if (selectedHris == null) {
      informationDialog(context, 'Validasi', 'Pilih kantor HRIS yang akan disinkronisasi terlebih dahulu.');
      return;
    }

    if (!(keyForm.currentState?.validate() ?? false)) return;

    final body = _officePayloadFromForm();
    final statusKantor = body['status_kantor'];
    final kodeInduk = (body['kode_induk'] ?? '').toString().trim();
    if ((statusKantor == 3 || statusKantor == 4) && kodeInduk.isEmpty) {
      informationDialog(context, 'Validasi', 'Kode induk wajib diisi untuk Kantor Cabang Pembantu / Kas.');
      return;
    }

    try {
      DialogCustom().showLoading(context);
      await OfficeRepository.save(isEdit: editData, body: body);
      if (context.mounted) Navigator.pop(context);
      dialog = false;
      notifyListeners();
      if (context.mounted) informationDialog(context, 'Informasi', editData ? 'Kantor berhasil diupdate.' : 'Kantor berhasil disinkronisasi.');
      await getKantor(page: 1);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  void dispose() {
    keyword.dispose();
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
