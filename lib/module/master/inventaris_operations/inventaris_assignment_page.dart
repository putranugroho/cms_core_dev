import 'inventory_form_layout.dart';
import 'inventory_detail_fields.dart';
import 'package:cms_core/models/kantor_model.dart';
import 'package:flutter/material.dart';
import 'package:cms_core/models/banking_setup_models.dart';
import 'package:cms_core/models/hris_employee_model.dart';
import 'package:cms_core/module/shared/banking_widgets.dart';
import 'package:cms_core/repository/hris_repository.dart';
import 'package:cms_core/repository/new_menu_repository.dart';

class InventoryAssignmentPage extends StatefulWidget {
  const InventoryAssignmentPage({super.key});
  @override
  State<InventoryAssignmentPage> createState() => _InventoryAssignmentState();
}
class _InventoryAssignmentState extends BankingListState<Map<String, String>, InventoryAssignmentPage> {
  final _drafts = <String, Map<String, String>>{};
  @override
  bool get showAddButton => false;
  @override
  String get title => 'Penempatan Inventaris';
  @override
  String get route => '/master/inventaris/penempatan';
  @override
  Map<String, String> get searchChoices => const {'code': 'Kode Inventaris', 'name': 'Nama Inventaris'};
  @override
  List<Widget> buildFilters() => [const SizedBox(width: 400, child: Text('Perubahan lokasi dan PIC berupa draft lokal. Data belum disimpan ke server dan hilang saat meninggalkan halaman.', style: TextStyle(color: Colors.deepOrange)))];
  @override
  Future<BankingPage<Map<String, String>>> fetchPage() async {
    final response = await NewMenuRepository.inventarisPage(keyword: keyword.text.trim(), searchField: searchField, page: page, limit: limit);
    final rows = response.items.map((asset) => <String, String>{
      ...inventoryDetailSnapshot(asset.raw),
      'code': asset.kodeInventaris, 'name': asset.namaInventaris,
      ...?_drafts[asset.kodeInventaris],
    }).toList();
    return BankingPage(items: rows, total: response.total, page: page, limit: limit);
  }
  @override
  Future<void> addRecord() async {}
  Future<void> _edit(Map<String, String> row, {bool readOnly = false}) async {
    final detail = await NewMenuRepository.inventarisDetail(row['code']!);
    if (!mounted) return;
    final original = <String, String>{
      ...inventoryDetailSnapshot(detail.raw),
      'office_code': detail.raw['kode_kantor']?.toString() ?? '',
      'office_name': detail.raw['nama_kantor']?.toString() ?? '',
      'location': detail.raw['lokasi_aset']?.toString() ?? '',
      'address': detail.raw['alamat']?.toString() ?? '',
      'village': detail.raw['kelurahan']?.toString() ?? '',
      'district': detail.raw['kecamatan']?.toString() ?? '',
      'city': detail.raw['kota']?.toString() ?? '',
      'place_notes': detail.raw['keterangan_tempat']?.toString() ?? '',
      ...?_drafts[row['code']],
    };
    final draft = await showDialog<Map<String, String>>(context: context, barrierDismissible: false,
      builder: (_) => _AssignmentForm(original: original, readOnly: readOnly));
    if (!mounted || draft == null) return;
    setState(() => _drafts[row['code']!] = draft);
    await reload();
  }
  @override
  Widget buildTable(List<Map<String, String>> items) => bankingTable(
    ['Kode Inventaris', 'Nama Inventaris', 'Lokasi Aset', 'Pengguna / PIC', 'Status', 'Aksi'],
    items.map((row) => DataRow(cells: [
      DataCell(Text(row['code'] ?? '')), DataCell(Text(row['name'] ?? '')),
      DataCell(Text(row['location'] ?? row['asset_location'] ?? '—')),
      DataCell(Text(row['employee_name'] ?? '—')),
      DataCell(Text(_drafts.containsKey(row['code']) ? 'Draft lokal' : 'Data inventaris')),
      DataCell(TextButton.icon(icon: const Icon(Icons.edit_location_alt_outlined),
        label: Text(access.update ? 'Atur Penempatan' : 'Lihat Penempatan'),
        onPressed: () => perform(() => _edit(row, readOnly: !access.update)))),
    ])).toList(),
  );
}
class _AssignmentForm extends StatefulWidget {
  final Map<String, String>? original;
  final bool readOnly;
  const _AssignmentForm({this.original, required this.readOnly});
  @override
  State<_AssignmentForm> createState() => _AssignmentFormState();
}
class _AssignmentFormState extends State<_AssignmentForm> {
  final _key = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  String _employeeId = '';
  String _location = '';
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    for (final key in ['code', 'name', 'employee_no', 'employee_name', 'office', 'date', 'notes', 'address', 'village', 'district', 'city', 'place_notes', 'office_code', 'office_name', ...inventoryDetailLabels.keys]) {
      _fields[key] = TextEditingController(text: widget.original?[key] ?? '');
    }
    _employeeId = widget.original?['employee_id'] ?? '';
    final location = widget.original?['location'] ?? '';
    _location = location == 'DALAM_KANTOR' ? 'KANTOR' : location;
    if (!['KANTOR', 'LUAR_KANTOR'].contains(_location)) _location = '';
    if (f('date').text.isEmpty) f('date').text = DateTime.now().toIso8601String().substring(0, 10);
  }
  TextEditingController f(String key) => _fields[key]!;
  @override
  void dispose() { for (final c in _fields.values) { c.dispose(); } super.dispose(); }
  Future<void> _office() async {
    final row = await showDialog<KantorModel>(context: context, builder: (_) => BankingLookupDialog<KantorModel>(
      title: 'Pilih Kantor Aset',
      load: (q, p) async {
        final all = await HrisRepository.listKantor();
        final rows = all.where((e) => '${e.kodeKantor} ${e.namaKantor}'.toLowerCase().contains(q.toLowerCase())).toList();
        return BankingPage(items: rows, total: rows.length, page: 1, limit: rows.isEmpty ? 1 : rows.length);
      }, label: (r) => '${r.kodeKantor} • ${r.namaKantor}', subtitle: (r) => r.alamat,
    ));
    if (!mounted || row == null) return;
    setState(() {
      f('office_code').text = row.kodeKantor; f('office_name').text = row.namaKantor;
      if (_location == 'KANTOR') {
        f('address').text = row.alamat; f('village').text = row.kelurahan;
        f('district').text = row.kecamatan; f('city').text = row.kota;
      }
    });
  }
  Future<void> _employee() async {
    final row = await showDialog<HrisEmployeeModel>(context: context, builder: (_) => BankingLookupDialog<HrisEmployeeModel>(
      title: 'Cari Pengguna / Penanggung Jawab HRIS', needsKeyword: true,
      load: (q, p) async {
        final rows = await HrisRepository.searchEmployee(search: q);
        return BankingPage(items: rows, total: rows.length, page: 1, limit: rows.isEmpty ? 1 : rows.length);
      }, label: (r) => r.title, subtitle: (r) => r.officeText,
    ));
    if (mounted && row != null) setState(() {
      _employeeId = row.id; f('employee_no').text = row.employeeNo; f('employee_name').text = row.name; f('office').text = row.officeText;
    });
  }
  Future<void> _date() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.tryParse(f('date').text) ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));
    if (mounted && date != null) setState(() => f('date').text = date.toIso8601String().substring(0, 10));
  }
  void _save() {
    if (_busy || widget.readOnly || !_key.currentState!.validate()) return;
    if (_location.isEmpty) { setState(() => _error = 'Pilih lokasi aset.'); return; }
    Navigator.pop(context, <String, String>{for (final e in _fields.entries) e.key: e.value.text.trim(), 'employee_id': _employeeId, 'location': _location});
  }
  @override
  Widget build(BuildContext context) => BankingFormDialog(
    width: 1120,
    sidePanel: true,
    title: 'Penempatan Inventaris', formKey: _key, readOnly: widget.readOnly, onSave: _save, busy: _busy, error: _error,
    fields: [InventoryFormGrid(children: [
      const InventoryFullWidth(child: Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Pratinjau: Simpan hanya membuat draft di halaman ini, belum memperbarui lokasi dan PIC aset di server.'))),
      bankingField('Kode Inventaris', f('code'), required: true, readOnly: true, search: null),
      bankingField('Nama Inventaris', f('name'), readOnly: true),
      ...inventoryDetailFields(_fields, exclude: const {'asset_location', 'asset_address', 'asset_office', 'last_revaluation_date'}),
      bankingDropdown('Lokasi Aset', _location, const {'': 'Pilih lokasi', 'KANTOR': 'Kantor', 'LUAR_KANTOR': 'Luar Kantor'},
        widget.readOnly ? null : (v) => setState(() {
          _location = v ?? '';
          for (final key in ['office_code', 'office_name', 'address', 'village', 'district', 'city']) { f(key).clear(); }
        })),
      bankingField('Kode Kantor Aset', f('office_code'), required: true, readOnly: true, search: widget.readOnly ? null : _office),
      bankingField('Nama Kantor Aset', f('office_name'), readOnly: true),
      if (_location == 'KANTOR') bankingField('Alamat Kantor', f('address'), readOnly: true),
      if (_location == 'LUAR_KANTOR') ...[
        bankingField('Keterangan Tempat', f('place_notes'), required: true, readOnly: widget.readOnly),
        bankingField('Alamat', f('address'), required: true, readOnly: widget.readOnly),
        bankingField('Kelurahan', f('village'), readOnly: widget.readOnly),
        bankingField('Kecamatan', f('district'), readOnly: widget.readOnly),
        bankingField('Kota', f('city'), required: true, readOnly: widget.readOnly),
      ],
      bankingField('Pengguna / Penanggung Jawab', f('employee_name'), required: true, readOnly: true, search: widget.readOnly ? null : _employee),
      bankingField('Nomor Pegawai', f('employee_no'), readOnly: true),
      bankingField('Kantor HRIS', f('office'), readOnly: true),
      bankingField('Tanggal Penyerahan', f('date'), required: true, readOnly: true, search: widget.readOnly ? null : _date),
      InventoryFullWidth(child: bankingField('Keterangan', f('notes'), readOnly: widget.readOnly, maxLines: 3)),
    ])],
  );
}
