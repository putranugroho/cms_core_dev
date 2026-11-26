import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/ao_repository.dart';
import 'package:cms_core/repository/hris_repository.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';

class AoNotifier extends ChangeNotifier {
  final BuildContext context;

  AoNotifier({required this.context}) {
    _init();
  }

  final keyForm = GlobalKey<FormState>();
  final keyword = TextEditingController();
  final employeeSearch = TextEditingController();
  final namaAo = TextEditingController();
  final nomorEmployee = TextEditingController();
  final kodeKantor = TextEditingController();
  final kodeAo = TextEditingController();
  final noHp = TextEditingController();

  List<AoModel> list = [];
  List<HrisEmployeeModel> employeeResults = [];
  AoModel? selected;
  HrisEmployeeModel? selectedEmployee;
  bool isLoading = true;
  bool loadingEmployee = false;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;
  String? employeeError;
  String? kantorError;

  int? filterRoleAo;
  String filterStatusData = '';
  int roleAo = 1;

  bool isSuperAdmin = false;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  String _currentBprId = '609999';

  Future<void> _init() async {
    final pref = Pref();
    isSuperAdmin = await pref.getIsSuperAdmin();
    final users = await pref.getUsers();
    _currentBprId = users.kodePt.trim().isNotEmpty ? users.kodePt.trim() : '609999';

    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeAo)) {
        current = item;
        break;
      }
    }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    canDelete = isSuperAdmin || (current?.canDelete ?? false);

    await getAo();
  }

  Future<void> searchEmployee() async {
    final keyword = employeeSearch.text.trim();
    if (keyword.length < 2) {
      employeeResults = [];
      employeeError = 'Masukkan minimal 2 karakter nama / employee no / no HP.';
      selectedEmployee = null;
      notifyListeners();
      return;
    }

    loadingEmployee = true;
    employeeError = null;
    employeeResults = [];
    selectedEmployee = null;
    notifyListeners();

    try {
      final rows = await HrisRepository.searchEmployee(bprId: _currentBprId, search: keyword);
      employeeResults = rows;
      employeeError = rows.isEmpty ? 'Employee tidak ditemukan di HRIS. AO baru harus dipilih dari employee HRIS.' : null;
    } catch (e) {
      employeeError = e.toString();
    }

    loadingEmployee = false;
    notifyListeners();
  }

  void pilihEmployee(HrisEmployeeModel employee) {
    selectedEmployee = employee;
    employeeError = null;
    nomorEmployee.text = employee.employeeNo.trim();
    namaAo.text = employee.name.trim().toUpperCase();
    kodeKantor.text = employee.officeCode.trim();
    noHp.text = employee.phone.trim();
    kantorError = null;
    notifyListeners();
  }

  Future<void> getAo() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      list = await AoRepository.list(
        keyword: keyword.text.trim(),
        roleAo: filterRoleAo,
        statusData: filterStatusData,
        limit: 100,
      );
      list.sort((a, b) => a.kodeAo.compareTo(b.kodeAo));
    } catch (e) {
      list = [];
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void pilihFilterRole(int? value) {
    filterRoleAo = value == 0 ? null : value;
    notifyListeners();
  }

  void pilihFilterStatus(String? value) {
    filterStatusData = value ?? '';
    notifyListeners();
  }

  void pilihRole(int? value) {
    roleAo = value ?? 1;
    notifyListeners();
  }

  void tambah() {
    if (!canCreate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses tambah AO.');
      return;
    }
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
    selectedEmployee = null;
    employeeResults = [];
    employeeError = null;
    editData = false;
    employeeSearch.clear();
    namaAo.clear();
    nomorEmployee.clear();
    kodeKantor.clear();
    kodeAo.clear();
    noHp.clear();
    roleAo = 1;
    kantorError = null;
  }

  Future<void> edit(AoModel value) async {
    if (!canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update AO.');
      return;
    }

    try {
      DialogCustom().showLoading(context);
      final detail = await AoRepository.detail(value.kodeAo);
      if (context.mounted) Navigator.pop(context);
      selected = detail;
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
      selected = value;
    }

    editData = true;
    dialog = true;
    selectedEmployee = null;
    employeeResults = [];
    employeeError = null;
    employeeSearch.clear();
    namaAo.text = selected?.namaAo ?? value.namaAo;
    nomorEmployee.text = selected?.nomorEmployee ?? value.nomorEmployee;
    kodeKantor.text = selected?.kodeKantor ?? value.kodeKantor;
    kodeAo.text = selected?.kodeAo ?? value.kodeAo;
    noHp.text = selected?.noHp ?? value.noHp;
    roleAo = selected?.roleAo ?? value.roleAo;
    kantorError = null;
    notifyListeners();
  }

  Future<void> cek() async {
    kantorError = null;

    if (!editData && selectedEmployee == null) {
      employeeError = 'Cari dan pilih employee HRIS terlebih dahulu sebelum membuat AO.';
      notifyListeners();
      informationDialog(context, 'Warning', employeeError!);
      return;
    }

    if (!(keyForm.currentState?.validate() ?? false)) return;

    if (kodeKantor.text.trim().isEmpty) {
      kantorError = 'Kode kantor wajib terisi dari response inquiry employee HRIS.';
      notifyListeners();
      informationDialog(context, 'Warning', kantorError!);
      return;
    }

    DialogCustom().showLoading(context);
    try {
      await AoRepository.save(
        isEdit: editData,
        kodeAo: kodeAo.text,
        nomorEmployee: nomorEmployee.text,
        namaAo: namaAo.text,
        noHp: noHp.text,
        roleAo: roleAo,
        kodeKantor: kodeKantor.text,
      );
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', editData ? 'AO berhasil diupdate.' : 'AO berhasil ditambahkan.');
      dialog = false;
      clear();
      await getAo();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void confirmDelete(AoModel value) {
    if (!canDelete) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus AO.');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Anda yakin menghapus AO ${value.kodeAo} - ${value.namaAo}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              remove(value);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> remove(AoModel value) async {
    DialogCustom().showLoading(context);
    try {
      await AoRepository.delete(value.kodeAo);
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'AO berhasil dihapus.');
      dialog = false;
      clear();
      await getAo();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  void dispose() {
    keyword.dispose();
    employeeSearch.dispose();
    namaAo.dispose();
    nomorEmployee.dispose();
    kodeKantor.dispose();
    kodeAo.dispose();
    noHp.dispose();
    super.dispose();
  }
}
