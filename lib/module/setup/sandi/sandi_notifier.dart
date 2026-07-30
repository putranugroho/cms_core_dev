import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/menu/menu_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:accounting_kantor_gl_useraccess/repository/sandi_repository.dart';
import 'package:accounting_kantor_gl_useraccess/utils/dialog_loading.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
import 'package:flutter/material.dart';

class SandiNotifier extends ChangeNotifier {
  final BuildContext context;

  SandiNotifier({required this.context}) {
    _init();
  }

  final keyForm = GlobalKey<FormState>();
  final keyword = TextEditingController();
  final group = TextEditingController();
  final kode = TextEditingController();
  final nama = TextEditingController();

  List<SandiModel> list = [];
  List<SandiGroupModel> listGroup = [];
  SandiModel? selected;
  SandiGroupModel? groupModel;
  SandiGroupModel? filterGroupModel;

  bool isLoading = true;
  bool isLoadingGroup = true;
  bool dialog = false;
  bool editData = false;
  bool pavorit = false;
  String status = 'A';
  String filterStatus = 'A';
  String? errorMessage;
  String? groupError;

  bool isSuperAdmin = false;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  Future<void> _init() async {
    final pref = Pref();
    isSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeSandi)) {
        current = item;
        break;
      }
    }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    canDelete = isSuperAdmin || (current?.canDelete ?? false);

    await getGroupList();
    await getSandi();
  }

  Future<void> getGroupList() async {
    isLoadingGroup = true;
    notifyListeners();

    try {
      listGroup = await SandiRepository.groupList(limit: 500);
      listGroup.sort((a, b) => a.group.compareTo(b.group));
    } catch (_) {
      listGroup = [];
    }

    isLoadingGroup = false;
    notifyListeners();
  }

  Future<void> getSandi() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      list = await SandiRepository.list(
        group: filterGroupModel?.group ?? '',
        keyword: keyword.text.trim(),
        status: filterStatus,
        limit: 100,
      );
      list.sort((a, b) {
        final groupCompare = a.group.compareTo(b.group);
        if (groupCompare != 0) return groupCompare;
        return a.kode.compareTo(b.kode);
      });
    } catch (e) {
      list = [];
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void pilihFilterGroup(SandiGroupModel? value) {
    filterGroupModel = value;
    notifyListeners();
  }

  void pilihFilterStatus(String? value) {
    filterStatus = value ?? '';
    notifyListeners();
  }

  void pilihGroup(SandiGroupModel? value) {
    groupModel = value;
    group.text = value?.group ?? '';
    groupError = null;
    notifyListeners();
  }

  void pilihStatus(String? value) {
    status = value ?? 'A';
    notifyListeners();
  }

  void togglePavorit(bool? value) {
    pavorit = value ?? false;
    notifyListeners();
  }

  void tambah() {
    if (!canCreate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses tambah Sandi BI/OJK.');
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
    group.clear();
    kode.clear();
    nama.clear();
    pavorit = false;
    status = 'A';
    groupError = null;
    groupModel = null;
  }

  SandiGroupModel? _findGroup(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final item in listGroup) {
      if (item.group.trim().toUpperCase() == normalized) return item;
    }
    return null;
  }

  Future<void> edit(SandiModel value) async {
    if (!canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update Sandi BI/OJK.');
      return;
    }

    try {
      DialogCustom().showLoading(context);
      final detail = await SandiRepository.detail(group: value.group, kode: value.kode);
      if (context.mounted) Navigator.pop(context);
      selected = detail;
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
      selected = value;
    }

    editData = true;
    dialog = true;
    group.text = selected?.group ?? value.group;
    groupModel = _findGroup(group.text);
    kode.text = selected?.kode ?? value.kode;
    nama.text = selected?.nama ?? value.nama;
    pavorit = selected?.pavorit ?? value.pavorit;
    status = selected?.status ?? value.status;
    groupError = null;
    notifyListeners();
  }

  Future<void> cek() async {
    groupError = null;
    if (!(keyForm.currentState?.validate() ?? false)) return;

    if (group.text.trim().isEmpty) {
      groupError = 'Pilih group sandi';
      notifyListeners();
      return;
    }

    DialogCustom().showLoading(context);
    try {
      await SandiRepository.save(
        isEdit: editData,
        group: group.text,
        kode: kode.text,
        nama: nama.text,
        pavorit: pavorit,
        status: status,
      );
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', editData ? 'Sandi berhasil diupdate.' : 'Sandi berhasil ditambahkan.');
      dialog = false;
      clear();
      await getSandi();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void confirmDelete(SandiModel value) {
    if (!canDelete) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus Sandi BI/OJK.');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Anda yakin menghapus sandi ${value.group} - ${value.kode}?'),
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

  Future<void> remove(SandiModel value) async {
    DialogCustom().showLoading(context);
    try {
      await SandiRepository.delete(group: value.group, kode: value.kode);
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'Sandi berhasil dihapus.');
      dialog = false;
      clear();
      await getSandi();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  void dispose() {
    keyword.dispose();
    group.dispose();
    kode.dispose();
    nama.dispose();
    super.dispose();
  }
}
