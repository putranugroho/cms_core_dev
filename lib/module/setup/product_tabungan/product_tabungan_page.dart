import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/menu/menu_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:accounting_kantor_gl_useraccess/repository/saving_product_repository.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:accounting_kantor_gl_useraccess/utils/dialog_loading.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ProductTabunganPage extends StatelessWidget {
  const ProductTabunganPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductTabunganNotifier(context: context),
      child: Consumer<ProductTabunganNotifier>(
        builder: (context, value, _) => SafeArea(
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Toolbar(value: value),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(child: Text(value.errorMessage!))
                              : _ProductTable(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _ProductForm(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductTabunganNotifier extends ChangeNotifier {
  final BuildContext context;

  ProductTabunganNotifier({required this.context}) {
    init();
  }

  final formKey = GlobalKey<FormState>();
  final keyword = TextEditingController();
  final Map<String, TextEditingController> controllers = {};

  List<SavingProductModel> list = [];
  SavingProductModel? selected;
  bool isLoading = true;
  bool dialog = false;
  bool editData = false;
  String? errorMessage;
  int step = 0;

  bool isSuperAdmin = false;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  String filterJenisTabungan = '';
  String filterStatusData = 'A';

  String jenisTabungan = 'Reguler';
  String dasarPerhitunganBunga = 'Saldo Harian';
  String metodePembukuanBunga = 'Cash Basis';
  String hitungBungaDibulatkan = 'YA';
  String tipeRate = 'STATIK';
  String saldoHitungPajak = 'SALDO AKHIR';
  String caraHitungPajak = 'Harian';
  String aksiLebihFrekuensi = '';

  final Map<String, bool> bools = {
    'saldo_bawah_min_otomatis_tutup': false,
    'saldo_nihil_otomatis_tutup': false,
    'frekuensi_penarikan_dibatasi': false,
    'bl_digital': false,
    'ba_bulanan': false,
    'kena_biaya_min_pasif': false,
    'pasif_perlu_otorisasi': false,
    'diasuransikan': false,
    'tabungan_berjangka': false,
    'gunakan_tabel_jangka_waktu': false,
    'denda_penarikan_sebelum_jatuh_tempo': false,
    'jatuh_tempo_alihkan_ke_sbb': false,
    'jatuh_tempo_bunga_distop': false,
    'penarikan_tutup_otomatis': false,
    'penutupan_nasabah_bunga_dibayar': false,
  };

  final List<String> steps = const [
    'Identitas & Setoran',
    'Bunga',
    'Pajak',
    'Penarikan',
    'Biaya',
    'Pasif',
    'Asuransi',
    'Tabungan Berjangka',
    'SBB / COA',
  ];

  static const decimalKeys = {
    'min_setoran_pertama',
    'min_setoran_berikutnya',
    'saldo_minimum',
    'kelipatan_setoran',
    'maks_saldo_tidak_kena_pajak',
    'rate_bunga',
    'rate_pajak',
    'maks_penarikan_tunai_perhari',
    'denda_maks_penarikan_persen',
    'nominal_denda_penarikan',
    'biaya_admin_bulanan',
    'biaya_penutupan',
    'biaya_pergantian_buku',
    'biaya_cetak_rekening_koran',
    'biaya_rekening_pasif',
    'min_saldo_kena_biaya_pasif',
    'biaya_dibawah_saldo_min',
    'premi_asuransi_per_tahun',
    'min_perpanjangan_premi_otomatis',
    'nominal_denda_jatuh_tempo',
  };

  static const intKeys = {
    'grace_periode_bawah_min',
    'grace_periode_nihil',
    'tgl_pembukuan_bunga',
    'faktor_pembagi',
    'frekuensi_maks_tarik_tunai',
    'hari_tidak_bertransaksi_pasif',
    'jangka_waktu_bulan',
  };

  static const textKeys = {
    'kode_produk',
    'nama_produk',
    'sbb_tabungan',
    'sbb_biaya_bunga',
    'sbb_accrual_biaya_bunga',
    'sbb_pendapatan_administrasi',
    'sbb_pendapatan_biaya_penutupan',
    'sbb_titipan_pajak',
    'sbb_pendapatan_rekening_pasif',
    'sbb_denda_maks_penarikan',
    'sbb_denda_penarikan',
    'sbb_denda_jatuh_tempo',
    'sbb_penampungan',
    'sbb_biaya_asuransi',
    'sbb_titipan_asuransi_tabungan',
    'nomor_sbb_jatuh_tempo',
  };

  Future<void> init() async {
    final pref = Pref();
    isSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeProductTabungan)) {
        current = item;
        break;
      }
    }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    canDelete = isSuperAdmin || (current?.canDelete ?? false);
    _initControllers();
    await getProducts();
  }

  void _initControllers() {
    for (final key in {...textKeys, ...decimalKeys, ...intKeys}) {
      controllers.putIfAbsent(key, () => TextEditingController(text: _defaultValue(key)));
    }
  }

  String _defaultValue(String key) {
    switch (key) {
      case 'faktor_pembagi':
        return '360';
      case 'tgl_pembukuan_bunga':
        return '1';
      case 'kode_produk':
      case 'nama_produk':
        return '';
      default:
        return decimalKeys.contains(key) || intKeys.contains(key) ? '0' : '';
    }
  }

  TextEditingController c(String key) {
    return controllers.putIfAbsent(key, () => TextEditingController(text: _defaultValue(key)));
  }

  Future<void> getProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      list = await SavingProductRepository.list(
        keyword: keyword.text.trim(),
        jenisTabungan: filterJenisTabungan,
        statusData: filterStatusData,
        limit: 100,
      );
      list.sort((a, b) => a.kodeProduk.compareTo(b.kodeProduk));
    } catch (e) {
      list = [];
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void pilihFilterJenis(String? value) {
    filterJenisTabungan = value ?? '';
    notifyListeners();
  }

  void pilihFilterStatus(String? value) {
    filterStatusData = value ?? '';
    notifyListeners();
  }

  void pilihJenisTabungan(String? value) {
    jenisTabungan = value ?? 'Reguler';
    final berjangka = jenisTabungan.toLowerCase().contains('berjangka');
    bools['tabungan_berjangka'] = berjangka;
    notifyListeners();
  }

  void setString(String key, String? value) {
    switch (key) {
      case 'dasar_perhitungan_bunga':
        dasarPerhitunganBunga = value ?? '';
        break;
      case 'metode_pembukuan_bunga':
        metodePembukuanBunga = value ?? '';
        break;
      case 'hitung_bunga_dibulatkan':
        hitungBungaDibulatkan = value ?? '';
        break;
      case 'tipe_rate':
        tipeRate = value ?? 'STATIK';
        break;
      case 'saldo_hitung_pajak':
        saldoHitungPajak = value ?? '';
        break;
      case 'cara_hitung_pajak':
        caraHitungPajak = value ?? '';
        break;
      case 'aksi_lebih_frekuensi':
        aksiLebihFrekuensi = value ?? '';
        break;
    }
    notifyListeners();
  }

  void setBool(String key, bool? value) {
    bools[key] = value ?? false;
    notifyListeners();
  }

  void tambah() {
    if (!canCreate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses tambah produk tabungan.');
      return;
    }
    clear();
    dialog = true;
    notifyListeners();
  }

  Future<void> edit(SavingProductModel value) async {
    if (!canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update produk tabungan.');
      return;
    }

    try {
      DialogCustom().showLoading(context);
      selected = await SavingProductRepository.detail(value.kodeProduk);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
      selected = value;
    }

    clear(keepSelected: true);
    _fillFromMap(selected!.raw);
    editData = true;
    dialog = true;
    notifyListeners();
  }

  void tutup() {
    dialog = false;
    notifyListeners();
  }

  void nextStep() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (step < steps.length - 1) {
      step++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (step > 0) {
      step--;
      notifyListeners();
    }
  }

  void goStep(int value) {
    step = value;
    notifyListeners();
  }

  void clear({bool keepSelected = false}) {
    if (!keepSelected) selected = null;
    editData = false;
    step = 0;
    jenisTabungan = 'Reguler';
    dasarPerhitunganBunga = 'Saldo Harian';
    metodePembukuanBunga = 'Cash Basis';
    hitungBungaDibulatkan = 'YA';
    tipeRate = 'STATIK';
    saldoHitungPajak = 'SALDO AKHIR';
    caraHitungPajak = 'Harian';
    aksiLebihFrekuensi = '';
    for (final key in controllers.keys) {
      controllers[key]!.text = _defaultValue(key);
    }
    for (final key in bools.keys) {
      bools[key] = false;
    }
  }

  void _fillFromMap(Map<String, dynamic> data) {
    for (final key in controllers.keys) {
      if (data.containsKey(key) && data[key] != null) {
        controllers[key]!.text = data[key].toString();
      }
    }
    jenisTabungan = _str(data['jenis_tabungan'], jenisTabungan);
    dasarPerhitunganBunga = _str(data['dasar_perhitungan_bunga'], dasarPerhitunganBunga);
    metodePembukuanBunga = _str(data['metode_pembukuan_bunga'], metodePembukuanBunga);
    hitungBungaDibulatkan = _str(data['hitung_bunga_dibulatkan'], hitungBungaDibulatkan);
    tipeRate = _str(data['tipe_rate'], tipeRate);
    saldoHitungPajak = _str(data['saldo_hitung_pajak'], saldoHitungPajak);
    caraHitungPajak = _str(data['cara_hitung_pajak'], caraHitungPajak);
    aksiLebihFrekuensi = _str(data['aksi_lebih_frekuensi'], aksiLebihFrekuensi);
    for (final key in bools.keys) {
      bools[key] = _bool(data[key]);
    }
  }

  String _str(dynamic value, String def) => value == null || value.toString().isEmpty ? def : value.toString();

  bool _bool(dynamic value) {
    if (value is bool) return value;
    final text = (value ?? '').toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'y' || text == 'yes';
  }

  double _decimal(String key) {
    final text = c(key).text.replaceAll(',', '').trim();
    return double.tryParse(text) ?? 0;
  }

  int _int(String key) {
    final text = c(key).text.replaceAll(',', '').trim();
    return int.tryParse(text) ?? 0;
  }

  Map<String, dynamic> buildBody() {
    final body = <String, dynamic>{
      'kode_produk': c('kode_produk').text.trim().toUpperCase(),
      'nama_produk': c('nama_produk').text.trim(),
      'jenis_tabungan': jenisTabungan,
      'dasar_perhitungan_bunga': dasarPerhitunganBunga,
      'metode_pembukuan_bunga': metodePembukuanBunga,
      'hitung_bunga_dibulatkan': hitungBungaDibulatkan,
      'tipe_rate': tipeRate,
      'saldo_hitung_pajak': saldoHitungPajak,
      'cara_hitung_pajak': caraHitungPajak,
      'aksi_lebih_frekuensi': aksiLebihFrekuensi,
    };
    for (final key in decimalKeys) {
      body[key] = _decimal(key);
    }
    for (final key in intKeys) {
      body[key] = _int(key);
    }
    for (final key in textKeys) {
      if (key != 'kode_produk' && key != 'nama_produk') body[key] = c(key).text.trim();
    }
    body.addAll(bools);
    return body;
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (editData && !canUpdate) return;
    if (!editData && !canCreate) return;

    DialogCustom().showLoading(context);
    try {
      await SavingProductRepository.save(isEdit: editData, body: buildBody());
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', editData ? 'Produk tabungan berhasil diupdate.' : 'Produk tabungan berhasil ditambahkan.');
      dialog = false;
      clear();
      await getProducts();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void confirmDelete(SavingProductModel value) {
    if (!canDelete) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus produk tabungan.');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Anda yakin menghapus produk ${value.kodeProduk} - ${value.namaProduk}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              delete(value);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> delete(SavingProductModel value) async {
    DialogCustom().showLoading(context);
    try {
      await SavingProductRepository.delete(value.kodeProduk);
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'Produk tabungan berhasil dihapus.');
      await getProducts();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  void dispose() {
    keyword.dispose();
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class _Toolbar extends StatelessWidget {
  final ProductTabunganNotifier value;

  const _Toolbar({required this.value});

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
                Text('Produk Tabungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Master produk tabungan, bunga, pajak, biaya, denda, dan SBB COA', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              controller: value.keyword,
              onSubmitted: (_) => value.getProducts(),
              decoration: InputDecoration(
                hintText: 'Cari kode / nama produk',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              value: value.filterJenisTabungan,
              decoration: _decoration('Jenis'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua Jenis')),
                DropdownMenuItem(value: 'Reguler', child: Text('Reguler')),
                DropdownMenuItem(value: 'Berjangka', child: Text('Berjangka')),
              ],
              onChanged: value.pilihFilterJenis,
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: value.filterStatusData,
              decoration: _decoration('Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua')),
                DropdownMenuItem(value: 'A', child: Text('Aktif')),
                DropdownMenuItem(value: 'D', child: Text('Hapus')),
              ],
              onChanged: value.pilihFilterStatus,
            ),
          ),
          ElevatedButton(
            onPressed: value.getProducts,
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
            child: const Text('Cari', style: TextStyle(color: Colors.white)),
          ),
          if (value.canCreate)
            ElevatedButton.icon(
              onPressed: value.tambah,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Produk', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(150, 50)),
            ),
        ],
      ),
    );
  }
}

class _ProductTable extends StatelessWidget {
  final ProductTabunganNotifier value;

  const _ProductTable({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) return const Center(child: Text('Tidak ada data produk tabungan.'));
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
              DataColumn(label: Text('Kode Produk')),
              DataColumn(label: Text('Nama Produk')),
              DataColumn(label: Text('Jenis')),
              DataColumn(label: Text('Tipe Rate')),
              DataColumn(label: Text('Rate Bunga')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Created By')),
              DataColumn(label: Text('Created At')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: value.list.map((data) {
              return DataRow(cells: [
                DataCell(Text(data.kodeProduk, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(SizedBox(width: 260, child: Text(data.namaProduk, overflow: TextOverflow.ellipsis))),
                DataCell(Text(data.jenisTabungan.isEmpty ? '-' : data.jenisTabungan)),
                DataCell(Text(data.tipeRate)),
                DataCell(Text('${data.rateBunga}%')),
                DataCell(_StatusChip(text: data.statusText, code: data.statusData)),
                DataCell(Text(data.createdBy)),
                DataCell(Text(data.createdAt)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (value.canUpdate)
                        ElevatedButton(
                          onPressed: () => value.edit(data),
                          style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                          child: const Text('Edit', style: TextStyle(color: Colors.white)),
                        ),
                      if (value.canUpdate && value.canDelete) const SizedBox(width: 8),
                      if (value.canDelete)
                        ElevatedButton(
                          onPressed: () => value.confirmDelete(data),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                        ),
                    ],
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

class _ProductForm extends StatelessWidget {
  final ProductTabunganNotifier value;

  const _ProductForm({required this.value});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        alignment: Alignment.centerRight,
        child: Container(
          width: 1100,
          height: double.infinity,
          color: Colors.white,
          child: Form(
            key: value.formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value.editData ? 'Edit Produk Tabungan' : 'Tambah Produk Tabungan',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(onPressed: value.tutup, icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 250, child: _StepNavigation(value: value)),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _stepContent(),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(onPressed: value.step == 0 ? null : value.previousStep, child: const Text('Back')),
                      const SizedBox(width: 8),
                      OutlinedButton(onPressed: value.step >= value.steps.length - 1 ? null : value.nextStep, child: const Text('Next')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: value.save,
                        style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                        child: Text(value.editData ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepContent() {
    switch (value.step) {
      case 0:
        return _SectionCard(
          title: 'Identitas Produk, Setoran, dan Saldo',
          children: [
            _text('Kode Produk', 'kode_produk', required: true, maxLength: 20, readOnly: value.editData, uppercase: true),
            _text('Nama Produk', 'nama_produk', required: true, maxLength: 200),
            _dropdown('Jenis Tabungan', value.jenisTabungan, const ['Reguler', 'Berjangka'], value.pilihJenisTabungan),
            _number('Minimal Setoran Pertama', 'min_setoran_pertama'),
            _number('Minimal Setoran Berikutnya', 'min_setoran_berikutnya'),
            _number('Saldo Minimum Rekening', 'saldo_minimum'),
            _number('Kelipatan Setoran', 'kelipatan_setoran'),
            _number('Maks Saldo Tidak Kena Pajak', 'maks_saldo_tidak_kena_pajak'),
            _check('Saldo < Minimum Otomatis Tutup', 'saldo_bawah_min_otomatis_tutup'),
            _integer('Grace Periode Bawah Min (hari)', 'grace_periode_bawah_min'),
            _check('Saldo Nihil Otomatis Tutup', 'saldo_nihil_otomatis_tutup'),
            _integer('Grace Periode Nihil (hari)', 'grace_periode_nihil'),
          ],
        );
      case 1:
        return _SectionCard(
          title: 'Perhitungan Bunga',
          children: [
            _dropdown('Dasar Perhitungan Bunga', value.dasarPerhitunganBunga, const ['Saldo Harian', 'Saldo Rata-rata', 'Saldo Minimum', 'Saldo Minimum Harian'], (v) => value.setString('dasar_perhitungan_bunga', v)),
            _dropdown('Metode Pembukuan Bunga', value.metodePembukuanBunga, const ['Cash Basis', 'Accrual Harian', 'Accrual Bulanan'], (v) => value.setString('metode_pembukuan_bunga', v)),
            _integer('Tgl Pembukuan Bunga', 'tgl_pembukuan_bunga'),
            _integer('Faktor Pembagi', 'faktor_pembagi'),
            _dropdown('Hitung Bunga Dibulatkan', value.hitungBungaDibulatkan, const ['YA', 'TIDAK'], (v) => value.setString('hitung_bunga_dibulatkan', v)),
            _dropdown('Tipe Rate', value.tipeRate, const ['STATIK', 'PROGRESIF'], (v) => value.setString('tipe_rate', v)),
            _number('Rate Bunga Default (%)', 'rate_bunga'),
          ],
        );
      case 2:
        return _SectionCard(
          title: 'Pajak',
          children: [
            _number('Rate Pajak (%)', 'rate_pajak'),
            _dropdown('Saldo Hitung Pajak', value.saldoHitungPajak, const ['SALDO AKHIR', 'SALDO RATA-RATA'], (v) => value.setString('saldo_hitung_pajak', v)),
            _dropdown('Cara Hitung Pajak', value.caraHitungPajak, const ['Proportional', 'Harian', 'Bulanan'], (v) => value.setString('cara_hitung_pajak', v)),
          ],
        );
      case 3:
        return _SectionCard(
          title: 'Penarikan Tunai',
          children: [
            _number('Maks Penarikan Tunai Per Hari', 'maks_penarikan_tunai_perhari'),
            _number('Denda Maks Penarikan (%)', 'denda_maks_penarikan_persen'),
            _check('Frekuensi Penarikan Dibatasi', 'frekuensi_penarikan_dibatasi'),
            _integer('Frekuensi Maks Tarik Tunai', 'frekuensi_maks_tarik_tunai'),
            _dropdown('Aksi Lebih Frekuensi', value.aksiLebihFrekuensi, const ['', 'REJECT', 'PENDING', 'DENDA'], (v) => value.setString('aksi_lebih_frekuensi', v)),
            _number('Nominal Denda Penarikan', 'nominal_denda_penarikan'),
          ],
        );
      case 4:
        return _SectionCard(
          title: 'Biaya Produk Tabungan',
          children: [
            _number('Biaya Admin Bulanan', 'biaya_admin_bulanan'),
            _number('Biaya Penutupan', 'biaya_penutupan'),
            _number('Biaya Pergantian Buku', 'biaya_pergantian_buku'),
            _number('Biaya Cetak Rekening Koran', 'biaya_cetak_rekening_koran'),
            _number('Biaya Rekening Pasif', 'biaya_rekening_pasif'),
            _number('Min Saldo Kena Biaya Pasif', 'min_saldo_kena_biaya_pasif'),
            _check('Biaya Layanan Digital', 'bl_digital'),
            _check('Biaya Administrasi Bulanan', 'ba_bulanan'),
            _number('Biaya Dibawah Saldo Minimum', 'biaya_dibawah_saldo_min'),
            _check('Kena Biaya Min Pasif', 'kena_biaya_min_pasif'),
          ],
        );
      case 5:
        return _SectionCard(
          title: 'Rekening Pasif',
          children: [
            _integer('Hari Tidak Bertransaksi Pasif', 'hari_tidak_bertransaksi_pasif'),
            _check('Pasif Perlu Otorisasi', 'pasif_perlu_otorisasi'),
          ],
        );
      case 6:
        return _SectionCard(
          title: 'Asuransi Tabungan',
          children: [
            _check('Diasuransikan', 'diasuransikan'),
            _number('Premi Asuransi Per Tahun', 'premi_asuransi_per_tahun'),
            _number('Min Perpanjangan Premi Otomatis', 'min_perpanjangan_premi_otomatis'),
          ],
        );
      case 7:
        return _SectionCard(
          title: 'Tabungan Berjangka',
          children: [
            _check('Tabungan Berjangka', 'tabungan_berjangka'),
            _integer('Jangka Waktu Bulan', 'jangka_waktu_bulan'),
            _check('Gunakan Tabel Jangka Waktu', 'gunakan_tabel_jangka_waktu'),
            _check('Denda Penarikan Sebelum JT', 'denda_penarikan_sebelum_jatuh_tempo'),
            _number('Nominal Denda Jatuh Tempo', 'nominal_denda_jatuh_tempo'),
            _check('JT Alihkan ke SBB', 'jatuh_tempo_alihkan_ke_sbb'),
            _check('JT Bunga Distop', 'jatuh_tempo_bunga_distop'),
            _check('Penarikan Tutup Otomatis', 'penarikan_tutup_otomatis'),
            _check('Penutupan Nasabah Bunga Dibayar', 'penutupan_nasabah_bunga_dibayar'),
          ],
        );
      default:
        return _SectionCard(
          title: 'Setup SBB / COA Produk Tabungan',
          children: [
            _text('SBB Tabungan', 'sbb_tabungan'),
            _text('SBB Biaya Bunga', 'sbb_biaya_bunga'),
            _text('SBB Accrual Biaya Bunga', 'sbb_accrual_biaya_bunga'),
            _text('SBB Pendapatan Administrasi', 'sbb_pendapatan_administrasi'),
            _text('SBB Pendapatan Biaya Penutupan', 'sbb_pendapatan_biaya_penutupan'),
            _text('SBB Titipan Pajak', 'sbb_titipan_pajak'),
            _text('SBB Pendapatan Rekening Pasif', 'sbb_pendapatan_rekening_pasif'),
            _text('SBB Denda Maks Penarikan', 'sbb_denda_maks_penarikan'),
            _text('SBB Denda Penarikan', 'sbb_denda_penarikan'),
            _text('SBB Denda Jatuh Tempo', 'sbb_denda_jatuh_tempo'),
            _text('SBB Penampungan', 'sbb_penampungan'),
            _text('SBB Biaya Asuransi', 'sbb_biaya_asuransi'),
            _text('SBB Titipan Asuransi Tabungan', 'sbb_titipan_asuransi_tabungan'),
            _text('Nomor SBB Jatuh Tempo', 'nomor_sbb_jatuh_tempo'),
          ],
        );
    }
  }

  Widget _text(String label, String key, {bool required = false, int? maxLength, bool readOnly = false, bool uppercase = false}) {
    return TextFormField(
      controller: value.c(key),
      readOnly: readOnly,
      maxLength: maxLength,
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
      inputFormatters: uppercase ? [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]'))] : null,
      validator: (v) {
        final text = (v ?? '').trim();
        if (required && text.isEmpty) return 'Wajib diisi';
        if (maxLength != null && text.length > maxLength) return 'Maksimal $maxLength karakter';
        return null;
      },
      decoration: _decoration(label),
    );
  }

  Widget _number(String label, String key) {
    return TextFormField(
      controller: value.c(key),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]'))],
      decoration: _decoration(label),
    );
  }

  Widget _integer(String label, String key) {
    return TextFormField(
      controller: value.c(key),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _decoration(label),
    );
  }

  Widget _dropdown(String label, String selected, List<String> items, ValueChanged<String?> onChanged) {
    final valueSelected = items.contains(selected) ? selected : items.first;
    return DropdownButtonFormField<String>(
      value: valueSelected,
      decoration: _decoration(label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.isEmpty ? '-' : e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _check(String label, String key) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value.bools[key] ?? false,
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (v) => value.setBool(key, v),
    );
  }
}

class _StepNavigation extends StatelessWidget {
  final ProductTabunganNotifier value;

  const _StepNavigation({required this.value});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Step Produk Tabungan', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(value.steps.length, (i) {
            final selected = i == value.step;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => value.goStep(i),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: selected ? colorPrimary : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '${i + 1}. ${value.steps[i]}',
                    style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(spacing: 16, runSpacing: 12, children: children.map((e) => SizedBox(width: 320, child: e)).toList()),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final String code;

  const _StatusChip({required this.text, required this.code});

  @override
  Widget build(BuildContext context) {
    final active = code.toUpperCase() == 'A';
    final color = active ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

InputDecoration _decoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    counterText: '',
  );
}
