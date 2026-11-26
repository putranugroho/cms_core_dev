import 'dart:math' as math;

import 'package:cms_core/models/banking_setup_models.dart';
import 'package:cms_core/models/core_coa_model.dart';
import 'package:cms_core/models/new_menu_models.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/banking_setup_repository.dart';
import 'package:cms_core/repository/new_menu_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BankingPermissions {
  final bool create;
  final bool update;
  final bool delete;
  const BankingPermissions({
    this.create = false,
    this.update = false,
    this.delete = false,
  });
  static Future<BankingPermissions> load(String route) async {
    final pref = Pref();
    final admin = await pref.getIsSuperAdmin();
    final access = (await pref.getCoreAccessList()).where(
      (e) => e.matchesRoute(route),
    );
    return BankingPermissions(
      create: admin || access.any((e) => e.canCreate),
      update: admin || access.any((e) => e.canUpdate),
      delete: admin || access.any((e) => e.canDelete),
    );
  }
}

// The three menus share the same list-first layout, request ordering and pager.
abstract class BankingListState<T, W extends StatefulWidget> extends State<W> {
  final keyword = TextEditingController();
  BankingPermissions access = const BankingPermissions();
  BankingPage<T>? result;
  String searchField = '';
  String? error;
  bool loading = true;
  bool available = true;
  bool actionBusy = false;
  bool _modalOpen = false;
  int page = 1;
  int limit = 10;
  int _generation = 0;

  String get title;
  String get route;
  Map<String, String> get searchChoices;
  Future<BankingPage<T>> fetchPage();
  Future<bool> serviceAvailable() async => true;
  Widget buildTable(List<T> items);
  Future<void> addRecord();
  List<Widget> buildFilters() => [];
  bool get showAddButton => true;

  @override
  void initState() {
    super.initState();
    searchField = searchChoices.keys.first;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final permissions = await BankingPermissions.load(route);
      if (!mounted) return;
      setState(() => access = permissions);
      await reload();
    } catch (e) {
      if (mounted)
        setState(() {
          loading = false;
          error = e.toString();
        });
    }
  }

  Future<void> reload({bool resetPage = false}) async {
    if (!mounted) return;
    final generation = ++_generation;
    if (resetPage) page = 1;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final ready = await serviceAvailable();
      if (!mounted || generation != _generation) return;
      available = ready;
      if (!ready) {
        setState(() {
          loading = false;
          result = null;
          error =
              'Layanan $title belum tersedia. Form dapat dibuka untuk ditinjau.';
        });
        return;
      }
      final data = await fetchPage();
      if (!mounted || generation != _generation) return;
      if (data.items.isEmpty &&
          page > 1 &&
          data.total < (page - 1) * limit + 1) {
        page = math.max(1, (data.total + limit - 1) ~/ limit);
        await reload();
        return;
      }
      setState(() {
        result = data;
        page = data.page;
        limit = data.limit;
        loading = false;
      });
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() {
          error = e.toString();
          result = null;
          loading = false;
        });
    }
  }

  Future<void> perform(Future<void> Function() action) async {
    if (actionBusy) return;
    setState(() => actionBusy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) bankingMessage(context, e.toString());
    } finally {
      if (mounted) setState(() => actionBusy = false);
    }
  }

  Future<R?> _showModal<R>(Widget dialog, {bool dismissible = false}) async {
    setState(() => _modalOpen = true);
    try {
      return await showDialog<R>(
        context: context,
        barrierDismissible: dismissible,
        builder: (_) => dialog,
      );
    } finally {
      if (mounted) setState(() => _modalOpen = false);
    }
  }

  Future<bool?> showEditor(Widget form) => _showModal<bool>(form);

  Future<bool> confirmDelete(String name) async =>
      await _showModal<bool>(
        Builder(
          builder: (dialogContext) => AlertDialog(
            title: const Text('Hapus data?'),
            content: Text('Hapus $name?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        dismissible: true,
      ) ??
      false;

  @override
  void dispose() {
    _generation++;
    keyword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: searchField,
                    decoration: const InputDecoration(
                      labelText: 'Cari berdasarkan',
                      border: OutlineInputBorder(),
                    ),
                    items: searchChoices.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: loading || actionBusy
                        ? null
                        : (v) {
                            if (v != null) setState(() => searchField = v);
                          },
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: keyword,
                    onSubmitted: (_) {
                      if (!actionBusy) reload(resetPage: true);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Kata kunci',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ...buildFilters(),
                ElevatedButton(
                  onPressed: loading || actionBusy
                      ? null
                      : () => reload(resetPage: true),
                  child: const Text('Cari'),
                ),
                IconButton(
                  tooltip: 'Muat ulang',
                  onPressed: loading || actionBusy ? null : () => reload(),
                  icon: const Icon(Icons.refresh),
                ),
                if (access.create && showAddButton)
                  ElevatedButton.icon(
                    onPressed: loading || actionBusy
                        ? null
                        : () => perform(addRecord),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
              ],
            ),
          ),
          if (actionBusy && !_modalOpen) const LinearProgressIndicator(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(error!, textAlign: TextAlign.center),
                    ),
                  )
                : (result?.items.isEmpty ?? true)
                ? const Center(child: Text('Belum ada data.'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: buildTable(result!.items),
                    ),
                  ),
          ),
          if (!loading && error == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Total ${result?.total ?? 0} data • Halaman $page'),
                  TextButton(
                    onPressed: page > 1 && !actionBusy
                        ? () {
                            page--;
                            reload();
                          }
                        : null,
                    child: const Text('Sebelumnya'),
                  ),
                  TextButton(
                    onPressed: (result?.hasNext ?? false) && !actionBusy
                        ? () {
                            page++;
                            reload();
                          }
                        : null,
                    child: const Text('Berikutnya'),
                  ),
                  SizedBox(
                    width: 125,
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: limit,
                      decoration: const InputDecoration(
                        labelText: 'Per halaman',
                      ),
                      items: ({10, 25, 50, limit}.toList()..sort())
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: Text('$e')),
                          )
                          .toList(),
                      onChanged: actionBusy
                          ? null
                          : (v) {
                              if (v != null) {
                                limit = v;
                                reload(resetPage: true);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class BankingActions extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showEdit;
  final bool showDelete;
  const BankingActions({
    super.key,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.showEdit = false,
    this.showDelete = false,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Lihat detail',
        onPressed: onView,
        icon: const Icon(Icons.visibility_outlined),
      ),
      if (showEdit) TextButton(onPressed: onEdit, child: const Text('Edit')),
      if (showDelete)
        TextButton(
          onPressed: onDelete,
          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
    ],
  );
}

DataTable bankingTable(List<String> headings, List<DataRow> rows) => DataTable(
  headingRowColor: MaterialStateProperty.all(colorPrimary),
  headingTextStyle: const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  ),
  columns: headings.map((e) => DataColumn(label: Text(e))).toList(),
  rows: rows,
);

void bankingMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

Widget bankingField(
  String label,
  TextEditingController controller, {
  bool required = false,
  bool readOnly = false,
  VoidCallback? search,
  VoidCallback? clear,
  String? helper,
  int maxLines = 1,
  TextInputType? keyboard,
  List<TextInputFormatter>? formatters,
  String? Function(String?)? validator,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: TextFormField(
    controller: controller,
    readOnly: readOnly || search != null,
    onTap: search,
    mouseCursor: search == null ? null : SystemMouseCursors.click,
    maxLines: maxLines,
    keyboardType: keyboard,
    inputFormatters: formatters,
    decoration: InputDecoration(
      labelText: required ? '$label *' : label,
      helperText: helper,
      border: const OutlineInputBorder(),
      suffixIcon: search == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (clear != null)
                  IconButton(
                    tooltip: 'Kosongkan',
                    onPressed: clear,
                    icon: const Icon(Icons.clear),
                  ),
                IconButton(
                  tooltip: 'Cari $label',
                  onPressed: search,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
    ),
    validator:
        validator ??
        (value) =>
            required && (value ?? '').trim().isEmpty ? 'Wajib diisi' : null,
  ),
);

Widget bankingDropdown(
  String label,
  String value,
  Map<String, String> choices,
  ValueChanged<String?>? changed,
) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: DropdownButtonFormField<String>(
    isExpanded: true,
    value: value,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: choices.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList(),
    onChanged: changed,
  ),
);

class BankingFormDialog extends StatelessWidget {
  final bool sidePanel;
  final double width;
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final VoidCallback? onSave;
  final bool busy;
  final bool readOnly;
  final bool available;
  final String? error;
  const BankingFormDialog({
    super.key,
    required this.title,
    this.width = 620,
    this.sidePanel = false,
    required this.formKey,
    required this.fields,
    required this.onSave,
    this.busy = false,
    this.readOnly = false,
    this.available = true,
    this.error,
  });
  @override
  Widget build(BuildContext context) => sidePanel ? _buildSidePanel(context) : WillPopScope(
    onWillPop: () async => !busy,
    child: AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: math.max(100, MediaQuery.of(context).size.height - 210),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!available)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Layanan belum tersedia. Data belum dapat disimpan.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  AbsorbPointer(
                    absorbing: busy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: fields,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(readOnly ? 'Tutup' : 'Batal'),
        ),
        if (!readOnly)
          ElevatedButton(
            onPressed: busy || !available ? null : onSave,
            child: Text(busy ? 'Menyimpan…' : 'Simpan'),
          ),
      ],
    ),
  );
  Widget _buildSidePanel(BuildContext context) => WillPopScope(
    onWillPop: () async => !busy,
    child: Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Material(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(tooltip: 'Tutup', onPressed: busy ? null : () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 18),
              if (error != null) Padding(padding: const EdgeInsets.only(bottom: 16),
                child: Text(error!, style: const TextStyle(color: Colors.red))),
              if (!available) const Padding(padding: EdgeInsets.only(bottom: 16),
                child: Text('Layanan belum tersedia. Data belum dapat disimpan.', style: TextStyle(color: Colors.orange))),
              Form(key: formKey, child: AbsorbPointer(absorbing: busy,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: fields))),
              if (!readOnly) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: busy || !available ? null : onSave,
                  style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(double.infinity, 50)),
                  child: Text(busy ? 'Menyimpan…' : 'Simpan', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ]),
          ),
        ),
      ),
    ),
  );
}

class BankingLookupDialog<T> extends StatefulWidget {
  final String title;
  final Future<BankingPage<T>> Function(String, int) load;
  final String Function(T) label;
  final String Function(T) subtitle;
  final bool needsKeyword;
  const BankingLookupDialog({
    super.key,
    required this.title,
    required this.load,
    required this.label,
    required this.subtitle,
    this.needsKeyword = false,
  });
  @override
  State<BankingLookupDialog<T>> createState() => _BankingLookupState<T>();
}

class _BankingLookupState<T> extends State<BankingLookupDialog<T>> {
  final _keyword = TextEditingController();
  BankingPage<T>? _result;
  String? _error;
  bool _loading = false;
  int _page = 1;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    if (!widget.needsKeyword) _load();
  }

  Future<void> _load({bool reset = false}) async {
    final generation = ++_generation;
    if (reset) _page = 1;
    if (widget.needsKeyword && _keyword.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.load(_keyword.text.trim(), _page);
      if (mounted && generation == _generation)
        setState(() {
          _result = data;
          _loading = false;
        });
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() {
          _error = e.toString();
          _result = null;
          _loading = false;
        });
    }
  }

  @override
  void dispose() {
    _generation++;
    _keyword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 560,
      height: math.min(
        400,
        math.max(180, MediaQuery.of(context).size.height - 240),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keyword,
                  onSubmitted: (_) => _load(reset: true),
                  decoration: const InputDecoration(
                    labelText: 'Kode atau nama',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cari',
                onPressed: _loading ? null : () => _load(reset: true),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _result == null
                ? const Center(
                    child: Text('Masukkan kata kunci lalu tekan Cari.'),
                  )
                : _result!.items.isEmpty
                ? const Center(child: Text('Tidak ada data.'))
                : ListView.builder(
                    itemCount: _result!.items.length,
                    itemBuilder: (_, i) {
                      final row = _result!.items[i];
                      return ListTile(
                        title: Text(widget.label(row)),
                        subtitle: Text(widget.subtitle(row)),
                        onTap: () => Navigator.pop(context, row),
                      );
                    },
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _page > 1 && !_loading
                    ? () {
                        _page--;
                        _load();
                      }
                    : null,
                child: const Text('Sebelumnya'),
              ),
              TextButton(
                onPressed: (_result?.hasNext ?? false) && !_loading
                    ? () {
                        _page++;
                        _load();
                      }
                    : null,
                child: const Text('Berikutnya'),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tutup'),
      ),
    ],
  );
}

Future<BankProfileModel?> pickBankingBank(
  BuildContext context,
) => showDialog<BankProfileModel>(
  context: context,
  builder: (_) => BankingLookupDialog<BankProfileModel>(
    title: 'Cari Bank',
    needsKeyword: true,
    load: (q, page) async {
      final rows =
          (await NewMenuRepository.searchBankProfile(keyword: q, limit: 100))
              .where(
                (row) => row.kodeBank.isNotEmpty && row.displayName.isNotEmpty,
              )
              .toList();
      return BankingPage(items: rows, total: rows.length, page: 1, limit: 100);
    },
    label: (row) => '${row.kodeBank} • ${row.displayName}',
    subtitle: (row) => row.namaBpr,
  ),
);

Future<CoreCoaModel?> pickBankingSbb(
  BuildContext context,
) => showDialog<CoreCoaModel>(
  context: context,
  builder: (_) => BankingLookupDialog<CoreCoaModel>(
    title: 'Cari SBB',
    needsKeyword: true,
    load: (q, page) async {
      final rows = await NewMenuRepository.searchCoa(keyword: q, limit: 100);
      return BankingPage(items: rows, total: rows.length, page: 1, limit: 100);
    },
    label: (row) => '${row.kodeCoa} • ${row.namaCoa}',
    subtitle: (row) => row.postingType,
  ),
);

Future<PartyGroupModel?> pickBankingPartyGroup(BuildContext context) =>
    showDialog<PartyGroupModel>(
      context: context,
      builder: (_) => BankingLookupDialog<PartyGroupModel>(
        title: 'Cari Kelompok Pihak Ketiga',
        load: (q, page) => BankingSetupRepository.groupList(
          keyword: q,
          searchField: RegExp(r'^[0-9]{2}$').hasMatch(q)
              ? 'kode_kelompok'
              : 'nama_kelompok',
          page: page,
          limit: 20,
        ),
        label: (row) => '${row.kode} • ${row.nama}',
        subtitle: (row) => row.nomorSbb.isEmpty
            ? 'Tanpa SBB'
            : '${row.nomorSbb} • ${row.namaSbb}',
      ),
    );
