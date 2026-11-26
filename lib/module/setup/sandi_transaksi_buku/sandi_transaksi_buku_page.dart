import 'package:cms_core/models/index.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/print_setup_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SandiTransaksiBukuPage extends StatelessWidget {
  const SandiTransaksiBukuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SandiTransaksiBukuNotifier(context: context),
      child: Consumer<SandiTransaksiBukuNotifier>(
        builder: (context, value, _) => SafeArea(
          child: Scaffold(
            body: Column(
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
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Setup Kode Transaksi Buku', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Mapping kode transaksi BPR ke simbol print buku tabungan', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: value.kodeBuku,
                          maxLength: 5,
                          decoration: _decoration('Kode Buku').copyWith(counterText: ''),
                          onSubmitted: (_) => value.getList(),
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: value.keyword,
                          onChanged: (_) => value.applyLocalFilter(),
                          decoration: InputDecoration(
                            hintText: 'Cari kode / keterangan',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: value.getList,
                        style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(160, 50)),
                        child: const Text('Muat Kode Transaksi', style: TextStyle(color: Colors.white)),
                      ),
                      if (value.canSave)
                        ElevatedButton.icon(
                          onPressed: value.saveAll,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text('Simpan Semua', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(150, 50)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: value.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : value.errorMessage != null
                          ? Center(child: Text(value.errorMessage!))
                          : _MappingTable(value: value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SandiTransaksiBukuNotifier extends ChangeNotifier {
  final BuildContext context;

  SandiTransaksiBukuNotifier({required this.context}) {
    init();
  }

  static const routePath = '/setup/sandi-transaksi-buku';

  final keyword = TextEditingController();
  final kodeBuku = TextEditingController(text: '01');
  final Map<String, TextEditingController> mappingControllers = {};

  List<KodeTransaksiTabunganModel> sourceList = [];
  List<KodeTransaksiTabunganModel> filteredList = [];
  Map<String, SandiTransaksiBukuModel> existingByKode = {};

  bool isLoading = true;
  String? errorMessage;
  bool isSuperAdmin = false;
  bool canCreate = false;
  bool canUpdate = false;

  bool get canSave => isSuperAdmin || canCreate || canUpdate;

  Future<void> init() async {
    final pref = Pref();
    isSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(routePath)) {
        current = item;
        break;
      }
    }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    await getList();
  }

  Future<void> getList() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final kodeBukuText = kodeBuku.text.trim().isEmpty ? '01' : kodeBuku.text.trim();
      sourceList = await PrintSetupRepository.listKodeTransaksiTabungan(kodeBuku: kodeBukuText);
      sourceList.sort((a, b) {
        final byKode = a.kdtrn.compareTo(b.kdtrn);
        if (byKode != 0) return byKode;
        return a.keterangan.compareTo(b.keterangan);
      });

      final saved = await PrintSetupRepository.listSandiTransaksiBuku(keyword: '', statusData: '', limit: 1000);
      existingByKode = {for (final row in saved) row.kodeSandiTransaksi: row};

      _syncControllers();
      applyLocalFilter(notify: false);
    } catch (e) {
      sourceList = [];
      filteredList = [];
      existingByKode = {};
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void _syncControllers() {
    final activeKeys = <String>{};
    for (final row in sourceList) {
      activeKeys.add(row.localKey);
      final controller = mappingControllers.putIfAbsent(row.localKey, () => TextEditingController());
      if (controller.text.trim().isEmpty) {
        final saved = existingByKode[row.kdtrn];
        controller.text = row.kodePadaBuku.trim().isNotEmpty ? row.kodePadaBuku.trim() : (saved?.simbolPrint ?? '');
      }
    }
    final unused = mappingControllers.keys.where((key) => !activeKeys.contains(key)).toList();
    for (final key in unused) {
      mappingControllers.remove(key)?.dispose();
    }
  }

  void applyLocalFilter({bool notify = true}) {
    final q = keyword.text.trim().toLowerCase();
    if (q.isEmpty) {
      filteredList = List<KodeTransaksiTabunganModel>.from(sourceList);
    } else {
      filteredList = sourceList.where((row) {
        return row.kdtrn.toLowerCase().contains(q) || row.keterangan.toLowerCase().contains(q);
      }).toList();
    }
    if (notify) notifyListeners();
  }

  TextEditingController controllerFor(KodeTransaksiTabunganModel row) {
    return mappingControllers.putIfAbsent(row.localKey, () => TextEditingController(text: row.kodePadaBuku));
  }

  String existingText(KodeTransaksiTabunganModel row) {
    final saved = existingByKode[row.kdtrn];
    if (saved == null) return '-';
    if (saved.simbolPrint.trim().isEmpty) return 'Sudah tersimpan';
    return saved.simbolPrint;
  }

  Future<void> saveOne(KodeTransaksiTabunganModel row) async {
    if (!canSave) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses menyimpan mapping kode transaksi.');
      return;
    }

    final symbol = controllerFor(row).text.trim().toUpperCase();
    if (symbol.isEmpty) {
      informationDialog(context, 'Validasi', 'Kode mapping untuk ${row.kdtrn} - ${row.keterangan} wajib diisi.');
      return;
    }

    DialogCustom().showLoading(context);
    try {
      await _saveRow(row, symbol);
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'Mapping ${row.kdtrn} berhasil disimpan.');
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Future<void> saveAll() async {
    if (!canSave) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses menyimpan mapping kode transaksi.');
      return;
    }

    final rowsToSave = sourceList.where((row) => controllerFor(row).text.trim().isNotEmpty).toList();
    if (rowsToSave.isEmpty) {
      informationDialog(context, 'Validasi', 'Isi minimal 1 kode mapping terlebih dahulu.');
      return;
    }

    DialogCustom().showLoading(context);
    int success = 0;
    final errors = <String>[];
    for (final row in rowsToSave) {
      final symbol = controllerFor(row).text.trim().toUpperCase();
      try {
        await _saveRow(row, symbol);
        success++;
      } catch (e) {
        errors.add('${row.kdtrn} ${row.keterangan}: $e');
      }
    }
    if (context.mounted) Navigator.pop(context);

    await getList();
    if (errors.isEmpty) {
      informationDialog(context, 'Informasi', '$success mapping berhasil disimpan.');
    } else {
      informationDialog(context, 'Informasi', '$success mapping berhasil disimpan. ${errors.length} gagal. ${errors.take(3).join(' | ')}');
    }
  }

  Future<void> _saveRow(KodeTransaksiTabunganModel row, String symbol) async {
    final body = {
      'kode_sandi_transaksi': row.kdtrn.trim().toUpperCase(),
      'nama_sandi_transaksi': row.keterangan.trim(),
      'simbol_print': symbol,
      'keterangan': 'Kode buku ${row.kodeBuku}; source_id ${row.id}; sts_rec ${row.stsRec}',
    };

    final isEdit = existingByKode.containsKey(row.kdtrn);
    try {
      await PrintSetupRepository.saveSandiTransaksiBuku(isEdit: isEdit, body: body);
    } catch (_) {
      if (!isEdit) {
        await PrintSetupRepository.saveSandiTransaksiBuku(isEdit: true, body: body);
      } else {
        rethrow;
      }
    }
  }

  @override
  void dispose() {
    keyword.dispose();
    kodeBuku.dispose();
    for (final c in mappingControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class _MappingTable extends StatelessWidget {
  final SandiTransaksiBukuNotifier value;

  const _MappingTable({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.filteredList.isEmpty) return const Center(child: Text('Data kode transaksi belum tersedia.'));
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(colorPrimary),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            columns: const [
              DataColumn(label: Text('Kode Buku')),
              DataColumn(label: Text('KD Transaksi')),
              DataColumn(label: Text('Keterangan')),
              DataColumn(label: Text('Kode Mapping BPR')),
              DataColumn(label: Text('Existing')),
              DataColumn(label: Text('STS Rec')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: value.filteredList.map((row) {
              return DataRow(cells: [
                DataCell(Text(row.kodeBuku)),
                DataCell(Text(row.kdtrn, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(SizedBox(width: 320, child: Text(row.keterangan, overflow: TextOverflow.ellipsis))),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: value.controllerFor(row),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]'))],
                      decoration: _decoration('Kode').copyWith(isDense: true),
                    ),
                  ),
                ),
                DataCell(Text(value.existingText(row))),
                DataCell(Text(row.stsRec)),
                DataCell(
                  ElevatedButton(
                    onPressed: value.canSave ? () => value.saveOne(row) : null,
                    style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                    child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(String label) =>
    InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), counterText: '');
