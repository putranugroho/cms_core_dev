import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/lending_setup_repository.dart';
import 'package:cms_core/repository/saving_product_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:cms_core/utils/percentage_input_formatter.dart';
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
        builder: (context, value, _) => SafeArea(child: Scaffold(body: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(padding: const EdgeInsets.all(24), color: Colors.white, child: Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SBB RAK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Setup rekening RAK per kantor', style: TextStyle(color: Colors.black54))])),
              SizedBox(width: 280, child: TextField(controller: value.keyword, onSubmitted: (_) => value.filterOffices(), decoration: _decoration('Kode / Nama Kantor').copyWith(suffixIcon: IconButton(onPressed: value.filterOffices, icon: const Icon(Icons.search))))),
            ])),
            Expanded(child: value.isLoading ? const Center(child: CircularProgressIndicator()) : value.visibleKantor.isEmpty ? const Center(child: Text('Data kantor tidak ditemukan.')) : SingleChildScrollView(padding: const EdgeInsets.all(24), child: SizedBox(width: double.infinity, child: DataTable(columns: const [DataColumn(label: Text('Kode Kantor')), DataColumn(label: Text('Nama Kantor')), DataColumn(label: Text('Aksi'))], rows: value.visibleKantor.map((kantor) => DataRow(cells: [DataCell(Text(kantor.kodeKantor)), DataCell(Text(kantor.namaKantor)), DataCell(Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: 'Edit setup SBB RAK', onPressed: value.canSave ? () => value.openEdit(kantor) : null, icon: const Icon(Icons.edit)), IconButton(tooltip: 'Hapus setup SBB RAK', onPressed: value.canDelete ? () => value.deleteUnavailable(kantor) : null, icon: const Icon(Icons.delete, color: Colors.red))]))])).toList())))),
          ]),
          if (value.showForm) _form(context, value),
        ]))),
      ),
    );
  }

  Widget _form(BuildContext context, RakOfficeNotifier value) => Positioned.fill(child: Container(color: Colors.black26, alignment: Alignment.centerRight, child: Container(width: 760, height: double.infinity, color: Colors.white, child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [Expanded(child: Text('Edit SBB RAK - ${value.kodeKantor.text}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), IconButton(onPressed: value.closeForm, icon: const Icon(Icons.close))]),
    const SizedBox(height: 20),
    Row(children: [Expanded(child: _readOnlyField('Kode Kantor', value.kodeKantor)), const SizedBox(width: 12), Expanded(child: _readOnlyField('Nama Kantor', value.namaKantor))]),
    const SizedBox(height: 14), _sbbRow(context, value, 'No SBB RAK *', 'Nama SBB RAK', value.kodeCoaRak, value.namaCoaRak, 'rak'),
    const SizedBox(height: 14), _sbbRow(context, value, 'No SBB Pendapatan RAK *', 'Nama SBB Pendapatan RAK', value.kodeCoaRakIncome, value.namaCoaRakIncome, 'income'),
    const SizedBox(height: 14), _sbbRow(context, value, 'No SBB Biaya RAK *', 'Nama SBB Biaya RAK', value.kodeCoaRakExpense, value.namaCoaRakExpense, 'expense'),
    const SizedBox(height: 18), ElevatedButton.icon(onPressed: value.canSave && !value.isSaving ? value.save : null, icon: const Icon(Icons.save, color: Colors.white), label: Text(value.hasExistingSetup ? 'Simpan Perubahan' : 'Simpan Setup', style: const TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(180, 50))),
  ])))));

  Widget _inquiryField(String label, TextEditingController controller, VoidCallback onTap) => TextFormField(
        controller: controller,
        readOnly: true,
        decoration: _decoration(label).copyWith(suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: onTap)),
        onTap: onTap,
      );

  Widget _readOnlyField(String label, TextEditingController controller) =>
      TextFormField(controller: controller, readOnly: true, decoration: _decoration(label).copyWith(fillColor: Colors.grey.shade100));

  Widget _sbbRow(BuildContext context, RakOfficeNotifier value, String noLabel, String nameLabel,
      TextEditingController nomor, TextEditingController nama, String key) {
    return Row(children: [
      Expanded(child: _inquiryField(noLabel, nomor, () => _showSbbInquiry(context, value, key))),
      const SizedBox(width: 12),
      Expanded(child: _readOnlyField(nameLabel, nama)),
    ]);
  }

  Future<void> _showSbbInquiry(BuildContext context, RakOfficeNotifier value, String key) async {
    final selected = await showDialog<CoreCoaModel>(context: context, builder: (_) => const _SbbInquiryDialog());
    if (selected != null) value.pilihSbb(key, selected);
  }
}

class RateRakPage extends StatefulWidget {
  const RateRakPage({super.key});

  @override
  State<RateRakPage> createState() => _RateRakPageState();
}

class _RateRakPageState extends State<RateRakPage> {
  final _formKey = GlobalKey<FormState>();
  final _rate = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await LendingSetupRepository.detailRakRate();
      if (data != null) _rate.text = _rakRateText(data['rate']);
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final data = await LendingSetupRepository.saveRakRate(rate: _rate.text);
      _rate.text = _rakRateText(data['rate']);
      if (mounted) informationDialog(context, 'Informasi', 'Rate RAK berhasil disimpan.');
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 760,
              child: Card(
                elevation: 0,
                color: const Color(0xFFFBF6FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: _loading
                        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                        : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Setup Rate RAK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _rate,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final text = newValue.text.replaceAll(',', '.');
                            if (!RegExp(r'^\d*(\.\d{0,6})?$').hasMatch(text)) return oldValue;
                            return newValue.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
                          }),
                        ],
                        validator: (value) {
                          final text = (value ?? '').trim().replaceAll(',', '.');
                          final number = double.tryParse(text);
                          if (text.isEmpty) return 'Wajib diisi';
                          if (number == null || number < 0) return 'Rate harus berupa angka yang valid dan tidak boleh negatif';
                          return null;
                        },
                        decoration: _decoration('Rate Pajak (%) *'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(140, 52)),
                        child: _saving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Simpan', style: TextStyle(color: Colors.white)),
                      ),
                    ]),
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

class AgunanNotifier extends ChangeNotifier {
  final BuildContext context;
  AgunanNotifier({required this.context}) {
    init();
  }

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
      if (item.matchesRoute(route)) {
        current = item;
        break;
      }
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
    kodeAgunan.clear();
    keterangan.clear();
    bobotPengurang.clear();
  }

  Future<void> edit(AgunanSetupModel value) async {
    if (!canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update agunan.');
      return;
    }
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
    if (bobot < 0 || bobot > 100) {
      informationDialog(context, 'Validasi', 'Bobot pengurang harus antara 0 sampai 100.');
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
    if (!canDelete) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus agunan.');
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Konfirmasi'),
              content: Text('Hapus agunan ${value.kodeAgunan} - ${value.keterangan}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      delete(value);
                    },
                    child: const Text('Hapus')),
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
  void dispose() {
    keyword.dispose();
    kodeAgunan.dispose();
    keterangan.dispose();
    bobotPengurang.dispose();
    super.dispose();
  }
}

class BobotPpapNotifier extends ChangeNotifier {
  final BuildContext context;
  BobotPpapNotifier({required this.context}) {
    init();
  }

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
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routePpap)) {
        current = item;
        break;
      }
    }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    canDelete = isSuperAdmin || (current?.canDelete ?? false);
    await getList();
  }

  Future<void> getList() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      list = await LendingSetupRepository.listBobotPpap(keyword: keyword.text.trim(), limit: 200);
      list.sort((a, b) => a.coll.compareTo(b.coll));
    } catch (e) {
      list = [];
      errorMessage = e.toString();
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

  void pilihFaktor(bool? value) {
    faktorPengurang = value ?? false;
    notifyListeners();
  }

  void clear() {
    selected = null;
    editData = false;
    coll.clear();
    bobot.clear();
    bdr.clear();
    faktorPengurang = false;
  }

  Future<void> edit(BobotPpapModel value) async {
    if (!canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update PPAP.');
      return;
    }
    try {
      DialogCustom().showLoading(context);
      selected = await LendingSetupRepository.detailBobotPpap(value.coll);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
      selected = value;
    }
    editData = true;
    dialog = true;
    coll.text = selected?.coll ?? value.coll;
    bobot.text = _numText(selected?.bobot ?? value.bobot);
    bdr.text = _numText(selected?.bdr ?? value.bdr);
    faktorPengurang = selected?.faktorPengurang ?? value.faktorPengurang;
    notifyListeners();
  }

  Future<void> save() async {
    final collText = coll.text.trim();
    final bobotVal = double.tryParse(bobot.text.trim().replaceAll(',', '.'));
    final bdrVal = double.tryParse(bdr.text.trim().replaceAll(',', '.'));
    if (collText.isEmpty || bobotVal == null || bdrVal == null) {
      informationDialog(context, 'Validasi', 'Collateral, bobot, dan BDR wajib diisi.');
      return;
    }
    if (!RegExp(r'^[1-5]$').hasMatch(collText)) {
      informationDialog(context, 'Validasi', 'Collateral hanya boleh angka 1, 2, 3, 4, atau 5.');
      return;
    }
    if (bobotVal < 0 || bobotVal > 100 || bdrVal < 0 || bdrVal > 100) {
      informationDialog(context, 'Validasi', 'Bobot dan BDR harus antara 0 sampai 100.');
      return;
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
      dialog = false;
      clear();
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void confirmDelete(BobotPpapModel value) {
    if (!canDelete) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus PPAP.');
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Konfirmasi'),
              content: Text('Hapus PPAP ${value.coll}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      delete(value);
                    },
                    child: const Text('Hapus')),
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
  void dispose() {
    keyword.dispose();
    coll.dispose();
    bobot.dispose();
    bdr.dispose();
    super.dispose();
  }
}

class RakOfficeNotifier extends ChangeNotifier {
  final BuildContext context;
  RakOfficeNotifier({required this.context}) {
    init();
  }

  final kodeKantor = TextEditingController();
  final namaKantor = TextEditingController();
  final kodeCoaRak = TextEditingController();
  final namaCoaRak = TextEditingController();
  final kodeCoaRakIncome = TextEditingController();
  final namaCoaRakIncome = TextEditingController();
  final kodeCoaRakExpense = TextEditingController();
  final namaCoaRakExpense = TextEditingController();
  final keyword = TextEditingController();
  List<KantorModel> listKantor = [];
  List<KantorModel> visibleKantor = [];
  bool isLoading = true;
  bool isSaving = false;
  bool showForm = false;
  bool canSave = false;
  bool canDelete = false;
  bool hasExistingSetup = false;
  String? lastMessage;

  Future<void> init() async {
    final pref = Pref();
    final superAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeRak)) {
        current = item;
        break;
      }
    }
    canSave = superAdmin || (current?.canCreate ?? false) || (current?.canUpdate ?? false);
    canDelete = superAdmin || (current?.canDelete ?? false);
    try {
      listKantor = await LendingSetupRepository.listKantor();
      visibleKantor = List<KantorModel>.from(listKantor);
    } catch (_) {
      listKantor = [];
    }
    isLoading = false;
    notifyListeners();
  }

  void filterOffices() {
    final query = keyword.text.trim().toLowerCase();
    visibleKantor = query.isEmpty ? List<KantorModel>.from(listKantor) : listKantor.where((item) => item.kodeKantor.toLowerCase().contains(query) || item.namaKantor.toLowerCase().contains(query)).toList();
    notifyListeners();
  }

  Future<void> openEdit(KantorModel value) async {
    kodeKantor.text = value.kodeKantor;
    namaKantor.text = value.namaKantor;
    showForm = true;
    notifyListeners();
    await loadOfficeDetail();
  }

  void closeForm() {
    showForm = false;
    notifyListeners();
  }

  void deleteUnavailable(KantorModel value) {
    informationDialog(context, 'Endpoint belum tersedia', 'Endpoint delete setup SBB RAK belum diberikan. Data kantor ${value.kodeKantor} tidak dihapus agar tidak mengirim request ke endpoint yang salah.');
  }

  Future<void> loadOfficeDetail({bool showError = true}) async {
    kodeCoaRak.clear();
    namaCoaRak.clear();
    kodeCoaRakIncome.clear();
    namaCoaRakIncome.clear();
    kodeCoaRakExpense.clear();
    namaCoaRakExpense.clear();
    hasExistingSetup = false;
    if (kodeKantor.text.trim().isEmpty) return;
    try {
      final data = await LendingSetupRepository.detailRakOffice(kodeKantor.text);
      if (data != null) {
        hasExistingSetup = true;
        kodeCoaRak.text = (data['kode_coa_rak'] ?? '').toString();
        namaCoaRak.text = (data['kode_coa_rak_nama'] ?? '').toString();
        kodeCoaRakIncome.text = (data['kode_coa_rak_income'] ?? '').toString();
        namaCoaRakIncome.text = (data['kode_coa_rak_income_nama'] ?? '').toString();
        kodeCoaRakExpense.text = (data['kode_coa_rak_expense'] ?? '').toString();
        namaCoaRakExpense.text = (data['kode_coa_rak_expense_nama'] ?? '').toString();
      }
    } catch (e) {
      if (showError) informationDialog(context, 'Warning', e.toString());
    }
    notifyListeners();
  }

  void pilihSbb(String key, CoreCoaModel value) {
    if (key == 'rak') {
      kodeCoaRak.text = value.kodeCoa;
      namaCoaRak.text = value.namaCoa;
    } else if (key == 'income') {
      kodeCoaRakIncome.text = value.kodeCoa;
      namaCoaRakIncome.text = value.namaCoa;
    } else {
      kodeCoaRakExpense.text = value.kodeCoa;
      namaCoaRakExpense.text = value.namaCoa;
    }
    notifyListeners();
  }

  Future<void> save() async {
    if (!canSave) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses menyimpan RAK.');
      return;
    }
    if (kodeKantor.text.trim().isEmpty ||
        kodeCoaRak.text.trim().isEmpty ||
        kodeCoaRakIncome.text.trim().isEmpty ||
        kodeCoaRakExpense.text.trim().isEmpty) {
      informationDialog(context, 'Validasi', 'Kantor, COA RAK, COA pendapatan, dan COA biaya wajib diisi.');
      return;
    }
    DialogCustom().showLoading(context);
    isSaving = true;
    notifyListeners();
    try {
      await LendingSetupRepository.saveRakOffice(body: {
        'kode_kantor': kodeKantor.text.trim(),
        'kode_coa_rak': kodeCoaRak.text.trim(),
        'kode_coa_rak_income': kodeCoaRakIncome.text.trim(),
        'kode_coa_rak_expense': kodeCoaRakExpense.text.trim(),
      });
      hasExistingSetup = true;
      if (context.mounted) Navigator.pop(context);
      lastMessage = 'RAK kantor ${kodeKantor.text.trim()} berhasil disimpan.';
      informationDialog(context, 'Informasi', lastMessage!);
      notifyListeners();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    kodeKantor.dispose();
    namaKantor.dispose();
    kodeCoaRak.dispose();
    namaCoaRak.dispose();
    kodeCoaRakIncome.dispose();
    namaCoaRakIncome.dispose();
    kodeCoaRakExpense.dispose();
    namaCoaRakExpense.dispose();
    keyword.dispose();
    super.dispose();
  }
}

class _KantorInquiryDialog extends StatefulWidget {
  const _KantorInquiryDialog();

  @override
  State<_KantorInquiryDialog> createState() => _KantorInquiryDialogState();
}

class _KantorInquiryDialogState extends State<_KantorInquiryDialog> {
  final search = TextEditingController();
  late Future<List<KantorModel>> future = LendingSetupRepository.listKantor(limit: 100);

  void find() => setState(() => future = LendingSetupRepository.listKantor(keyword: search.text.trim(), limit: 100));

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Inquiry Kantor'),
        content: SizedBox(
          width: 650,
          height: 500,
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(controller: search, autofocus: true, onSubmitted: (_) => find(), decoration: _decoration('Kode / Nama Kantor'))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: find, style: ElevatedButton.styleFrom(backgroundColor: colorPrimary), child: const Text('Cari', style: TextStyle(color: Colors.white))),
            ]),
            const SizedBox(height: 12),
            Expanded(child: FutureBuilder<List<KantorModel>>(
              future: future,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) return const Center(child: Text('Kantor tidak ditemukan.'));
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) => ListTile(
                    title: Text(rows[index].kodeKantor),
                    subtitle: Text(rows[index].namaKantor),
                    onTap: () => Navigator.pop(context, rows[index]),
                  ),
                );
              },
            )),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      );
}

class _SbbInquiryDialog extends StatefulWidget {
  const _SbbInquiryDialog();

  @override
  State<_SbbInquiryDialog> createState() => _SbbInquiryDialogState();
}

class _SbbInquiryDialogState extends State<_SbbInquiryDialog> {
  final search = TextEditingController();
  late Future<List<CoreCoaModel>> future = SavingProductRepository.searchCoa(limit: 100);

  void find() => setState(() => future = SavingProductRepository.searchCoa(keyword: search.text.trim(), limit: 100));

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Inquiry SBB / COA'),
        content: SizedBox(
          width: 700,
          height: 520,
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(controller: search, autofocus: true, onSubmitted: (_) => find(), decoration: _decoration('No SBB / Nama SBB'))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: find, style: ElevatedButton.styleFrom(backgroundColor: colorPrimary), child: const Text('Cari', style: TextStyle(color: Colors.white))),
            ]),
            const SizedBox(height: 12),
            Expanded(child: FutureBuilder<List<CoreCoaModel>>(
              future: future,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
                final rows = (snapshot.data ?? []).where((item) => item.levelCoa == 3 || item.levelCoa == null).toList();
                if (rows.isEmpty) return const Center(child: Text('SBB tidak ditemukan.'));
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) => ListTile(
                    title: Text(rows[index].kodeCoa),
                    subtitle: Text(rows[index].namaCoa),
                    onTap: () => Navigator.pop(context, rows[index]),
                  ),
                );
              },
            )),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      );
}

class RakRelasiNotifier extends ChangeNotifier {
  final BuildContext context;
  RakRelasiNotifier({required this.context}) {
    init();
  }

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
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeRateRak)) {
        current = item;
        break;
      }
    }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    canDelete = isSuperAdmin || (current?.canDelete ?? false);
    try {
      listKantor = await LendingSetupRepository.listKantor();
    } catch (_) {
      listKantor = [];
    }
    await getList();
  }

  Future<void> getList() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
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
    } catch (e) {
      list = [];
      errorMessage = e.toString();
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

  void pilihKantor(String? value) {
    kodeKantor.text = value ?? '';
    notifyListeners();
  }

  void pilihKantorLawan(String? value) {
    kodeKantorLawan.text = value ?? '';
    notifyListeners();
  }

  void clear() {
    selected = null;
    editData = false;
    kodeKantor.clear();
    kodeKantorLawan.clear();
    rate.clear();
  }

  void edit(RakRelasiModel value) {
    if (!canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update Rate RAK.');
      return;
    }
    selected = value;
    editData = true;
    dialog = true;
    kodeKantor.text = value.kodeKantor;
    kodeKantorLawan.text = value.kodeKantorLawan;
    rate.text = _numText(value.rate);
    notifyListeners();
  }

  Future<void> save() async {
    final rateValue = double.tryParse(rate.text.trim().replaceAll(',', '.'));
    if (kodeKantor.text.trim().isEmpty || kodeKantorLawan.text.trim().isEmpty || rateValue == null) {
      informationDialog(context, 'Validasi', 'Kantor, kantor lawan, dan rate wajib diisi.');
      return;
    }
    if (rateValue < 0 || rateValue > 100) {
      informationDialog(context, 'Validasi', 'Rate harus antara 0 sampai 100.');
      return;
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
      dialog = false;
      clear();
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void confirmDelete(RakRelasiModel value) {
    if (!canDelete) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus Rate RAK.');
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Konfirmasi'),
              content: Text('Hapus rate RAK ${value.kodeKantor} -> ${value.kodeKantorLawan}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      delete(value);
                    },
                    child: const Text('Hapus')),
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
  void dispose() {
    filterKantor.dispose();
    filterKantorLawan.dispose();
    kodeKantor.dispose();
    kodeKantorLawan.dispose();
    rate.dispose();
    super.dispose();
  }
}

class _HeaderBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController keyword;
  final String hint;
  final VoidCallback onSearch;
  final VoidCallback? onAdd;
  final String addText;

  const _HeaderBar(
      {required this.title,
      required this.subtitle,
      required this.keyword,
      required this.hint,
      required this.onSearch,
      required this.onAdd,
      required this.addText});

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
        rows: value.list
            .map((row) => DataRow(cells: [
                  DataCell(Text(row.kodeAgunan, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(SizedBox(width: 320, child: Text(row.keterangan, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(_numText(row.bobotPengurang))),
                  DataCell(_StatusChip(code: row.statusData)),
                  DataCell(_ActionButtons(
                      canUpdate: value.canUpdate,
                      canDelete: value.canDelete,
                      onEdit: () => value.edit(row),
                      onDelete: () => value.confirmDelete(row))),
                ]))
            .toList(),
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
        rows: value.list
            .map((row) => DataRow(cells: [
                  DataCell(Text(row.coll, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(_numText(row.bobot))),
                  DataCell(Text(_numText(row.bdr))),
                  DataCell(Text(row.faktorPengurang ? 'Ya' : 'Tidak')),
                  DataCell(_StatusChip(code: row.statusData)),
                  DataCell(_ActionButtons(
                      canUpdate: value.canUpdate,
                      canDelete: value.canDelete,
                      onEdit: () => value.edit(row),
                      onDelete: () => value.confirmDelete(row))),
                ]))
            .toList(),
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
        rows: value.list
            .map((row) => DataRow(cells: [
                  DataCell(Text(row.kodeKantor, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(row.kodeKantorLawan)),
                  DataCell(Text(_numText(row.rate))),
                  DataCell(_StatusChip(code: row.statusData)),
                  DataCell(_ActionButtons(
                      canUpdate: value.canUpdate,
                      canDelete: value.canDelete,
                      onEdit: () => value.edit(row),
                      onDelete: () => value.confirmDelete(row))),
                ]))
            .toList(),
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
        _textField('Kode Agunan', value.kodeAgunan,
            required: true, readOnly: value.editData, maxLength: 40, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-]'))]),
        _textField('Keterangan', value.keterangan, required: true, maxLength: 200),
        _textField('Bobot Pengurang', value.bobotPengurang,
            required: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: const [PercentageInputFormatter()]),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: value.save,
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(120, 48)),
            child: Text(value.editData ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white))),
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
        _textField(
          'Collateral',
          value.coll,
          required: true,
          readOnly: value.editData,
          maxLength: 1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[1-5]'))],
        ),
        _textField('Bobot (%)', value.bobot,
            required: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: const [PercentageInputFormatter()]),
        _textField('BDR', value.bdr,
            required: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: const [PercentageInputFormatter()]),
        CheckboxListTile(
          value: value.faktorPengurang,
          onChanged: value.pilihFaktor,
          contentPadding: EdgeInsets.zero,
          title: const Text('Faktor Pengurang'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: value.save,
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(120, 48)),
            child: Text(value.editData ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white))),
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
        _KantorDropdown(
            label: 'Kantor', value: value.kodeKantor.text, list: value.listKantor, onChanged: value.pilihKantor, enabled: !value.editData),
        const SizedBox(height: 14),
        _KantorDropdown(
            label: 'Kantor Lawan',
            value: value.kodeKantorLawan.text,
            list: value.listKantor,
            onChanged: value.pilihKantorLawan,
            enabled: !value.editData),
        const SizedBox(height: 14),
        _textField('Rate', value.rate,
            required: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: const [PercentageInputFormatter()]),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: value.save,
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(120, 48)),
            child: Text(value.editData ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white))),
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
          ElevatedButton(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
              child: const Text('Edit', style: TextStyle(color: Colors.white))),
        if (canUpdate && canDelete) const SizedBox(width: 8),
        if (canDelete)
          ElevatedButton(
              onPressed: onDelete,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white))),
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
    final color = upper == 'A'
        ? Colors.green
        : upper == 'D'
            ? Colors.red
            : Colors.grey;
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

InputDecoration _decoration(String label) =>
    InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), counterText: '');

String _numText(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

String _rakRateText(dynamic value) {
  final number = double.tryParse(value?.toString() ?? '');
  if (number == null) return '';
  return _numText(number);
}
