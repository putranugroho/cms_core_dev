import 'dart:math';

import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/kategori_agunan_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Kategori bawaan: form detailnya sudah ada di CSR, jadi hanya ditampilkan
/// dan tidak bisa diubah atau dihapus. Kode sama dengan kelompok_agunan backend.
const Map<String, String> kategoriBawaan = {
  'KENDARAAN': 'Kendaraan',
  'TANAH': 'Tanah',
  'TANAH_BANGUNAN': 'Tanah & Bangunan',
  'DEPOSITO': 'Deposito',
};

/// Setup kategori agunan custom: definisi field untuk form Agunan di CSR.
/// Data di /setup/request-kategori, kode berawalan AGN-.
class KategoriAgunanPage extends StatelessWidget {
  const KategoriAgunanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KategoriAgunanNotifier(context: context),
      child: Consumer<KategoriAgunanNotifier>(
        builder: (context, value, _) => SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(value: value),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(value.errorMessage!, textAlign: TextAlign.center),
                                  ),
                                )
                              : _Tabel(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _Form(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KategoriAgunanNotifier extends ChangeNotifier {
  final BuildContext context;
  KategoriAgunanNotifier({required this.context}) {
    init();
  }

  final keyword = TextEditingController();
  final kode = TextEditingController();
  final nama = TextEditingController();

  List<KategoriAgunanModel> list = [];
  List<FieldKategori> fields = [];
  // Key field yang sudah tersimpan di backend: dihapus = ditandai nonaktif.
  Set<String> keyTersimpan = {};
  bool isLoading = true;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  Future<void> init() async {
    final pref = Pref();
    final superAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeKategoriAgunan)) {
        current = item;
        break;
      }
    }
    canCreate = superAdmin || (current?.canCreate ?? false);
    canUpdate = superAdmin || (current?.canUpdate ?? false);
    canDelete = superAdmin || (current?.canDelete ?? false);
    await getList();
  }

  Future<void> getList() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      list = await KategoriAgunanRepository.list(keyword: keyword.text);
      list.sort((a, b) => a.kode.compareTo(b.kode));
    } catch (e) {
      list = [];
      errorMessage = _pesan(e);
    }
    isLoading = false;
    notifyListeners();
  }

  static String kunciBaru() {
    final r = Random();
    return 'f${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${r.nextInt(1 << 20).toRadixString(36)}';
  }

  void tambah() {
    editData = false;
    kode.clear();
    nama.clear();
    keyTersimpan = {};
    fields = [FieldKategori(key: kunciBaru())];
    dialog = true;
    notifyListeners();
  }

  void tutup() {
    dialog = false;
    notifyListeners();
  }

  Future<void> edit(KategoriAgunanModel row) async {
    DialogCustom().showLoading(context);
    try {
      final d = await KategoriAgunanRepository.detail(row.kode);
      if (context.mounted) Navigator.pop(context);
      editData = true;
      kode.text = d.kodePendek;
      nama.text = d.nama;
      fields = d.fields;
      keyTersimpan = d.fields.map((e) => e.key).toSet();
      dialog = true;
      notifyListeners();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) informationDialog(context, 'Warning', _pesan(e));
    }
  }

  void tambahField() {
    fields.add(FieldKategori(key: kunciBaru()));
    notifyListeners();
  }

  /// Field baru dibuang; field tersimpan hanya dinonaktifkan supaya nomornya tetap.
  void hapusField(FieldKategori f) {
    if (keyTersimpan.contains(f.key)) {
      f.nonaktif = true;
    } else {
      fields.remove(f);
    }
    notifyListeners();
  }

  void aktifkanField(FieldKategori f) {
    f.nonaktif = false;
    notifyListeners();
  }

  void ubah(VoidCallback aksi) {
    aksi();
    notifyListeners();
  }

  String? _validasi() {
    final k = kode.text.trim();
    if (k.isEmpty) return 'Kode kategori wajib diisi.';
    if (nama.text.trim().isEmpty) return 'Nama kategori wajib diisi.';
    final aktif = fields.where((f) => !f.nonaktif).toList();
    if (aktif.isEmpty) return 'Minimal satu field aktif.';
    if (fields.length > 100) return 'Maksimal 100 field (termasuk field nonaktif).';
    final label = <String>{};
    for (final f in aktif) {
      final l = f.label.trim();
      if (l.isEmpty) return 'Semua field aktif harus punya label.';
      if (!label.add(l.toLowerCase())) return 'Label "$l" dipakai lebih dari sekali.';
      final opsi = f.opsi.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (f.butuhOpsi && opsi.isEmpty) return 'Field "$l" (${labelTipeField[f.tipe]}) butuh minimal satu pilihan.';
      if (f.tipe == 'checkbox' && opsi.length > maksOpsiCheckbox) return 'Field "$l": checkbox maksimal $maksOpsiCheckbox pilihan.';
    }
    return null;
  }

  Future<void> save() async {
    final err = _validasi();
    if (err != null) {
      informationDialog(context, 'Validasi', err);
      return;
    }
    final kodeLengkap = '$awalanKategoriAgunan${kode.text.trim().toUpperCase()}';
    DialogCustom().showLoading(context);
    try {
      await KategoriAgunanRepository.simpan(isEdit: editData, kode: kodeLengkap, nama: nama.text.trim(), fields: fields);
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        informationDialog(context, 'Informasi', editData ? 'Kategori berhasil diupdate.' : 'Kategori berhasil ditambahkan.');
      }
      dialog = false;
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) informationDialog(context, 'Warning', _pesan(e));
    }
  }

  void confirmDelete(KategoriAgunanModel row) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          'Hapus kategori ${row.kode} - ${row.nama}?\n\n'
          'Kategori tidak bisa dipilih lagi untuk agunan baru. Agunan yang sudah memakai kategori ini '
          'tidak dapat menampilkan field custom-nya selama backend hanya mengembalikan kategori aktif.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              delete(row);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> delete(KategoriAgunanModel row) async {
    DialogCustom().showLoading(context);
    try {
      await KategoriAgunanRepository.hapus(row.kode);
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) informationDialog(context, 'Informasi', 'Kategori berhasil dihapus.');
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) informationDialog(context, 'Warning', _pesan(e));
    }
  }

  static String _pesan(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    keyword.dispose();
    kode.dispose();
    nama.dispose();
    super.dispose();
  }
}

class _Header extends StatelessWidget {
  final KategoriAgunanNotifier value;
  const _Header({required this.value});

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
          const SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kategori Agunan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('4 kategori bawaan (terkunci) dan kategori custom', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          SizedBox(
            width: 280,
            child: TextField(
              controller: value.keyword,
              onSubmitted: (_) => value.getList(),
              decoration: InputDecoration(
                hintText: 'Cari nama kategori',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
              label: const Text('Tambah Kategori', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(140, 50)),
            ),
        ],
      ),
    );
  }
}

class _Tabel extends StatelessWidget {
  final KategoriAgunanNotifier value;
  const _Tabel({required this.value});

  @override
  Widget build(BuildContext context) {
    final cari = value.keyword.text.trim().toLowerCase();
    final bawaan = kategoriBawaan.entries.where((e) => cari.isEmpty || e.value.toLowerCase().contains(cari) || e.key.toLowerCase().contains(cari)).toList();
    if (bawaan.isEmpty && value.list.isEmpty) return const Center(child: Text('Kategori agunan tidak ditemukan.'));
    // Tabel minimal selebar area konten supaya kolom terbagi sampai kanan;
    // di layar sempit tetap bisa digeser ke samping.
    return LayoutBuilder(
      builder: (context, box) => Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth - 40),
              child: DataTable(
                columnSpacing: 32,
                headingRowColor: MaterialStateProperty.all(colorPrimary),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                columns: const [
                  DataColumn(label: Text('Kode')),
                  DataColumn(label: Text('Nama Kategori')),
                  DataColumn(label: Text('Jumlah Field'), numeric: true),
                  DataColumn(label: Text('Dibuat')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: [
                  ...bawaan.map((e) => DataRow(
                        color: MaterialStateProperty.all(const Color(0xFFF3F5F4)),
                        cells: [
                          DataCell(Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(SizedBox(width: 220, child: Text(e.value, overflow: TextOverflow.ellipsis))),
                          const DataCell(Text('-')),
                          const DataCell(Text('-')),
                          const DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 16, color: Colors.black54),
                              SizedBox(width: 6),
                              Text('Bawaan', style: TextStyle(color: Colors.black54)),
                            ],
                          )),
                        ],
                      )),
                  ...value.list.map((row) => DataRow(cells: [
                        DataCell(Text(row.kode, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(SizedBox(width: 220, child: Text(row.nama, overflow: TextOverflow.ellipsis))),
                        DataCell(Text('${row.jumlahField}')),
                        DataCell(Text(row.createdAt)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (value.canUpdate)
                              ElevatedButton(
                                onPressed: () => value.edit(row),
                                style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                                child: const Text('Edit', style: TextStyle(color: Colors.white)),
                              ),
                            if (value.canUpdate && value.canDelete) const SizedBox(width: 8),
                            if (value.canDelete)
                              ElevatedButton(
                                onPressed: () => value.confirmDelete(row),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                              ),
                          ],
                        )),
                      ])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  final KategoriAgunanNotifier value;
  const _Form({required this.value});

  @override
  Widget build(BuildContext context) {
    final nomorAktif = <String, int>{};
    var n = 0;
    for (final f in value.fields) {
      if (!f.nonaktif) nomorAktif[f.key] = ++n;
    }
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        alignment: Alignment.centerRight,
        child: Container(
          width: 760,
          height: double.infinity,
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.editData ? 'Edit Kategori Agunan' : 'Tambah Kategori Agunan',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(onPressed: value.tutup, icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: value.kode,
                  readOnly: value.editData,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-]'))],
                  decoration: _dekorasi('Kode Kategori').copyWith(
                    prefixText: awalanKategoriAgunan,
                    helperText: value.editData ? 'Kode tidak bisa diubah.' : 'Disimpan sebagai $awalanKategoriAgunan<kode>, mis. ${awalanKategoriAgunan}MESIN.',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: value.nama,
                  maxLength: 200,
                  decoration: _dekorasi('Nama Kategori'),
                ),
                const SizedBox(height: 18),
                const Text('Field', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Field yang sudah tersimpan tidak dihapus permanen, hanya dinonaktifkan, supaya isian agunan lama tetap di kolom yang sama.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...value.fields.map((f) => _BarisField(
                      key: ValueKey(f.key),
                      value: value,
                      field: f,
                      nomor: nomorAktif[f.key],
                    )),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: value.tambahField,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Field'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: value.save,
                      style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(120, 48)),
                      child: Text(value.editData ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    TextButton(onPressed: value.tutup, child: const Text('Batal')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarisField extends StatelessWidget {
  final KategoriAgunanNotifier value;
  final FieldKategori field;
  final int? nomor;
  const _BarisField({super.key, required this.value, required this.field, required this.nomor});

  @override
  Widget build(BuildContext context) {
    final f = field;
    if (f.nonaktif) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${f.label.isEmpty ? '(tanpa label)' : f.label} — nonaktif',
                style: const TextStyle(color: Colors.black45, decoration: TextDecoration.lineThrough),
              ),
            ),
            TextButton(onPressed: () => value.aktifkanField(f), child: const Text('Aktifkan lagi')),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                child: Text('${nomor ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: f.label,
                  maxLength: 100,
                  decoration: _dekorasi('Label'),
                  onChanged: (v) => f.label = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: f.tipe,
                  decoration: _dekorasi('Tipe'),
                  items: tipeFieldKategori.map((t) => DropdownMenuItem(value: t, child: Text(labelTipeField[t] ?? t))).toList(),
                  onChanged: (v) => value.ubah(() => f.tipe = v ?? 'teks'),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(value: f.wajib, onChanged: (v) => value.ubah(() => f.wajib = v ?? false)),
                  const Text('Wajib'),
                ],
              ),
              IconButton(
                tooltip: 'Hapus field',
                onPressed: () => value.hapusField(f),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          if (f.butuhOpsi)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 18, right: 4),
              child: TextFormField(
                key: ValueKey('${f.key}-opsi'),
                initialValue: f.opsi.join(', '),
                decoration: _dekorasi(f.tipe == 'checkbox' ? 'Pilihan (pisahkan koma, maks $maksOpsiCheckbox)' : 'Pilihan (pisahkan koma)'),
                onChanged: (v) => f.opsi = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

InputDecoration _dekorasi(String label) =>
    InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), counterText: '');
