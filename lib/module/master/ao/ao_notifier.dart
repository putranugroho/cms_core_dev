import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/menu/menu_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:accounting_kantor_gl_useraccess/repository/ao_repository.dart';
import 'package:accounting_kantor_gl_useraccess/utils/dialog_loading.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
import 'package:flutter/material.dart';

class AoNotifier extends ChangeNotifier {
  final BuildContext context;

  AoNotifier({required this.context}) {
    _init();
  }

  final keyForm = GlobalKey<FormState>();
  final keyword = TextEditingController();
  final kodeAo = TextEditingController();
  final namaAo = TextEditingController();
  final noHp = TextEditingController();
  final kodeKantor = TextEditingController();

  List<AoModel> list = [];
  List<KantorModel> listKantor = [];
  AoModel? selected;
  KantorModel? kantorModel;
  bool isLoading = true;
  bool isLoadingKantor = true;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;
  String? kantorError;

  int? filterRoleAo;
  String filterStatusData = '';
  int roleAo = 1;

  bool isSuperAdmin = false;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  String _defaultKodeKantor = '001';

  Future<void> _init() async {
    final pref = Pref();
    isSuperAdmin = await pref.getIsSuperAdmin();
    final users = await pref.getUsers();
    _defaultKodeKantor = users.kodeKantor.isNotEmpty ? users.kodeKantor : '001';
    kodeKantor.text = _defaultKodeKantor;

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

    await getKantorList();
    await getAo();
  }

  Future<void> getKantorList() async {
    isLoadingKantor = true;
    notifyListeners();

    try {
      listKantor = await AoRepository.listKantor(limit: 500);
      listKantor.sort((a, b) => a.kodeKantor.compareTo(b.kodeKantor));
      kantorModel = _findKantor(kodeKantor.text);
      if (kantorModel != null) {
        kodeKantor.text = kantorModel!.kodeKantor;
      }
    } catch (e) {
      listKantor = [];
      kantorModel = null;
    }

    isLoadingKantor = false;
    notifyListeners();
  }

  KantorModel? _findKantor(String kode) {
    final normalized = kode.trim();
    if (normalized.isEmpty) return null;
    for (final kantor in listKantor) {
      if (kantor.kodeKantor.trim() == normalized) return kantor;
    }
    return null;
  }

  void pilihKantor(KantorModel? value) {
    kantorModel = value;
    kodeKantor.text = value?.kodeKantor ?? '';
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
    editData = false;
    kodeAo.clear();
    namaAo.clear();
    noHp.clear();
    roleAo = 1;
    kantorError = null;
    kodeKantor.text = _defaultKodeKantor;
    kantorModel = _findKantor(_defaultKodeKantor);
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
    kodeAo.text = selected?.kodeAo ?? value.kodeAo;
    namaAo.text = selected?.namaAo ?? value.namaAo;
    noHp.text = selected?.noHp ?? value.noHp;
    roleAo = selected?.roleAo ?? value.roleAo;
    kodeKantor.text = selected?.kodeKantor ?? value.kodeKantor;
    kantorModel = _findKantor(kodeKantor.text);
    kantorError = null;
    notifyListeners();
  }

  Future<void> cek() async {
    kantorError = null;
    if (!(keyForm.currentState?.validate() ?? false)) return;

    if (kodeKantor.text.trim().isEmpty) {
      kantorError = 'Pilih kantor AO';
      notifyListeners();
      return;
    }

    DialogCustom().showLoading(context);
    try {
      await AoRepository.save(
        isEdit: editData,
        kodeAo: kodeAo.text,
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
    kodeAo.dispose();
    namaAo.dispose();
    noHp.dispose();
    kodeKantor.dispose();
    super.dispose();
  }
}
