import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/saving_product_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/currency_formatted.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:cms_core/utils/percentage_input_formatter.dart';
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

class _ProgressiveRateRow {
  final TextEditingController maxController;
  final TextEditingController rateController;

  _ProgressiveRateRow()
      : maxController = TextEditingController(text: '0'),
        rateController = TextEditingController(text: '0');

  void clear() {
    maxController.text = '0';
    rateController.text = '0';
  }

  void dispose() {
    maxController.dispose();
    rateController.dispose();
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
  final Map<String, String> coaNames = {};
  final List<_ProgressiveRateRow> progressiveRates = List.generate(5, (_) => _ProgressiveRateRow());

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
  String faktorPembagi = '360';
  String aksiLebihFrekuensi = '';
  String saldoTutupMode = 'saldo_minimum';

  final Map<String, bool> bools = {
    'saldo_bawah_min_otomatis_tutup': true,
    'saldo_nihil_otomatis_tutup': false,
    'frekuensi_penarikan_dibatasi': false,
    'bl_digital': false,
    'ba_bulanan': false,
    'kena_biaya_min_pasif': false,
    'pasif_perlu_otorisasi': false,
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
    'Penarikan',
    'Biaya',
    'Tabungan Berjangka',
    'SBB / COA',
  ];

  static const decimalKeys = {
    'min_setoran_pertama',
    'min_setoran_berikutnya',
    'saldo_minimum',
    'kelipatan_setoran',
    'rate_bunga',
    'maks_penarikan_tunai_perhari',
    'denda_maks_penarikan_persen',
    'nominal_denda_penarikan',
    'biaya_admin_bulanan',
    'biaya_layanan_digital',
    'biaya_penutupan',
    'biaya_pergantian_buku',
    'biaya_cetak_rekening_koran',
    'biaya_rekening_pasif',
    'min_saldo_kena_biaya_pasif',
    'biaya_dibawah_saldo_min',
    'nominal_denda_jatuh_tempo',
  };

  static const moneyKeys = {
    'min_setoran_pertama',
    'min_setoran_berikutnya',
    'saldo_minimum',
    'kelipatan_setoran',
    'maks_penarikan_tunai_perhari',
    'nominal_denda_penarikan',
    'biaya_admin_bulanan',
    'biaya_layanan_digital',
    'biaya_penutupan',
    'biaya_pergantian_buku',
    'biaya_cetak_rekening_koran',
    'biaya_rekening_pasif',
    'min_saldo_kena_biaya_pasif',
    'biaya_dibawah_saldo_min',
    'nominal_denda_jatuh_tempo',
  };

  static const intKeys = {
    'grace_periode_bawah_min',
    'grace_periode_nihil',
    'tgl_pembukuan_bunga',
    'frekuensi_maks_tarik_tunai',
    'hari_tidak_bertransaksi_pasif',
    'tgl_proses_biaya',
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
    'nomor_sbb_jatuh_tempo',
    'sbb_pendapatan_layanan_digital',
  };

  static const uiOnlyKeys = <String>{};

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
    for (final key in {...textKeys, ...decimalKeys, ...intKeys, ...uiOnlyKeys}) {
      controllers.putIfAbsent(key, () => TextEditingController(text: _defaultValue(key)));
    }
  }

  String _defaultValue(String key) {
    switch (key) {
      case 'tgl_pembukuan_bunga':
      case 'tgl_proses_biaya':
        return '99';
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
        if (tipeRate.toUpperCase() == 'PROGRESIF') {
          c('rate_bunga').text = '0';
        }
        break;
      case 'faktor_pembagi':
        faktorPembagi = value ?? '360';
        break;
      case 'aksi_lebih_frekuensi':
        aksiLebihFrekuensi = value ?? '';
        break;
    }
    notifyListeners();
  }


  bool get isProgressiveRate => tipeRate.toUpperCase() == 'PROGRESIF';

  void progressiveRateChanged() {
    notifyListeners();
  }

  double _rateRowMax(int index) {
    if (index < 0 || index >= progressiveRates.length) return 0;
    final text = cleanCurrencyInput(progressiveRates[index].maxController.text);
    return double.tryParse(text) ?? 0;
  }

  double _rateRowValue(int index) {
    if (index < 0 || index >= progressiveRates.length) return 0;
    final text = progressiveRates[index].rateController.text.replaceAll(',', '.').trim();
    return double.tryParse(text) ?? 0;
  }

  double progressiveMinimumAt(int index) {
    if (index == 0) return 0;
    final previousMax = _rateRowMax(index - 1);
    if (previousMax <= 0) return 0;
    return previousMax + 1;
  }

  String progressiveMinimumText(int index) {
    final min = progressiveMinimumAt(index);
    if (min <= 0) return '0';
    return _formatAmount(min);
  }

  String _formatAmount(double value) {
    if (value <= 0) return '0';
    return CurrencyInputFormatter().formatEditUpdate(
      const TextEditingValue(text: ''),
      TextEditingValue(text: value.toInt().toString()),
    ).text;
  }

  List<Map<String, dynamic>> buildProgressiveRates() {
    final rows = <Map<String, dynamic>>[];

    for (var i = 0; i < progressiveRates.length; i++) {
      final row = progressiveRates[i];
      final maxText = cleanCurrencyInput(row.maxController.text);
      final rateText = row.rateController.text.replaceAll(',', '.').trim();
      final rate = double.tryParse(rateText) ?? 0;
      final max = double.tryParse(maxText.isEmpty ? '0' : maxText) ?? 0;
      final empty = max <= 0 && rate <= 0;

      if (empty) continue;
      if (rate <= 0) continue;

      final min = progressiveMinimumAt(i);
      if (max > 0 && max < min) continue;

      rows.add({
        'nominal_minimum': min,
        'nominal_maksimum': max <= 0 ? 0 : max,
        'rate_bunga': rate,
      });

      // nominal_maksimum 0 berarti tidak terbatas, sehingga baris setelahnya diabaikan.
      if (max <= 0) break;
    }

    return rows;
  }

  String? validateProgressiveRates() {
    if (!isProgressiveRate) return null;

    var hasValidRow = false;

    for (var i = 0; i < progressiveRates.length; i++) {
      final row = progressiveRates[i];
      final maxText = cleanCurrencyInput(row.maxController.text);
      final rateText = row.rateController.text.replaceAll(',', '.').trim();
      final rate = double.tryParse(rateText) ?? 0;
      final max = double.tryParse(maxText.isEmpty ? '0' : maxText) ?? 0;
      final empty = max <= 0 && rate <= 0;

      if (empty) continue;

      final min = progressiveMinimumAt(i);
      if (max > 0 && max < min) {
        return 'Saldo akhir baris ${i + 1} tidak boleh lebih kecil dari saldo awal.';
      }

      if (rate <= 0) {
        return 'Rate bunga baris ${i + 1} wajib diisi jika status rate aktif.';
      }

      hasValidRow = true;

      // nominal_maksimum 0 berarti tidak terbatas, baris setelahnya tidak dipakai.
      if (max <= 0) break;
    }

    if (!hasValidRow) {
      return 'Rate progresif wajib diisi minimal 1 baris. Isi Saldo Akhir dan Rate Bunga.';
    }

    return null;
  }

  void setBool(String key, bool? value) {
    bools[key] = value ?? false;
    notifyListeners();
  }

  void setSaldoTutupMode(String? value) {
    saldoTutupMode = value ?? 'saldo_minimum';
    bools['saldo_bawah_min_otomatis_tutup'] = saldoTutupMode == 'saldo_minimum';
    bools['saldo_nihil_otomatis_tutup'] = saldoTutupMode == 'saldo_nihil';
    notifyListeners();
  }

  void pilihCoa(String key, CoreCoaModel coa) {
    c(key).text = coa.kodeCoa;
    coaNames[key] = coa.namaCoa;
    notifyListeners();
  }

  String coaDisplayText(String key) {
    final code = c(key).text.trim();
    if (code.isEmpty) return '';
    final name = coaNames[key]?.trim() ?? '';
    return name.isEmpty ? code : '$code - $name';
  }

  Future<void> _hydrateCoaNames() async {
    final sbbKeys = textKeys.where((key) => key.startsWith('sbb_') || key == 'nomor_sbb_jatuh_tempo').toList();
    final codes = <String>{
      for (final key in sbbKeys) c(key).text.trim()
    }..removeWhere((code) => code.isEmpty);

    if (codes.isEmpty) return;

    try {
      final rows = await SavingProductRepository.searchCoa(keyword: '', limit: 2000);
      final byCode = {for (final row in rows) row.kodeCoa: row};
      for (final key in sbbKeys) {
        final code = c(key).text.trim();
        final coa = byCode[code];
        if (coa != null && coa.namaCoa.trim().isNotEmpty) {
          coaNames[key] = coa.namaCoa.trim();
        }
      }

      final missing = sbbKeys.where((key) {
        final code = c(key).text.trim();
        return code.isNotEmpty && (coaNames[key]?.trim().isEmpty ?? true);
      }).toList();

      for (final key in missing) {
        final code = c(key).text.trim();
        final exact = await SavingProductRepository.searchCoa(keyword: code, limit: 20);
        for (final coa in exact) {
          if (coa.kodeCoa == code && coa.namaCoa.trim().isNotEmpty) {
            coaNames[key] = coa.namaCoa.trim();
            break;
          }
        }
      }
    } catch (_) {
      // Jika lookup nama COA gagal, form tetap dapat digunakan dengan kode COA saja.
    }
  }

  Future<List<CoreCoaModel>> searchCoa(String keyword) {
    return SavingProductRepository.searchCoa(keyword: keyword);
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
    await _hydrateCoaNames();
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
    if (!(formKey.currentState?.validate() ?? false)) return;
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
    faktorPembagi = '360';
    aksiLebihFrekuensi = '';
    saldoTutupMode = 'saldo_minimum';
    for (final key in controllers.keys) {
      controllers[key]!.text = _defaultValue(key);
    }
    for (final key in bools.keys) {
      bools[key] = false;
    }
    bools['saldo_bawah_min_otomatis_tutup'] = true;
    for (final row in progressiveRates) {
      row.clear();
    }
    coaNames.clear();
  }

  void _fillFromMap(Map<String, dynamic> data) {
    for (final key in controllers.keys) {
      if (data.containsKey(key) && data[key] != null) {
        final rawValue = data[key].toString();
        controllers[key]!.text = moneyKeys.contains(key) && rawValue.isNotEmpty ? _formatAmount(double.tryParse(rawValue) ?? 0) : rawValue;
      }
    }
    jenisTabungan = _str(data['jenis_tabungan'], jenisTabungan);
    dasarPerhitunganBunga = _str(data['dasar_perhitungan_bunga'], dasarPerhitunganBunga);
    metodePembukuanBunga = _str(data['metode_pembukuan_bunga'], metodePembukuanBunga);
    hitungBungaDibulatkan = _str(data['hitung_bunga_dibulatkan'], hitungBungaDibulatkan);
    tipeRate = _str(data['tipe_rate'], tipeRate);
    faktorPembagi = _str(data['faktor_pembagi'], faktorPembagi);
    aksiLebihFrekuensi = _str(data['aksi_lebih_frekuensi'], aksiLebihFrekuensi);
    for (final key in bools.keys) {
      bools[key] = _bool(data[key]);
    }
    if (bools['saldo_nihil_otomatis_tutup'] == true) {
      saldoTutupMode = 'saldo_nihil';
    } else {
      saldoTutupMode = 'saldo_minimum';
      bools['saldo_bawah_min_otomatis_tutup'] = true;
      bools['saldo_nihil_otomatis_tutup'] = false;
    }
    if (jenisTabungan.toLowerCase().contains('berjangka')) {
      bools['tabungan_berjangka'] = true;
    }

    for (final row in progressiveRates) {
      row.clear();
    }
    final rawRates = data['rate_progresif'] is List ? data['rate_progresif'] : data['rates'];
    if (rawRates is List) {
      final maxRows = rawRates.length > progressiveRates.length ? progressiveRates.length : rawRates.length;
      for (var i = 0; i < maxRows; i++) {
        final item = rawRates[i];
        if (item is Map) {
          final max = item['nominal_maksimum'];
          final rate = item['rate_bunga'];
          progressiveRates[i].maxController.text = max == null ? '0' : _formatAmount(double.tryParse(max.toString()) ?? 0);
          progressiveRates[i].rateController.text = rate == null ? '0' : rate.toString();
        }
      }
    }

    if (isProgressiveRate) {
      c('rate_bunga').text = '0';
    }
  }

  String _str(dynamic value, String def) => value == null || value.toString().isEmpty ? def : value.toString();

  bool _bool(dynamic value) {
    if (value is bool) return value;
    final text = (value ?? '').toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'y' || text == 'yes';
  }

  double _decimal(String key) {
    final raw = c(key).text.trim();
    final text = moneyKeys.contains(key) ? cleanCurrencyInput(raw) : raw.replaceAll(',', '').replaceAll('Rp', '').trim();
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
      'faktor_pembagi': int.tryParse(faktorPembagi) ?? 360,
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

    if (isProgressiveRate) {
      body['rate_bunga'] = 0;
      body['rate_progresif'] = buildProgressiveRates();
    } else {
      body['rate_progresif'] = [];
    }

    if (saldoTutupMode == 'saldo_minimum') {
      body['saldo_bawah_min_otomatis_tutup'] = true;
      body['saldo_nihil_otomatis_tutup'] = false;
      body['grace_periode_nihil'] = 0;
    } else {
      body['saldo_bawah_min_otomatis_tutup'] = false;
      body['saldo_nihil_otomatis_tutup'] = true;
      body['grace_periode_bawah_min'] = 0;
    }

    if (bools['frekuensi_penarikan_dibatasi'] != true) {
      body['frekuensi_maks_tarik_tunai'] = 0;
      body['aksi_lebih_frekuensi'] = '';
      body['nominal_denda_penarikan'] = 0;
    }

    if (bools['tabungan_berjangka'] != true) {
      body['jenis_tabungan'] = 'Reguler';
      body['jangka_waktu_bulan'] = 0;
      body['gunakan_tabel_jangka_waktu'] = false;
      body['denda_penarikan_sebelum_jatuh_tempo'] = false;
      body['nominal_denda_jatuh_tempo'] = 0;
      body['jatuh_tempo_alihkan_ke_sbb'] = false;
      body['nomor_sbb_jatuh_tempo'] = '';
      body['jatuh_tempo_bunga_distop'] = false;
      body['penarikan_tutup_otomatis'] = false;
      body['penutupan_nasabah_bunga_dibayar'] = false;
    }

    return body;
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (editData && !canUpdate) return;
    if (!editData && !canCreate) return;

    final progressiveError = validateProgressiveRates();
    if (progressiveError != null) {
      step = 1;
      notifyListeners();
      informationDialog(context, 'Warning', progressiveError);
      return;
    }

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
    for (final row in progressiveRates) {
      row.dispose();
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
                Text('Master produk tabungan, bunga, biaya, denda, dan SBB COA', style: TextStyle(color: Colors.black54)),
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
          width: 1150,
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
                          child: _stepContent(context),
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

  Widget _stepContent(BuildContext context) {
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
            _FullWidth(child: _saldoTutupRadio()),
          ],
        );
      case 1:
        return _SectionCard(
          title: 'Perhitungan Bunga',
          children: [
            _dropdown(
                'Dasar Perhitungan Bunga',
                value.dasarPerhitunganBunga,
                const ['Saldo Harian', 'Saldo Rata-rata', 'Saldo Minimum', 'Saldo Minimum Harian'],
                (v) => value.setString('dasar_perhitungan_bunga', v)),
            _dropdown('Metode Pembukuan Bunga', value.metodePembukuanBunga, const ['Cash Basis', 'Accrual Harian', 'Accrual Bulanan'],
                (v) => value.setString('metode_pembukuan_bunga', v)),
            _integer('Tgl Pembukuan Bunga', 'tgl_pembukuan_bunga', validator: _validateDayOrEndMonth),
            _dropdown('Faktor Pembagi', value.faktorPembagi, const ['360', '365'], (v) => value.setString('faktor_pembagi', v)),
            _dropdown(
                'Hitung Bunga Dibulatkan', value.hitungBungaDibulatkan, const ['YA', 'TIDAK'], (v) => value.setString('hitung_bunga_dibulatkan', v)),
            _dropdown('Tipe Rate', value.tipeRate, const ['STATIK', 'PROGRESIF'], (v) => value.setString('tipe_rate', v)),
            _number('Rate Bunga Default (%)', 'rate_bunga', enabled: !value.isProgressiveRate),
            if (value.isProgressiveRate) _FullWidth(child: _ProgressiveRatesTable(value: value)),
          ],
        );
      case 2:
        return _SectionCard(
          title: 'Penarikan Tunai',
          children: [
            _number('Maks Penarikan Tunai Per Hari', 'maks_penarikan_tunai_perhari'),
            _number('Denda Maks Penarikan (%)', 'denda_maks_penarikan_persen'),
            _check('Frekuensi Penarikan Dibatasi', 'frekuensi_penarikan_dibatasi'),
            _integer('Frekuensi Maks Tarik Tunai', 'frekuensi_maks_tarik_tunai', enabled: value.bools['frekuensi_penarikan_dibatasi'] == true),
            _dropdown('Aksi Lebih Frekuensi', value.aksiLebihFrekuensi, const ['', 'REJECT', 'PENDING', 'DENDA'],
                (v) => value.setString('aksi_lebih_frekuensi', v),
                enabled: value.bools['frekuensi_penarikan_dibatasi'] == true),
            _number('Nominal Denda Penarikan', 'nominal_denda_penarikan', enabled: value.bools['frekuensi_penarikan_dibatasi'] == true),
          ],
        );
      case 3:
        return _BiayaCard(value: value);
      case 4:
        return _TabunganBerjangkaCard(
            value: value,
            textBuilder: _text,
            numberBuilder: _number,
            integerBuilder: _integer,
            checkBuilder: _check,
            coaBuilder: (ctx, label, key, {enabled = true}) => _coaField(ctx, label, key, enabled: enabled));
      default:
        return _SectionCard(
          title: 'Setup SBB / COA Produk Tabungan',
          children: [
            _coaField(context, 'SBB Tabungan', 'sbb_tabungan'),
            _coaField(context, 'SBB Biaya Bunga', 'sbb_biaya_bunga'),
            _coaField(context, 'SBB Accrual Biaya Bunga', 'sbb_accrual_biaya_bunga'),
            _coaField(context, 'SBB Pendapatan Administrasi', 'sbb_pendapatan_administrasi'),
            _coaField(context, 'SBB Pendapatan Biaya Penutupan', 'sbb_pendapatan_biaya_penutupan'),
            _coaField(context, 'SBB Titipan Pajak', 'sbb_titipan_pajak'),
            _coaField(context, 'SBB Pendapatan Rekening Pasif', 'sbb_pendapatan_rekening_pasif'),
            _coaField(context, 'SBB Pendapatan Layanan Digital', 'sbb_pendapatan_layanan_digital'),
            _coaField(context, 'SBB Denda Maks Penarikan', 'sbb_denda_maks_penarikan'),
            _coaField(context, 'SBB Denda Penarikan', 'sbb_denda_penarikan'),
            _coaField(context, 'SBB Denda Jatuh Tempo', 'sbb_denda_jatuh_tempo'),
            _coaField(context, 'SBB Penampungan', 'sbb_penampungan'),
            _coaField(context, 'Nomor SBB Jatuh Tempo', 'nomor_sbb_jatuh_tempo'),
          ],
        );
    }
  }

  Widget _text(String label, String key,
      {bool required = false, int? maxLength, bool readOnly = false, bool uppercase = false, bool enabled = true}) {
    return TextFormField(
      controller: value.c(key),
      readOnly: readOnly,
      enabled: enabled,
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

  Widget _number(String label, String key, {bool enabled = true}) {
    final isMoney = ProductTabunganNotifier.moneyKeys.contains(key);
    final isPercentage = key == 'rate_bunga' || key == 'denda_maks_penarikan_persen';
    return TextFormField(
      controller: value.c(key),
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isMoney
          ? [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()]
          : isPercentage
              ? const [PercentageInputFormatter()]
              : [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]'))],
      validator: isPercentage ? (text) => validatePercentage(text) : null,
      decoration: _decoration(label),
    );
  }

  Widget _integer(String label, String key, {bool enabled = true, FormFieldValidator<String>? validator}) {
    return TextFormField(
      controller: value.c(key),
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
      decoration: _decoration(label),
    );
  }

  Widget _dropdown(String label, String selected, List<String> items, ValueChanged<String?> onChanged, {bool enabled = true}) {
    final valueSelected = items.contains(selected) ? selected : items.first;
    return DropdownButtonFormField<String>(
      value: valueSelected,
      decoration: _decoration(label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.isEmpty ? '-' : e))).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _check(String label, String key) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value.bools[key] ?? false,
      title: Text(label),
      activeColor: colorPrimary,
      onChanged: (v) => value.setBool(key, v),
    );
  }

  Widget _saldoTutupRadio() {
    Widget option({
      required String mode,
      required String label,
      required String graceLabel,
      required String graceKey,
    }) {
      final active = value.saldoTutupMode == mode;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: RadioListTile<String>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: mode,
              groupValue: value.saldoTutupMode,
              title: Text(label),
              onChanged: value.setSaldoTutupMode,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _integer(
              graceLabel,
              graceKey,
              enabled: active,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Otomatis Tutup Rekening',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        option(
          mode: 'saldo_minimum',
          label: 'Saldo < Minimum',
          graceLabel: 'Grace Period Bawah Min',
          graceKey: 'grace_periode_bawah_min',
        ),
        const SizedBox(height: 10),
        option(
          mode: 'saldo_nihil',
          label: 'Saldo Nihil',
          graceLabel: 'Grace Period Saldo Nihil',
          graceKey: 'grace_periode_nihil',
        ),
      ],
    );
  }

  Widget _coaField(BuildContext context, String label, String key, {bool enabled = true}) {
    return TextFormField(
      key: ValueKey('coa-$key-${value.c(key).text}-${value.coaNames[key] ?? ''}'),
      initialValue: value.coaDisplayText(key),
      enabled: enabled,
      readOnly: true,
      decoration: _decoration(label).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: enabled ? () => _showCoaDialog(context, label, key) : null,
        ),
      ),
    );
  }

  Future<void> _showCoaDialog(BuildContext context, String label, String key) async {
    final search = TextEditingController();
    Future<List<CoreCoaModel>> future = value.searchCoa('');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('Cari COA - $label'),
            content: SizedBox(
              width: 650,
              height: 520,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: search,
                          autofocus: true,
                          decoration: _decoration('Kode / Nama COA'),
                          onSubmitted: (_) => setState(() {
                            future = value.searchCoa(search.text.trim());
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          future = value.searchCoa(search.text.trim());
                        }),
                        style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                        child: const Text('Cari', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<CoreCoaModel>>(
                      future: future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        }
                        final rows = snapshot.data ?? [];
                        if (rows.isEmpty) return const Center(child: Text('COA tidak ditemukan.'));
                        return ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final coa = rows[i];
                            return ListTile(
                              dense: true,
                              title: Text('${coa.kodeCoa} - ${coa.namaCoa}'),
                              subtitle: Text('${coa.tipeCoaText} • ${coa.levelCoaText}'),
                              onTap: () {
                                value.pilihCoa(key, coa);
                                Navigator.pop(dialogContext);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup')),
            ],
          ),
        );
      },
    );
    search.dispose();
  }

  String? _validateDayOrEndMonth(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return 'Wajib diisi';
    final value = int.tryParse(text);
    if (value == null) return 'Harus angka';
    if ((value >= 1 && value <= 31) || value == 99) return null;
    return 'Isi 1-31 atau 99';
  }
}

class _BiayaCard extends StatelessWidget {
  final ProductTabunganNotifier value;

  const _BiayaCard({required this.value});

  @override
  Widget build(BuildContext context) {
    final form = context.findAncestorWidgetOfExactType<_ProductForm>();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardTitle('BIAYA'),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form!._number('Biaya Penutupan', 'biaya_penutupan')),
                const SizedBox(width: 24),
                Expanded(child: form._number('Biaya Pergantian Buku', 'biaya_pergantian_buku')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form._number('Biaya Administrasi Bulanan', 'biaya_admin_bulanan')),
                const SizedBox(width: 24),
                Expanded(child: form._check('Dikenakan Biaya Administrasi Bulanan', 'ba_bulanan')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form._number('Biaya Layanan Digital', 'biaya_layanan_digital')),
                const SizedBox(width: 24),
                Expanded(child: form._check('Dikenakan Biaya Layanan Digital', 'bl_digital')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form._number('Biaya Rekening Pasif', 'biaya_rekening_pasif')),
                const SizedBox(width: 16),
                Expanded(child: form._number('Saldo Minimum Pasif', 'min_saldo_kena_biaya_pasif')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form._integer('Waktu Pasif', 'hari_tidak_bertransaksi_pasif')),
                const SizedBox(width: 16),
                Expanded(child: _radioBool('Pasif Perlu Otorisasi', 'pasif_perlu_otorisasi')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form._number('Biaya di Bawah Saldo Min', 'biaya_dibawah_saldo_min')),
                const SizedBox(width: 16),
                Expanded(child: form._number('Saldo Minimum', 'saldo_minimum')),
                const SizedBox(width: 16),
                Expanded(child: _checkbox('Dikenakan Hanya Ketika Pasif', 'kena_biaya_min_pasif')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form._integer('Tanggal Proses', 'tgl_proses_biaya', validator: form._validateDayOrEndMonth)),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkbox(String label, String key) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: value.bools[key] ?? false,
      title: Text(label),
      activeColor: colorPrimary,
      onChanged: (v) => value.setBool(key, v),
    );
  }

  Widget _radioBool(String label, String key) {
    final selected = value.bools[key] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: true,
                groupValue: selected,
                title: const Text('Ya'),
                onChanged: (v) => value.setBool(key, v),
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: false,
                groupValue: selected,
                title: const Text('Tidak'),
                onChanged: (v) => value.setBool(key, v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class _ProgressiveRatesTable extends StatelessWidget {
  final ProductTabunganNotifier value;

  const _ProgressiveRatesTable({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFFAFCFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Table Rate Progresif',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Saldo awal otomatis mengikuti saldo akhir baris sebelumnya + 1. Isi Saldo Akhir 0 dan Rate > 0 untuk batas maksimum tidak terbatas. Baris Saldo Akhir 0 dan Rate 0 dianggap kosong.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 760,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    color: Colors.grey.shade200,
                    child: const Row(
                      children: [
                        SizedBox(width: 45, child: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                        SizedBox(width: 180, child: Text('Saldo Awal', style: TextStyle(fontWeight: FontWeight.bold))),
                        SizedBox(width: 210, child: Text('Saldo Akhir', style: TextStyle(fontWeight: FontWeight.bold))),
                        SizedBox(width: 150, child: Text('Rate (%)', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  ...List.generate(value.progressiveRates.length, (i) {
                    final row = value.progressiveRates[i];
                    final min = value.progressiveMinimumAt(i);
                    final maxRaw = cleanCurrencyInput(row.maxController.text);
                    final max = double.tryParse(maxRaw.isEmpty ? '0' : maxRaw) ?? 0;
                    final rate = double.tryParse(row.rateController.text.trim()) ?? 0;
                    final empty = max <= 0 && rate <= 0;
                    final unlimited = max <= 0 && rate > 0;
                    final invalid = max > 0 && max < min;
                    final rateInvalid = !empty && rate <= 0;
                    final statusText = empty
                        ? 'Kosong'
                        : invalid
                            ? 'Saldo tidak valid'
                            : rateInvalid
                                ? 'Rate wajib'
                                : unlimited
                                    ? 'Tidak terbatas'
                                    : 'Aktif';

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 45, child: Padding(padding: const EdgeInsets.only(top: 14), child: Text('${i + 1}'))),
                          SizedBox(
                            width: 180,
                            child: TextFormField(
                              key: ValueKey('progressive-min-${i}-${value.progressiveMinimumText(i)}-${empty}'),
                              readOnly: true,
                              initialValue: empty ? '0' : value.progressiveMinimumText(i),
                              decoration: _decoration('Saldo Awal').copyWith(fillColor: Colors.grey.shade100),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 198,
                            child: TextFormField(
                              controller: row.maxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                              decoration: _decoration('Saldo Akhir').copyWith(
                                errorText: invalid ? 'Tidak boleh < saldo awal' : null,
                              ),
                              onChanged: (_) => value.progressiveRateChanged(),
                              validator: (_) => invalid ? 'Saldo akhir tidak boleh lebih kecil dari saldo awal' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 138,
                            child: TextFormField(
                              controller: row.rateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: const [PercentageInputFormatter()],
                              decoration: _decoration('Rate').copyWith(
                                errorText: rateInvalid ? 'Wajib > 0' : null,
                              ),
                              onChanged: (_) => value.progressiveRateChanged(),
                              validator: (text) => validatePercentage(text, required: !empty, allowZero: false) ??
                                  (rateInvalid ? 'Rate wajib > 0' : null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                statusText,
                                style: TextStyle(color: invalid || rateInvalid ? Colors.red : Colors.black54, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabunganBerjangkaCard extends StatelessWidget {
  final ProductTabunganNotifier value;
  final Widget Function(String, String, {bool required, int? maxLength, bool readOnly, bool uppercase, bool enabled}) textBuilder;
  final Widget Function(String, String, {bool enabled}) numberBuilder;
  final Widget Function(String, String, {bool enabled, FormFieldValidator<String>? validator}) integerBuilder;
  final Widget Function(String, String) checkBuilder;
  final Widget Function(BuildContext, String, String, {bool enabled}) coaBuilder;

  const _TabunganBerjangkaCard({
    required this.value,
    required this.textBuilder,
    required this.numberBuilder,
    required this.integerBuilder,
    required this.checkBuilder,
    required this.coaBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final active = value.bools['tabungan_berjangka'] == true;
    final dendaActive = active && value.bools['denda_penarikan_sebelum_jatuh_tempo'] == true;
    final alihSbbActive = active && value.bools['jatuh_tempo_alihkan_ke_sbb'] == true;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardTitle('TABUNGAN BERJANGKA'),
            const SizedBox(height: 12),
            checkBuilder('Tabungan Berjangka', 'tabungan_berjangka'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: integerBuilder('Jangka Waktu Bulan', 'jangka_waktu_bulan', enabled: active)),
                const SizedBox(width: 16),
                Expanded(
                    child: Opacity(
                        opacity: active ? 1 : 0.5,
                        child: IgnorePointer(
                            ignoring: !active, child: checkBuilder('J/W dan Setoran Menggunakan Tabel', 'gunakan_tabel_jangka_waktu')))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Opacity(
                        opacity: active ? 1 : 0.5,
                        child: IgnorePointer(
                            ignoring: !active, child: checkBuilder('Denda Penarikan Sebelum JT Tempo', 'denda_penarikan_sebelum_jatuh_tempo')))),
                const SizedBox(width: 16),
                Expanded(child: numberBuilder('Nominal Denda JT Tempo', 'nominal_denda_jatuh_tempo', enabled: dendaActive)),
                const SizedBox(width: 16),
                Expanded(child: coaBuilder(context, 'SBB Denda', 'sbb_denda_jatuh_tempo', enabled: dendaActive)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Opacity(
                        opacity: active ? 1 : 0.5,
                        child: IgnorePointer(
                            ignoring: !active, child: checkBuilder('Jika Sudah JT Tempo Dialihkan ke SBB', 'jatuh_tempo_alihkan_ke_sbb')))),
                const SizedBox(width: 16),
                Expanded(child: coaBuilder(context, 'SBB Tujuan Pengalihan', 'nomor_sbb_jatuh_tempo', enabled: alihSbbActive)),
              ],
            ),
            const SizedBox(height: 12),
            Opacity(
                opacity: active ? 1 : 0.5,
                child:
                    IgnorePointer(ignoring: !active, child: checkBuilder('Jika Sudah JT Tempo Perhitungan Bunga STOP', 'jatuh_tempo_bunga_distop'))),
            Opacity(
                opacity: active ? 1 : 0.5,
                child: IgnorePointer(ignoring: !active, child: checkBuilder('Jika Ditarik, Status Rekening TUTUP', 'penarikan_tutup_otomatis'))),
            Opacity(
                opacity: active ? 1 : 0.5,
                child: IgnorePointer(
                    ignoring: !active, child: checkBuilder('Penutupan Nasabah, Bunga Berjalan Dibayar', 'penutupan_nasabah_bunga_dibayar'))),
          ],
        ),
      ),
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

class _FullWidth extends StatelessWidget {
  final Widget child;

  const _FullWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
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
            LayoutBuilder(
              builder: (context, constraints) {
                final normalWidth = constraints.maxWidth < 320 ? constraints.maxWidth : 320.0;

                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: children.map((e) {
                    if (e is _FullWidth) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        child: e,
                      );
                    }

                    return SizedBox(
                      width: normalWidth,
                      child: e,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;

  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 5, height: 20, decoration: BoxDecoration(color: colorPrimary, borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimary)),
      ],
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
