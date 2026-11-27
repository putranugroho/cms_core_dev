import 'package:cms_core/models/banking_setup_models.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/module/shared/banking_widgets.dart';
import 'package:cms_core/repository/banking_setup_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PartyGroupPage extends StatefulWidget {
  const PartyGroupPage({super.key});
  @override
  State<PartyGroupPage> createState() => _PartyGroupPageState();
}

class _PartyGroupPageState
    extends BankingListState<PartyGroupModel, PartyGroupPage> {
  @override
  String get title => 'Kelompok Mitra';
  @override
  String get route => MenuNotifier.routeKelompokPihakKetiga;
  @override
  Map<String, String> get searchChoices => const {
    'nama_kelompok': 'Nama Kelompok',
    'kode_kelompok': 'Kode Kelompok',
  };
  @override
  Future<bool> serviceAvailable() => Future.value(true);
  @override
  Future<BankingPage<PartyGroupModel>> fetchPage() =>
      BankingSetupRepository.groupList(
        keyword: keyword.text,
        searchField: searchField,
        page: page,
        limit: limit,
      );
  @override
  Future<void> addRecord() => _openForm();
  Future<void> _openForm({PartyGroupModel? row, bool readOnly = false}) async {
    final detail = row == null
        ? null
        : await BankingSetupRepository.groupDetail(row.kode);
    if (!mounted) return;
    final saved = await showEditor(
      _PartyGroupForm(
        original: detail,
        readOnly: readOnly,
        available: available,
      ),
    );
    if (saved == true && mounted) {
      bankingMessage(context, 'Kelompok mitra berhasil disimpan.');
      await reload();
    }
  }

  Future<void> _delete(PartyGroupModel row) async {
    if (!access.delete ||
        !available ||
        !await confirmDelete('kelompok ${row.kode} • ${row.nama}') ||
        !mounted)
      return;
    await BankingSetupRepository.groupDelete(row.kode);
    if (mounted) {
      bankingMessage(context, 'Kelompok mitra berhasil dihapus.');
      await reload();
    }
  }

  @override
  Widget buildTable(List<PartyGroupModel> items) => bankingTable(
    ['Kode Kelompok', 'Nama Kelompok', 'SBB', 'Nama SBB', 'Aksi'],
    items
        .map(
          (row) => DataRow(
            cells: [
              DataCell(Text(row.kode)),
              DataCell(Text(row.nama)),
              DataCell(Text(row.nomorSbb)),
              DataCell(Text(row.namaSbb)),
              DataCell(
                BankingActions(
                  showEdit: access.update,
                  showDelete: access.delete,
                  onView: actionBusy
                      ? null
                      : () =>
                            perform(() => _openForm(row: row, readOnly: true)),
                  onEdit: access.update && !actionBusy
                      ? () => perform(() => _openForm(row: row))
                      : null,
                  onDelete: access.delete && !actionBusy
                      ? () => perform(() => _delete(row))
                      : null,
                ),
              ),
            ],
          ),
        )
        .toList(),
  );
}

class _PartyGroupForm extends StatefulWidget {
  final PartyGroupModel? original;
  final bool readOnly;
  final bool available;
  const _PartyGroupForm({
    this.original,
    this.readOnly = false,
    required this.available,
  });
  @override
  State<_PartyGroupForm> createState() => _PartyGroupFormState();
}

class _PartyGroupFormState extends State<_PartyGroupForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _sbb;
  late final TextEditingController _sbbName;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.original?.kode ?? '');
    _name = TextEditingController(text: widget.original?.nama ?? '');
    _sbb = TextEditingController(text: widget.original?.nomorSbb ?? '');
    _sbbName = TextEditingController(text: widget.original?.namaSbb ?? '');
  }

  Future<void> _pickSbb() async {
    final row = await pickBankingSbb(context);
    if (mounted && row != null)
      setState(() {
        _sbb.text = row.kodeCoa;
        _sbbName.text = row.namaCoa;
      });
  }

  Future<void> _save() async {
    if (_busy ||
        !widget.available ||
        widget.readOnly ||
        !(_formKey.currentState?.validate() ?? false))
      return;
    final body = partyGroupFormPayload({
      'kode_kelompok': _code.text,
      'nama_kelompok': _name.text,
      'nomor_sbb': _sbb.text,
      'nama_sbb': _sbbName.text,
    });
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BankingSetupRepository.groupSave(widget.original != null, body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_code, _name, _sbb, _sbbName]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BankingFormDialog(
    error: _error,
    title: widget.readOnly
        ? 'Detail Kelompok Mitra'
        : widget.original == null
        ? 'Tambah Kelompok Mitra'
        : 'Edit Kelompok Mitra',
    formKey: _formKey,
    onSave: _save,
    busy: _busy,
    available: widget.available,
    readOnly: widget.readOnly,
    fields: [
      bankingField(
        'Kode Kelompok',
        _code,
        required: !widget.readOnly,
        readOnly: widget.readOnly || widget.original != null,
        keyboard: TextInputType.number,
        formatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        helper: '2 digit angka, contoh 01',
        validator: widget.readOnly
            ? (_) => null
            : (v) => validateBankingCode(v, 2),
      ),
      bankingField(
        'Nama Kelompok',
        _name,
        required: !widget.readOnly,
        readOnly: widget.readOnly,
      ),
      bankingField(
        'SBB',
        _sbb,
        readOnly: widget.readOnly,
        search: widget.readOnly ? null : _pickSbb,
        helper: 'SBB fee mitra di data kredit. Opsional.',
        clear: widget.readOnly
            ? null
            : () => setState(() {
                _sbb.clear();
                _sbbName.clear();
              }),
      ),
      bankingField('Nama SBB', _sbbName, readOnly: true),
    ],
  );
}

class MitraBisnisFormPage extends StatefulWidget {
  const MitraBisnisFormPage({super.key});
  @override
  State<MitraBisnisFormPage> createState() => _MitraBisnisFormPageState();
}

class _MitraBisnisFormPageState
    extends BankingListState<ThirdPartyModel, MitraBisnisFormPage> {
  @override
  String get title => 'Mitra Bisnis';
  @override
  String get route => MenuNotifier.routeMitraBisnis;
  @override
  Map<String, String> get searchChoices => const {
    'nama_perusahaan': 'Nama Perusahaan',
    'kode_pihak_ketiga': 'Kode Mitra',
  };
  @override
  Future<bool> serviceAvailable() =>
      Future.value(true);
  @override
  Future<BankingPage<ThirdPartyModel>> fetchPage() =>
      BankingSetupRepository.partyList(
        keyword: keyword.text,
        searchField: searchField,
        page: page,
        limit: limit,
      );
  @override
  Future<void> addRecord() => _openForm();
  Future<void> _openForm({ThirdPartyModel? row, bool readOnly = false}) async {
    final detail = row == null
        ? null
        : await BankingSetupRepository.partyDetail(row.kode);
    if (!mounted) return;
    final saved = await showEditor(
      _ThirdPartyForm(
        original: detail,
        readOnly: readOnly,
        available: available,
      ),
    );
    if (saved == true && mounted) {
      bankingMessage(context, 'Mitra bisnis berhasil disimpan.');
      await reload();
    }
  }

  Future<void> _delete(ThirdPartyModel row) async {
    if (!access.delete ||
        !available ||
        !await confirmDelete('mitra bisnis ${row.kode} • ${row.nama}') ||
        !mounted)
      return;
    await BankingSetupRepository.partyDelete(row.kode);
    if (mounted) {
      bankingMessage(context, 'Mitra bisnis berhasil dihapus.');
      await reload();
    }
  }

  @override
  Widget buildTable(List<ThirdPartyModel> items) => bankingTable(
    [
      'Kode',
      'Kelompok',
      'Nama Perusahaan',
      'Kota',
      'No Telp',
      'Bank',
      'No Rekening',
      'Aksi',
    ],
    items
        .map(
          (row) => DataRow(
            cells: [
              DataCell(Text(row.kode)),
              DataCell(Text('${row.kodeKelompok} • ${row.namaKelompok}')),
              DataCell(Text(row.nama)),
              DataCell(Text(row.field('kota'))),
              DataCell(Text(row.field('no_telp'))),
              DataCell(Text(row.namaBank)),
              DataCell(Text(row.field('nomor_rekening'))),
              DataCell(
                BankingActions(
                  showEdit: access.update,
                  showDelete: access.delete,
                  onView: actionBusy
                      ? null
                      : () =>
                            perform(() => _openForm(row: row, readOnly: true)),
                  onEdit: access.update && !actionBusy
                      ? () => perform(() => _openForm(row: row))
                      : null,
                  onDelete: access.delete && !actionBusy
                      ? () => perform(() => _delete(row))
                      : null,
                ),
              ),
            ],
          ),
        )
        .toList(),
  );
}

class _ThirdPartyForm extends StatefulWidget {
  final ThirdPartyModel? original;
  final bool readOnly;
  final bool available;
  const _ThirdPartyForm({
    this.original,
    this.readOnly = false,
    required this.available,
  });
  @override
  State<_ThirdPartyForm> createState() => _ThirdPartyFormState();
}

class _ThirdPartyFormState extends State<_ThirdPartyForm> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  bool _busy = false;
  String? _error;
  TextEditingController _field(String key) => _fields[key]!;
  @override
  void initState() {
    super.initState();
    for (final key in [...partyInputKeys, 'nama_kelompok', 'nama_bank']) {
      _fields[key] = TextEditingController(
        text: widget.original?.field(key) ?? '',
      );
    }
  }

  Future<void> _group() async {
    try {
      final row = await pickBankingPartyGroup(context);
      if (mounted && row != null) setState(() {
        _field('kode_kelompok').text = row.kode;
        _field('nama_kelompok').text = row.nama;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _bank() async {
    final row = await pickBankingBank(context);
    if (mounted && row != null)
      setState(() {
        _field('sandi_bank').text = row.kodeBank;
        _field('nama_bank').text = row.displayName;
      });
  }

  Future<void> _save() async {
    if (_busy ||
        !widget.available ||
        widget.readOnly ||
        !(_formKey.currentState?.validate() ?? false))
      return;
    final body = thirdPartyFormPayload(
      _fields.map((key, value) => MapEntry(key, value.text)),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BankingSetupRepository.partySave(widget.original != null, body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _text(
    String label,
    String key, {
    bool required = false,
    TextInputType? keyboard,
    int lines = 1,
    String? Function(String?)? validator,
  }) => bankingField(
    label,
    _field(key),
    required: required && !widget.readOnly,
    readOnly: widget.readOnly,
    keyboard: keyboard,
    maxLines: lines,
    validator: widget.readOnly ? (_) => null : validator,
  );
  Widget _email(String label, String key) => _text(
    label,
    key,
    keyboard: TextInputType.emailAddress,
    validator: validateBankingEmail,
  );
  Widget _phone(String label, String key) =>
      _text(label, key, keyboard: TextInputType.phone);
  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  @override
  Widget build(BuildContext context) => BankingFormDialog(
    error: _error,
    title: widget.readOnly
        ? 'Detail Mitra Bisnis'
        : widget.original == null
        ? 'Tambah Mitra Bisnis'
        : 'Edit Mitra Bisnis',
    formKey: _formKey,
    onSave: _save,
    busy: _busy,
    available: widget.available,
    readOnly: widget.readOnly,
    fields: [
      bankingField(
        'Kode Mitra',
        _field('kode_pihak_ketiga'),
        required: !widget.readOnly,
        readOnly: widget.readOnly || widget.original != null,
      ),
      // Kelompok wajib dipilih dari Kelompok Mitra; SBB fee mitra di data
      // kredit diambil dari kelompok ini.
      bankingField(
        'Kelompok Mitra',
        _field('kode_kelompok'),
        required: !widget.readOnly,
        readOnly: true,
        search: widget.readOnly ? null : _group,
        helper: widget.readOnly ? null : 'Pilih dari menu Kelompok Mitra.',
      ),
      bankingField('Nama Kelompok', _field('nama_kelompok'), readOnly: true),
      _text('Nama Perusahaan', 'nama_perusahaan', required: true),
      _text('Alamat', 'alamat', lines: 2, required: true),
      _text('Kelurahan', 'kelurahan'),
      _text('Kecamatan', 'kecamatan'),
      _text('Kota', 'kota', required: true),
      _text('Provinsi', 'provinsi'),
      bankingField(
        'Kode Pos',
        _field('kode_pos'),
        readOnly: widget.readOnly,
        keyboard: TextInputType.number,
        formatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(5),
        ],
        validator: widget.readOnly
            ? (_) => null
            : (v) => (v ?? '').isEmpty ? null : validateBankingCode(v, 5),
      ),
      _text('NPWP', 'npwp'),
      _phone('No Telp', 'no_telp'),
      _email('Email', 'email'),
      bankingField(
        'Bank',
        _field('sandi_bank'),
        readOnly: widget.readOnly,
        search: widget.readOnly ? null : _bank,
        clear: widget.readOnly
            ? null
            : () => setState(() {
                _field('sandi_bank').clear();
                _field('nama_bank').clear();
              }),
        validator: widget.readOnly
            ? (_) => null
            : (v) =>
                  _field('nomor_rekening').text.trim().isNotEmpty &&
                      (v ?? '').isEmpty
                  ? 'Pilih Bank untuk nomor rekening ini'
                  : null,
      ),
      bankingField('Nama Bank', _field('nama_bank'), readOnly: true),
      _text('No Rekening', 'nomor_rekening'),
      _heading('PIC 1'),
      _text('Nama PIC 1', 'nama_pic_1', required: true),
      _text('Jabatan 1', 'jabatan_1'),
      _phone('No HP 1', 'no_hp_1'),
      _email('Email 1', 'email_1'),
      _heading('PIC 2'),
      _text('Nama PIC 2', 'nama_pic_2'),
      _text('Jabatan 2', 'jabatan_2'),
      _phone('No HP 2', 'no_hp_2'),
      _email('Email 2', 'email_2'),
    ],
  );
}
