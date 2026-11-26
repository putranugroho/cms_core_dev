import 'package:cms_core/models/core_access_model.dart';
import 'package:cms_core/models/core_coa_model.dart';
import 'package:cms_core/models/new_menu_models.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/new_menu_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetupInventarisPage extends StatefulWidget {
  const SetupInventarisPage({super.key});

  @override
  State<SetupInventarisPage> createState() => _SetupInventarisPageState();
}

class _SetupInventarisPageState extends State<SetupInventarisPage> {
  final _formKey = GlobalKey<FormState>();
  final _keyword = TextEditingController();
  final _groupInventaris = TextEditingController();
  final _keterangan = TextEditingController();
  final _masaManfaat = TextEditingController();
  final Map<String, TextEditingController> _sbbControllers = {
    for (final row in kSetupInventarisSbbRows) row.kode: TextEditingController(),
  };
  final Map<String, TextEditingController> _sbbNameControllers = {
    for (final row in kSetupInventarisSbbRows) row.kode: TextEditingController(),
  };

  List<SetupInventarisModel> _items = [];
  bool _loading = true;
  bool _dialog = false;
  bool _editMode = false;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;
  String _status = '';
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
      if (item.matchesRoute(MenuNotifier.routeSetupInventaris)) {
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
      _items = await NewMenuRepository.setupInventarisList(
        keyword: _keyword.text.trim(),
        statusData: _status,
      );
    } catch (e) {
      _items = [];
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _clearForm() {
    _groupInventaris.clear();
    _keterangan.clear();
    _masaManfaat.clear();
    for (final c in _sbbControllers.values) {
      c.clear();
    }
    for (final c in _sbbNameControllers.values) {
      c.clear();
    }
  }

  void _add() {
    _clearForm();
    setState(() {
      _editMode = false;
      _dialog = true;
    });
  }

  Future<void> _edit(SetupInventarisModel item) async {
    if (!_canUpdate) return;
    _clearForm();
    DialogCustom().showLoading(context);
    try {
      final rows = await NewMenuRepository.setupInventarisDetailRows(item.groupInventaris);
      if (mounted) Navigator.pop(context);
      _groupInventaris.text = item.groupInventaris;
      _keterangan.text = item.labelGroup;
      _masaManfaat.text = item.masaManfaatBulan == 0 ? '' : item.masaManfaatBulan.toString();
      for (final row in rows) {
        if (_sbbControllers[row.kode] != null) {
          _sbbControllers[row.kode]!.text = row.nosbb;
          _sbbNameControllers[row.kode]!.text = row.nosbbNama;
        }
        if (_keterangan.text.trim().isEmpty) _keterangan.text = row.labelGroup;
        if (_masaManfaat.text.trim().isEmpty && row.masaManfaatBulan > 0) _masaManfaat.text = row.masaManfaatBulan.toString();
      }
      setState(() {
        _editMode = true;
        _dialog = true;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final missing = kSetupInventarisSbbRows.where((row) => _sbbControllers[row.kode]!.text.trim().isEmpty).toList();
    if (missing.isNotEmpty) {
      informationDialog(context, 'Warning', 'Semua 10 SBB wajib diisi. Kosong: ${missing.map((e) => e.kode).join(', ')}');
      return;
    }

    final body = <String, dynamic>{
      'group_inventaris': _groupInventaris.text.trim().toUpperCase(),
      'keterangan': _keterangan.text.trim(),
      'masa_manfaat_bulan': int.tryParse(_masaManfaat.text.trim()) ?? 0,
      'data': kSetupInventarisSbbRows
              .map((row) => {
                'kode': row.kode,
                'nosbb': _sbbControllers[row.kode]!.text.trim(),
              })
          .toList(),
    };

    DialogCustom().showLoading(context);
    try {
      await NewMenuRepository.setupInventarisSave(isEdit: _editMode, body: body);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', _editMode ? 'Jenis inventaris berhasil diupdate.' : 'Jenis inventaris berhasil ditambahkan.');
      setState(() => _dialog = false);
      await _loadList();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Future<void> _delete(SetupInventarisModel item) async {
    DialogCustom().showLoading(context);
    try {
      await NewMenuRepository.setupInventarisDelete(item.groupInventaris);
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Informasi', 'Jenis inventaris berhasil dihapus.');
      await _loadList();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Future<void> _pickCoa(TextEditingController target, TextEditingController nameTarget) async {
    final selected = await showDialog<CoreCoaModel>(
      context: context,
      builder: (_) => const _CoaPickerDialog(),
    );
    if (selected != null) {
      target.text = selected.kodeCoa;
      nameTarget.text = selected.namaCoa;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _keyword.dispose();
    _groupInventaris.dispose();
    _keterangan.dispose();
    _masaManfaat.dispose();
    for (final c in _sbbControllers.values) {
      c.dispose();
    }
    for (final c in _sbbNameControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Toolbar(
                  title: 'Jenis Inventaris',
                  subtitle: 'Setup group inventaris dan mapping 10 SBB tetap',
                  keyword: _keyword,
                  status: _status,
                  onStatusChanged: (v) => setState(() => _status = v ?? ''),
                  onSearch: _loadList,
                  onAdd: _canCreate ? _add : null,
                  addText: 'Tambah Jenis',
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : _InventorySetupTable(items: _items, canUpdate: _canUpdate, canDelete: _canDelete, onEdit: _edit, onDelete: _delete),
                ),
              ],
            ),
            if (_dialog) _InventorySetupForm(),
          ],
        ),
      ),
    );
  }

  Widget _InventorySetupForm() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        alignment: Alignment.centerRight,
        child: Container(
          width: 720,
          height: double.infinity,
          color: Colors.white,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(_editMode ? 'Edit Jenis Inventaris' : 'Tambah Jenis Inventaris', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(onPressed: () => setState(() => _dialog = false), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _textField('Group Inventaris *', _groupInventaris, readOnly: _editMode, textCapitalization: TextCapitalization.characters),
                  _textField('Keterangan', _keterangan),
                  _textField('Masa Manfaat Bulan *', _masaManfaat, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                  const SizedBox(height: 14),
                  const Text('Mapping SBB Tetap', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {0: FixedColumnWidth(80), 1: FlexColumnWidth(), 2: FixedColumnWidth(180), 3: FixedColumnWidth(240)},
                    border: TableBorder.all(color: Colors.black12),
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFEFF3F8)),
                        children: [_Cell('Kode', bold: true), _Cell('Keterangan', bold: true), _Cell('No SBB', bold: true), _Cell('Nama SBB', bold: true)],
                      ),
                      ...kSetupInventarisSbbRows.map((row) {
                        final c = _sbbControllers[row.kode]!;
                        final name = _sbbNameControllers[row.kode]!;
                        return TableRow(
                          children: [
                            _Cell(row.kode),
                            _Cell(row.label),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: TextFormField(
                                controller: c,
                                readOnly: true,
                                decoration: _inputDecoration('No SBB *').copyWith(
                                  suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _pickCoa(c, name)),
                                ),
                                validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib' : null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: TextFormField(
                                controller: name,
                                readOnly: true,
                                decoration: _inputDecoration('Nama SBB'),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(double.infinity, 50)), child: const Text('Simpan', style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventorySetupTable extends StatelessWidget {
  final List<SetupInventarisModel> items;
  final bool canUpdate;
  final bool canDelete;
  final void Function(SetupInventarisModel) onEdit;
  final void Function(SetupInventarisModel) onDelete;

  const _InventorySetupTable({required this.items, required this.canUpdate, required this.canDelete, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Tidak ada data jenis inventaris.'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(colorPrimary),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Group Inventaris')),
            DataColumn(label: Text('Keterangan')),
            DataColumn(label: Text('Masa Manfaat')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Created By')),
            DataColumn(label: Text('Created At')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: items.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.groupInventaris)),
              DataCell(SizedBox(width: 240, child: Text(item.labelGroup, overflow: TextOverflow.ellipsis))),
              DataCell(Text(item.masaManfaatBulan.toString())),
              DataCell(Text(item.statusData)),
              DataCell(Text(item.createdBy)),
              DataCell(Text(item.createdAt)),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                if (canUpdate) ElevatedButton(onPressed: () => onEdit(item), style: ElevatedButton.styleFrom(backgroundColor: colorPrimary), child: const Text('Edit', style: TextStyle(color: Colors.white))),
                if (canUpdate && canDelete) const SizedBox(width: 8),
                if (canDelete) ElevatedButton(onPressed: () => onDelete(item), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
              ])),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController keyword;
  final String status;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onSearch;
  final VoidCallback? onAdd;
  final String addText;

  const _Toolbar({required this.title, required this.subtitle, required this.keyword, required this.status, required this.onStatusChanged, required this.onSearch, required this.onAdd, required this.addText});

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
          SizedBox(width: 280, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54))])),
          SizedBox(width: 260, child: TextField(controller: keyword, onSubmitted: (_) => onSearch(), decoration: _inputDecoration('Cari group inventaris').copyWith(prefixIcon: const Icon(Icons.search)))),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              value: status,
              decoration: _inputDecoration('Status'),
              items: const [DropdownMenuItem(value: '', child: Text('Default')), DropdownMenuItem(value: 'AKTIF', child: Text('Aktif')), DropdownMenuItem(value: 'NONAKTIF', child: Text('Nonaktif')), DropdownMenuItem(value: 'SEMUA', child: Text('Semua'))],
              onChanged: onStatusChanged,
            ),
          ),
          ElevatedButton(onPressed: onSearch, style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)), child: const Text('Cari', style: TextStyle(color: Colors.white))),
          if (onAdd != null) ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, color: Colors.white), label: Text(addText, style: const TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(150, 50))),
        ],
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
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextField(controller: search, onSubmitted: (_) => setState(() => future = NewMenuRepository.searchCoa(keyword: search.text.trim(), limit: 40)), decoration: _inputDecoration('Cari kode / nama COA'))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => setState(() => future = NewMenuRepository.searchCoa(keyword: search.text.trim(), limit: 40)), child: const Text('Cari')),
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
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  const _Cell(this.text, {this.bold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(10), child: Text(text, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)));
  }
}

Widget _textField(String label, TextEditingController controller, {bool readOnly = false, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, TextCapitalization textCapitalization = TextCapitalization.none}) {
  final required = label.contains('*');
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(label),
      validator: required ? (v) => (v ?? '').trim().isEmpty ? '$label wajib diisi' : null : null,
    ),
  );
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true);
}
