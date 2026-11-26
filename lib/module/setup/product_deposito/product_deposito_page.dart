import 'bilyet_format_dialog.dart';
import 'package:cms_core/models/core_coa_model.dart';
import 'package:cms_core/models/deposit_product_model.dart';
import 'package:cms_core/repository/deposit_product_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:cms_core/utils/percentage_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductDepositoPage extends StatefulWidget {
  const ProductDepositoPage({super.key});

  @override
  State<ProductDepositoPage> createState() => _ProductDepositoPageState();
}

class _ProductDepositoPageState extends State<ProductDepositoPage> {
  final _formKey = GlobalKey<FormState>();
  final _keyword = TextEditingController();
  final _controllers = <String, TextEditingController>{};

  final List<DepositProductModel> _items = [];
  int _page = 1;
  int _limit = 50;
  int _total = 0;
  bool _isLoading = true;
  bool _dialog = false;
  bool _editData = false;
  int _step = 0;
  String _filterStatus = 'A';
  String? _errorMessage;

  String _jenisJangkaWaktu = 'BULAN';
  String _pembayaranBunga = 'CASH_BASIS';
  String _faktorPembagi = '365';
  String _pencadanganBunga = 'PROPOSIONAL';
  String _perhitunganPinalti = 'PERSENTASE';
  String _bungaDepositoPI = 'TIAP_JATUH_TEMPO';
  bool _pencairanBebas = true;
  bool _pencairanDikenakanPinalti = false;
  bool _bilyetDigital = false;

  final List<_PenaltyRow> _penaltyRows = List.generate(3, (_) => _PenaltyRow());

  final Map<String, String> _coaDisplay = {};

  final List<String> _steps = const [
    'Identitas Produk',
    'Pencairan & Penalti',
    'Setup SBB',
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
      'singkatan_produk': '',
      'nama_produk': '',
      'jangka_waktu': '1',
      'minimal_nominal_deposito': '500000',
      'maksimal_nominal_deposito': '1000000000000',
      'rate_deposito': '2.00',
      'maksimal_spread': '0',
      'maksimal_deposito_tidak_kena_pajak': '7500000',
      'rate_pajak': '20.00',
      'sbb_deposito': '',
      'sbb_biaya_bunga': '',
      'sbb_titipan_pajak': '',
      'sbb_materai': '',
      'sbb_titipan_acrual_bunga': '',
      'sbb_titipan_pencairan_pokok': '',
      'sbb_titipan_pencairan_bunga': '',
      'sbb_penalti': '',
      'sbb_titipan_bunga_jatuh_tempo': '',
      'sbb_subsidi_tax': '',
    };
    for (final entry in defaults.entries) {
      _controllers.putIfAbsent(entry.key, () => TextEditingController(text: entry.value));
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
    for (final row in _penaltyRows) {
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
      final result = await DepositProductRepository.list(
        keyword: _keyword.text.trim(),
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
    c('kode_produk').text = '';
    c('singkatan_produk').text = '';
    c('nama_produk').text = '';
    c('kode_format_bilyet').text = '';
    c('jangka_waktu').text = '1';
    c('minimal_nominal_deposito').text = _moneyText(500000);
    c('maksimal_nominal_deposito').text = _moneyText(1000000000000);
    c('rate_deposito').text = '2.00';
    c('maksimal_spread').text = '0';
    c('maksimal_deposito_tidak_kena_pajak').text = _moneyText(7500000);
    c('rate_pajak').text = '20.00';

    for (final key in [
      'sbb_deposito',
      'sbb_biaya_bunga',
      'sbb_titipan_pajak',
      'sbb_materai',
      'sbb_titipan_acrual_bunga',
      'sbb_titipan_pencairan_pokok',
      'sbb_titipan_pencairan_bunga',
      'sbb_penalti',
      'sbb_titipan_bunga_jatuh_tempo',
      'sbb_subsidi_tax',
    ]) {
      c(key).text = '';
    }
    _coaDisplay.clear();

    _jenisJangkaWaktu = 'BULAN';
    _pembayaranBunga = 'CASH_BASIS';
    _faktorPembagi = '365';
    _pencadanganBunga = 'PROPOSIONAL';
    _perhitunganPinalti = 'PERSENTASE';
    _bungaDepositoPI = 'TIAP_JATUH_TEMPO';
    _pencairanBebas = true;
    _pencairanDikenakanPinalti = false;
    _bilyetDigital = false;
    _step = 0;
    for (final row in _penaltyRows) {
      row.clear();
    }
  }

  void _tambah() {
    _clear();
    setState(() {
      _editData = false;
      _dialog = true;
    });
  }

  Future<void> _edit(DepositProductModel row) async {
    try {
      DialogCustom().showLoading(context);
      final detail = await DepositProductRepository.detail(row.kodeProduk);
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

  void _fillFromModel(DepositProductModel model) {
    _clear();
    c('kode_produk').text = model.kodeProduk;
    c('singkatan_produk').text = model.singkatanProduk;
    c('nama_produk').text = model.namaProduk;
    c('kode_format_bilyet').text = (model.raw['kode_format_bilyet'] ?? '').toString();
    c('jangka_waktu').text = model.jangkaWaktu.toString();
    c('minimal_nominal_deposito').text = _moneyText(model.minimalNominalDeposito);
    c('maksimal_nominal_deposito').text = _moneyText(model.maksimalNominalDeposito);
    c('rate_deposito').text = _decimalText(model.rateDeposito);
    c('maksimal_spread').text = _decimalText(model.maksimalSpread);
    c('maksimal_deposito_tidak_kena_pajak').text = _moneyText(model.maksimalDepositoTidakKenaPajak);
    c('rate_pajak').text = _decimalText(model.ratePajak);

    _jenisJangkaWaktu = _normalJangkaWaktu(model.jenisJangkaWaktu);
    _pembayaranBunga = _normalPembayaran(model.pembayaranBunga);
    _faktorPembagi = ['365', '360', '12'].contains(model.faktorPembagi.toString()) ? model.faktorPembagi.toString() : '365';
    _pencadanganBunga = _normalPencadangan(model.pencadanganBungaAcrual);
    _perhitunganPinalti = _normalPinalti(model.perhitunganPinalti);
    _bungaDepositoPI = _normalBungaPI(model.bungaDepositoPI);
    _pencairanBebas = model.pencairanBebasKapanSaja;
    _pencairanDikenakanPinalti = model.pencairanAbnormalPinalti;
    _bilyetDigital = _boolValue(model.raw['bl_digital'] ?? model.raw['bilyet_digital']);

    c('sbb_deposito').text = model.sbbDeposito;
    c('sbb_biaya_bunga').text = model.sbbBiayaBunga;
    c('sbb_titipan_pajak').text = model.sbbTitipanPajak;
    c('sbb_materai').text = model.sbbMaterai;
    c('sbb_titipan_acrual_bunga').text = model.sbbTitipanAcrualBunga;
    c('sbb_titipan_pencairan_pokok').text = model.sbbTitipanPencairanPokok;
    c('sbb_titipan_pencairan_bunga').text = model.sbbTitipanPencairanBunga;
    c('sbb_penalti').text = model.sbbPenalti;
    c('sbb_titipan_bunga_jatuh_tempo').text = model.sbbTitipanBungaJatuhTempo;
    c('sbb_subsidi_tax').text = model.sbbSubsidiTax;

    _fillPenaltyRows(model);
  }

  Future<void> _delete(DepositProductModel row) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Anda yakin menghapus produk ${row.kodeProduk} - ${row.namaProduct}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                DialogCustom().showLoading(context);
                await DepositProductRepository.delete(row.kodeProduk);
                if (mounted) Navigator.pop(context);
                informationDialog(context, 'Informasi', 'Produk deposito berhasil dihapus.');
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

    if (_step == 1) {
      final penaltyError = _validatePenaltyRows();
      if (penaltyError != null) {
        informationDialog(context, 'Warning', penaltyError);
        return;
      }
    }

    if (_step < _steps.length - 1) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_pembayaranBunga != 'CASH_BASIS' && _pencadanganBunga.isEmpty) {
      setState(() => _step = 0);
      informationDialog(context, 'Warning', 'Pencadangan Bunga wajib dipilih untuk pembayaran bunga accrual.');
      return;
    }

    final penaltyError = _validatePenaltyRows();
    if (penaltyError != null) {
      setState(() => _step = 1);
      informationDialog(context, 'Warning', penaltyError);
      return;
    }

    final body = _buildBody();
    try {
      DialogCustom().showLoading(context);
      await DepositProductRepository.save(isEdit: _editData, body: body);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', _editData ? 'Produk deposito berhasil diupdate.' : 'Produk deposito berhasil ditambahkan.');
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

  String? _validatePenaltyRows() {
    if (!_pencairanDikenakanPinalti) return null;

    int previousDay = 0;
    bool hasFinalDay99 = false;

    for (int i = 0; i < _penaltyRows.length; i++) {
      final row = _penaltyRows[i];
      final day = _int(row.jumlahHari.text);
      if (day == 0) continue;

      if (!_isPenaltyDayAllowed(day)) {
        return 'Jml Hari baris ${i + 1} hanya boleh 1-31 atau 99.';
      }

      if (day <= previousDay) {
        final minText = previousDay == 99 ? 'tidak ada, karena baris sebelumnya sudah 99' : '${previousDay + 1}';
        return 'Jml Hari baris ${i + 1} harus lebih besar dari baris aktif sebelumnya. Minimal: $minText.';
      }

      if (_perhitunganPinalti == 'PERSENTASE') {
        if (_decimalNum(row.persen.text) <= 0) {
          return 'Persen baris ${i + 1} wajib diisi karena Perhitungan Penalti = Persen.';
        }
      } else {
        if (_moneyNum(row.denda.text) <= 0) {
          return 'Nominal baris ${i + 1} wajib diisi karena Perhitungan Penalti = Nominal.';
        }
      }

      if (day == 99) {
        hasFinalDay99 = true;
      }

      previousDay = day;
    }

    if (!hasFinalDay99) {
      return 'Table penalti wajib memiliki minimal 1 baris dengan Jml Hari 99 sebagai batas akhir.';
    }

    return null;
  }

  void _fillPenaltyRows(DepositProductModel model) {
    for (final row in _penaltyRows) {
      row.clear();
    }

    final rows = model.penalti.take(_penaltyRows.length).toList();
    for (int i = 0; i < rows.length; i++) {
      final source = rows[i];
      final target = _penaltyRows[i];
      if (source.jumlahHari > 0) {
        target.jumlahHari.text = source.jumlahHari.toString();
      }
      final perhitungan = _normalPinalti(model.perhitunganPinalti);
      if (perhitungan == 'PERSENTASE') {
        final rate = source.rate > 0 ? source.rate : source.nilai;
        if (rate > 0) target.persen.text = _decimalText(rate);
        if (source.nominal > 0) target.denda.text = _moneyText(source.nominal);
      } else {
        final nominal = source.nominal > 0 ? source.nominal : source.nilai;
        if (nominal > 0) target.denda.text = _moneyText(nominal);
      }
      target.bungaDibayar = source.bungaBerjalanDibayar;
    }

    if (rows.isEmpty && _pencairanDikenakanPinalti && model.minimalPinalti > 0) {
      _penaltyRows.first.jumlahHari.text = '99';
      _penaltyRows.first.denda.text = _moneyText(model.minimalPinalti);
      _penaltyRows.first.bungaDibayar = true;
    }
  }

  List<Map<String, dynamic>> _penaltyPayloadRows() {
    if (!_pencairanDikenakanPinalti) return [];

    final rows = <Map<String, dynamic>>[];
    for (final row in _penaltyRows) {
      final day = _int(row.jumlahHari.text);
      if (day == 0 || !_isPenaltyDayAllowed(day)) continue;

      final rate = _perhitunganPinalti == 'PERSENTASE' ? _decimalNum(row.persen.text) : 0.0;
      final nominal = _moneyNum(row.denda.text);
      rows.add({
        'jumlah_hari': day,
        'rate': rate > 0 ? rate : null,
        'nominal': nominal > 0 ? nominal : null,
        'bunga_berjalan_dibayar': row.bungaDibayar,
      });
    }
    return rows;
  }

  double _minimalPinaltiFromRows() {
    if (!_pencairanDikenakanPinalti) return 0;

    for (final row in _penaltyRows) {
      final day = _int(row.jumlahHari.text);
      if (day == 0 || !_isPenaltyDayAllowed(day)) continue;

      final nominal = _moneyNum(row.denda.text);
      if (nominal > 0) return nominal;
    }

    return 0;
  }

  Map<String, dynamic> _buildBody() {
    return {
      'kode_produk': c('kode_produk').text.trim().toUpperCase(),
      'kode_format_bilyet': _bilyetDigital ? '' : c('kode_format_bilyet').text.trim(),
      'singkatan_produk': c('singkatan_produk').text.trim(),
      'bl_digital': _bilyetDigital,
      'bilyet_digital': _bilyetDigital,
      'nama_produk': c('nama_produk').text.trim(),
      'jangka_waktu': _int(c('jangka_waktu').text),
      'jenis_jangka_waktu': _jenisJangkaWaktu,
      'pembayaran_bunga': _pembayaranBunga,
      'faktor_pembagi': _int(_faktorPembagi, 365),
      'pencadangan_bunga_acrual': _pembayaranBunga == 'CASH_BASIS' ? null : _pencadanganBunga,
      'pencairan_bebas_kapan_saja': _pencairanBebas,
      'pencairan_abnormal_pinalti': _pencairanDikenakanPinalti,
      'perhitungan_pinalti': _pencairanDikenakanPinalti ? _perhitunganPinalti : null,
      'minimal_pinalti': _pencairanDikenakanPinalti ? _minimalPinaltiFromRows() : 0,
      'penalti': _penaltyPayloadRows(),
      'bunga_deposito_P_I': _bungaDepositoPI,
      'rate_deposito': _decimalNum(c('rate_deposito').text),
      'minimal_nominal_deposito': _moneyNum(c('minimal_nominal_deposito').text),
      'maksimal_nominal_deposito': _moneyNum(c('maksimal_nominal_deposito').text),
      'maksimal_spread': _decimalNum(c('maksimal_spread').text),
      'maksimal_deposito_tidak_kena_pajak': _moneyNum(c('maksimal_deposito_tidak_kena_pajak').text),
      'rate_pajak': _decimalNum(c('rate_pajak').text),
      'sbb_deposito': _coaCode('sbb_deposito'),
      'sbb_biaya_bunga': _coaCode('sbb_biaya_bunga'),
      'sbb_titipan_pajak': _coaCode('sbb_titipan_pajak'),
      'sbb_materai': _coaCode('sbb_materai'),
      'sbb_titipan_acrual_bunga': _coaCode('sbb_titipan_acrual_bunga'),
      'sbb_titipan_pencairan_pokok': _coaCode('sbb_titipan_pencairan_pokok'),
      'sbb_titipan_pencairan_bunga': _coaCode('sbb_titipan_pencairan_bunga'),
      'sbb_penalti': _coaCode('sbb_penalti'),
      'sbb_titipan_bunga_jatuh_tempo': _coaCode('sbb_titipan_bunga_jatuh_tempo'),
      'sbb_subsidi_tax': _coaCode('sbb_subsidi_tax'),
    };
  }

  String _coaCode(String key) {
    final text = c(key).text.trim();
    return text.contains(' - ') ? text.split(' - ').first.trim() : text;
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
                  onFilterStatusChanged: (value) => setState(() => _filterStatus = value ?? ''),
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
          width: MediaQuery.of(context).size.width > 1120 ? 1040 : MediaQuery.of(context).size.width * 0.94,
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
                        child: Text(_editData ? 'Edit Produk Deposito' : 'Tambah Produk Deposito',
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
                                      onSave: _save),
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
          SizedBox(width: 220, child: _text('Singkatan Produk', 'singkatan_produk', required: true)),
          SizedBox(
            width: 190,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _bilyetDigital,
              title: const Text('Bilyet Digital'),
              subtitle: Text(_bilyetDigital ? 'ON' : 'OFF'),
              activeColor: colorPrimary,
              onChanged: (v) => setState(() => _bilyetDigital = v),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBilyet() async {
    if (_bilyetDigital) return;
    final selected = await pickBilyetFormat(context);
    if (!mounted || selected == null || _bilyetDigital) return;
    setState(() => c('kode_format_bilyet').text = selected);
  }

  Widget _bilyetField() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_bilyetDigital)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Menggunakan Format Bilyet Digital milik BPR dari Setup Format Bilyet Digital.'),
        )
      else TextFormField(
        controller: c('kode_format_bilyet'),
        readOnly: true,
        onTap: _pickBilyet,
        decoration: _decoration('Kode Bilyet').copyWith(
          hintText: 'Pilih format bilyet',
          suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            if (c('kode_format_bilyet').text.isNotEmpty)
              IconButton(tooltip: 'Kosongkan pilihan', icon: const Icon(Icons.clear),
                onPressed: () => setState(() => c('kode_format_bilyet').clear())),
            IconButton(tooltip: 'Pilih bilyet', icon: const Icon(Icons.search), onPressed: _pickBilyet),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _bilyetDigital
          ? () => showDigitalBilyetFormat(context)
          : c('kode_format_bilyet').text.trim().isEmpty ? null
          : () => showBilyetFormat(context, c('kode_format_bilyet').text.trim()),
        icon: const Icon(Icons.visibility_outlined),
        label: Text(_bilyetDigital ? 'Lihat Format Bilyet Digital' : 'Lihat Format Bilyet'),
      ),
    ],
  );

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _SectionCard(
          title: 'Identitas Produk Deposito',
          children: [
            _dropdown('Jenis Jangka Waktu', _jenisJangkaWaktu, const {'BULAN': 'Bulan', 'HARI': 'Hari'},
                (v) => setState(() => _jenisJangkaWaktu = v ?? 'BULAN')),
            _integer('Jangka Waktu', 'jangka_waktu', required: true),
            _text('Nama Panjang Produk', 'nama_produk', required: true),
            _bilyetField(),
            _money('Minimal Nominal Deposito', 'minimal_nominal_deposito'),
            _money('Maksimal Nominal Deposito', 'maksimal_nominal_deposito'),
            _dropdown('Faktor Pembagi', _faktorPembagi, const {'365': 'A-365', '360': 'B-360', '12': 'C-12'},
                (v) => setState(() => _faktorPembagi = v ?? '365')),
            _decimal('Bunga per Tahun (%)', 'rate_deposito'),
            _dropdown('Pencairan Bunga', _bungaDepositoPI, const {'TIAP_BULAN': 'Bulan', 'TIAP_JATUH_TEMPO': 'Jatuh Tempo'},
                (v) => setState(() => _bungaDepositoPI = v ?? 'TIAP_JATUH_TEMPO')),
            _dropdown(
                'Pembayaran Bunga',
                _pembayaranBunga,
                const {
                  'CASH_BASIS': 'CASH_BASIS',
                  'ACRUAL_HARIAN': 'ACRUAL_HARIAN',
                  'ACRUAL_BULANAN': 'ACRUAL_BULANAN',
                },
                (v) => setState(() => _pembayaranBunga = v ?? 'CASH_BASIS')),
            _dropdown('Pencadangan Bunga (Akrual)', _pencadanganBunga, const {'PROPOSIONAL': 'P-Proportional', 'FULL': 'F-Full'},
                (v) => setState(() => _pencadanganBunga = v ?? 'PROPOSIONAL'),
                enabled: _pembayaranBunga != 'CASH_BASIS'),
            _decimal('Maksimal Spread', 'maksimal_spread'),
          ],
        );
      case 1:
        return _SectionCard(
          title: 'Pencairan & Penalti',
          children: [
            _switch('Pencairan Bebas kapan saja', _pencairanBebas, (v) => setState(() => _pencairanBebas = v)),
            _switch('Pencairan dikenakan Penalti', _pencairanDikenakanPinalti, (v) => setState(() => _pencairanDikenakanPinalti = v)),
            _dropdown('Perhitungan Penalti', _perhitunganPinalti, const {'PERSENTASE': 'Persen', 'NOMINAL_TETAP': 'Nominal'}, (v) {
              final selected = v ?? 'PERSENTASE';
              setState(() {
                _perhitunganPinalti = selected;
                if (selected == 'NOMINAL_TETAP') {
                  for (final row in _penaltyRows) {
                    row.persen.clear();
                  }
                }
              });
            }, enabled: _pencairanDikenakanPinalti),
            _FullWidth(
                child: _PenaltyTable(rows: _penaltyRows, enabled: _pencairanDikenakanPinalti, allowPercent: _perhitunganPinalti == 'PERSENTASE')),
          ],
        );
      default:
        return _SectionCard(
          title: 'Setup SBB Produk Deposito',
          children: [
            _coa('SBB Deposito', 'sbb_deposito'),
            _coa('SBB Biaya Bunga', 'sbb_biaya_bunga'),
            _coa('SBB Titipan Pajak', 'sbb_titipan_pajak'),
            _coa('SBB Materai', 'sbb_materai'),
            _coa('SBB Titipan Akrual Bunga', 'sbb_titipan_acrual_bunga'),
            _coa('SBB Titipan Pencairan Pokok', 'sbb_titipan_pencairan_pokok'),
            _coa('SBB Titipan Pencairan Bunga', 'sbb_titipan_pencairan_bunga'),
            _coa('SBB Penalti', 'sbb_penalti'),
            _coa('SBB Titipan Bunga Jatuh Tempo', 'sbb_titipan_bunga_jatuh_tempo'),
            _coa('SBB Subsidi Tax', 'sbb_subsidi_tax'),
          ],
        );
    }
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

  Widget _integer(String label, String key, {bool required = false}) {
    return TextFormField(
      controller: c(key),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) => required && _int(value) <= 0 ? 'Wajib > 0' : null,
      decoration: _decoration(label),
    );
  }

  Widget _decimal(String label, String key, {bool enabled = true}) {
    return TextFormField(
      controller: c(key),
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: const [PercentageInputFormatter()],
      validator: validatePercentage,
      decoration: _decoration(label),
    );
  }

  Widget _money(String label, String key, {bool enabled = true}) {
    return TextFormField(
      controller: c(key),
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, _RupiahInputFormatter()],
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

  Widget _coa(String label, String key) {
    return TextFormField(
      controller: c(key),
      readOnly: true,
      decoration: _decoration(label).copyWith(
        suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _showCoaDialog(label, key)),
      ),
    );
  }

  Future<void> _showCoaDialog(String label, String key) async {
    final search = TextEditingController();
    Future<List<CoreCoaModel>> future = DepositProductRepository.searchCoa();
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
                            onSubmitted: (_) => setDialogState(() => future = DepositProductRepository.searchCoa(keyword: search.text.trim())))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setDialogState(() => future = DepositProductRepository.searchCoa(keyword: search.text.trim())),
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
                              _coaDisplay[key] = coa.namaCoa;
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
  final ValueChanged<String?> onFilterStatusChanged;
  final VoidCallback onSearch;
  final VoidCallback onTambah;

  const _Toolbar(
      {required this.keyword, required this.filterStatus, required this.onFilterStatusChanged, required this.onSearch, required this.onTambah});

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
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Produk Deposito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Master produk deposito, pencairan, penalti, dan SBB COA', style: TextStyle(color: Colors.black54)),
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
            width: 150,
            child: DropdownButtonFormField<String>(
              value: filterStatus,
              decoration: _decoration('Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua')),
                DropdownMenuItem(value: 'A', child: Text('Aktif')),
                DropdownMenuItem(value: 'D', child: Text('Hapus'))
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
              label: const Text('Tambah Produk', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(150, 50))),
        ],
      ),
    );
  }
}

class _ProductTable extends StatelessWidget {
  final List<DepositProductModel> items;
  final int page;
  final int limit;
  final ValueChanged<DepositProductModel> onEdit;
  final ValueChanged<DepositProductModel> onDelete;

  const _ProductTable({required this.items, required this.page, required this.limit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Tidak ada data produk deposito.'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(colorPrimary),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        columns: const [
          DataColumn(label: Text('No')),
          DataColumn(label: Text('Kode Produk')),
          DataColumn(label: Text('Singkatan')),
          DataColumn(label: Text('Nama Produk')),
          DataColumn(label: Text('Jangka Waktu')),
          DataColumn(label: Text('Pembayaran Bunga')),
          DataColumn(label: Text('Rate')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: List.generate(items.length, (i) {
          final item = items[i];
          return DataRow(cells: [
            DataCell(Text('${((page - 1) * limit) + i + 1}')),
            DataCell(Text(item.kodeProduk, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(SizedBox(width: 120, child: Text(item.singkatanProduk, overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 280, child: Text(item.namaProduk, overflow: TextOverflow.ellipsis))),
            DataCell(Text('${item.jangkaWaktu} ${item.jenisJangkaWaktu}')),
            DataCell(Text(item.pembayaranBunga)),
            DataCell(Text('${item.rateDeposito}%')),
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
        const Text('Step Produk Deposito', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _FullWidth extends StatelessWidget {
  final Widget child;
  const _FullWidth({required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class _PenaltyTable extends StatefulWidget {
  final List<_PenaltyRow> rows;
  final bool enabled;
  final bool allowPercent;

  const _PenaltyTable({required this.rows, required this.enabled, required this.allowPercent});

  @override
  State<_PenaltyTable> createState() => _PenaltyTableState();
}

class _PenaltyTableState extends State<_PenaltyTable> {
  bool _isRowActive(_PenaltyRow row) {
    final day = _int(row.jumlahHari.text);
    return widget.enabled && day > 0 && _isPenaltyDayAllowed(day);
  }

  void _handleDayChanged(_PenaltyRow row, String raw) {
    final day = _int(raw);
    setState(() {
      if (day == 0) {
        row.persen.clear();
        row.denda.clear();
        row.bungaDibayar = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            headingRowHeight: 38,
            columns: const [
              DataColumn(label: Text('< Jml Hari')),
              DataColumn(label: Text('Persen')),
              DataColumn(label: Text('Nominal')),
              DataColumn(label: Text('Bunga Berjalan Dibayar')),
            ],
            rows: widget.rows.map((row) {
              final active = _isRowActive(row);
              final percentEnabled = active && widget.allowPercent;
              final nominalEnabled = active;

              return DataRow(cells: [
                DataCell(SizedBox(
                  width: 90,
                  child: TextField(
                    controller: row.jumlahHari,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, _PenaltyDayInputFormatter()],
                    onChanged: (v) => _handleDayChanged(row, v),
                    decoration: const InputDecoration(isDense: true, hintText: '0'),
                  ),
                )),
                DataCell(SizedBox(
                  width: 90,
                  child: TextField(
                    controller: row.persen,
                    enabled: percentEnabled,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [PercentageInputFormatter()],
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: percentEnabled ? '0.00' : '-',
                      filled: true,
                      fillColor: percentEnabled ? Colors.white : Colors.grey.shade200,
                    ),
                  ),
                )),
                DataCell(SizedBox(
                  width: 120,
                  child: TextField(
                    controller: row.denda,
                    enabled: nominalEnabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, _RupiahInputFormatter()],
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: nominalEnabled ? '0' : '-',
                      filled: true,
                      fillColor: nominalEnabled ? Colors.white : Colors.grey.shade200,
                    ),
                  ),
                )),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  Radio<bool>(
                      value: true, groupValue: row.bungaDibayar, onChanged: active ? (v) => setState(() => row.bungaDibayar = v ?? true) : null),
                  const Text('Ya'),
                  Radio<bool>(
                      value: false, groupValue: row.bungaDibayar, onChanged: active ? (v) => setState(() => row.bungaDibayar = v ?? false) : null),
                  const Text('Tidak'),
                ])),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
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

class _PenaltyRow {
  final TextEditingController jumlahHari = TextEditingController();
  final TextEditingController persen = TextEditingController();
  final TextEditingController denda = TextEditingController();
  bool bungaDibayar = true;

  void clear() {
    jumlahHari.clear();
    persen.clear();
    denda.clear();
    bungaDibayar = true;
  }

  void dispose() {
    jumlahHari.dispose();
    persen.dispose();
    denda.dispose();
  }
}

bool _isPenaltyDayAllowed(int day) {
  return day == 0 || (day >= 1 && day <= 31) || day == 99;
}

class _PenaltyDayInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final value = int.tryParse(digits);
    if (value == null || !_isPenaltyDayAllowed(value)) {
      return oldValue;
    }

    return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
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

bool _boolValue(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  final text = value.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'y' || text == 'yes';
}

String _normalJangkaWaktu(String value) => value.toUpperCase() == 'HARI' ? 'HARI' : 'BULAN';
String _normalPembayaran(String value) =>
    ['CASH_BASIS', 'ACRUAL_HARIAN', 'ACRUAL_BULANAN'].contains(value.toUpperCase()) ? value.toUpperCase() : 'CASH_BASIS';
String _normalPencadangan(String value) => value.toUpperCase() == 'FULL' ? 'FULL' : 'PROPOSIONAL';
String _normalPinalti(String value) => value.toUpperCase() == 'NOMINAL_TETAP' ? 'NOMINAL_TETAP' : 'PERSENTASE';
String _normalBungaPI(String value) => value.toUpperCase() == 'TIAP_BULAN' ? 'TIAP_BULAN' : 'TIAP_JATUH_TEMPO';
