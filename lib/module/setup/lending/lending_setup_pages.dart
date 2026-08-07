import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/menu/menu_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:accounting_kantor_gl_useraccess/repository/lending_setup_repository.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:accounting_kantor_gl_useraccess/utils/dialog_loading.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AgunanPage extends StatelessWidget {
  const AgunanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AgunanNotifier(context: context),
      child: Consumer<AgunanNotifier>(
        builder: (context, value, _) => SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderBar(
                      title: 'Agunan',
                      subtitle: 'Master jenis agunan untuk pinjaman',
                      keyword: value.keyword,
                      hint: 'Cari kode / keterangan',
                      onSearch: value.getList,
                      onAdd: value.canCreate ? value.tambah : null,
                      addText: 'Tambah Agunan',
                    ),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(child: Text(value.errorMessage!))
                              : _AgunanTable(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _AgunanForm(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PpapPage extends StatelessWidget {
  const PpapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BobotPpapNotifier(context: context),
      child: Consumer<BobotPpapNotifier>(
        builder: (context, value, _) => SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderBar(
                      title: 'PPAP',
                      subtitle: 'Setup bobot PPAP untuk scoring kredit',
                      keyword: value.keyword,
                      hint: 'Cari collateral',
                      onSearch: value.getList,
                      onAdd: value.canCreate ? value.tambah : null,
                      addText: 'Tambah PPAP',
                    ),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(child: Text(value.errorMessage!))
                              : _PpapTable(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _PpapForm(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RakPage extends StatelessWidget {
  const RakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RakOfficeNotifier(context: context),
      child: Consumer<RakOfficeNotifier>(
        builder: (context, value, _) => SafeArea(
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 880),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('RAK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Setup rekening antar kantor berdasarkan kantor', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 24),
                      if (value.isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                      else ...[
                        _KantorDropdown(
                          label: 'Kantor',
                          value: value.kodeKantor.text,
                          list: value.listKantor,
                          onChanged: value.pilihKantor,
                        ),
                        const SizedBox(height: 14),
                        _textField('COA RAK', value.kodeCoaRak, required: true, maxLength: 30),
                        _textField('COA Pendapatan RAK', value.kodeCoaRakIncome, required: true, maxLength: 30),
                        _textField('COA Biaya RAK', value.kodeCoaRakExpense, required: true, maxLength: 30),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: value.canSave ? value.save : null,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text('Simpan RAK Kantor', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(180, 50)),
                        ),
                        if (value.lastMessage != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                            child: Text(value.lastMessage!, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                        const SizedBox(height: 14),
                        const Text(
                          'Catatan: dokumentasi gateway hanya menyediakan endpoint setup-office untuk simpan RAK kantor, belum ada endpoint list/detail RAK kantor.',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RateRakPage extends StatelessWidget {
  const RateRakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RakRelasiNotifier(context: context),
      child: Consumer<RakRelasiNotifier>(
        builder: (context, value, _) => SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const SizedBox(
                            width: 260,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rate RAK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Relasi dan rate antar kantor', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: value.filterKantor,
                              decoration: _decoration('Kode Kantor'),
                              onSubmitted: (_) => value.getList(),
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: value.filterKantorLawan,
                              decoration: _decoration('Kantor Lawan'),
                              onSubmitted: (_) => value.getList(),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: value.getList,
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
                            child: const Text('Cari', style: TextStyle(color: Colors.white)),
                          ),
                          if (value.canCreate)
                            ElevatedButton.icon(
                              onPressed: value.tambah,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Tambah Rate', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(130, 50)),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(child: Text(value.errorMessage!))
                              : _RateRakTable(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _RateRakForm(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AgunanNotifier extends ChangeNotifier {
  final BuildContext context;
  AgunanNotifier({required this.context}) { init(); }

  final keyword = TextEditingController();
  final kodeAgunan = TextEditingController();
  final keterangan = TextEditingController();
  final bobotPengurang = TextEditingController();

  List<AgunanSetupModel> list = [];
  AgunanSetupModel? selected;
  bool isLoading = true;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;
  bool isSuperAdmin = false;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  Future<void> init() async {
    await _loadAccess(MenuNotifier.routeAgunan);
    await getList();
  }

  Future<void> _loadAccess(String route) async {
    final pref = Pref();
    isSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(route)) { current = item; break; }
    }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    canDelete = isSuperAdmin || (current?.canDelete ?? false);
  }

  Future<void> getList() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      list = await LendingSetupRepository.listAgunan(keyword: keyword.text.trim(), limit: 200);
      list.sort((a, b) => a.kodeAgunan.compareTo(b.kodeAgunan));
    } catch (e) {
      list = [];
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void tambah() { clear(); dialog = true; notifyListeners(); }
  void tutup() { dialog = false; notifyListeners(); }
  void clear() { selected = null; editData = false; kodeAgunan.clear(); keterangan.clear(); bobotPengurang.clear(); }

  Future<void> edit(AgunanSetupModel value) async {
    if (!canUpdate) { informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update agunan.'); return; }
    try {
      DialogCustom().showLoading(context);
      selected = await LendingSetupRepository.detailAgunan(value.kodeAgunan);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
      selected = value;
    }
    editData = true;
    dialog = true;
    kodeAgunan.text = selected?.kodeAgunan ?? value.kodeAgunan;
    keterangan.text = selected?.keterangan ?? value.keterangan;
    bobotPengurang.text = _numText(selected?.bobotPengurang ?? value.bobotPengurang);
    notifyListeners();
  }

  Future<void> save() async {
    final kode = kodeAgunan.text.trim().toUpperCase();
    final ket = keterangan.text.trim();
    final bobot = double.tryParse(bobotPengurang.text.trim().replaceAll(',', '.'));
    if (kode.isEmpty || ket.isEmpty || bobot == null) {
      informationDialog(context, 'Validasi', 'Kode agunan, keterangan, dan bobot pengurang wajib diisi.');
      return;
    }
    DialogCustom().showLoading(context);
    try {
      await LendingSetupRepository.saveAgunan(isEdit: editData, body: {
        'kode_agunan': kode,
        'keterangan': ket,
        'bobot_pengurang': bobot,
      });
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', editData ? 'Agunan berhasil diupdate.' : 'Agunan berhasil ditambahkan.');
      dialog = false;
      clear();
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void confirmDelete(AgunanSetupModel value) {
    if (!canDelete) { informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus agunan.'); return; }
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: Text('Hapus agunan ${value.kodeAgunan} - ${value.keterangan}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: () { Navigator.pop(context); delete(value); }, child: const Text('Hapus')),
      ],
    ));
  }

  Future<void> delete(AgunanSetupModel value) async {
    DialogCustom().showLoading(context);
    try {
      await LendingSetupRepository.deleteAgunan(value.kodeAgunan);
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'Agunan berhasil dihapus.');
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  void dispose() { keyword.dispose(); kodeAgunan.dispose(); keterangan.dispose(); bobotPengurang.dispose(); super.dispose(); }
}

class BobotPpapNotifier extends ChangeNotifier {
  final BuildContext context;
  BobotPpapNotifier({required this.context}) { init(); }

  final keyword = TextEditingController();
  final coll = TextEditingController();
  final bobot = TextEditingController();
  final bdr = TextEditingController();
  bool faktorPengurang = false;

  List<BobotPpapModel> list = [];
  BobotPpapModel? selected;
  bool isLoading = true;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;
  bool isSuperAdmin = false;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  Future<void> init() async {
    final pref = Pref();
    isSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) { if (item.matchesRoute(MenuNotifier.routePpap)) { current = item; break; } }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    canDelete = isSuperAdmin || (current?.canDelete ?? false);
    await getList();
  }

  Future<void> getList() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      list = await LendingSetupRepository.listBobotPpap(keyword: keyword.text.trim(), limit: 200);
      list.sort((a, b) => a.coll.compareTo(b.coll));
    } catch (e) { list = []; errorMessage = e.toString(); }
    isLoading = false; notifyListeners();
  }

  void tambah() { clear(); dialog = true; notifyListeners(); }
  void tutup() { dialog = false; notifyListeners(); }
  void pilihFaktor(bool? value) { faktorPengurang = value ?? false; notifyListeners(); }
  void clear() { selected = null; editData = false; coll.clear(); bobot.clear(); bdr.clear(); faktorPengurang = false; }

  Future<void> edit(BobotPpapModel value) async {
    if (!canUpdate) { informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update PPAP.'); return; }
    try {
      DialogCustom().showLoading(context);
      selected = await LendingSetupRepository.detailBobotPpap(value.coll);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
      selected = value;
    }
    editData = true; dialog = true;
    coll.text = selected?.coll ?? value.coll;
    bobot.text = _numText(selected?.bobot ?? value.bobot);
    bdr.text = _numText(selected?.bdr ?? value.bdr);
    faktorPengurang = selected?.faktorPengurang ?? value.faktorPengurang;
    notifyListeners();
  }

  Future<void> save() async {
    final collText = coll.text.trim().toUpperCase();
    final bobotVal = double.tryParse(bobot.text.trim().replaceAll(',', '.'));
    final bdrVal = double.tryParse(bdr.text.trim().replaceAll(',', '.'));
    if (collText.isEmpty || bobotVal == null || bdrVal == null) {
      informationDialog(context, 'Validasi', 'Collateral, bobot, dan BDR wajib diisi.'); return;
    }
    DialogCustom().showLoading(context);
    try {
      await LendingSetupRepository.saveBobotPpap(isEdit: editData, body: {
        'coll': collText,
        'bobot': bobotVal,
        'bdr': bdrVal,
        'faktor_pengurang': faktorPengurang,
      });
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', editData ? 'PPAP berhasil diupdate.' : 'PPAP berhasil ditambahkan.');
      dialog = false; clear(); await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void confirmDelete(BobotPpapModel value) {
    if (!canDelete) { informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus PPAP.'); return; }
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: Text('Hapus PPAP ${value.coll}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: () { Navigator.pop(context); delete(value); }, child: const Text('Hapus')),
      ],
    ));
  }

  Future<void> delete(BobotPpapModel value) async {
    DialogCustom().showLoading(context);
    try {
      await LendingSetupRepository.deleteBobotPpap(value.coll);
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'PPAP berhasil dihapus.');
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  void dispose() { keyword.dispose(); coll.dispose(); bobot.dispose(); bdr.dispose(); super.dispose(); }
}

class RakOfficeNotifier extends ChangeNotifier {
  final BuildContext context;
  RakOfficeNotifier({required this.context}) { init(); }

  final kodeKantor = TextEditingController();
  final kodeCoaRak = TextEditingController();
  final kodeCoaRakIncome = TextEditingController();
  final kodeCoaRakExpense = TextEditingController();
  List<KantorModel> listKantor = [];
  bool isLoading = true;
  bool canSave = false;
  String? lastMessage;

  Future<void> init() async {
    final pref = Pref();
    final superAdmin = await pref.getIsSuperAdmin();
    final users = await pref.getUsers();
    kodeKantor.text = users.kodeKantor.isNotEmpty ? users.kodeKantor : '001';
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) { if (item.matchesRoute(MenuNotifier.routeRak)) { current = item; break; } }
    canSave = superAdmin || (current?.canCreate ?? false) || (current?.canUpdate ?? false);
    try { listKantor = await LendingSetupRepository.listKantor(); } catch (_) { listKantor = []; }
    isLoading = false;
    notifyListeners();
  }

  void pilihKantor(String? value) { kodeKantor.text = value ?? ''; notifyListeners(); }

  Future<void> save() async {
    if (!canSave) { informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses menyimpan RAK.'); return; }
    if (kodeKantor.text.trim().isEmpty || kodeCoaRak.text.trim().isEmpty || kodeCoaRakIncome.text.trim().isEmpty || kodeCoaRakExpense.text.trim().isEmpty) {
      informationDialog(context, 'Validasi', 'Kantor, COA RAK, COA pendapatan, dan COA biaya wajib diisi.'); return;
    }
    DialogCustom().showLoading(context);
    try {
      await LendingSetupRepository.saveRakOffice(body: {
        'kode_kantor': kodeKantor.text.trim(),
        'kode_coa_rak': kodeCoaRak.text.trim(),
        'kode_coa_rak_income': kodeCoaRakIncome.text.trim(),
        'kode_coa_rak_expense': kodeCoaRakExpense.text.trim(),
      });
      if (context.mounted) Navigator.pop(context);
      lastMessage = 'RAK kantor ${kodeKantor.text.trim()} berhasil disimpan.';
      informationDialog(context, 'Informasi', lastMessage!);
      notifyListeners();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  void dispose() { kodeKantor.dispose(); kodeCoaRak.dispose(); kodeCoaRakIncome.dispose(); kodeCoaRakExpense.dispose(); super.dispose(); }
}

class RakRelasiNotifier extends ChangeNotifier {
  final BuildContext context;
  RakRelasiNotifier({required this.context}) { init(); }

  final filterKantor = TextEditingController();
  final filterKantorLawan = TextEditingController();
  final kodeKantor = TextEditingController();
  final kodeKantorLawan = TextEditingController();
  final rate = TextEditingController();

  List<RakRelasiModel> list = [];
  List<KantorModel> listKantor = [];
  RakRelasiModel? selected;
  bool isLoading = true;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;
  bool isSuperAdmin = false;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  Future<void> init() async {
    final pref = Pref();
    isSuperAdmin = await pref.getIsSuperAdmin();
    final users = await pref.getUsers();
    kodeKantor.text = users.kodeKantor.isNotEmpty ? users.kodeKantor : '001';
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) { if (item.matchesRoute(MenuNotifier.routeRateRak)) { current = item; break; } }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    canDelete = isSuperAdmin || (current?.canDelete ?? false);
    try { listKantor = await LendingSetupRepository.listKantor(); } catch (_) { listKantor = []; }
    await getList();
  }

  Future<void> getList() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      list = await LendingSetupRepository.listRakRelasi(
        kodeKantor: filterKantor.text.trim(),
        kodeKantorLawan: filterKantorLawan.text.trim(),
        limit: 200,
      );
      list.sort((a, b) {
        final byKantor = a.kodeKantor.compareTo(b.kodeKantor);
        if (byKantor != 0) return byKantor;
        return a.kodeKantorLawan.compareTo(b.kodeKantorLawan);
      });
    } catch (e) { list = []; errorMessage = e.toString(); }
    isLoading = false; notifyListeners();
  }

  void tambah() { clear(); dialog = true; notifyListeners(); }
  void tutup() { dialog = false; notifyListeners(); }
  void pilihKantor(String? value) { kodeKantor.text = value ?? ''; notifyListeners(); }
  void pilihKantorLawan(String? value) { kodeKantorLawan.text = value ?? ''; notifyListeners(); }
  void clear() { selected = null; editData = false; kodeKantor.clear(); kodeKantorLawan.clear(); rate.clear(); }

  void edit(RakRelasiModel value) {
    if (!canUpdate) { informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update Rate RAK.'); return; }
    selected = value; editData = true; dialog = true;
    kodeKantor.text = value.kodeKantor;
    kodeKantorLawan.text = value.kodeKantorLawan;
    rate.text = _numText(value.rate);
    notifyListeners();
  }

  Future<void> save() async {
    final rateValue = double.tryParse(rate.text.trim().replaceAll(',', '.'));
    if (kodeKantor.text.trim().isEmpty || kodeKantorLawan.text.trim().isEmpty || rateValue == null) {
      informationDialog(context, 'Validasi', 'Kantor, kantor lawan, dan rate wajib diisi.'); return;
    }
    DialogCustom().showLoading(context);
    try {
      await LendingSetupRepository.saveRakRelasi(isEdit: editData, body: {
        'kode_kantor': kodeKantor.text.trim(),
        'kode_kantor_lawan': kodeKantorLawan.text.trim(),
        'rate': rateValue,
      });
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', editData ? 'Rate RAK berhasil diupdate.' : 'Rate RAK berhasil ditambahkan.');
      dialog = false; clear(); await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void confirmDelete(RakRelasiModel value) {
    if (!canDelete) { informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus Rate RAK.'); return; }
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: Text('Hapus rate RAK ${value.kodeKantor} -> ${value.kodeKantorLawan}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: () { Navigator.pop(context); delete(value); }, child: const Text('Hapus')),
      ],
    ));
  }

  Future<void> delete(RakRelasiModel value) async {
    DialogCustom().showLoading(context);
    try {
      await LendingSetupRepository.deleteRakRelasi(kodeKantor: value.kodeKantor, kodeKantorLawan: value.kodeKantorLawan);
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'Rate RAK berhasil dihapus.');
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  void dispose() { filterKantor.dispose(); filterKantorLawan.dispose(); kodeKantor.dispose(); kodeKantorLawan.dispose(); rate.dispose(); super.dispose(); }
}

class _HeaderBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController keyword;
  final String hint;
  final VoidCallback onSearch;
  final VoidCallback? onAdd;
  final String addText;

  const _HeaderBar({required this.title, required this.subtitle, required this.keyword, required this.hint, required this.onSearch, required this.onAdd, required this.addText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          SizedBox(
            width: 280,
            child: TextField(
              controller: keyword,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: onSearch,
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
            child: const Text('Cari', style: TextStyle(color: Colors.white)),
          ),
          if (onAdd != null)
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(addText, style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(140, 50)),
            ),
        ],
      ),
    );
  }
}

class _AgunanTable extends StatelessWidget {
  final AgunanNotifier value;
  const _AgunanTable({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) return const Center(child: Text('Data agunan belum tersedia.'));
    return _TableShell(
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(colorPrimary),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        columns: const [
          DataColumn(label: Text('Kode Agunan')),
          DataColumn(label: Text('Keterangan')),
          DataColumn(label: Text('Bobot Pengurang')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: value.list.map((row) => DataRow(cells: [
          DataCell(Text(row.kodeAgunan, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(SizedBox(width: 320, child: Text(row.keterangan, overflow: TextOverflow.ellipsis))),
          DataCell(Text(_numText(row.bobotPengurang))),
          DataCell(_StatusChip(code: row.statusData)),
          DataCell(_ActionButtons(canUpdate: value.canUpdate, canDelete: value.canDelete, onEdit: () => value.edit(row), onDelete: () => value.confirmDelete(row))),
        ])).toList(),
      ),
    );
  }
}

class _PpapTable extends StatelessWidget {
  final BobotPpapNotifier value;
  const _PpapTable({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) return const Center(child: Text('Data PPAP belum tersedia.'));
    return _TableShell(
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(colorPrimary),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        columns: const [
          DataColumn(label: Text('Collateral')),
          DataColumn(label: Text('Bobot')),
          DataColumn(label: Text('BDR')),
          DataColumn(label: Text('Faktor Pengurang')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: value.list.map((row) => DataRow(cells: [
          DataCell(Text(row.coll, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_numText(row.bobot))),
          DataCell(Text(_numText(row.bdr))),
          DataCell(Text(row.faktorPengurang ? 'Ya' : 'Tidak')),
          DataCell(_StatusChip(code: row.statusData)),
          DataCell(_ActionButtons(canUpdate: value.canUpdate, canDelete: value.canDelete, onEdit: () => value.edit(row), onDelete: () => value.confirmDelete(row))),
        ])).toList(),
      ),
    );
  }
}

class _RateRakTable extends StatelessWidget {
  final RakRelasiNotifier value;
  const _RateRakTable({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) return const Center(child: Text('Data rate RAK belum tersedia.'));
    return _TableShell(
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(colorPrimary),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        columns: const [
          DataColumn(label: Text('Kode Kantor')),
          DataColumn(label: Text('Kantor Lawan')),
          DataColumn(label: Text('Rate')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: value.list.map((row) => DataRow(cells: [
          DataCell(Text(row.kodeKantor, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(row.kodeKantorLawan)),
          DataCell(Text(_numText(row.rate))),
          DataCell(_StatusChip(code: row.statusData)),
          DataCell(_ActionButtons(canUpdate: value.canUpdate, canDelete: value.canDelete, onEdit: () => value.edit(row), onDelete: () => value.confirmDelete(row))),
        ])).toList(),
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  final Widget child;
  const _TableShell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

class _AgunanForm extends StatelessWidget {
  final AgunanNotifier value;
  const _AgunanForm({required this.value});
  @override
  Widget build(BuildContext context) {
    return _SideDialog(
      title: value.editData ? 'Edit Agunan' : 'Tambah Agunan',
      onClose: value.tutup,
      children: [
        _textField('Kode Agunan', value.kodeAgunan, required: true, readOnly: value.editData, maxLength: 40, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-]'))]),
        _textField('Keterangan', value.keterangan, required: true, maxLength: 200),
        _textField('Bobot Pengurang', value.bobotPengurang, required: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))]),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: value.save, style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(120, 48)), child: Text(value.editData ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white))),
      ],
    );
  }
}

class _PpapForm extends StatelessWidget {
  final BobotPpapNotifier value;
  const _PpapForm({required this.value});
  @override
  Widget build(BuildContext context) {
    return _SideDialog(
      title: value.editData ? 'Edit PPAP' : 'Tambah PPAP',
      onClose: value.tutup,
      children: [
        _textField('Collateral', value.coll, required: true, readOnly: value.editData, maxLength: 40, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-]'))]),
        _textField('Bobot (%)', value.bobot, required: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))]),
        _textField('BDR', value.bdr, required: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))]),
        CheckboxListTile(
          value: value.faktorPengurang,
          onChanged: value.pilihFaktor,
          contentPadding: EdgeInsets.zero,
          title: const Text('Faktor Pengurang'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: value.save, style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(120, 48)), child: Text(value.editData ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white))),
      ],
    );
  }
}

class _RateRakForm extends StatelessWidget {
  final RakRelasiNotifier value;
  const _RateRakForm({required this.value});
  @override
  Widget build(BuildContext context) {
    return _SideDialog(
      title: value.editData ? 'Edit Rate RAK' : 'Tambah Rate RAK',
      onClose: value.tutup,
      children: [
        _KantorDropdown(label: 'Kantor', value: value.kodeKantor.text, list: value.listKantor, onChanged: value.pilihKantor, enabled: !value.editData),
        const SizedBox(height: 14),
        _KantorDropdown(label: 'Kantor Lawan', value: value.kodeKantorLawan.text, list: value.listKantor, onChanged: value.pilihKantorLawan, enabled: !value.editData),
        const SizedBox(height: 14),
        _textField('Rate', value.rate, required: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))]),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: value.save, style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(120, 48)), child: Text(value.editData ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white))),
      ],
    );
  }
}

class _SideDialog extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final List<Widget> children;
  const _SideDialog({required this.title, required this.onClose, required this.children});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        alignment: Alignment.centerRight,
        child: Container(
          width: 520,
          height: double.infinity,
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KantorDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<KantorModel> list;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const _KantorDropdown({required this.label, required this.value, required this.list, required this.onChanged, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final currentValue = list.any((e) => e.kodeKantor == value) ? value : (value.isEmpty ? null : value);
    final items = <DropdownMenuItem<String>>[
      if (currentValue != null && !list.any((e) => e.kodeKantor == currentValue)) DropdownMenuItem(value: currentValue, child: Text(currentValue)),
      ...list.map((e) => DropdownMenuItem(value: e.kodeKantor, child: Text('${e.kodeKantor} - ${e.namaKantor}'))),
    ];
    return DropdownButtonFormField<String>(
      value: currentValue,
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: _decoration(label),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ActionButtons({required this.canUpdate, required this.canDelete, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canUpdate)
          ElevatedButton(onPressed: onEdit, style: ElevatedButton.styleFrom(backgroundColor: colorPrimary), child: const Text('Edit', style: TextStyle(color: Colors.white))),
        if (canUpdate && canDelete) const SizedBox(width: 8),
        if (canDelete)
          ElevatedButton(onPressed: onDelete, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String code;
  const _StatusChip({required this.code});
  @override
  Widget build(BuildContext context) {
    final upper = code.toUpperCase();
    final color = upper == 'A' ? Colors.green : upper == 'D' ? Colors.red : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color)),
      child: Text(LendingValue.statusText(code), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

Widget _textField(
  String label,
  TextEditingController controller, {
  bool required = false,
  bool readOnly = false,
  int? maxLength,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: TextCapitalization.characters,
      decoration: _decoration(label),
    ),
  );
}

InputDecoration _decoration(String label) => InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), counterText: '');

String _numText(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}
