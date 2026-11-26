import '../inventaris_operations/inventory_form_layout.dart';
import 'package:cms_core/models/core_access_model.dart';
import 'package:cms_core/models/core_coa_model.dart';
import 'package:cms_core/models/new_menu_models.dart';
import 'package:cms_core/models/kantor_model.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/hris_repository.dart';
import 'package:cms_core/repository/new_menu_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:cms_core/utils/currency_formatted.dart';
import 'package:cms_core/utils/percentage_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AbaPage extends StatefulWidget {
  const AbaPage({super.key});
  @override
  State<AbaPage> createState() => _AbaPageState();
}

class _AbaPageState extends State<AbaPage> {
  final _formKey = GlobalKey<FormState>();
  final _keyword = TextEditingController();
  final _nomorRekening = TextEditingController();
  final _nomorSbb = TextEditingController();
  final _namaSbb = TextEditingController();
  final _namaBank = TextEditingController();
  final _sandiBank = TextEditingController();
  final _jangkaWaktu = TextEditingController();
  final _tanggalBuka = TextEditingController();
  final _sukuBunga = TextEditingController();
  final _coll = TextEditingController();
  final _ppap = TextEditingController();

  List<AbaModel> _items = [];
  bool _loading = true;
  bool _dialog = false;
  bool _editMode = false;
  bool _terkait = false;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;
  String _jenisRekening = 'G';
  String _jenisJangkaWaktu = 'B';
  String _filterJenis = '';
  String _filterStatus = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAccess();
    await _loadList();
  }

  Future<void> _loadAccess() async {
    final pref = Pref();
    final isSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeAba)) {
        current = item;
        break;
      }
    }
    _canCreate = isSuperAdmin || (current?.canCreate ?? false);
    _canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    _canDelete = isSuperAdmin || (current?.canDelete ?? false);
  }

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await NewMenuRepository.abaList(keyword: _keyword.text.trim(), jenisRekening: _filterJenis, statusData: _filterStatus);
    } catch (e) {
      _items = [];
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _clear() {
    _nomorRekening.clear();
    _nomorSbb.clear();
    _namaSbb.clear();
    _namaBank.clear();
    _sandiBank.clear();
    _jangkaWaktu.clear();
    _tanggalBuka.clear();
    _sukuBunga.clear();
    _coll.clear();
    _ppap.clear();
    _jenisRekening = 'G';
    _jenisJangkaWaktu = 'B';
    _terkait = false;
  }

  void _add() {
    _clear();
    setState(() {
      _editMode = false;
      _dialog = true;
    });
  }

  Future<void> _edit(AbaModel item) async {
    if (!_canUpdate) return;
    DialogCustom().showLoading(context);
    try {
      final detail = await NewMenuRepository.abaDetail(item.nomorRekening);
      if (mounted) Navigator.pop(context);
      _fill(detail);
      setState(() {
        _editMode = true;
        _dialog = true;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void _fill(AbaModel item) {
    _nomorRekening.text = item.nomorRekening;
    _nomorSbb.text = item.nomorSbb;
    _namaSbb.text = (item.raw['nama_sbb'] ?? item.raw['nama_coa'] ?? item.raw['namasbb'] ?? '').toString();
    _namaBank.text = item.namaBank;
    _sandiBank.text = item.sandiBank;
    _jangkaWaktu.text = item.jangkaWaktu == 0 ? '' : item.jangkaWaktu.toString();
    _tanggalBuka.text = _dateOnly(item.tanggalBuka);
    _sukuBunga.text = _numText(item.sukuBunga);
    _coll.text = item.coll;
    _ppap.text = _numText(item.ppap);
    _jenisRekening = item.jenisRekening.isEmpty ? 'G' : item.jenisRekening;
    _jenisJangkaWaktu = item.jenisJangkaWaktu.isEmpty ? 'B' : item.jenisJangkaWaktu;
    _terkait = item.terkait;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sukuBunga = parsePercentage(_sukuBunga.text);
    final ppap = parsePercentage(_ppap.text);
    if (_jenisRekening == 'D' && (sukuBunga == null || sukuBunga < 0 || sukuBunga > 100)) {
      informationDialog(context, 'Warning', 'Suku Bunga harus menggunakan format desimal 0 sampai 100.');
      return;
    }
    if (_ppap.text.trim().isNotEmpty && (ppap == null || ppap < 0 || ppap > 100)) {
      informationDialog(context, 'Warning', 'PPAP harus menggunakan format desimal 0 sampai 100.');
      return;
    }
    if (_jenisRekening == 'D') {
      if (_tanggalBuka.text.trim().isEmpty || (int.tryParse(_jangkaWaktu.text.trim()) ?? 0) <= 0) {
        informationDialog(context, 'Warning', 'Untuk jenis deposito, Tanggal Buka dan Jangka Waktu wajib diisi.');
        return;
      }
      final tanggalBuka = DateTime.tryParse(_tanggalBuka.text.trim());
      final hariIni = DateTime.now();
      final batasHariIni = DateTime(hariIni.year, hariIni.month, hariIni.day);
      if (tanggalBuka == null || tanggalBuka.isAfter(batasHariIni)) {
        informationDialog(context, 'Warning', 'Tanggal Buka tidak boleh melewati hari ini.');
        return;
      }
    }

    final body = <String, dynamic>{
      'nomor_rekening': _nomorRekening.text.trim(),
      'nomor_sbb': _nomorSbb.text.trim(),
      'jenis_rekening': _jenisRekening,
      'nama_bank': _namaBank.text.trim().toUpperCase(),
      'sandi_bank': _sandiBank.text.trim(),
      'jangka_waktu': int.tryParse(_jangkaWaktu.text.trim()) ?? 0,
      'jenis_jangka_waktu': _jenisJangkaWaktu,
      'tanggal_buka': _tanggalBuka.text.trim(),
      'suku_bunga': sukuBunga ?? 0,
      'terkait': _terkait,
      'coll': _coll.text.trim(),
      'ppap': ppap ?? 0,
    };

    DialogCustom().showLoading(context);
    try {
      await NewMenuRepository.abaSave(isEdit: _editMode, body: body);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', _editMode ? 'ABA berhasil diupdate.' : 'ABA berhasil ditambahkan.');
      setState(() => _dialog = false);
      await _loadList();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Future<void> _delete(AbaModel item) async {
    DialogCustom().showLoading(context);
    try {
      await NewMenuRepository.abaDelete(item.nomorRekening);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'ABA berhasil dihapus.');
      await _loadList();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Future<void> _pickCoa(TextEditingController target, {TextEditingController? nameTarget}) async {
    final selected = await showDialog<CoreCoaModel>(context: context, builder: (_) => const _CoaPickerDialog());
    if (selected != null) {
      target.text = selected.kodeCoa;
      nameTarget?.text = selected.namaCoa;
    }
  }

  Future<void> _pickSandiBank() async {
    final selected = await showDialog<BankProfileModel>(context: context, builder: (_) => const _BankProfilePickerDialog(title: 'Pilih Sandi Bank'));
    if (selected != null) {
      _sandiBank.text = selected.kodeBank;
      _namaBank.text = selected.displayName.toUpperCase();
    }
  }

  Future<void> _pickTanggalBuka() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateOnly(_tanggalBuka.text)) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _tanggalBuka.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  void _setJenisRekening(String? value) {
    final next = value ?? 'G';
    setState(() {
      _jenisRekening = next;
      if (next != 'D') {
        _jangkaWaktu.clear();
        _tanggalBuka.clear();
        _sukuBunga.clear();
        _jenisJangkaWaktu = 'B';
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_keyword, _nomorRekening, _nomorSbb, _namaSbb, _namaBank, _sandiBank, _jangkaWaktu, _tanggalBuka, _sukuBunga, _coll, _ppap]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ModuleScaffold(
      title: 'ABA',
      subtitle: 'Akun Bank Afiliasi / rekening penempatan dana pada bank lain',
      keyword: _keyword,
      filter: _filterJenis,
      filterItems: const [
        DropdownMenuItem(value: '', child: Text('Semua Jenis')),
        DropdownMenuItem(value: 'G', child: Text('Giro')),
        DropdownMenuItem(value: 'T', child: Text('Tabungan')),
        DropdownMenuItem(value: 'D', child: Text('Deposito')),
      ],
      filterLabel: 'Jenis',
      onFilterChanged: (v) => setState(() => _filterJenis = v ?? ''),
      onSearch: _loadList,
      onAdd: _canCreate ? _add : null,
      addText: 'Tambah ABA',
      loading: _loading,
      error: _error,
      dialog: _dialog,
      body: _AbaTable(items: _items, canUpdate: _canUpdate, canDelete: _canDelete, onEdit: _edit, onDelete: _delete),
      dialogBody: _abaForm(),
    );
  }

  Widget _abaForm() {
    return _SideDialog(
      title: _editMode ? 'Edit ABA' : 'Tambah ABA',
      onClose: () => setState(() => _dialog = false),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _coaField('Sandi Bank', _sandiBank, _pickSandiBank),
          _textField('Nama Bank *', _namaBank, readOnly: true, textCapitalization: TextCapitalization.characters),
          _textField('Nomor Rekening *', _nomorRekening, readOnly: _editMode),
          _dropdown(
              'Jenis Rekening *',
              _jenisRekening,
              const [
                DropdownMenuItem(value: 'G', child: Text('Giro')),
                DropdownMenuItem(value: 'T', child: Text('Tabungan')),
                DropdownMenuItem(value: 'D', child: Text('Deposito'))
              ],
              _setJenisRekening),
          if (_jenisRekening == 'D') ...[
            _textField('Suku Bunga (%) *', _sukuBunga,
                keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: const [PercentageInputFormatter()]),
            _textField('Jangka Waktu *', _jangkaWaktu, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            _dropdown(
                'Jenis Jangka Waktu *',
                _jenisJangkaWaktu,
                const [DropdownMenuItem(value: 'H', child: Text('Hari')), DropdownMenuItem(value: 'B', child: Text('Bulan'))],
                (v) => setState(() => _jenisJangkaWaktu = v ?? 'B')),
            _calendarTextField('Tanggal Buka * (YYYY-MM-DD)', _tanggalBuka, _pickTanggalBuka),
          ],
          _coaField('Nomor SBB', _nomorSbb, () => _pickCoa(_nomorSbb, nameTarget: _namaSbb)),
          _textField('Nama SBB', _namaSbb, readOnly: true),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Terkait pihak berelasi'),
              value: _terkait,
              onChanged: (v) => setState(() => _terkait = v)),
          _textField('Coll', _coll),
          _textField('PPAP (%)', _ppap,
              keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: const [PercentageInputFormatter()]),
          const SizedBox(height: 16),
          _saveButton(_save),
        ]),
      ),
    );
  }
}

class MitraBisnisPage extends StatefulWidget {
  const MitraBisnisPage({super.key});
  @override
  State<MitraBisnisPage> createState() => _MitraBisnisPageState();
}

class _MitraBisnisPageState extends State<MitraBisnisPage> {
  final _formKey = GlobalKey<FormState>();
  final _keyword = TextEditingController();
  final _kodeMitra = TextEditingController();
  final _namaMitra = TextEditingController();
  final _alamat = TextEditingController();
  final _kota = TextEditingController();
  final _kodePos = TextEditingController();
  final _npwp = TextEditingController();
  final _namaPic = TextEditingController();
  final _nomorHpPic = TextEditingController();
  final _nomorTelpPic = TextEditingController();
  final _email = TextEditingController();
  final _nomorRekening = TextEditingController();
  final _bankRekening = TextEditingController();

  List<MitraBisnisModel> _items = [];
  bool _loading = true;
  bool _dialog = false;
  bool _editMode = false;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;
  String _kelompok = 'asuransi';
  String _filterKelompok = '';
  String? _error;

  static const _kelompokOptions = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'asuransi', child: Text('Asuransi')),
    DropdownMenuItem(value: 'developer', child: Text('Developer')),
    DropdownMenuItem(value: 'dealer', child: Text('Dealer')),
    DropdownMenuItem(value: 'notaris', child: Text('Notaris')),
    DropdownMenuItem(value: 'bank', child: Text('Bank')),
    DropdownMenuItem(value: 'lembaga_keuangan_lainnya', child: Text('Lembaga Keuangan Lainnya')),
    DropdownMenuItem(value: 'organisasi_guru', child: Text('Organisasi Guru')),
    DropdownMenuItem(value: 'organisasi_lainnya', child: Text('Organisasi Lainnya')),
    DropdownMenuItem(value: 'instansi_pemerintah', child: Text('Instansi Pemerintah')),
    DropdownMenuItem(value: 'perguruan_tinggi', child: Text('Perguruan Tinggi')),
    DropdownMenuItem(value: 'lembaga_sekolah', child: Text('Lembaga Sekolah')),
    DropdownMenuItem(value: 'pt', child: Text('PT')),
    DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAccess();
    await _loadList();
  }

  Future<void> _loadAccess() async {
    final pref = Pref();
    final isSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeMitraBisnis)) {
        current = item;
        break;
      }
    }
    _canCreate = isSuperAdmin || (current?.canCreate ?? false);
    _canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    _canDelete = isSuperAdmin || (current?.canDelete ?? false);
  }

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await NewMenuRepository.mitraList(keyword: _keyword.text.trim(), kelompok: _filterKelompok);
    } catch (e) {
      _items = [];
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _clear() {
    for (final c in [
      _kodeMitra,
      _namaMitra,
      _alamat,
      _kota,
      _kodePos,
      _npwp,
      _namaPic,
      _nomorHpPic,
      _nomorTelpPic,
      _email,
      _nomorRekening,
      _bankRekening
    ]) {
      c.clear();
    }
    _kelompok = 'asuransi';
  }

  void _add() {
    _clear();
    setState(() {
      _editMode = false;
      _dialog = true;
    });
  }

  Future<void> _edit(MitraBisnisModel item) async {
    if (!_canUpdate) return;
    DialogCustom().showLoading(context);
    try {
      final detail = await NewMenuRepository.mitraDetail(item.kodeMitra);
      if (mounted) Navigator.pop(context);
      _fill(detail);
      setState(() {
        _editMode = true;
        _dialog = true;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void _fill(MitraBisnisModel item) {
    _kodeMitra.text = item.kodeMitra;
    _namaMitra.text = item.namaMitra;
    _alamat.text = item.alamat;
    _kota.text = item.kota;
    _kodePos.text = item.kodePos;
    _npwp.text = item.npwp;
    _namaPic.text = item.namaPic;
    _nomorHpPic.text = item.nomorHpPic;
    _nomorTelpPic.text = item.nomorTelpPic;
    _email.text = item.email;
    _nomorRekening.text = item.nomorRekening;
    _bankRekening.text = item.bankRekening;
    _kelompok = item.kelompok.isEmpty ? 'asuransi' : item.kelompok;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final body = <String, dynamic>{
      'kode_mitra': _kodeMitra.text.trim().toUpperCase(),
      'kelompok': _kelompok,
      'nama_mitra': _namaMitra.text.trim().toUpperCase(),
      'alamat': _alamat.text.trim(),
      'kota': _kota.text.trim(),
      'kode_pos': _kodePos.text.trim(),
      'npwp': _npwp.text.trim(),
      'nama_pic': _namaPic.text.trim(),
      'nomor_hp_pic': _nomorHpPic.text.trim(),
      'nomor_telp_pic': _nomorTelpPic.text.trim(),
      'email': _email.text.trim(),
      'nomor_rekening': _nomorRekening.text.trim(),
      'bank_rekening': _bankRekening.text.trim(),
    };
    DialogCustom().showLoading(context);
    try {
      await NewMenuRepository.mitraSave(isEdit: _editMode, body: body);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', _editMode ? 'Mitra Bisnis berhasil diupdate.' : 'Mitra Bisnis berhasil ditambahkan.');
      setState(() => _dialog = false);
      await _loadList();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Future<void> _delete(MitraBisnisModel item) async {
    DialogCustom().showLoading(context);
    try {
      await NewMenuRepository.mitraDelete(item.kodeMitra);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'Mitra Bisnis berhasil dihapus.');
      await _loadList();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Future<void> _pickBankRekening() async {
    final selected =
        await showDialog<BankProfileModel>(context: context, builder: (_) => const _BankProfilePickerDialog(title: 'Pilih Bank Rekening'));
    if (selected != null) {
      setState(() {
        _bankRekening.text = selected.displayName.toUpperCase();
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _keyword,
      _kodeMitra,
      _namaMitra,
      _alamat,
      _kota,
      _kodePos,
      _npwp,
      _namaPic,
      _nomorHpPic,
      _nomorTelpPic,
      _email,
      _nomorRekening,
      _bankRekening
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ModuleScaffold(
      title: 'Mitra Bisnis',
      subtitle: 'Master data rekanan bank: asuransi, developer, dealer, notaris, bank, dan lainnya',
      keyword: _keyword,
      filter: _filterKelompok,
      filterItems: [const DropdownMenuItem(value: '', child: Text('Semua Kelompok')), ..._kelompokOptions],
      filterLabel: 'Kelompok',
      onFilterChanged: (v) => setState(() => _filterKelompok = v ?? ''),
      onSearch: _loadList,
      onAdd: _canCreate ? _add : null,
      addText: 'Tambah Mitra',
      loading: _loading,
      error: _error,
      dialog: _dialog,
      body: _MitraTable(items: _items, canUpdate: _canUpdate, canDelete: _canDelete, onEdit: _edit, onDelete: _delete),
      dialogBody: _mitraForm(),
    );
  }

  Widget _mitraForm() {
    return _SideDialog(
      title: _editMode ? 'Edit Mitra Bisnis' : 'Tambah Mitra Bisnis',
      onClose: () => setState(() => _dialog = false),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _textField('Kode Mitra *', _kodeMitra, readOnly: _editMode, textCapitalization: TextCapitalization.characters),
          _dropdown('Kelompok *', _kelompok, _kelompokOptions, (v) => setState(() => _kelompok = v ?? 'asuransi')),
          _textField('Nama Mitra *', _namaMitra, textCapitalization: TextCapitalization.characters),
          _textField('Alamat *', _alamat, maxLines: 2),
          _textField('Kota *', _kota, inputFormatters: [_LettersAndSpacesInputFormatter()]),
          _textField('Kode Pos', _kodePos,
              keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)]),
          _textField('NPWP', _npwp),
          _textField('Nama PIC *', _namaPic, inputFormatters: [_LettersAndSpacesInputFormatter()]),
          _textField('Nomor HP PIC', _nomorHpPic,
              keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)]),
          _textField('Nomor Telp PIC', _nomorTelpPic,
              keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)]),
          _textField('Email', _email, keyboardType: TextInputType.emailAddress),
          _coaField('Cari Bank Rekening', _bankRekening, _pickBankRekening),
          _textField('Nomor Rekening', _nomorRekening,
              keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)]),
          const SizedBox(height: 16),
          _saveButton(_save),
        ]),
      ),
    );
  }
}

class MasterInventarisPage extends StatefulWidget {
  const MasterInventarisPage({super.key});
  @override
  State<MasterInventarisPage> createState() => _MasterInventarisPageState();
}

class _MasterInventarisPageState extends State<MasterInventarisPage> {
  final _formKey = GlobalKey<FormState>();
  final _keyword = TextEditingController();
  final _kodeInventaris = TextEditingController();
  final _namaInventaris = TextEditingController();
  final _groupAset = TextEditingController();
  final _lokasi = TextEditingController();
  final _alamat = TextEditingController();
  final _kelurahan = TextEditingController();
  final _kecamatan = TextEditingController();
  final _kota = TextEditingController();
  final _kodeKantor = TextEditingController();
  final _namaKantor = TextEditingController();
  final _masaPenyusutan = TextEditingController();
  final _keterangan = TextEditingController();
  final _tanggalBeli = TextEditingController();
  final _nomorDokumen = TextEditingController();
  final _tanggalKirim = TextEditingController();
  final _hargaBeli = TextEditingController();
  final _discount = TextEditingController();
  final _biaya = TextEditingController();
  final _ppnNominal = TextEditingController();
  final _awalPenyusutan = TextEditingController();
  final _totalPerolehan = TextEditingController();
  String _existingLocation = '';
  final _nilaiSusutPerbulan = TextEditingController();
  final _namaMitra = TextEditingController();
  final _rekeningMitra = TextEditingController();

  List<MasterInventarisAsetModel> _items = [];
  List<SetupInventarisModel> _groupAsetOptions = [];
  bool _loading = true;
  bool _loadingGroupAset = false;
  bool _dialog = false;
  bool _editMode = false;
  bool _penyusutan = false;
  bool _lokasiDiKantor = true;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;
  String _kelompokAset = 'BE';
  String _statusAset = 'O';
  String _kondisiAset = 'BK';
  String _filterKelompok = '';
  String _filterStatus = '';
  String? _error;

  static const _kelompokAsetItems = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'RH', child: Text('Rumah')),
    DropdownMenuItem(value: 'MT', child: Text('Motor')),
    DropdownMenuItem(value: 'MB', child: Text('Mobil')),
    DropdownMenuItem(value: 'KP', child: Text('Kapal')),
    DropdownMenuItem(value: 'KA', child: Text('Kereta Api')),
    DropdownMenuItem(value: 'MM', child: Text('Mesin-Mesin')),
    DropdownMenuItem(value: 'GD', child: Text('Gedung')),
    DropdownMenuItem(value: 'TN', child: Text('Tanah')),
    DropdownMenuItem(value: 'BB', child: Text('Barang Berharga')),
    DropdownMenuItem(value: 'HP', child: Text('Hasil Pertanian')),
    DropdownMenuItem(value: 'HB', child: Text('Hasil Perkebunan')),
    DropdownMenuItem(value: 'FR', child: Text('Furniture')),
    DropdownMenuItem(value: 'BE', child: Text('Barang Elektronik')),
    DropdownMenuItem(value: 'LY', child: Text('Lainnya')),
  ];

  static const _statusAsetItems = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'O', child: Text('Open')),
    DropdownMenuItem(value: 'R', child: Text('Reserved')),
    DropdownMenuItem(value: 'C', child: Text('Close')),
    DropdownMenuItem(value: 'X', child: Text('Reject')),
    DropdownMenuItem(value: 'D', child: Text('Disewakan')),
    DropdownMenuItem(value: 'J', child: Text('Dijual')),
    DropdownMenuItem(value: 'S', child: Text('Sewa')),
    DropdownMenuItem(value: 'K', child: Text('Disewa-kan')),
  ];

  static const _kondisiItems = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'BK', child: Text('Baik')),
    DropdownMenuItem(value: 'BC', child: Text('Baik Dengan Catatan')),
    DropdownMenuItem(value: 'CT', child: Text('Cacat')),
    DropdownMenuItem(value: 'RS', child: Text('Rusak')),
    DropdownMenuItem(value: 'DP', child: Text('Dalam Proses')),
    DropdownMenuItem(value: 'BS', child: Text('Berbeda Spesifikasi')),
    DropdownMenuItem(value: 'BQ', child: Text('Berbeda Kualitas')),
    DropdownMenuItem(value: 'LN', child: Text('Lainnya')),
  ];

  @override
  void initState() {
    super.initState();
    for (final c in [_hargaBeli, _discount, _biaya, _ppnNominal]) {
      c.addListener(_updateTotalAsset);
    }
    _init();
  }

  void _updateTotalAsset() {
    final total = _double(_hargaBeli.text) - _double(_discount.text) + _double(_biaya.text) + _double(_ppnNominal.text);
    _totalPerolehan.text = total == 0 ? '0' : '${total < 0 ? '-' : ''}${_currencyText(total.abs())}';
  }

  Future<void> _init() async {
    await _loadAccess();
    await _loadCurrentUserKantor();
    await _loadGroupAsetOptions();
    await _loadList();
  }

  Future<void> _loadAccess() async {
    final pref = Pref();
    final isSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeInventaris)) {
        current = item;
        break;
      }
    }
    _canCreate = isSuperAdmin || (current?.canCreate ?? false);
    _canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    _canDelete = isSuperAdmin || (current?.canDelete ?? false);
  }

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await NewMenuRepository.inventarisList(keyword: _keyword.text.trim(), kelompokAset: _filterKelompok, statusData: _filterStatus);
    } catch (e) {
      _items = [];
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadGroupAsetOptions({bool showError = false}) async {
    if (mounted) setState(() => _loadingGroupAset = true);
    try {
      final rows = await NewMenuRepository.setupInventarisList(statusData: '');
      if (!mounted) return;
      setState(() {
        _groupAsetOptions = rows;
        _loadingGroupAset = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _groupAsetOptions = [];
        _loadingGroupAset = false;
      });
      if (showError) {
        informationDialog(context, 'Warning', 'Gagal memuat data Setup Inventaris: $e');
      }
    }
  }

  Future<void> _loadCurrentUserKantor() async {
    try {
      final users = await Pref().getUsers();
      final currentCode = users.kodeKantor.trim();
      if (currentCode.isEmpty) return;
      final offices = await HrisRepository.listKantor();
      KantorModel? selected;
      for (final office in offices) {
        if (office.kodeKantor.trim().toUpperCase() == currentCode.toUpperCase()) {
          selected = office;
          break;
        }
      }
      if (selected != null) {
        _fillLokasiFromKantor(selected);
      } else {
        _kodeKantor.text = currentCode;
      }
    } catch (_) {}
  }

  void _fillLokasiFromKantor(KantorModel kantor) {
    _kodeKantor.text = kantor.kodeKantor;
    _namaKantor.text = kantor.namaKantor;
    _alamat.text = kantor.alamat;
    _kelurahan.text = kantor.kelurahan;
    _kecamatan.text = kantor.kecamatan;
    _kota.text = kantor.kota;
    _lokasi.text = kantor.alamat;
  }

  Future<void> _pickKantorInventaris() async {
    final selected = await showDialog<KantorModel>(context: context, builder: (_) => const _KantorPickerDialog());
    if (selected != null) {
      final kantor = selected;
      setState(() {
        if (_lokasiDiKantor) {
          _fillLokasiFromKantor(kantor);
        } else {
          // Lokasi luar kantor tetap memakai alamat yang dimasukkan pengguna.
          _kodeKantor.text = kantor.kodeKantor;
          _namaKantor.text = kantor.namaKantor;
        }
      });
    }
  }

  void _setLokasiAset(bool diKantor) {
    setState(() {
      _lokasiDiKantor = diKantor;
      _alamat.clear();
      _kelurahan.clear();
      _kecamatan.clear();
      _kota.clear();
      _kodeKantor.clear();
      _namaKantor.clear();
      _lokasi.clear();
    });
    if (diKantor) {
      _loadCurrentUserKantor();
    }
  }

  List<DropdownMenuItem<String>> _groupAsetDropdownItems() {
    final seen = <String>{};
    final items = <DropdownMenuItem<String>>[];
    for (final row in _groupAsetOptions) {
      final value = row.groupInventaris.trim().toUpperCase();
      if (value.isEmpty || seen.contains(value)) continue;
      seen.add(value);
      final subtitle = row.labelGroup.trim();
      items.add(DropdownMenuItem(
        value: value,
        child: Text(subtitle.isEmpty || subtitle == value ? value : '$value - $subtitle'),
      ));
    }
    final selected = _groupAset.text.trim().toUpperCase();
    if (selected.isNotEmpty && !seen.contains(selected)) {
      items.add(DropdownMenuItem(value: selected, child: Text('$selected - data existing')));
    }
    return items;
  }

  void _setGroupAset(String? value) {
    final selected = (value ?? '').trim().toUpperCase();
    int masaManfaat = 0;
    for (final row in _groupAsetOptions) {
      if (row.groupInventaris.trim().toUpperCase() == selected) {
        masaManfaat = row.masaManfaatBulan;
        if (masaManfaat > 0) break;
      }
    }
    setState(() {
      _groupAset.text = selected;
      // Masa manfaat menjadi nilai awal dan tetap dapat diubah pengguna.
      _masaPenyusutan.text = masaManfaat > 0 ? masaManfaat.toString() : '';
    });
  }

  DateTime _initialDate(String value) {
    final parsed = DateTime.tryParse(value.trim());
    return parsed != null && !parsed.isAfter(DateTime.now()) ? parsed : DateTime.now();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _initialDate(controller.text),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => controller.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _pickDepreciationMonth() async {
    final parts = _awalPenyusutan.text.trim().split('-');
    int selectedMonth = parts.length == 2 ? int.tryParse(parts[0]) ?? DateTime.now().month : DateTime.now().month;
    int selectedYear = parts.length == 2 ? int.tryParse(parts[1]) ?? DateTime.now().year : DateTime.now().year;
    final result = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pilih Awal Penyusutan'),
          content: Row(mainAxisSize: MainAxisSize.min, children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedMonth,
                decoration: _inputDecoration('Bulan'),
                items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text((index + 1).toString().padLeft(2, '0')))),
                onChanged: (value) => setDialogState(() => selectedMonth = value ?? selectedMonth),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: _inputDecoration('Tahun'),
                items: List.generate(101, (index) {
                  final year = DateTime.now().year - 80 + index;
                  return DropdownMenuItem(value: year, child: Text(year.toString()));
                }),
                onChanged: (value) => setDialogState(() => selectedYear = value ?? selectedYear),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, [selectedMonth, selectedYear]), child: const Text('Pilih')),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() => _awalPenyusutan.text = '${result[0].toString().padLeft(2, '0')}-${result[1]}');
    }
  }

  Widget _calendarField(String label, TextEditingController controller, {bool monthOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: monthOnly ? _pickDepreciationMonth : () => _pickDate(controller),
        decoration: _inputDecoration(label).copyWith(suffixIcon: const Icon(Icons.calendar_month)),
        validator: label.contains('*') ? (value) => (value ?? '').trim().isEmpty ? '$label wajib diisi' : null : null,
      ),
    );
  }

  void _clear() {
    for (final c in [
      _kodeInventaris,
      _namaInventaris,
      _groupAset,
      _lokasi,
      _alamat,
      _kelurahan,
      _kecamatan,
      _kota,
      _kodeKantor,
      _namaKantor,
      _masaPenyusutan,
      _keterangan,
      _tanggalBeli,
      _nomorDokumen,
      _tanggalKirim,
      _hargaBeli,
      _discount,
      _biaya,
      _ppnNominal,
      _awalPenyusutan,
      _totalPerolehan,
      _nilaiSusutPerbulan,
      _namaMitra,
      _rekeningMitra
    ]) {
      c.clear();
    }
    _kelompokAset = 'BE';
    _statusAset = 'O';
    _kondisiAset = 'BK';
    _penyusutan = false;
    _lokasiDiKantor = true;
  }

  Future<void> _add() async {
    _clear();
    _updateTotalAsset();
    await _loadCurrentUserKantor();
    await _loadGroupAsetOptions(showError: true);
    setState(() {
      _editMode = false;
      _dialog = true;
    });
  }

  Future<void> _edit(MasterInventarisAsetModel item) async {
    if (!_canUpdate) return;
    DialogCustom().showLoading(context);
    try {
      await _loadGroupAsetOptions(showError: true);
      final detail = await NewMenuRepository.inventarisDetail(item.kodeInventaris);
      if (mounted) Navigator.pop(context);
      _fill(detail);
      setState(() {
        _editMode = true;
        _dialog = true;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  void _fill(MasterInventarisAsetModel item) {
    _kodeInventaris.text = item.kodeInventaris;
    _namaInventaris.text = item.namaInventaris;
    _groupAset.text = item.groupAset;
    _lokasi.text = item.lokasi;
    _existingLocation = item.raw['lokasi_aset']?.toString() ?? '';
    _alamat.text = item.alamat;
    _kelurahan.text = item.kelurahan;
    _kecamatan.text = item.kecamatan;
    _kota.text = item.kota;
    _kodeKantor.text = item.kodeKantor;
    _namaKantor.text = item.namaKantor;
    final jenisLokasi = (item.raw['jenis_lokasi'] ?? item.raw['jenis_penempatan'] ?? item.lokasi).toString().trim().toUpperCase();
    _lokasiDiKantor = jenisLokasi == 'KANTOR' || jenisLokasi == 'DALAM_KANTOR';
    _masaPenyusutan.text = item.masaPenyusutan == 0 ? '' : item.masaPenyusutan.toString();
    _keterangan.text = item.keterangan;
    _tanggalBeli.text = _dateOnly(item.tanggalBeli);
    _nomorDokumen.text = item.nomorDokumen;
    _tanggalKirim.text = _dateOnly(item.tanggalKirim);
    _hargaBeli.text = _currencyText(item.hargaBeli);
    _discount.text = _currencyText(item.discount);
    _biaya.text = _currencyText(item.biaya);
    _ppnNominal.text = _currencyText(item.ppnNominal);
    _awalPenyusutan.text = item.awalPenyusutan;
    _updateTotalAsset();
    _nilaiSusutPerbulan.text = _currencyText(item.nilaiSusutPerbulan);
    _namaMitra.text = item.namaMitra;
    _rekeningMitra.text = item.rekeningMitra;
    _kelompokAset = item.kelompokAset.isEmpty ? 'BE' : item.kelompokAset;
    _statusAset = item.statusAset.isEmpty ? 'O' : item.statusAset;
    _kondisiAset = item.kondisiAset.isEmpty ? 'BK' : item.kondisiAset;
    _penyusutan = item.penyusutan;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_penyusutan && ((int.tryParse(_masaPenyusutan.text.trim()) ?? 0) <= 0 || _awalPenyusutan.text.trim().isEmpty)) {
      informationDialog(context, 'Warning', 'Jika penyusutan aktif, masa dan awal penyusutan wajib diisi.');
      return;
    }
    final body = <String, dynamic>{
      'kode_inventaris': _kodeInventaris.text.trim().toUpperCase(),
      'nama_inventaris': _namaInventaris.text.trim(),
      'kelompok_aset': _kelompokAset,
      'group_aset': _groupAset.text.trim().toUpperCase(),
      'lokasi_aset': _editMode ? _existingLocation : 'KANTOR',
      'alamat': _alamat.text.trim(),
      'kelurahan': _kelurahan.text.trim(),
      'kecamatan': _kecamatan.text.trim(),
      'kota': _kota.text.trim(),
      'kode_kantor': _kodeKantor.text.trim(),
      'nama_kantor': _namaKantor.text.trim(),
      'status_aset': _statusAset,
      'penyusutan': _penyusutan,
      'masa_penyusutan': int.tryParse(_masaPenyusutan.text.trim()) ?? 0,
      'kondisi_aset': _kondisiAset,
      'keterangan': _keterangan.text.trim(),
      'tanggal_beli': _tanggalBeli.text.trim(),
      'nomor_dokumen': _nomorDokumen.text.trim(),
      'tanggal_kirim': _tanggalKirim.text.trim(),
      'harga_beli': _double(_hargaBeli.text),
      'discount': _double(_discount.text),
      'biaya': _double(_biaya.text),
      'ppn_nominal': _double(_ppnNominal.text),
      if (_penyusutan) 'awal_penyusutan': _awalPenyusutan.text.trim(),
      'nama_mitra': _namaMitra.text.trim(),
      'rekening_mitra': _rekeningMitra.text.trim(),
    };
    DialogCustom().showLoading(context);
    try {
      await NewMenuRepository.inventarisSave(isEdit: _editMode, body: body);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', _editMode ? 'Inventaris berhasil diupdate.' : 'Inventaris berhasil ditambahkan.');
      setState(() => _dialog = false);
      await _loadList();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Future<void> _delete(MasterInventarisAsetModel item) async {
    DialogCustom().showLoading(context);
    try {
      await NewMenuRepository.inventarisDelete(item.kodeInventaris);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'Inventaris berhasil dihapus.');
      await _loadList();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  void dispose() {
    for (final c in [_hargaBeli, _discount, _biaya, _ppnNominal]) {
      c.removeListener(_updateTotalAsset);
    }
    for (final c in [
      _keyword,
      _kodeInventaris,
      _namaInventaris,
      _groupAset,
      _lokasi,
      _alamat,
      _kelurahan,
      _kecamatan,
      _kota,
      _kodeKantor,
      _namaKantor,
      _masaPenyusutan,
      _keterangan,
      _tanggalBeli,
      _nomorDokumen,
      _tanggalKirim,
      _hargaBeli,
      _discount,
      _biaya,
      _ppnNominal,
      _awalPenyusutan,
      _totalPerolehan,
      _nilaiSusutPerbulan,
      _namaMitra,
      _rekeningMitra
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ModuleScaffold(
      title: 'Inventaris',
      subtitle: 'Master data aset inventaris',
      keyword: _keyword,
      filter: _filterKelompok,
      filterItems: [const DropdownMenuItem(value: '', child: Text('Semua Kelompok')), ..._kelompokAsetItems],
      filterLabel: 'Kelompok',
      onFilterChanged: (v) => setState(() => _filterKelompok = v ?? ''),
      onSearch: _loadList,
      onAdd: _canCreate ? _add : null,
      addText: 'Tambah Inventaris',
      loading: _loading,
      error: _error,
      dialog: _dialog,
      body: _InventarisTable(items: _items, canUpdate: _canUpdate, canDelete: _canDelete, onEdit: _edit, onDelete: _delete),
      dialogBody: _inventarisForm(),
    );
  }

  Widget _groupAsetField() {
    final items = _groupAsetDropdownItems();
    if (_loadingGroupAset) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          readOnly: true,
          decoration: _inputDecoration('Group Aset *').copyWith(hintText: 'Memuat data Setup Inventaris...'),
        ),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            readOnly: true,
            decoration: _inputDecoration('Group Aset *').copyWith(hintText: 'Data Setup Inventaris belum tersedia'),
            validator: (_) => 'Group Aset wajib dipilih dari Setup Inventaris',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _loadGroupAsetOptions(showError: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang Setup Inventaris'),
            ),
          ),
        ]),
      );
    }
    final selected = _groupAset.text.trim().toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: items.any((e) => e.value == selected) ? selected : null,
        decoration: _inputDecoration('Group Aset *').copyWith(helperText: 'Diambil dari menu Setup > Jenis Inventaris'),
        items: items,
        onChanged: _setGroupAset,
        validator: (value) => (value ?? '').trim().isEmpty ? 'Group Aset wajib dipilih dari Setup Inventaris' : null,
      ),
    );
  }

  Widget _lokasiAsetSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('LOKASI ASET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _dropdown(
          'Pilih Lokasi *',
          _lokasiDiKantor ? 'KANTOR' : 'LUAR_KANTOR',
          const [
            DropdownMenuItem(value: 'KANTOR', child: Text('Kantor')),
            DropdownMenuItem(value: 'LUAR_KANTOR', child: Text('Luar Kantor')),
          ],
          (v) => _setLokasiAset((v ?? 'KANTOR') == 'KANTOR'),
        ),
        if (!_lokasiDiKantor)
          Wrap(
            spacing: 12,
            runSpacing: 0,
            children: [
              SizedBox(width: 750, child: _textField('Alamat *', _alamat)),
              SizedBox(width: 215, child: _textField('Kelurahan', _kelurahan)),
              SizedBox(width: 215, child: _textField('Kecamatan', _kecamatan)),
              SizedBox(width: 215, child: _textField('Kota *', _kota)),
            ],
          ),
        Wrap(
          spacing: 12,
          runSpacing: 0,
          children: [
            SizedBox(
              width: 250,
              child: _coaField('Kode Kantor *', _kodeKantor, _pickKantorInventaris),
            ),
            SizedBox(width: 330, child: _textField('Nama Kantor *', _namaKantor, readOnly: true)),
          ],
        ),
      ]),
    );
  }

  Widget _inventarisForm() {
    return _SideDialog(
      title: _editMode ? 'Edit Inventaris' : 'Tambah Inventaris',
      width: 1120,
      onClose: () => setState(() => _dialog = false),
      child: Form(
        key: _formKey,
        child: InventoryFormGrid(children: [
          _textField('Kode Inventaris *', _kodeInventaris, readOnly: _editMode, textCapitalization: TextCapitalization.characters),
          _textField('Nama Inventaris *', _namaInventaris),
          _dropdown('Kelompok Aset *', _kelompokAset, _kelompokAsetItems, (v) => setState(() => _kelompokAset = v ?? 'BE')),
          _groupAsetField(),
          _dropdown('Status Aset', _statusAset, _statusAsetItems, (v) => setState(() => _statusAset = v ?? 'O')),
          _dropdown('Kondisi Aset *', _kondisiAset, _kondisiItems, (v) => setState(() => _kondisiAset = v ?? 'BK')),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Penyusutan'),
              value: _penyusutan,
              onChanged: (v) => setState(() => _penyusutan = v)),
          if (_penyusutan) ...[
            _textField('Masa Penyusutan *', _masaPenyusutan,
                keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            _calendarField('Awal Penyusutan * (MM-YYYY)', _awalPenyusutan, monthOnly: true),
          ],
          _calendarField('Tanggal Beli * (YYYY-MM-DD)', _tanggalBeli),
          _textField('Nomor Dokumen', _nomorDokumen),
          _calendarField('Tanggal Kirim (YYYY-MM-DD)', _tanggalKirim),
          _textField('Harga Beli *', _hargaBeli, keyboardType: TextInputType.number, inputFormatters: [CurrencyInputFormatter()]),
          _textField('Discount', _discount, keyboardType: TextInputType.number, inputFormatters: [CurrencyInputFormatter()]),
          _textField('Biaya', _biaya, keyboardType: TextInputType.number, inputFormatters: [CurrencyInputFormatter()]),
          _textField('PPN Nominal', _ppnNominal, keyboardType: TextInputType.number, inputFormatters: [CurrencyInputFormatter()]),
          _textField('Total Nilai Aset', _totalPerolehan, readOnly: true),
          if (_editMode) ...[
            if (_penyusutan) _textField('Nilai Susut per Bulan', _nilaiSusutPerbulan, readOnly: true),
          ],
          _textField('Nama Supplier', _namaMitra),
          _textField('Rekening Supplier', _rekeningMitra),
          InventoryFullWidth(child: _textField('Keterangan', _keterangan, maxLines: 2)),
          InventoryFullWidth(child: _saveButton(_save)),
        ]),
      ),
    );
  }
}

class _AbaTable extends StatelessWidget {
  final List<AbaModel> items;
  final bool canUpdate;
  final bool canDelete;
  final void Function(AbaModel) onEdit;
  final void Function(AbaModel) onDelete;
  const _AbaTable({required this.items, required this.canUpdate, required this.canDelete, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Tidak ada data ABA.'));
    return _TableScroll(
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(colorPrimary),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        columns: const [
          DataColumn(label: Text('No Rekening')),
          DataColumn(label: Text('SBB')),
          DataColumn(label: Text('Jenis')),
          DataColumn(label: Text('Nama Bank')),
          DataColumn(label: Text('Suku Bunga')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Otorisasi')),
          DataColumn(label: Text('Aksi'))
        ],
        rows: items
            .map((item) => DataRow(cells: [
                  DataCell(Text(item.nomorRekening)),
                  DataCell(Text(item.nomorSbb)),
                  DataCell(Text(item.jenisLabel)),
                  DataCell(SizedBox(width: 220, child: Text(item.namaBank, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(_numText(item.sukuBunga))),
                  DataCell(Text(item.statusData)),
                  DataCell(Text(item.statusOtorisasi)),
                  DataCell(_actions(canUpdate: canUpdate, canDelete: canDelete, onEdit: () => onEdit(item), onDelete: () => onDelete(item))),
                ]))
            .toList(),
      ),
    );
  }
}

class _MitraTable extends StatelessWidget {
  final List<MitraBisnisModel> items;
  final bool canUpdate;
  final bool canDelete;
  final void Function(MitraBisnisModel) onEdit;
  final void Function(MitraBisnisModel) onDelete;
  const _MitraTable({required this.items, required this.canUpdate, required this.canDelete, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Tidak ada data Mitra Bisnis.'));
    return _TableScroll(
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(colorPrimary),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        columns: const [
          DataColumn(label: Text('Kode Mitra')),
          DataColumn(label: Text('Kelompok')),
          DataColumn(label: Text('Nama Mitra')),
          DataColumn(label: Text('Kota')),
          DataColumn(label: Text('PIC')),
          DataColumn(label: Text('No HP PIC')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi'))
        ],
        rows: items
            .map((item) => DataRow(cells: [
                  DataCell(Text(item.kodeMitra)),
                  DataCell(Text(item.kelompok)),
                  DataCell(SizedBox(width: 240, child: Text(item.namaMitra, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(item.kota)),
                  DataCell(Text(item.namaPic)),
                  DataCell(Text(item.nomorHpPic)),
                  DataCell(Text(item.statusData)),
                  DataCell(_actions(canUpdate: canUpdate, canDelete: canDelete, onEdit: () => onEdit(item), onDelete: () => onDelete(item))),
                ]))
            .toList(),
      ),
    );
  }
}

class _InventarisTable extends StatelessWidget {
  final List<MasterInventarisAsetModel> items;
  final bool canUpdate;
  final bool canDelete;
  final void Function(MasterInventarisAsetModel) onEdit;
  final void Function(MasterInventarisAsetModel) onDelete;
  const _InventarisTable({required this.items, required this.canUpdate, required this.canDelete, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Tidak ada data Inventaris.'));
    return _TableScroll(
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(colorPrimary),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        columns: const [
          DataColumn(label: Text('Kode')),
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('Kelompok')),
          DataColumn(label: Text('Group')),
          DataColumn(label: Text('Kantor')),
          DataColumn(label: Text('Status Aset')),
          DataColumn(label: Text('Kondisi')),
          DataColumn(label: Text('Harga Beli')),
          DataColumn(label: Text('Status Data')),
          DataColumn(label: Text('Aksi'))
        ],
        rows: items
            .map((item) => DataRow(cells: [
                  DataCell(Text(item.kodeInventaris)),
                  DataCell(SizedBox(width: 240, child: Text(item.namaInventaris, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(item.kelompokAsetLabel.isEmpty ? item.kelompokAset : item.kelompokAsetLabel)),
                  DataCell(Text(item.groupAset)),
                  DataCell(Text(item.kodeKantor)),
                  DataCell(Text(item.statusAsetLabel.isEmpty ? item.statusAset : item.statusAsetLabel)),
                  DataCell(Text(item.kondisiAsetLabel.isEmpty ? item.kondisiAset : item.kondisiAsetLabel)),
                  DataCell(Text(_numText(item.hargaBeli))),
                  DataCell(Text(item.statusData)),
                  DataCell(_actions(canUpdate: canUpdate, canDelete: canDelete, onEdit: () => onEdit(item), onDelete: () => onDelete(item))),
                ]))
            .toList(),
      ),
    );
  }
}

class _ModuleScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController keyword;
  final String filter;
  final List<DropdownMenuItem<String>> filterItems;
  final String filterLabel;
  final ValueChanged<String?> onFilterChanged;
  final VoidCallback onSearch;
  final VoidCallback? onAdd;
  final String addText;
  final bool loading;
  final String? error;
  final Widget body;
  final bool dialog;
  final Widget dialogBody;

  const _ModuleScaffold(
      {required this.title,
      required this.subtitle,
      required this.keyword,
      required this.filter,
      required this.filterItems,
      required this.filterLabel,
      required this.onFilterChanged,
      required this.onSearch,
      required this.onAdd,
      required this.addText,
      required this.loading,
      required this.error,
      required this.body,
      required this.dialog,
      required this.dialogBody});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(
                    width: 300,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.black54))
                    ])),
                SizedBox(
                    width: 280,
                    child: TextField(
                        controller: keyword,
                        onSubmitted: (_) => onSearch(),
                        decoration: _inputDecoration('Cari').copyWith(prefixIcon: const Icon(Icons.search)))),
                SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                        value: filter, decoration: _inputDecoration(filterLabel), items: filterItems, onChanged: onFilterChanged)),
                ElevatedButton(
                    onPressed: onSearch,
                    style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
                    child: const Text('Cari', style: TextStyle(color: Colors.white))),
                if (onAdd != null)
                  ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(addText, style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(150, 50))),
              ]),
            ),
            Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? Center(child: Text(error!))
                        : body),
          ]),
          if (dialog) dialogBody,
        ]),
      ),
    );
  }
}

class _SideDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final double width;
  const _SideDialog({required this.title, required this.child, required this.onClose, this.width = 640});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        alignment: Alignment.centerRight,
        child: Container(
          width: width,
          height: double.infinity,
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close))
              ]),
              const SizedBox(height: 18),
              child,
            ]),
          ),
        ),
      ),
    );
  }
}

class _TableScroll extends StatelessWidget {
  final Widget child;
  const _TableScroll({required this.child});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), scrollDirection: Axis.horizontal, child: SingleChildScrollView(child: child));
  }
}

Widget _actions({required bool canUpdate, required bool canDelete, required VoidCallback onEdit, required VoidCallback onDelete}) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
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
  ]);
}

Widget _textField(String label, TextEditingController controller,
    {bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1}) {
  final required = label.contains('*');
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
      validator: required ? (v) => (v ?? '').trim().isEmpty ? '$label wajib diisi' : null : null,
    ),
  );
}

Widget _coaField(String label, TextEditingController controller, VoidCallback onPick) {
  final required = label.contains('*');
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      decoration: _inputDecoration(label).copyWith(suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: onPick)),
      validator: required ? (v) => (v ?? '').trim().isEmpty ? '$label wajib diisi' : null : null,
    ),
  );
}

Widget _calendarTextField(String label, TextEditingController controller, VoidCallback onPick) {
  final required = label.contains('*');
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onPick,
      decoration: _inputDecoration(label).copyWith(suffixIcon: const Icon(Icons.calendar_month)),
      validator: required ? (value) => (value ?? '').trim().isEmpty ? '$label wajib diisi' : null : null,
    ),
  );
}

class _LettersAndSpacesInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return RegExp(r'^[A-Za-z ]*$').hasMatch(newValue.text) ? newValue : oldValue;
  }
}

Widget _dropdown(String label, String value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: items.any((e) => e.value == value) ? value : items.first.value,
      decoration: _inputDecoration(label),
      items: items,
      onChanged: onChanged,
      validator: label.contains('*') ? (v) => (v ?? '').trim().isEmpty ? '$label wajib dipilih' : null : null,
    ),
  );
}

Widget _saveButton(VoidCallback onPressed) {
  return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(double.infinity, 50)),
      child: const Text('Simpan', style: TextStyle(color: Colors.white)));
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true);
}

double _double(String text) {
  final cleaned = cleanCurrencyInput(text);
  return double.tryParse(cleaned) ?? 0;
}

String _numText(double value) {
  if (value == 0) return '';
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toString();
}

String _currencyText(double value) {
  if (value == 0) return '';
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _dateOnly(String value) {
  final text = value.trim();
  if (text.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text)) return text.substring(0, 10);
  return text;
}

class _BankProfilePickerDialog extends StatefulWidget {
  final String title;
  const _BankProfilePickerDialog({this.title = 'Pilih Bank'});
  @override
  State<_BankProfilePickerDialog> createState() => _BankProfilePickerDialogState();
}

class _BankProfilePickerDialogState extends State<_BankProfilePickerDialog> {
  final search = TextEditingController();
  late Future<List<BankProfileModel>> future = _load();

  Future<List<BankProfileModel>> _load() async {
    return NewMenuRepository.searchBankProfile(keyword: search.text.trim(), limit: 100);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 720,
        height: 500,
        child: Column(children: [
          Row(children: [
            Expanded(
                child: TextField(
                    controller: search, onSubmitted: (_) => setState(() => future = _load()), decoration: _inputDecoration('Cari kode / nama bank'))),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: () => setState(() => future = _load()), child: const Text('Cari')),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<BankProfileModel>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) return const Center(child: Text('Data bank tidak ditemukan.'));
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    return ListTile(
                      title: Text(row.displayName.isEmpty ? row.kodeBank : row.displayName),
                      subtitle: Text([row.kodeBank, row.jenis, row.tipe].where((e) => e.trim().isNotEmpty).join(' • ')),
                      trailing: row.registrationStatus.isEmpty
                          ? null
                          : Text(row.registrationStatus, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      onTap: () => Navigator.pop(context, row),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _KantorPickerDialog extends StatefulWidget {
  const _KantorPickerDialog();
  @override
  State<_KantorPickerDialog> createState() => _KantorPickerDialogState();
}

class _KantorPickerDialogState extends State<_KantorPickerDialog> {
  final search = TextEditingController();
  late Future<List<KantorModel>> future = HrisRepository.listKantor();

  Future<List<KantorModel>> _load() async {
    final rows = await HrisRepository.listKantor();
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((e) {
      return e.kodeKantor.toLowerCase().contains(q) ||
          e.namaKantor.toLowerCase().contains(q) ||
          e.alamat.toLowerCase().contains(q) ||
          e.kota.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Kantor'),
      content: SizedBox(
        width: 720,
        height: 500,
        child: Column(children: [
          Row(children: [
            Expanded(
                child: TextField(
                    controller: search,
                    onSubmitted: (_) => setState(() => future = _load()),
                    decoration: _inputDecoration('Cari kode / nama kantor'))),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: () => setState(() => future = _load()), child: const Text('Cari')),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<KantorModel>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) return const Center(child: Text('Data kantor tidak ditemukan.'));
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    return ListTile(
                      title: Text('${row.kodeKantor} - ${row.namaKantor}'),
                      subtitle: Text([row.alamat, row.kelurahan, row.kecamatan, row.kota].where((e) => e.trim().isNotEmpty).join(', ')),
                      onTap: () => Navigator.pop(context, row),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _CoaPickerDialog extends StatefulWidget {
  const _CoaPickerDialog();
  @override
  State<_CoaPickerDialog> createState() => _CoaPickerDialogState();
}

class _CoaPickerDialogState extends State<_CoaPickerDialog> {
  final search = TextEditingController();
  late Future<List<CoreCoaModel>> future = NewMenuRepository.searchCoa(limit: 40);

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih COA / SBB'),
      content: SizedBox(
        width: 640,
        height: 480,
        child: Column(children: [
          Row(children: [
            Expanded(
                child: TextField(
                    controller: search,
                    onSubmitted: (_) => setState(() => future = NewMenuRepository.searchCoa(keyword: search.text.trim(), limit: 40)),
                    decoration: _inputDecoration('Cari kode / nama COA'))),
            const SizedBox(width: 8),
            ElevatedButton(
                onPressed: () => setState(() => future = NewMenuRepository.searchCoa(keyword: search.text.trim(), limit: 40)),
                child: const Text('Cari')),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<CoreCoaModel>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) return const Center(child: Text('COA tidak ditemukan.'));
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    return ListTile(title: Text(row.kodeCoa), subtitle: Text(row.namaCoa), onTap: () => Navigator.pop(context, row));
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
