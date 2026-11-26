import 'package:cms_core/models/banking_setup_models.dart';
import 'package:cms_core/models/new_menu_models.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/module/shared/banking_widgets.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/banking_setup_repository.dart';
import 'package:cms_core/repository/office_repository.dart';
import 'package:cms_core/utils/percentage_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AbaPage extends StatefulWidget {
  const AbaPage({super.key});
  @override
  State<AbaPage> createState() => _AbaPageState();
}

class _AbaPageState extends BankingListState<AbaModel, AbaPage> {
  String _jenis = '';
  String _status = '';
  String _officeCode = '';
  String _officeName = '';
  @override
  String get title => 'ABA';
  @override
  String get route => MenuNotifier.routeAba;
  @override
  Map<String, String> get searchChoices => const {
    'nomor_rekening': 'No Rekening',
    'nama_bank': 'Nama Bank',
    'sandi_bank': 'Sandi Bank',
    'nomor_sbb': 'No SBB',
  };
  @override
  Future<BankingPage<AbaModel>> fetchPage() => BankingSetupRepository.abaList(
    keyword: keyword.text,
    searchField: searchField,
    jenis: _jenis,
    status: _status,
    page: page,
    limit: limit,
  );

  @override
  void initState() {
    super.initState();
    _loadOffice();
  }

  Future<void> _loadOffice() async {
    try {
      final user = await Pref().getUsers();
      if (!mounted) return;
      setState(() => _officeCode = user.kodeKantor);
      if (_officeCode.isEmpty) return;
      final office = await OfficeRepository.detail(_officeCode);
      if (mounted) setState(() => _officeName = office.namaKantor);
    } catch (_) {
      // Office lookup is descriptive. The verified middleware session remains
      // the only source of X-Kode-Kantor on the actual gateway request.
    }
  }

  @override
  List<Widget> buildFilters() => [
    SizedBox(
      width: 165,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: _jenis,
        decoration: const InputDecoration(
          labelText: 'Jenis rekening',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: '', child: Text('Semua jenis')),
          DropdownMenuItem(value: 'G', child: Text('Giro')),
          DropdownMenuItem(value: 'T', child: Text('Tabungan')),
          DropdownMenuItem(value: 'D', child: Text('Deposito')),
        ],
        onChanged: loading || actionBusy
            ? null
            : (value) {
                _jenis = value ?? '';
                reload(resetPage: true);
              },
      ),
    ),
    SizedBox(
      width: 165,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: _status,
        decoration: const InputDecoration(
          labelText: 'Status rekening',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: '', child: Text('Semua status')),
          DropdownMenuItem(value: 'N', child: Text('Draft')),
          DropdownMenuItem(value: 'A', child: Text('Aktif')),
          DropdownMenuItem(value: 'C', child: Text('Tutup')),
          DropdownMenuItem(value: 'R', child: Text('Reject')),
        ],
        onChanged: loading || actionBusy
            ? null
            : (value) {
                _status = value ?? '';
                reload(resetPage: true);
              },
      ),
    ),
  ];

  @override
  Future<void> addRecord() => _openForm();
  Future<void> _openForm({AbaModel? row, bool readOnly = false}) async {
    final detail = row == null
        ? null
        : await BankingSetupRepository.abaDetail(row.nomorRekening);
    if (!mounted) return;
    if (detail != null && !readOnly && !abaIsDraft(detail)) {
      bankingMessage(
        context,
        'ABA hanya dapat diedit saat status rekening Draft (N).',
      );
      await reload();
      return;
    }
    final saved = await showEditor(
      _AbaForm(
        original: detail,
        readOnly: readOnly,
        officeCode: _officeCode,
        officeName: _officeName,
      ),
    );
    if (saved == true && mounted) {
      bankingMessage(context, 'ABA berhasil disimpan.');
      await reload();
    }
  }

  Future<void> _delete(AbaModel row) async {
    if (!access.delete || !abaIsDraft(row)) return;
    if (!await confirmDelete('rekening ABA ${row.nomorRekening}') || !mounted)
      return;
    await BankingSetupRepository.abaDelete(row.nomorRekening);
    if (mounted) {
      bankingMessage(context, 'ABA berhasil dihapus.');
      await reload();
    }
  }

  @override
  Widget buildTable(List<AbaModel> items) => bankingTable(
    [
      'No Rekening',
      'Bank',
      'No SBB',
      'Jenis',
      'Tgl Buka',
      'Nominal',
      'Jatuh Tempo',
      'Kantor',
      'Status',
      'Aksi',
    ],
    items
        .map(
          (row) => DataRow(
            cells: [
              DataCell(Text(row.nomorRekening)),
              DataCell(Text('${row.sandiBank} • ${row.namaBank}')),
              DataCell(Text(row.nomorSbb)),
              DataCell(Text(row.jenisLabel)),
              DataCell(Text(bankingDate(row.tanggalBuka))),
              DataCell(Text(_amount(row.nominal))),
              DataCell(Text(bankingDate(row.tanggalJatuhTempo))),
              DataCell(Text(row.officeCode)),
              DataCell(Text(_statusLabel(row.statusRekening))),
              DataCell(
                BankingActions(
                  showEdit: access.update,
                  showDelete: access.delete,
                  onView: actionBusy
                      ? null
                      : () =>
                            perform(() => _openForm(row: row, readOnly: true)),
                  onEdit: access.update && abaIsDraft(row) && !actionBusy
                      ? () => perform(() => _openForm(row: row))
                      : null,
                  onDelete: access.delete && abaIsDraft(row) && !actionBusy
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

String _statusLabel(String value) =>
    const {'N': 'Draft', 'A': 'Aktif', 'C': 'Tutup', 'R': 'Reject'}[value] ??
    value;
String _amount(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '$whole,${parts[1]}';
}

class _AbaForm extends StatefulWidget {
  final AbaModel? original;
  final bool readOnly;
  final String officeCode;
  final String officeName;
  const _AbaForm({
    this.original,
    this.readOnly = false,
    required this.officeCode,
    required this.officeName,
  });
  @override
  State<_AbaForm> createState() => _AbaFormState();
}

class _AbaFormState extends State<_AbaForm> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  String _jenis = 'G';
  String _unit = 'B';
  bool _busy = false;
  String? _error;
  bool get _readOnly => widget.readOnly;
  TextEditingController _field(String key) => _fields[key]!;
  @override
  void initState() {
    super.initState();
    final row = widget.original;
    final officeCode = _readOnly && row != null
        ? row.officeCode
        : widget.officeCode;
    final officeName = officeCode == widget.officeCode
        ? widget.officeName
        : bankingText(row?.raw['nama_kantor']);
    final initial = <String, String>{
      'bank': row?.sandiBank ?? '',
      'nama_bank': row?.namaBank ?? '',
      'kantor': officeName.isEmpty ? officeCode : '$officeCode • $officeName',
      'sbb': row?.nomorSbb ?? '',
      'nama_sbb': bankingText(row?.raw['nama_sbb'] ?? row?.raw['nama_coa']),
      'rekening': row?.nomorRekening ?? '',
      'tanggal_buka': bankingDate(row?.tanggalBuka ?? ''),
      'nominal': (row?.nominal ?? 0).toStringAsFixed(2),
      'tenor': (row?.jangkaWaktu ?? 0) == 0 ? '' : row!.jangkaWaktu.toString(),
      'rate': row?.sukuBunga.toString() ?? '',
      'aro': ['Y', 'YES', 'TRUE', '1'].contains(bankingText(row?.raw['aro']).toUpperCase()) ? 'Y' : 'N',
      'jatuh_tempo': bankingDate(row?.tanggalJatuhTempo ?? ''),
    };
    for (final entry in initial.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
    _jenis = ['G', 'T', 'D'].contains(row?.jenisRekening)
        ? row!.jenisRekening
        : 'G';
    _unit = ['B', 'H'].contains(row?.jenisJangkaWaktu)
        ? row!.jenisJangkaWaktu
        : 'B';
  }

  Future<void> _bank() async {
    final selected = await pickBankingBank(context);
    if (!mounted || selected == null) return;
    setState(() {
      _field('bank').text = selected.kodeBank;
      _field('nama_bank').text = selected.displayName;
    });
  }

  Future<void> _sbb() async {
    final selected = await pickBankingSbb(context);
    if (!mounted || selected == null) return;
    setState(() {
      _field('sbb').text = selected.kodeCoa;
      _field('nama_sbb').text = selected.namaCoa;
    });
  }

  Future<void> _date() async {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(now.year, now.month, now.day);
    var initial = DateTime.tryParse(_field('tanggal_buka').text) ?? today;
    if (initial.isAfter(today) || initial.isBefore(DateTime(1900)))
      initial = today;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (mounted && date != null)
      setState(
        () => _field('tanggal_buka').text =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
  }

  Future<void> _save() async {
    if (_busy || _readOnly || !(_formKey.currentState?.validate() ?? false))
      return;
    final body = abaFormPayload(
      nomorRekening: _field('rekening').text,
      nomorSbb: _field('sbb').text,
      jenis: _jenis,
      namaBank: _field('nama_bank').text,
      sandiBank: _field('bank').text,
      tanggalBuka: _field('tanggal_buka').text,
      tenor: int.tryParse(_field('tenor').text) ?? 0,
      tenorUnit: _unit,
      rate: parsePercentage(_field('rate').text) ?? 0,
      nominal: double.tryParse(_field('nominal').text.replaceAll(',', '.')) ?? 0,
      aro: _field('aro').text,
      original: widget.original,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BankingSetupRepository.abaSave(widget.original != null, body);
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

  @override
  Widget build(BuildContext context) => BankingFormDialog(
    error: _error,
    title: _readOnly
        ? 'Detail ABA'
        : widget.original == null
        ? 'Tambah ABA'
        : 'Edit ABA',
    formKey: _formKey,
    busy: _busy,
    readOnly: _readOnly,
    onSave: _save,
    fields: [
      bankingField(
        'Bank',
        _field('bank'),
        required: !_readOnly,
        readOnly: _readOnly,
        search: _readOnly ? null : _bank,
      ),
      bankingField('Nama Bank', _field('nama_bank'), readOnly: true),
      bankingField(
        'Nama Kantor',
        _field('kantor'),
        readOnly: true,
        helper: _readOnly ? null : 'Mengikuti kantor user yang login.',
      ),
      bankingField(
        'No SBB',
        _field('sbb'),
        required: !_readOnly,
        readOnly: _readOnly,
        search: _readOnly ? null : _sbb,
      ),
      bankingField('Nama SBB', _field('nama_sbb'), readOnly: true),
      bankingDropdown('Jenis Rekening', _jenis, const {
        'G': 'GIRO',
        'T': 'TABUNGAN',
        'D': 'DEPOSITO',
      }, _readOnly ? null : (v) => setState(() => _jenis = v ?? 'G')),
      bankingField(
        'No Rekening',
        _field('rekening'),
        required: !_readOnly,
        readOnly: _readOnly || widget.original != null,
      ),
      bankingField(
        'Tgl Buka',
        _field('tanggal_buka'),
        required: !_readOnly,
        readOnly: true,
        search: _readOnly ? null : _date,
        helper: 'YYYY-MM-DD',
      ),
      if (_jenis == 'D') ...[
        bankingField(
          'Nominal',
          _field('nominal'),
          readOnly: _readOnly,
          required: !_readOnly,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          helper: 'Tanpa pemisah ribuan, contoh 1500000,50.',
          validator: (v) {
            final text = (v ?? '').trim();
            final value = double.tryParse(text.replaceAll(',', '.'));
            return RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(text) &&
                value != null && value.isFinite && value >= 0
                ? null : 'Isi nominal valid, maksimal 2 angka desimal';
          },
        ),
        bankingField(
          'Jangka Waktu',
          _field('tenor'),
          required: !_readOnly,
          readOnly: _readOnly,
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          validator: _readOnly
              ? (_) => null
              : (v) => (int.tryParse(v ?? '') ?? 0) > 0
                    ? null
                    : 'Isi jangka waktu lebih dari 0',
        ),
        bankingDropdown('Satuan Jangka Waktu', _unit, const {
          'B': 'Bulan',
          'H': 'Hari',
        }, _readOnly ? null : (v) => setState(() => _unit = v ?? 'B')),
        bankingField(
          'Suku Bunga / Thn (%)',
          _field('rate'),
          required: !_readOnly,
          readOnly: _readOnly,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          formatters: const [PercentageInputFormatter()],
          validator: _readOnly
              ? (_) => null
              : (v) => validatePercentage(v, required: true),
        ),
        bankingDropdown('ARO', _field('aro').text, const {
          'Y': 'Yes', 'N': 'No',
        }, _readOnly ? null : (v) => setState(() => _field('aro').text = v ?? 'N')),
        bankingField(
          'Tgl Jatuh Tempo',
          _field('jatuh_tempo'),
          readOnly: true,
          helper: 'Dihitung otomatis oleh layanan saat disimpan.',
        ),
      ],
      if (_readOnly && widget.original != null)
        Text(
          'Status: ${_statusLabel(widget.original!.statusRekening)} • ${widget.original!.statusOtorisasi}',
        ),
    ],
  );
}
