import 'package:cms_core/models/core_coa_model.dart';
import 'package:cms_core/models/loan_product_model.dart';
import 'package:cms_core/repository/loan_product_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:cms_core/utils/percentage_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductKreditPage extends StatefulWidget {
  const ProductKreditPage({super.key});

  @override
  State<ProductKreditPage> createState() => _ProductKreditPageState();
}

class _ProductKreditPageState extends State<ProductKreditPage> {
  final _formKey = GlobalKey<FormState>();
  final _keyword = TextEditingController();
  final _controllers = <String, TextEditingController>{};

  final List<LoanProductModel> _items = [];
  int _page = 1;
  final int _limit = 50;
  int _total = 0;
  bool _isLoading = true;
  bool _dialog = false;
  bool _editData = false;
  int _step = 0;
  String _filterStatus = 'A';
  String _filterJenisLoan = '';
  String? _errorMessage;

  String _jenisLoan = 'INSTALLMENT';
  String _metodeBunga = 'FLAT';
  String _jenisRate = 'FLAT';
  String _baseDenda = 'POKOK_BUNGA';
  String _basePenalty = 'PERSEN_OS';
  bool _agunan = true;
  bool _dendaHarian = true;
  bool _penaltiPelunasan = false;
  bool _provisiDiAcru = false;
  bool _bungaDiAcrual = false;
  bool _bungaAwalDiamortisasi = false;
  bool _backToBack = true;
  String _biayaAdmBasis = 'NOMINAL_KREDIT';
  String _provisiBasis = 'PERSEN_PLAFOND';
  String _modelPembayaranProvisi = 'BULANAN_3';
  String _fullPaymentProvisi = 'TIDAK';
  String _amortisasiPertamaDroping = 'TIDAK';
  bool _syncingAdminFee = false;

  final List<_ProgressiveFeeRow> _adminFeeRows = List.generate(5, (_) => _ProgressiveFeeRow());
  final List<_CollectibilityRow> _collectibilityRows = [
    _CollectibilityRow('Coll 2', 'coll_2'),
    _CollectibilityRow('Coll 3', 'coll_3'),
    _CollectibilityRow('Coll 4', 'coll_4'),
    _CollectibilityRow('Coll 5', 'coll_5'),
  ];
  final List<String> _steps = const [
    'Master',
    'Biaya Administrasi',
    'Provisi',
    'Denda & Pinalti',
    'Setup SBB',
    'Kolektibilitas',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadList();
  }

  void _initControllers() {
    final defaults = <String, String>{
      'kode_produk': '',
      'nama_produk': '',
      'jangka_waktu_min': '1',
      'jangka_waktu_max': '60',
      'biaya_administrasi': '',
      'rate_provisi': '0',
      'rate_denda': '',
      'max_tunggakan_accrual': '',
      'sbb_pend_diterima_dimuka': '',
      'spread': '',
      'minimal_nominal_provisi_diacru': '',
      'jumlah_hari_perhitungan_denda': '',
      'prosentase_1': '',
      'sbb_loan': '',
      'sbb_bunga': '',
      'sbb_pad': '',
      'sbb_biaya_administrasi': '',
      'sbb_provisi': '',
      'sbb_titipan_notaris': '',
      'sbb_asuransi_jiwa': '',
      'sbb_titipan_tunai': '',
      'sbb_titipan_setoran_credit': '',
      'sbb_penalty': '',
      'sbb_materai': '',
      'sbb_titipan_droping': '',
      'sbb_titipan_asuransi_agunan': '',
      'sbb_komitmen': '',
      'sbb_kontijensi': '',
      'sbb_write_off': '',
      'sbb_titipan_provisi': '',
      'sbb_kerugian_diperoleh_kembali': '',
      'sbb_do_prk': '',
      'sbb_bonus': '',
      'sbb_ppap_coll_1': '',
      'sbb_ppap_coll_lebih_1': '',
    };
    for (final entry in defaults.entries) {
      _controllers.putIfAbsent(entry.key, () => TextEditingController(text: entry.value));
    }
    c('biaya_administrasi').addListener(_onAdminDefaultChanged);
    for (final row in _adminFeeRows) {
      row.dasar.addListener(_onAdminRowsChanged);
      row.biaya.addListener(_onAdminRowsChanged);
    }
  }

  TextEditingController c(String key) {
    return _controllers.putIfAbsent(key, () => TextEditingController());
  }

  @override
  void dispose() {
    _keyword.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final row in _adminFeeRows) {
      row.dispose();
    }
    for (final row in _collectibilityRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadList({int? page}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (page != null) _page = page;
    });

    try {
      final result = await LoanProductRepository.list(
        keyword: _keyword.text.trim(),
        jenisLoan: _filterJenisLoan,
        statusData: _filterStatus,
        page: _page,
        limit: _limit,
      );
      _items
        ..clear()
        ..addAll(result.items);
      _total = result.total;
    } catch (e) {
      _items.clear();
      _total = 0;
      _errorMessage = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _clear() {
    _syncingAdminFee = true;
    c('kode_produk').text = '';
    c('nama_produk').text = '';
    c('jangka_waktu_min').text = '1';
    c('jangka_waktu_max').text = '60';
    c('biaya_administrasi').text = '';
    c('rate_provisi').text = '0';
    c('rate_denda').text = '';
    c('max_tunggakan_accrual').text = '';
    c('spread').text = '';
    c('minimal_nominal_provisi_diacru').text = '';
    c('jumlah_hari_perhitungan_denda').text = '';
    c('prosentase_1').text = '';

    for (final key in _sbbKeys) {
      c(key).text = '';
    }

    _jenisLoan = 'INSTALLMENT';
    _metodeBunga = 'FLAT';
    _jenisRate = 'FLAT';
    _baseDenda = 'POKOK_BUNGA';
    _basePenalty = 'PERSEN_OS';
    _agunan = true;
    _dendaHarian = true;
    _penaltiPelunasan = false;
    _provisiDiAcru = false;
    _bungaDiAcrual = false;
    _bungaAwalDiamortisasi = false;
    _backToBack = true;
    _biayaAdmBasis = 'NOMINAL_KREDIT';
    _provisiBasis = 'PERSEN_PLAFOND';
    _modelPembayaranProvisi = 'BULANAN_3';
    _fullPaymentProvisi = 'TIDAK';
    _amortisasiPertamaDroping = 'TIDAK';
    for (final row in _adminFeeRows) {
      row.clear();
    }
    for (final row in _collectibilityRows) {
      row.clear();
    }
    _collectibilityRows[0].pokok.text = '60';
    _collectibilityRows[0].bdr.text = '10';
    _collectibilityRows[1].pokok.text = '6';
    _collectibilityRows[1].bdr.text = '50';
    _collectibilityRows[2].pokok.text = '12';
    _collectibilityRows[2].bdr.text = '100';
    _syncingAdminFee = false;
    _step = 0;
  }

  void _tambah() {
    _clear();
    setState(() {
      _editData = false;
      _dialog = true;
    });
  }

  Future<void> _edit(LoanProductModel row) async {
    try {
      DialogCustom().showLoading(context);
      final detail = await LoanProductRepository.detail(row.kodeProduk);
      if (mounted) Navigator.pop(context);
      _fillFromModel(detail);
      setState(() {
        _editData = true;
        _dialog = true;
        _step = 0;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void _fillFromModel(LoanProductModel model) {
    _clear();
    c('kode_produk').text = model.kodeProduk;
    c('nama_produk').text = model.namaProduk;
    c('jangka_waktu_min').text = model.jangkaWaktuMin.toString();
    c('jangka_waktu_max').text = model.jangkaWaktuMax.toString();
    c('biaya_administrasi').text = _moneyText(model.biayaAdministrasi);
    c('rate_provisi').text = _decimalText(model.rateProvisi);
    c('rate_denda').text = _decimalText(model.rateDenda);
    c('max_tunggakan_accrual').text = _rawText(model.raw, ['max_tunggakan_accrual', 'max_tunggakan_yang_diacru'], c('max_tunggakan_accrual').text);
    c('sbb_pend_diterima_dimuka').text = _rawText(model.raw, ['sbb_pend_diterima_dimuka', 'sbb_pend_diterima_dimuka'], '');
    c('spread').text = _rawDecimalText(model.raw, ['spread'], '');
    c('minimal_nominal_provisi_diacru').text = _rawMoneyText(model.raw, ['minimal_nominal_provisi_diacru'], c('minimal_nominal_provisi_diacru').text);
    c('jumlah_hari_perhitungan_denda').text = _rawText(model.raw, ['jumlah_hari_perhitungan_denda'], c('jumlah_hari_perhitungan_denda').text);
    c('prosentase_1').text = _rawDecimalText(model.raw, ['prosentase_1', 'prosentase_penalty'], '');

    _jenisLoan = _normalJenisLoan(model.jenisLoan);
    _metodeBunga = _normalMetodeBunga(model.metodePerhitunganBunga);
    _jenisRate = _normalJenisRate(_rawText(model.raw, ['jenis_rate'], _jenisRateFromMetode(_metodeBunga)));
    _baseDenda = _normalBaseDenda(model.basePerhitunganDenda);
    _basePenalty = _normalBasePenalty(model.basePerhitunganPenalty);
    _agunan = model.agunan;
    _dendaHarian = model.perhitunganDendaHarian;
    _penaltiPelunasan = model.penaltiPelunasanDipercepat;
    _provisiDiAcru = model.provisiDiAcru;
    _bungaDiAcrual = _rawBool(model.raw, ['bunga_di_accrual', 'bunga_di_acru'], false);
    _bungaAwalDiamortisasi = _rawBool(model.raw, ['bunga_diterima_awal_diamortisasi'], false);
    _backToBack = _rawBool(model.raw, ['back_to_back'], true);
    _biayaAdmBasis = _rawText(model.raw, ['biaya_administrasi_progresif_berdasarkan'], 'NOMINAL_KREDIT');
    if (!['JANGKA_WAKTU', 'NOMINAL_KREDIT'].contains(_biayaAdmBasis)) _biayaAdmBasis = 'NOMINAL_KREDIT';
    _provisiBasis = _rawText(model.raw, ['provisi_basis'], 'PERSEN_PLAFOND');
    if (!['PERSEN_PLAFOND', 'NOMINAL'].contains(_provisiBasis)) _provisiBasis = 'PERSEN_PLAFOND';
    _fillAdminFeeRows(model.raw);
    _fillCollectibilityRows(model.raw);

    c('sbb_loan').text = model.sbbLoan;
    c('sbb_bunga').text = model.sbbBunga;
    c('sbb_pad').text = model.sbbPad;
    c('sbb_biaya_administrasi').text = model.sbbBiayaAdministrasi;
    c('sbb_provisi').text = model.sbbProvisi;
    c('sbb_titipan_notaris').text = model.sbbTitipanNotaris;
    c('sbb_asuransi_jiwa').text = model.sbbAsuransiJiwa;
    c('sbb_titipan_tunai').text = model.sbbTitipanTunai;
    c('sbb_titipan_setoran_credit').text = _rawText(model.raw, ['sbb_titipan_setoran_credit'], '');
    c('sbb_penalty').text = model.sbbPenalty;
    c('sbb_materai').text = model.sbbMaterai;
    c('sbb_titipan_droping').text = model.sbbTitipanDroping;
    c('sbb_titipan_asuransi_agunan').text = model.sbbTitipanAsuransiAgunan;
    c('sbb_komitmen').text = model.sbbKomitmen;
    c('sbb_kontijensi').text = model.sbbKontijensi;
    c('sbb_write_off').text = model.sbbWriteOff;
    c('sbb_titipan_provisi').text = model.sbbTitipanProvisi;
    c('sbb_ppap_coll_1').text = model.sbbPpapColl1;
    c('sbb_ppap_coll_lebih_1').text = model.sbbPpapCollLebih1;
    c('sbb_kerugian_diperoleh_kembali').text = _rawText(model.raw, ['sbb_kerugian_diperoleh_kembali', 'sbb_kerugian_diperoleh_kembali'], '');
    c('sbb_do_prk').text = _rawText(model.raw, ['sbb_do_prk'], '');
    c('sbb_bonus').text = _rawText(model.raw, ['sbb_bonus'], '');
    c('sbb_pend_diterima_dimuka').text = _rawText(model.raw, ['sbb_pend_diterima_dimuka'], c('sbb_pend_diterima_dimuka').text);
  }

  Future<void> _delete(LoanProductModel row) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Anda yakin menghapus produk ${row.kodeProduk} - ${row.namaProduk}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                DialogCustom().showLoading(context);
                await LoanProductRepository.delete(row.kodeProduk);
                if (mounted) Navigator.pop(context);
                informationDialog(context, 'Informasi', 'Produk kredit berhasil dihapus.');
                await _loadList();
              } catch (e) {
                if (mounted) Navigator.pop(context);
                informationDialog(context, 'Warning', e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step < _steps.length - 1) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final minTenor = _int(c('jangka_waktu_min').text);
    final maxTenor = _int(c('jangka_waktu_max').text);
    if (minTenor <= 0 || maxTenor <= 0 || maxTenor < minTenor) {
      setState(() => _step = 0);
      informationDialog(context, 'Warning', 'Jangka waktu max harus lebih besar atau sama dengan jangka waktu min.');
      return;
    }

    if (!_validateOpenItemRules()) return;

    final body = _buildBody();
    try {
      DialogCustom().showLoading(context);
      await LoanProductRepository.save(isEdit: _editData, body: body);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', _editData ? 'Produk kredit berhasil diupdate.' : 'Produk kredit berhasil ditambahkan.');
      setState(() {
        _dialog = false;
        _editData = false;
      });
      await _loadList(page: 1);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Map<String, dynamic> _buildBody() {
    return {
      'kode_produk': c('kode_produk').text.trim().toUpperCase(),
      'nama_produk': c('nama_produk').text.trim(),
      'jenis_loan': _jenisLoan,
      'metode_perhitungan_bunga': _metodeBunga,
      'jenis_rate': _jenisRate,
      'jangka_waktu_min': _int(c('jangka_waktu_min').text),
      'jangka_waktu_max': _int(c('jangka_waktu_max').text),
      'agunan': _agunan,
      'bunga_di_accrual': _bungaDiAcrual,
      'max_tunggakan_accrual': _bungaDiAcrual ? _int(c('max_tunggakan_accrual').text) : 0,
      'bunga_diterima_awal_diamortisasi': _bungaAwalDiamortisasi,
      'sbb_pend_diterima_dimuka': _bungaAwalDiamortisasi ? _coaCode('sbb_pend_diterima_dimuka') : '',
      'back_to_back': _backToBack,
      'spread': _backToBack ? _decimalNum(c('spread').text) : 0,
      'biaya_administrasi': _hasProgressiveAdminFee ? 0 : _moneyNum(c('biaya_administrasi').text),
      'biaya_administrasi_progresif_berdasarkan': _hasProgressiveAdminFee ? _biayaAdmBasis : '',
      'biaya_administrasi_progresif': _hasProgressiveAdminFee ? _adminFeeRowsPayload() : <Map<String, dynamic>>[],
      'rate_provisi': _decimalNum(c('rate_provisi').text),
      'provisi_basis': _provisiBasis,
      'perhitungan_denda_harian': _dendaHarian,
      'rate_denda': _dendaHarian ? _decimalNum(c('rate_denda').text) : 0,
      'jumlah_hari_perhitungan_denda': _dendaHarian ? _int(c('jumlah_hari_perhitungan_denda').text) : 0,
      'base_perhitungan_denda': _dendaHarian ? _baseDenda : '',
      'penalti_pelunasan_dipercepat': _penaltiPelunasan,
      'base_perhitungan_penalty': _penaltiPelunasan ? _basePenalty : '',
      'prosentase_1': _penaltiPelunasan ? _decimalNum(c('prosentase_1').text) : 0,
      'provisi_di_acru': _provisiDiAcru,
      'minimal_nominal_provisi_diacru': _provisiDiAcru ? _moneyNum(c('minimal_nominal_provisi_diacru').text) : 0,
      'sbb_loan': _coaCode('sbb_loan'),
      'sbb_bunga': _coaCode('sbb_bunga'),
      'sbb_pad': _coaCode('sbb_pad'),
      'sbb_ppap_coll_1': _coaCode('sbb_ppap_coll_1'),
      'sbb_ppap_coll_lebih_1': _coaCode('sbb_ppap_coll_lebih_1'),
      'sbb_biaya_administrasi': _coaCode('sbb_biaya_administrasi'),
      'sbb_provisi': _coaCode('sbb_provisi'),
      'sbb_titipan_notaris': _coaCode('sbb_titipan_notaris'),
      'sbb_asuransi_jiwa': _coaCode('sbb_asuransi_jiwa'),
      'sbb_titipan_tunai': _coaCode('sbb_titipan_tunai'),
      'sbb_titipan_setoran_credit': _coaCode('sbb_titipan_setoran_credit'),
      'sbb_penalty': _coaCode('sbb_penalty'),
      'sbb_materai': _coaCode('sbb_materai'),
      'sbb_titipan_droping': _coaCode('sbb_titipan_droping'),
      'sbb_titipan_asuransi_agunan': _coaCode('sbb_titipan_asuransi_agunan'),
      'sbb_komitmen': _coaCode('sbb_komitmen'),
      'sbb_kontijensi': _coaCode('sbb_kontijensi'),
      'sbb_write_off': _coaCode('sbb_write_off'),
      'sbb_titipan_provisi': _provisiDiAcru ? _coaCode('sbb_titipan_provisi') : '',
      'sbb_kerugian_diperoleh_kembali': _coaCode('sbb_kerugian_diperoleh_kembali'),
      'sbb_do_prk': _coaCode('sbb_do_prk'),
      'sbb_bonus': _coaCode('sbb_bonus'),
      'kolektibilitas': _collectibilityPayload(),
    };
  }

  String _coaCode(String key) {
    final text = c(key).text.trim();
    return text.contains(' - ') ? text.split(' - ').first.trim() : text;
  }

  List<Map<String, dynamic>> _adminFeeRowsPayload() {
    final rows = <Map<String, dynamic>>[];
    for (int i = 0; i < _adminFeeRows.length; i++) {
      final row = _adminFeeRows[i];
      final dasar = _moneyNum(row.dasar.text);
      final biaya = _moneyNum(row.biaya.text);
      if (dasar <= 0 && biaya <= 0) continue;
      rows.add({
        'urutan': i + 1,
        'berdasarkan': _biayaAdmBasis,
        'jangka_waktu': _biayaAdmBasis == 'JANGKA_WAKTU' ? dasar.toInt() : null,
        'nominal_kredit': _biayaAdmBasis == 'NOMINAL_KREDIT' ? dasar : null,
        'biaya_administrasi': biaya,
      });
    }
    return rows;
  }

  List<Map<String, dynamic>> _collectibilityPayload() {
    return _collectibilityRows.map((row) {
      return {
        'coll': row.label.replaceAll('Coll ', ''),
        'jml_hari': _int(row.pokok.text),
        'bdr': _decimalNum(row.bdr.text),
      };
    }).toList();
  }

  void _fillAdminFeeRows(Map<String, dynamic> raw) {
    for (final row in _adminFeeRows) {
      row.clear();
    }
    final source = raw['biaya_administrasi_progresif'];
    if (source is! List) return;
    for (int i = 0; i < source.length && i < _adminFeeRows.length; i++) {
      final item = source[i];
      if (item is! Map) continue;
      final row = _adminFeeRows[i];
      final dasar = item['jangka_waktu'] ?? item['nominal_kredit'] ?? item['batas'] ?? item['nilai'] ?? item['dasar'];
      row.dasar.text = _moneyText(_numValue(dasar));
      row.biaya.text = _moneyText(_numValue(item['biaya_administrasi'] ?? item['biaya'] ?? item['by_administrasi']));
    }
  }

  void _fillCollectibilityRows(Map<String, dynamic> raw) {
    final source = raw['kolektibilitas'];
    if (source is List) {
      for (final item in source) {
        if (item is! Map) continue;
        final coll = (item['coll'] ?? '').toString().replaceAll('Coll ', '').trim();
        _CollectibilityRow? row;
        for (final candidate in _collectibilityRows) {
          if (candidate.label.endsWith(coll)) {
            row = candidate;
            break;
          }
        }
        if (row == null) continue;
        row.pokok.text = _safeText(item['jml_hari'] ?? item['jumlah_hari'] ?? item['pokok']);
        row.bdr.text = _safeText(item['bdr']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Toolbar(
                  keyword: _keyword,
                  filterStatus: _filterStatus,
                  filterJenisLoan: _filterJenisLoan,
                  onFilterStatusChanged: (value) => setState(() => _filterStatus = value ?? ''),
                  onFilterJenisLoanChanged: (value) => setState(() => _filterJenisLoan = value ?? ''),
                  onSearch: () => _loadList(page: 1),
                  onTambah: _tambah,
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(child: Text(_errorMessage!))
                          : _ProductTable(items: _items, page: _page, limit: _limit, onEdit: _edit, onDelete: _delete),
                ),
                _PaginationBar(
                  page: _page,
                  limit: _limit,
                  total: _total,
                  onPrev: _page <= 1 ? null : () => _loadList(page: _page - 1),
                  onNext: _items.length < _limit ? null : () => _loadList(page: _page + 1),
                ),
              ],
            ),
            if (_dialog) _productForm(),
          ],
        ),
      ),
    );
  }

  Widget _productForm() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        alignment: Alignment.centerRight,
        child: Container(
          width: MediaQuery.of(context).size.width > 1180 ? 1080 : MediaQuery.of(context).size.width * 0.94,
          height: double.infinity,
          color: Colors.white,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_editData ? 'Edit Prod Kredit' : 'Tambah Prod Kredit',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(onPressed: () => setState(() => _dialog = false), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 250, child: _StepNavigation(steps: _steps, current: _step, onTap: (i) => setState(() => _step = i))),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            color: const Color(0xFFFBF6FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _topIdentity(),
                                  const SizedBox(height: 16),
                                  Expanded(child: SingleChildScrollView(child: _buildStepContent())),
                                  const SizedBox(height: 16),
                                  _FormNavigation(
                                    current: _step,
                                    total: _steps.length,
                                    onBack: _back,
                                    onNext: _next,
                                    onReset: () => setState(_clear),
                                    onSave: _save,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topIdentity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.yellowAccent.shade400, borderRadius: BorderRadius.circular(8)),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(width: 190, child: _text('Kode Produk', 'kode_produk', required: true, readOnly: _editData, uppercase: true)),
          SizedBox(width: 420, child: _text('Nama Produk Kredit', 'nama_produk', required: true)),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _SectionCard(
          title: 'Master Setup Produk Kredit',
          children: [
            _dropdown(
                'Jenis Loan',
                _jenisLoan,
                const {
                  'INSTALLMENT': '1 - Angsuran',
                  'PRK': '2 - PRK',
                },
                (v) => setState(() => _jenisLoan = v ?? 'INSTALLMENT')),
            _dropdown(
                'Metode Perhitungan Bunga',
                _metodeBunga,
                const {
                  'FLAT': '1 - Flat Flat',
                  'FLAT78': '2 - Flat 78',
                  'SLIDING': '3 - Sliding',
                  'ANNUITAS': '4 - Annuitas',
                  'EFEKTIF': '5 - Efektif',
                },
                (v) => setState(() {
                      _metodeBunga = v ?? 'FLAT';
                      _jenisRate = _jenisRateFromMetode(_metodeBunga);
                    })),
            _integer('Jangka Waktu Min (Bln)', 'jangka_waktu_min', required: true),
            _integer('Jangka Waktu Max (Bln)', 'jangka_waktu_max', required: true),
            _switch('Agunan', _agunan, (v) => setState(() => _agunan = v)),
            _switch(
                'Back To Back',
                _backToBack,
                (v) => setState(() {
                      _backToBack = v;
                      if (!v) c('spread').clear();
                    })),
            _decimal('Spread', 'spread', enabled: _backToBack),
            const SizedBox(height: 16),
            _switch(
                'Bunga Di-Accrual',
                _bungaDiAcrual,
                (v) => setState(() {
                      _bungaDiAcrual = v;
                      if (v && c('max_tunggakan_accrual').text.trim().isEmpty) c('max_tunggakan_accrual').text = '2';
                      if (!v) c('max_tunggakan_accrual').clear();
                    })),
            _integer('Max Tunggakan yang di-Acru', 'max_tunggakan_accrual', required: _bungaDiAcrual, enabled: _bungaDiAcrual),
            _switch(
                'Bunga diterima awal diamortisasi',
                _bungaAwalDiamortisasi,
                (v) => setState(() {
                      _bungaAwalDiamortisasi = v;
                      if (!v) c('sbb_pend_diterima_dimuka').clear();
                    })),
            _coa('SBB Pend diterima dimuka', 'sbb_pend_diterima_dimuka', enabled: _bungaAwalDiamortisasi, required: _bungaAwalDiamortisasi),
          ],
        );
      case 1:
        return _SectionCard(
          title: 'Biaya Administrasi',
          children: [
            _money('Biaya Administrasi Default', 'biaya_administrasi', enabled: !_hasProgressiveAdminFee),
            _FullWidth(child: _adminFeeTable()),
          ],
        );
      case 2:
        return _SectionCard(
          title: 'Provisi',
          children: [
            _dropdown(
                'Provisi',
                _provisiBasis,
                const {
                  'PERSEN_PLAFOND': '1-% x Plafond',
                  'NOMINAL': '3-Nominal',
                },
                (v) => setState(() => _provisiBasis = v ?? 'PERSEN_PLAFOND')),
            _decimal('% Provisi', 'rate_provisi', required: true),
            _FullWidth(child: const Divider(height: 24)),
            _switch(
                'Provisi Di-Acru',
                _provisiDiAcru,
                (v) => setState(() {
                      _provisiDiAcru = v;
                      if (!v) {
                        c('sbb_titipan_provisi').clear();
                        c('minimal_nominal_provisi_diacru').clear();
                      }
                    })),
            _coa('SBB Titipan Provisi', 'sbb_titipan_provisi', enabled: _provisiDiAcru, required: _provisiDiAcru),
            _money('Minimal Nominal Provisi di-Acru', 'minimal_nominal_provisi_diacru', enabled: _provisiDiAcru, required: _provisiDiAcru),
          ],
        );
      case 3:
        return _SectionCard(
          title: 'Denda & Pinalti',
          children: [
            _switch(
                'Perhitungan denda harian',
                _dendaHarian,
                (v) => setState(() {
                      _dendaHarian = v;
                      if (v && c('jumlah_hari_perhitungan_denda').text.trim().isEmpty) c('jumlah_hari_perhitungan_denda').text = '1';
                      if (!v) {
                        c('jumlah_hari_perhitungan_denda').clear();
                        c('rate_denda').clear();
                      }
                    })),
            _integer('Jumlah Hari Perhitungan Denda', 'jumlah_hari_perhitungan_denda', enabled: _dendaHarian, required: _dendaHarian),
            _decimal('Denda (% per Bln)', 'rate_denda', enabled: _dendaHarian, required: _dendaHarian),
            _dropdown(
                'Base Perhitungan Denda',
                _baseDenda,
                const {
                  'TUNGGAKAN_POKOK': '1 - Pokok',
                  'POKOK_BUNGA': '2 - Pokok + Bunga',
                },
                (v) => setState(() => _baseDenda = v ?? 'POKOK_BUNGA'),
                enabled: _dendaHarian),
            _switch(
                'Penalty Pelunasan Awal',
                _penaltiPelunasan,
                (v) => setState(() {
                      _penaltiPelunasan = v;
                      if (!v) c('prosentase_1').clear();
                    })),
            _dropdown(
                'Pilihan',
                _basePenalty,
                const {
                  'PERSEN_PLAFOND': 'P',
                  'PERSEN_OS': 'P + B',
                },
                (v) => setState(() => _basePenalty = v ?? 'PERSEN_OS'),
                enabled: _penaltiPelunasan),
            _decimal('Prosentase Penalty', 'prosentase_1', enabled: _penaltiPelunasan, required: _penaltiPelunasan),
          ],
        );
      case 4:
        return _SectionCard(
          title: 'Setup SBB Produk Kredit',
          children: [
            _FullWidth(child: _sbbPanel()),
          ],
        );
      default:
        return _SectionCard(
          title: 'Kolektibilitas',
          children: [
            _FullWidth(child: _collectibilityPanel()),
          ],
        );
    }
  }

  Widget _adminFeeTable() {
    final progressiveEnabled = !_hasAdminDefault;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Biaya Administrasi Progresif Berdasarkan:', style: TextStyle(fontWeight: FontWeight.w600))),
            Radio<String>(
              value: 'JANGKA_WAKTU',
              groupValue: _biayaAdmBasis,
              onChanged: progressiveEnabled ? (v) => setState(() => _biayaAdmBasis = v ?? 'JANGKA_WAKTU') : null,
            ),
            const Text('Jangka Waktu'),
            const SizedBox(width: 16),
            Radio<String>(
              value: 'NOMINAL_KREDIT',
              groupValue: _biayaAdmBasis,
              onChanged: progressiveEnabled ? (v) => setState(() => _biayaAdmBasis = v ?? 'NOMINAL_KREDIT') : null,
            ),
            const Text('Nominal Kredit'),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('NO')),
              DataColumn(label: Text('JANGKA WAKTU / NOMINAL')),
              DataColumn(label: Text('BY-ADMINISTRASI')),
            ],
            rows: List.generate(_adminFeeRows.length, (i) {
              final row = _adminFeeRows[i];
              return DataRow(cells: [
                DataCell(Text('${i + 1}')),
                DataCell(SizedBox(width: 180, child: _tableMoney(row.dasar, hint: '0', enabled: progressiveEnabled))),
                DataCell(SizedBox(width: 180, child: _tableMoney(row.biaya, hint: '0', enabled: progressiveEnabled))),
              ]);
            }),
          ),
        ),
      ],
    );
  }

  Widget _sbbPanel() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _sbbBox('SBB', [
          _coa('SBB PAD', 'sbb_pad'),
          _coa('SBB PPAP Coll - 1', 'sbb_ppap_coll_1'),
          _coa('SBB PPAP Coll > 1', 'sbb_ppap_coll_lebih_1'),
          _coa('Kerugian diperoleh kembali', 'sbb_kerugian_diperoleh_kembali'),
          _coa('SBB DO PRK', 'sbb_do_prk'),
        ]),
        _sbbBox('SBB Titipan', [
          _coa('SBB Titipan Notaris', 'sbb_titipan_notaris'),
          _coa('SBB Titipan Asr Jiwa', 'sbb_asuransi_jiwa'),
          _coa('SBB Titipan Tunai', 'sbb_titipan_tunai'),
          _coa('SBB Ttp Setoran Credit', 'sbb_titipan_setoran_credit'),
          _coa('SBB Titipan Droping', 'sbb_titipan_droping'),
          _coa('SBB Titipan Asr Agunan', 'sbb_titipan_asuransi_agunan'),
        ]),
        _sbbBox('SBB Pos Administrasi', [
          _coa('SBB Komitmen', 'sbb_komitmen'),
          _coa('SBB Kontijensi', 'sbb_kontijensi'),
          _coa('SBB Write Off', 'sbb_write_off'),
        ]),
        _sbbBox('SBB Pendapatan', [
          _coa('SBB By Adm', 'sbb_biaya_administrasi'),
          _coa('SBB Provisi', 'sbb_provisi'),
          _coa('SBB Penalty', 'sbb_penalty'),
          _coa('SBB Materai', 'sbb_materai'),
          _coa('SBB Bonus', 'sbb_bonus'),
        ]),
      ],
    );
  }

  Widget _sbbBox(String title, List<Widget> children) {
    return SizedBox(
      width: 460,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupTitle(title),
              const SizedBox(height: 10),
              ...children.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: e)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collectibilityPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set sesuai dengan periode pembayarannya', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(colorPrimary),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('')),
              DataColumn(label: Text('Jml Hari')),
              DataColumn(label: Text('BDR (%)')),
            ],
            rows: _collectibilityRows.map((row) {
              return DataRow(cells: [
                DataCell(Text('${row.label}:')),
                DataCell(SizedBox(width: 120, child: _tableInteger(row.pokok))),
                DataCell(SizedBox(width: 120, child: _tableDecimal(row.bdr))),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _tableMoney(TextEditingController controller, {String hint = '', bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, _RupiahInputFormatter()],
      decoration: InputDecoration(isDense: true, hintText: hint, filled: true, fillColor: Colors.white, border: const OutlineInputBorder()),
    );
  }

  Widget _tableInteger(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
    );
  }

  Widget _tableDecimal(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: const [PercentageInputFormatter()],
      validator: validatePercentage,
      decoration: const InputDecoration(isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
    );
  }

  Widget _coaTableField(String key, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: const InputDecoration(isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder()).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () async {
            c(key).text = controller.text;
            await _showCoaDialog('COA', key);
            controller.text = c(key).text;
          },
        ),
      ),
    );
  }

  Widget _text(String label, String key, {bool required = false, bool readOnly = false, bool uppercase = false}) {
    return TextFormField(
      controller: c(key),
      readOnly: readOnly,
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
      inputFormatters: uppercase ? [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]'))] : null,
      validator: (value) => required && (value ?? '').trim().isEmpty ? 'Wajib diisi' : null,
      decoration: _decoration(label),
    );
  }

  Widget _integer(String label, String key, {bool required = false, bool enabled = true}) {
    return TextFormField(
      controller: c(key),
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) => required && _int(value) <= 0 ? 'Wajib > 0' : null,
      decoration: _decoration(label),
    );
  }

  Widget _decimal(String label, String key, {bool enabled = true, bool required = false}) {
    return TextFormField(
      controller: c(key),
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: const [PercentageInputFormatter()],
      validator: (value) => validatePercentage(value, required: required, allowZero: !required),
      decoration: _decoration(label),
    );
  }

  Widget _money(String label, String key, {bool enabled = true, bool required = false}) {
    return TextFormField(
      controller: c(key),
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, _RupiahInputFormatter()],
      validator: (value) => required && _moneyNum(value) <= 0 ? 'Wajib > 0' : null,
      decoration: _decoration(label),
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> items, ValueChanged<String?> onChanged, {bool enabled = true}) {
    final selected = items.containsKey(value) ? value : items.keys.first;
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: _decoration(label),
      items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(label),
      activeColor: colorPrimary,
      onChanged: onChanged,
    );
  }

  Widget _coa(String label, String key, {bool enabled = true, bool required = false}) {
    return TextFormField(
      controller: c(key),
      enabled: enabled,
      readOnly: true,
      validator: (value) => required && (value ?? '').trim().isEmpty ? 'Wajib diisi' : null,
      decoration: _decoration(label).copyWith(
        suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: enabled ? () => _showCoaDialog(label, key) : null),
      ),
    );
  }

  bool get _hasAdminDefault => _moneyNum(c('biaya_administrasi').text) > 0;

  bool get _hasProgressiveAdminFee => _adminFeeRows.any((row) => _moneyNum(row.dasar.text) > 0 || _moneyNum(row.biaya.text) > 0);

  void _onAdminDefaultChanged() {
    if (_syncingAdminFee || !mounted) return;
    if (!_hasAdminDefault) {
      setState(() {});
      return;
    }
    _syncingAdminFee = true;
    for (final row in _adminFeeRows) {
      row.clear();
    }
    _syncingAdminFee = false;
    setState(() {});
  }

  void _onAdminRowsChanged() {
    if (_syncingAdminFee || !mounted) return;
    if (!_hasProgressiveAdminFee) {
      setState(() {});
      return;
    }
    if (c('biaya_administrasi').text.trim().isNotEmpty) {
      _syncingAdminFee = true;
      c('biaya_administrasi').clear();
      _syncingAdminFee = false;
    }
    setState(() {});
  }

  bool _validateOpenItemRules() {
    if (_bungaDiAcrual && _int(c('max_tunggakan_accrual').text) <= 0) {
      setState(() => _step = 0);
      informationDialog(context, 'Warning', 'Max Tunggakan yang di-Acru wajib diisi jika Bunga Di-Accrual ON.');
      return false;
    }
    if (_bungaAwalDiamortisasi && _coaCode('sbb_pend_diterima_dimuka').isEmpty) {
      setState(() => _step = 0);
      informationDialog(context, 'Warning', 'SBB Pend diterima dimuka wajib diisi jika Bunga diterima awal diamortisasi ON.');
      return false;
    }
    if (_provisiDiAcru && _coaCode('sbb_titipan_provisi').isEmpty) {
      setState(() => _step = 2);
      informationDialog(context, 'Warning', 'SBB Titipan Provisi wajib diisi jika Provisi Di-Acru ON.');
      return false;
    }
    if (_provisiDiAcru && _moneyNum(c('minimal_nominal_provisi_diacru').text) <= 0) {
      setState(() => _step = 2);
      informationDialog(context, 'Warning', 'Minimal Nominal Provisi di-Acru wajib diisi jika Provisi Di-Acru ON.');
      return false;
    }
    if (_dendaHarian && (_int(c('jumlah_hari_perhitungan_denda').text) <= 0 || _decimalNum(c('rate_denda').text) <= 0)) {
      setState(() => _step = 3);
      informationDialog(context, 'Warning', 'Jumlah Hari Perhitungan Denda dan Denda (% per Bln) wajib diisi jika Perhitungan denda harian ON.');
      return false;
    }
    if (_penaltiPelunasan && _decimalNum(c('prosentase_1').text) <= 0) {
      setState(() => _step = 3);
      informationDialog(context, 'Warning', 'Prosentase Penalty wajib diisi jika Penalty Pelunasan Awal ON.');
      return false;
    }
    if (_hasAdminDefault && _hasProgressiveAdminFee) {
      setState(() => _step = 1);
      informationDialog(context, 'Warning', 'Pilih salah satu: Biaya Administrasi Default atau Biaya Administrasi Progresif.');
      return false;
    }
    return true;
  }

  Future<void> _showCoaDialog(String label, String key) async {
    final search = TextEditingController();
    Future<List<CoreCoaModel>> future = LoanProductRepository.searchCoa();
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
                            onSubmitted: (_) => setDialogState(() => future = LoanProductRepository.searchCoa(keyword: search.text.trim())))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setDialogState(() => future = LoanProductRepository.searchCoa(keyword: search.text.trim())),
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
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
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
                              c(key).text = '${coa.kodeCoa} - ${coa.namaCoa}';
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
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup'))],
        ),
      ),
    );
    search.dispose();
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController keyword;
  final String filterStatus;
  final String filterJenisLoan;
  final ValueChanged<String?> onFilterStatusChanged;
  final ValueChanged<String?> onFilterJenisLoanChanged;
  final VoidCallback onSearch;
  final VoidCallback onTambah;

  const _Toolbar({
    required this.keyword,
    required this.filterStatus,
    required this.filterJenisLoan,
    required this.onFilterStatusChanged,
    required this.onFilterJenisLoanChanged,
    required this.onSearch,
    required this.onTambah,
  });

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
                Text('Prod Kredit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Master produk pinjaman, biaya, provisi, denda, dan SBB COA', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              controller: keyword,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                  hintText: 'Cari kode / nama produk',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
          SizedBox(
            width: 185,
            child: DropdownButtonFormField<String>(
              value: filterJenisLoan,
              decoration: _decoration('Jenis Loan'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua')),
                DropdownMenuItem(value: 'INSTALLMENT', child: Text('Angsuran')),
                DropdownMenuItem(value: 'PRK', child: Text('PRK')),
              ],
              onChanged: onFilterJenisLoanChanged,
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: filterStatus,
              decoration: _decoration('Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua')),
                DropdownMenuItem(value: 'A', child: Text('Aktif')),
                DropdownMenuItem(value: 'D', child: Text('Hapus')),
              ],
              onChanged: onFilterStatusChanged,
            ),
          ),
          ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
              child: const Text('Cari', style: TextStyle(color: Colors.white))),
          ElevatedButton.icon(
              onPressed: onTambah,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Kredit', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(150, 50))),
        ],
      ),
    );
  }
}

class _ProductTable extends StatelessWidget {
  final List<LoanProductModel> items;
  final int page;
  final int limit;
  final ValueChanged<LoanProductModel> onEdit;
  final ValueChanged<LoanProductModel> onDelete;

  const _ProductTable({required this.items, required this.page, required this.limit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Tidak ada data setup kredit.'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(colorPrimary),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        columns: const [
          DataColumn(label: Text('No')),
          DataColumn(label: Text('Kode Produk')),
          DataColumn(label: Text('Nama Produk')),
          DataColumn(label: Text('Jenis Loan')),
          DataColumn(label: Text('Metode Bunga')),
          DataColumn(label: Text('Tenor')),
          DataColumn(label: Text('Rate Provisi')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: List.generate(items.length, (i) {
          final item = items[i];
          return DataRow(cells: [
            DataCell(Text('${((page - 1) * limit) + i + 1}')),
            DataCell(Text(item.kodeProduk, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(SizedBox(width: 280, child: Text(item.namaProduk, overflow: TextOverflow.ellipsis))),
            DataCell(Text(item.jenisLoan)),
            DataCell(Text(item.metodePerhitunganBunga)),
            DataCell(Text('${item.jangkaWaktuMin}-${item.jangkaWaktuMax} bln')),
            DataCell(Text('${item.rateProvisi}%')),
            DataCell(_StatusChip(code: item.statusData)),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton(
                  onPressed: () => onEdit(item),
                  style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                  child: const Text('Edit', style: TextStyle(color: Colors.white))),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: () => onDelete(item),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Hapus', style: TextStyle(color: Colors.white))),
            ])),
          ]);
        }),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int limit;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({required this.page, required this.limit, required this.total, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final from = total == 0 ? 0 : ((page - 1) * limit) + 1;
    final to = total == 0 ? 0 : (page * limit > total ? total : page * limit);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: [
          Expanded(child: Text('Menampilkan $from-$to dari $total data • Halaman $page')),
          OutlinedButton(onPressed: onPrev, child: const Text('Sebelumnya')),
          const SizedBox(width: 8),
          ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
              child: const Text('Selanjutnya', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _StepNavigation extends StatelessWidget {
  final List<String> steps;
  final int current;
  final ValueChanged<int> onTap;

  const _StepNavigation({required this.steps, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Step Prod Kredit', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...List.generate(steps.length, (i) {
          final selected = i == current;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: selected ? colorPrimary : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text('Step ${i + 1}: ${steps[i]}',
                    style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: children.map((e) {
                if (e is _FullWidth) return SizedBox(width: constraints.maxWidth, child: e.child);
                final width = constraints.maxWidth >= 680 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
                return SizedBox(width: width, child: e);
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String title;
  const _GroupTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: colorPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
    );
  }
}

class _FullWidth extends StatelessWidget {
  final Widget child;
  const _FullWidth({required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class _FormNavigation extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const _FormNavigation(
      {required this.current, required this.total, required this.onBack, required this.onNext, required this.onReset, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(onPressed: current == 0 ? null : onBack, child: const Text('Back')),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: current >= total - 1 ? null : onNext, child: const Text('Next')),
        const SizedBox(width: 8),
        ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
            child: const Text('Simpan', style: TextStyle(color: Colors.white))),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String code;
  const _StatusChip({required this.code});

  @override
  Widget build(BuildContext context) {
    final active = code.toUpperCase() == 'A';
    final color = active ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color)),
      child: Text(active ? 'Aktif' : 'Hapus', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

const List<String> _sbbKeys = [
  'sbb_loan',
  'sbb_bunga',
  'sbb_pad',
  'sbb_ppap_coll_1',
  'sbb_ppap_coll_lebih_1',
  'sbb_biaya_administrasi',
  'sbb_provisi',
  'sbb_titipan_notaris',
  'sbb_asuransi_jiwa',
  'sbb_titipan_tunai',
  'sbb_titipan_setoran_credit',
  'sbb_penalty',
  'sbb_materai',
  'sbb_titipan_droping',
  'sbb_titipan_asuransi_agunan',
  'sbb_komitmen',
  'sbb_kontijensi',
  'sbb_write_off',
  'sbb_titipan_provisi',
  'sbb_pend_diterima_dimuka',
  'sbb_kerugian_diperoleh_kembali',
  'sbb_do_prk',
  'sbb_bonus',
];

class _ProgressiveFeeRow {
  final TextEditingController dasar = TextEditingController();
  final TextEditingController biaya = TextEditingController();

  void clear() {
    dasar.clear();
    biaya.clear();
  }

  void dispose() {
    dasar.dispose();
    biaya.dispose();
  }
}

class _CollectibilityRow {
  final String label;
  final String keyPrefix;
  final TextEditingController pokok = TextEditingController();
  final TextEditingController bunga = TextEditingController();
  final TextEditingController jTempo = TextEditingController();
  final TextEditingController bdr = TextEditingController();

  _CollectibilityRow(this.label, this.keyPrefix);

  void clear() {
    pokok.clear();
    bunga.clear();
    jTempo.clear();
    bdr.clear();
  }

  void dispose() {
    pokok.dispose();
    bunga.dispose();
    jTempo.dispose();
    bdr.dispose();
  }
}

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final fromRight = digits.length - i;
      buffer.write(digits[i]);
      if (fromRight > 1 && fromRight % 3 == 1) buffer.write('.');
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

InputDecoration _decoration(String label) {
  return InputDecoration(
      labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), counterText: '');
}

int _int(dynamic raw, [int def = 0]) {
  if (raw == null) return def;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  final text = raw.toString().replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(text) ?? def;
}

double _moneyNum(dynamic raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toDouble();
  final text = raw.toString().replaceAll(RegExp(r'[^0-9]'), '');
  if (text.isEmpty) return 0;
  return double.tryParse(text) ?? 0;
}

double _decimalNum(dynamic raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toDouble();
  final text = raw.toString().trim().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
  if (text.isEmpty) return 0;
  return double.tryParse(text) ?? 0;
}

String _moneyText(num value) {
  final intValue = value.round();
  final digits = intValue.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final fromRight = digits.length - i;
    buffer.write(digits[i]);
    if (fromRight > 1 && fromRight % 3 == 1) buffer.write('.');
  }
  return buffer.toString();
}

String _decimalText(num value) {
  if (value == 0) return '0';
  final text = value.toStringAsFixed(4);
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String _safeText(dynamic value) => value == null ? '' : value.toString();

num _numValue(dynamic raw) {
  if (raw == null) return 0;
  if (raw is num) return raw;
  final text = raw.toString().trim().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
  return num.tryParse(text) ?? 0;
}

bool _rawBool(Map<String, dynamic> raw, List<String> keys, bool def) {
  for (final key in keys) {
    if (!raw.containsKey(key)) continue;
    final value = raw[key];
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (['true', '1', 'y', 'yes', 'ya'].contains(text)) return true;
    if (['false', '0', 'n', 'no', 'tidak'].contains(text)) return false;
  }
  return def;
}

String _rawText(Map<String, dynamic> raw, List<String> keys, String def) {
  for (final key in keys) {
    final value = raw[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return def;
}

String _rawDecimalText(Map<String, dynamic> raw, List<String> keys, String def) {
  for (final key in keys) {
    final value = raw[key];
    if (value == null) continue;
    return _decimalText(_numValue(value));
  }
  return def;
}

String _rawMoneyText(Map<String, dynamic> raw, List<String> keys, String def) {
  for (final key in keys) {
    final value = raw[key];
    if (value == null) continue;
    return _moneyText(_numValue(value));
  }
  return def;
}

String _normalJenisLoan(String value) {
  final v = value.toUpperCase();
  return ['INSTALLMENT', 'PRK'].contains(v) ? v : 'INSTALLMENT';
}

String _normalMetodeBunga(String value) {
  final v = value.toUpperCase().replaceAll('_', '');
  return ['FLAT', 'FLAT78', 'EFEKTIF', 'SLIDING', 'ANNUITAS'].contains(v) ? v : 'FLAT';
}

String _normalJenisRate(String value) {
  final v = value.toUpperCase().replaceAll('_', '');
  return ['FLAT', 'FLAT78', 'SLIDING', 'ANNUITAS'].contains(v) ? v : 'FLAT';
}

String _jenisRateFromMetode(String metode) {
  final v = _normalMetodeBunga(metode);
  return ['FLAT', 'FLAT78', 'SLIDING', 'ANNUITAS'].contains(v) ? v : 'FLAT';
}

String _normalBaseDenda(String value) {
  final v = value.toUpperCase();
  return ['TUNGGAKAN_POKOK', 'POKOK_BUNGA'].contains(v) ? v : 'POKOK_BUNGA';
}

String _normalBasePenalty(String value) {
  final v = value.toUpperCase();
  return ['PERSEN_PLAFOND', 'PERSEN_OS'].contains(v) ? v : 'PERSEN_OS';
}
