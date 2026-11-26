import 'inventory_form_layout.dart';
import 'inventory_detail_fields.dart';
import 'package:flutter/material.dart';
import 'package:cms_core/models/banking_setup_models.dart';
import 'package:cms_core/models/new_menu_models.dart';
import 'package:cms_core/models/hris_employee_model.dart';
import 'package:cms_core/module/shared/banking_widgets.dart';
import 'package:cms_core/repository/hris_repository.dart';
import 'package:cms_core/repository/new_menu_repository.dart';

enum InventoryScreen { group, revaluation, disposal }

class InventoryOperationsPage extends StatefulWidget {
  final InventoryScreen screen;
  const InventoryOperationsPage({super.key, required this.screen});
  @override
  State<InventoryOperationsPage> createState() => _InventoryOperationsState();
}

class _InventoryOperationsState extends BankingListState<Map<String, String>, InventoryOperationsPage> {
  final List<Map<String, String>> _drafts = [];
  bool get _group => widget.screen == InventoryScreen.group;
  bool get _revaluation => widget.screen == InventoryScreen.revaluation;
  @override
  String get title => _group ? 'Kelompok Aset' : _revaluation ? 'Revaluasi Inventaris' : 'Penghapusan Inventaris';
  @override
  String get route => _group ? '/setup/kelompok-aset' : _revaluation ? '/master/inventaris/revaluasi' : '/master/inventaris/penghapusan';
  @override
  Map<String, String> get searchChoices => const {'code': 'Kode', 'name': 'Nama'};
  @override
  List<Widget> buildFilters() => [const SizedBox(width: 400, child: Text(
    'Pratinjau tampilan: draft hanya tersimpan selama halaman ini terbuka. Belum mengubah data aset.',
    style: TextStyle(color: Colors.deepOrange),
  ))];
  @override
  Future<BankingPage<Map<String, String>>> fetchPage() async {
    final rows = _drafts.where((e) => (e[searchField] ?? '').toLowerCase().contains(keyword.text.trim().toLowerCase())).toList();
    return BankingPage(items: rows.skip((page - 1) * limit).take(limit).toList(), total: rows.length, page: page, limit: limit);
  }
  @override
  Future<void> addRecord() => _edit();
  Future<void> _edit([Map<String, String>? original, bool readOnly = false]) async {
    final value = await showDialog<Map<String, String>>(
      context: context, barrierDismissible: false,
      builder: (_) => _InventoryDraftForm(screen: widget.screen, original: original, readOnly: readOnly,
        existingCodes: _drafts.where((e) => !identical(e, original)).map((e) => e['code'] ?? '').toSet()),
    );
    if (!mounted || value == null) return;
    setState(() {
      if (original == null) { _drafts.add(value); }
      else { _drafts[_drafts.indexOf(original)] = value; }
    });
    await reload(resetPage: true);
  }
  Future<void> _delete(Map<String, String> row) async {
    if (!await confirmDelete('draft ${row['code']}') || !mounted) return;
    setState(() => _drafts.remove(row));
    await reload(resetPage: true);
  }
  @override
  Widget buildTable(List<Map<String, String>> items) => bankingTable(
    ['Kode', 'Nama', if (!_group) ...['Tanggal', _revaluation ? 'Nilai Baru' : 'Nilai Jual / Hapus', _revaluation ? 'Auditor' : 'Tindakan'], 'Aksi'],
    items.map((row) => DataRow(cells: [
      DataCell(Text(row['code'] ?? '')), DataCell(Text(row['name'] ?? '')),
      if (!_group) ...[
        DataCell(Text(row['date'] ?? '')), DataCell(Text(row['value'] ?? '')),
        DataCell(Text(_revaluation ? (row['auditor_name'] ?? '') : (row['action'] == 'sell' ? 'Jual' : 'Hapus'))),
      ],
      DataCell(BankingActions(showEdit: access.update, showDelete: access.delete,
        onView: () => perform(() => _edit(row, true)),
        onEdit: access.update ? () => perform(() => _edit(row)) : null,
        onDelete: access.delete ? () => perform(() => _delete(row)) : null)),
    ])).toList(),
  );
}

class _InventoryDraftForm extends StatefulWidget {
  final InventoryScreen screen;
  final Map<String, String>? original;
  final bool readOnly;
  final Set<String> existingCodes;
  const _InventoryDraftForm({required this.screen, this.original, required this.readOnly, required this.existingCodes});
  @override
  State<_InventoryDraftForm> createState() => _InventoryDraftFormState();
}

class _InventoryDraftFormState extends State<_InventoryDraftForm> {
  final _key = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  String _auditType = 'internal';
  String _auditorId = '';
  String _action = 'remove';
  String? _error;
  bool _busy = false;
  bool get _group => widget.screen == InventoryScreen.group;
  bool get _revaluation => widget.screen == InventoryScreen.revaluation;
  TextEditingController f(String key) => _fields[key]!;
  @override
  void initState() {
    super.initState();
    for (final key in ['code', 'name', 'date', 'next_revaluation_date', 'old_value', 'value', 'reason', 'auditor_name', 'auditor_no', 'organization', 'buyer', ...inventoryDetailLabels.keys].toSet()) {
      _fields[key] = TextEditingController(text: widget.original?[key] ?? '');
    }
    _auditType = widget.original?['audit_type'] ?? 'internal';
    _auditorId = widget.original?['auditor_id'] ?? '';
    _action = widget.original?['action'] ?? 'remove';
    if (widget.original == null) {
      final now = DateTime.now();
      f('date').text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (!_revaluation) f('value').text = '0';
    }
  }
  @override
  void dispose() { for (final c in _fields.values) { c.dispose(); } super.dispose(); }
  double? number(String key) => double.tryParse(f(key).text.trim().replaceAll(',', '.'));
  String? validateAmount(String? input, {bool positive = false}) {
    final text = (input ?? '').trim();
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (!RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(text) || value == null || !value.isFinite || (positive ? value <= 0 : value < 0)) {
      return positive ? 'Isi harga jual lebih dari 0, maksimal 2 desimal' : 'Isi angka 0 atau lebih, maksimal 2 desimal';
    }
    return null;
  }
  Future<void> _asset() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final row = await showDialog<MasterInventarisAsetModel>(context: context, builder: (_) => BankingLookupDialog<MasterInventarisAsetModel>(
        title: 'Pilih Inventaris — maksimal 100 hasil per pencarian', needsKeyword: true,
        load: (q, p) async {
          final rows = await NewMenuRepository.inventarisList(keyword: q, limit: 100);
          return BankingPage(items: rows, total: rows.length, page: 1, limit: 100);
        }, label: (r) => '${r.kodeInventaris} • ${r.namaInventaris}', subtitle: (r) => r.kelompokAset,
      ));
      if (!mounted || row == null) return;
      final detail = await NewMenuRepository.inventarisDetail(row.kodeInventaris);
      if (!mounted) return;
      setState(() {
        for (final entry in inventoryDetailSnapshot(detail.raw).entries) {
          f(entry.key).text = entry.value;
        }
        if (_revaluation) f('value').clear();
      });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _auditor() async {
    final row = await showDialog<HrisEmployeeModel>(context: context, builder: (_) => BankingLookupDialog<HrisEmployeeModel>(
      title: 'Pilih Auditor Internal HRIS', needsKeyword: true,
      load: (q, p) async {
        final rows = await HrisRepository.searchEmployee(search: q);
        return BankingPage(items: rows, total: rows.length, page: 1, limit: rows.isEmpty ? 1 : rows.length);
      }, label: (r) => r.title, subtitle: (r) => r.officeText,
    ));
    if (!mounted || row == null) return;
    setState(() { _auditorId = row.id; f('auditor_no').text = row.employeeNo; f('auditor_name').text = row.name; });
  }
  Future<void> _date({bool next = false}) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final first = next ? now.add(const Duration(days: 1)) : DateTime(1900);
    final last = next || !_revaluation ? DateTime(2100) : now;
    final key = next ? 'next_revaluation_date' : 'date';
    var initial = DateTime.tryParse(f(key).text) ?? (next ? first : now);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final chosen = await showDatePicker(context: context, initialDate: initial, firstDate: first, lastDate: last);
    if (mounted && chosen != null) setState(() => f(key).text = chosen.toIso8601String().substring(0, 10));
  }
  void _save() {
    if (_busy || widget.readOnly || !_key.currentState!.validate()) return;
    if (_revaluation) {
      final today = DateUtils.dateOnly(DateTime.now());
      final current = DateTime.tryParse(f('date').text);
      final next = DateTime.tryParse(f('next_revaluation_date').text);
      if (current == null || current.isAfter(today) || next == null || !next.isAfter(today)) {
        setState(() => _error = 'Tanggal revaluasi maksimal hari ini; tanggal berikutnya harus setelah hari ini.'); return;
      }
    }
    if (_group && widget.existingCodes.any((code) => code.toLowerCase() == f('code').text.trim().toLowerCase())) {
      setState(() => _error = 'Kode kelompok sudah ada pada draft.'); return;
    }
    if (_revaluation && _auditType == 'internal' && _auditorId.isEmpty && f('auditor_no').text.isEmpty) {
      setState(() => _error = 'Pilih auditor internal dari HRIS.'); return;
    }
    Navigator.pop(context, <String, String>{
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      'audit_type': _auditType, 'auditor_id': _auditorId, 'action': _action,
      if (!_group && !_revaluation && _action == 'remove') 'value': '0',
    });
  }
  Widget text(String label, String key, {bool required = false, bool readOnly = false}) => bankingField(label, f(key), required: required, readOnly: widget.readOnly || readOnly);
  Widget _valueField() => TextFormField(
    controller: f('value'), readOnly: widget.readOnly || (!_revaluation && _action == 'remove'),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: _revaluation ? 'Nilai hasil penilaian *' : 'Nilai Jual',
      helperText: !_revaluation && _action == 'remove' ? 'Hapus: nilai jual 0.' : 'Contoh: 1500000,50', border: const OutlineInputBorder()),
    validator: (v) => validateAmount(v, positive: !_revaluation && _action == 'sell'), onChanged: (_) => setState(() {}));
  @override
  Widget build(BuildContext context) {
    final old = number('old_value'); final value = number('value');
    return BankingFormDialog(
      width: _group ? 800 : 1120,
      sidePanel: _revaluation,
      title: _group ? 'Kelompok Aset' : _revaluation ? 'Revaluasi Inventaris' : 'Penghapusan Inventaris',
      formKey: _key, readOnly: widget.readOnly, busy: _busy, error: _error, onSave: _save,
      fields: [InventoryFormGrid(maxColumns: _group ? 2 : 3, children: [
        const InventoryFullWidth(child: Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Simpan hanya menambahkan draft tampilan; belum memproses transaksi.'))),
        if (_group) ...[text('Kode', 'code', required: true), text('Nama', 'name', required: true)]
        else ...[
          bankingField('Kode Inventaris', f('code'), required: true, readOnly: true, search: widget.readOnly || _busy ? null : _asset),
          text('Nama Inventaris', 'name', readOnly: true),
          bankingField(_revaluation ? 'Tanggal Revaluasi' : 'Tanggal', f('date'), required: true, readOnly: true, search: widget.readOnly ? null : () => _date()),
          ...inventoryDetailFields(_fields, exclude: _revaluation ? const {'last_revaluation_date'} : const {'asset_supplier', 'old_value', 'last_revaluation_date'}),
          if (_revaluation) ...[
            Padding(padding: const EdgeInsets.only(bottom: 14), child: InputDecorator(decoration: const InputDecoration(labelText: 'Tanggal Revaluasi Terakhir', border: OutlineInputBorder()),
              child: Text(f('last_revaluation_date').text.isEmpty ? '—' : f('last_revaluation_date').text))),
            bankingField('Tanggal Revaluasi Berikutnya', f('next_revaluation_date'), required: true, readOnly: true,
              search: widget.readOnly ? null : () => _date(next: true)),
          ],
          if (!_revaluation) bankingDropdown('Tindakan', _action, const {'remove': 'Hapus', 'sell': 'Jual'}, widget.readOnly ? null : (v) => setState(() {
            _action = v ?? 'remove'; f('value').text = _action == 'remove' ? '0' : ''; f('buyer').clear();
          })),
          if (_revaluation) _valueField()
          else InventoryFullWidth(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: bankingField('Nilai Buku', f('old_value'), readOnly: true)),
            const SizedBox(width: 12), Expanded(child: _valueField()),
          ])),
          InventoryFullWidth(child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(
            old == null || value == null ? 'Selisih: —' : '${_revaluation ? 'Selisih penilaian' : 'Selisih (nilai jual − nilai buku)'}: ${value - old >= 0 ? '+' : '−'}${(value - old).abs().toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold,
              color: old == null || value == null ? Colors.grey : value - old < 0 ? Colors.red : Colors.green)))),
          InventoryFullWidth(child: text('Alasan / keterangan', 'reason', required: true)),
          if (!_revaluation && _action == 'sell') text('Pembeli', 'buyer', required: true),
          if (_revaluation) ...[
            bankingDropdown('Auditor', _auditType, const {'internal': 'Internal — HRIS', 'external': 'Eksternal'}, widget.readOnly ? null : (v) => setState(() {
              _auditType = v ?? 'internal'; _auditorId = ''; f('auditor_no').clear(); f('auditor_name').clear(); f('organization').clear();
            })),
            if (_auditType == 'internal') ...[
              bankingField('Nama auditor internal', f('auditor_name'), required: true, readOnly: true, search: widget.readOnly ? null : _auditor),
              text('Nomor pegawai', 'auditor_no', readOnly: true),
            ] else ...[text('Nama auditor eksternal', 'auditor_name', required: true), text('Instansi auditor', 'organization')],
          ],
        ],
      ])],
    );
  }
}
