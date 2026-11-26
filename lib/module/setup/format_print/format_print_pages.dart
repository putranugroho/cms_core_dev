import 'dart:convert';

import 'package:cms_core/models/index.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/repository/print_setup_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Explicit API flags take precedence over coordinates, including zero positions.
bool _printFlag(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  switch (value?.toString().trim().toLowerCase()) {
    case 'true':
    case '1':
      return true;
    case 'false':
    case '0':
      return false;
    default:
      return fallback;
  }
}

bool _fieldIsVisible(FormatPrintConfig config, PrintFieldDef field, Map<String, dynamic> data) {
  final legacyVisible = data[field.xField] != null || data[field.yField] != null;
  return config.hasVisibilityFlags
      ? _printFlag(data['${field.key}_flag'], fallback: legacyVisible)
      : legacyVisible;
}

class FormatBukuPage extends StatelessWidget {
  const FormatBukuPage({super.key});

  @override
  Widget build(BuildContext context) => FormatPrintPage(config: FormatPrintConfig.formatBuku());
}

class FormatCoverPage extends StatelessWidget {
  const FormatCoverPage({super.key});

  @override
  Widget build(BuildContext context) => FormatPrintPage(config: FormatPrintConfig.formatCover());
}

class FormatBilyetPage extends StatelessWidget {
  const FormatBilyetPage({super.key});

  @override
  Widget build(BuildContext context) => FormatPrintPage(config: FormatPrintConfig.formatBilyet());
}

class PrintFieldDef {
  final String label;
  final String xField;
  final String yField;
  final double defaultX;
  final double defaultY;

  const PrintFieldDef(this.label, this.xField, this.yField, {this.defaultX = 5, this.defaultY = 5});

  String get key => xField.replaceAll('_x', '');

  bool get isQrCode => key == 'qr_code';
  // Fixed print size: 1 x 1 cm, while layout coordinates use mm.
  double get widthMm => isQrCode ? 20 : 0;
  double get heightMm => isQrCode ? 20 : 0;
}

class BaseFieldDef {
  final String label;
  final String field;
  final bool required;
  final bool numeric;
  final bool integer;
  final int? maxLength;
  final String hint;

  const BaseFieldDef(
    this.label,
    this.field, {
    this.required = false,
    this.numeric = false,
    this.integer = false,
    this.maxLength,
    this.hint = '',
  });
}

class FormatPrintConfig {
  final String title;
  final String subtitle;
  final String routePath;
  final String keyField;
  final String nameField;
  final String listUrl;
  final String detailUrl;
  final String createUrl;
  final String updateUrl;
  final String deleteUrl;
  final List<BaseFieldDef> baseFields;
  final List<PrintFieldDef> printFields;
  final double paperWidthMm;
  final double paperHeightMm;

  const FormatPrintConfig({
    required this.title,
    required this.subtitle,
    required this.routePath,
    required this.keyField,
    required this.nameField,
    required this.listUrl,
    required this.detailUrl,
    required this.createUrl,
    required this.updateUrl,
    required this.deleteUrl,
    required this.baseFields,
    required this.printFields,
    required this.paperWidthMm,
    required this.paperHeightMm,
  });

  bool get hasVisibilityFlags => keyField == 'kode_format_bilyet';

  factory FormatPrintConfig.formatBuku() {
    return FormatPrintConfig(
      title: 'Format Buku Tabungan',
      subtitle: 'Posisi print buku tabungan dalam koordinat X/Y mm',
      routePath: '/setup/format-buku',
      keyField: 'kode_format',
      nameField: 'nama_format',
      listUrl: NetworkURL.formatBukuList(),
      detailUrl: NetworkURL.formatBukuDetail(),
      createUrl: NetworkURL.formatBukuCreate(),
      updateUrl: NetworkURL.formatBukuUpdate(),
      deleteUrl: NetworkURL.formatBukuDelete(),
      paperWidthMm: 160,
      paperHeightMm: 95,
      baseFields: const [
        BaseFieldDef('Kode Format', 'kode_format', required: true, maxLength: 30),
        BaseFieldDef('Nama Format', 'nama_format', required: true, maxLength: 120),
        BaseFieldDef('Merk Buku', 'merk_buku', maxLength: 100),
        BaseFieldDef('Ukuran Kertas', 'ukuran_kertas', hint: 'contoh: 140x200'),
        BaseFieldDef('Jumlah Baris', 'jumlah_baris', numeric: true, integer: true),
        BaseFieldDef('Margin Atas', 'margin_atas', numeric: true),
        BaseFieldDef('Margin Bawah', 'margin_bawah', numeric: true),
        BaseFieldDef('Margin Kiri', 'margin_kiri', numeric: true),
        BaseFieldDef('Margin Kanan', 'margin_kanan', numeric: true),
        BaseFieldDef('Font Size', 'font_size', numeric: true),
      ],
      printFields: const [
        PrintFieldDef('Tanggal', 'tanggal_x', 'tanggal_y', defaultX: 5, defaultY: 5),
        PrintFieldDef('Keterangan', 'keterangan_x', 'keterangan_y', defaultX: 30, defaultY: 5),
        PrintFieldDef('Debet', 'debet_x', 'debet_y', defaultX: 80, defaultY: 5),
        PrintFieldDef('Kredit', 'kredit_x', 'kredit_y', defaultX: 100, defaultY: 5),
        PrintFieldDef('Saldo', 'saldo_x', 'saldo_y', defaultX: 120, defaultY: 5),
      ],
    );
  }

  factory FormatPrintConfig.formatCover() {
    return FormatPrintConfig(
      title: 'Format Cover Buku',
      subtitle: 'Posisi print cover/sampul buku tabungan dalam koordinat X/Y mm',
      routePath: '/setup/format-cover',
      keyField: 'kode_format_cover',
      nameField: 'nama_format_cover',
      listUrl: NetworkURL.formatCoverList(),
      detailUrl: NetworkURL.formatCoverDetail(),
      createUrl: NetworkURL.formatCoverCreate(),
      updateUrl: NetworkURL.formatCoverUpdate(),
      deleteUrl: NetworkURL.formatCoverDelete(),
      paperWidthMm: 160,
      paperHeightMm: 95,
      baseFields: const [
        BaseFieldDef('Kode Format Cover', 'kode_format_cover', required: true, maxLength: 30),
        BaseFieldDef('Nama Format Cover', 'nama_format_cover', required: true, maxLength: 120),
        BaseFieldDef('Merk Buku', 'merk_buku', maxLength: 100),
        BaseFieldDef('Ukuran Kertas', 'ukuran_kertas', hint: 'contoh: 140x200'),
        BaseFieldDef('Font Size', 'font_size', numeric: true),
      ],
      printFields: const [
        PrintFieldDef('Nomor Rekening', 'nomor_rekening_x', 'nomor_rekening_y', defaultX: 5, defaultY: 5),
        PrintFieldDef('Nama Nasabah', 'nama_nasabah_x', 'nama_nasabah_y', defaultX: 5, defaultY: 15),
        PrintFieldDef('Nomor CIF', 'nomor_cif_x', 'nomor_cif_y', defaultX: 5, defaultY: 25),
        PrintFieldDef('Alamat', 'alamat_x', 'alamat_y', defaultX: 5, defaultY: 35),
        PrintFieldDef('Nama Kantor', 'nama_kantor_x', 'nama_kantor_y', defaultX: 5, defaultY: 55),
        PrintFieldDef('Nama Produk', 'nama_produk_x', 'nama_produk_y', defaultX: 5, defaultY: 65),
        PrintFieldDef('Tanggal Terbit', 'tanggal_terbit_x', 'tanggal_terbit_y', defaultX: 5, defaultY: 75),
        PrintFieldDef('Logo', 'logo_x', 'logo_y', defaultX: 100, defaultY: 5),
      ],
    );
  }

  factory FormatPrintConfig.formatBilyet() {
    return FormatPrintConfig(
      title: 'Format Bilyet Deposito',
      subtitle: 'Posisi print sertifikat/bilyet deposito dalam koordinat X/Y mm',
      routePath: '/setup/format-bilyet',
      keyField: 'kode_format_bilyet',
      nameField: 'nama_format_bilyet',
      listUrl: NetworkURL.formatBilyetList(),
      detailUrl: NetworkURL.formatBilyetDetail(),
      createUrl: NetworkURL.formatBilyetCreate(),
      updateUrl: NetworkURL.formatBilyetUpdate(),
      deleteUrl: NetworkURL.formatBilyetDelete(),
      paperWidthMm: 160,
      paperHeightMm: 95,
      baseFields: const [
        BaseFieldDef('Kode Format Bilyet', 'kode_format_bilyet', required: true, maxLength: 30),
        BaseFieldDef('Nama Format Bilyet', 'nama_format_bilyet', required: true, maxLength: 120),
        BaseFieldDef('Merk Kertas', 'merk_kertas', maxLength: 100),
        BaseFieldDef('Ukuran Kertas', 'ukuran_kertas', hint: 'contoh: 210x297'),
        BaseFieldDef('Font Size', 'font_size', numeric: true),
      ],
      printFields: const [
        PrintFieldDef('Nomor Bilyet', 'nomor_bilyet_x', 'nomor_bilyet_y', defaultX: 10, defaultY: 10),
        PrintFieldDef('Nomor Deposito', 'nomor_deposito_x', 'nomor_deposito_y', defaultX: 10, defaultY: 20),
        PrintFieldDef('Nama Nasabah', 'nama_nasabah_x', 'nama_nasabah_y', defaultX: 10, defaultY: 30),
        PrintFieldDef('Nomor CIF', 'nomor_cif_x', 'nomor_cif_y', defaultX: 10, defaultY: 40),
        PrintFieldDef('Alamat Nasabah', 'alamat_nasabah_x', 'alamat_nasabah_y', defaultX: 10, defaultY: 50),
        PrintFieldDef('Nominal Deposito', 'nominal_deposito_x', 'nominal_deposito_y', defaultX: 10, defaultY: 60),
        PrintFieldDef('Terbilang', 'terbilang_x', 'terbilang_y', defaultX: 10, defaultY: 70),
        PrintFieldDef('Rate Bunga', 'rate_bunga_x', 'rate_bunga_y', defaultX: 10, defaultY: 80),
        PrintFieldDef('Tanggal Valuta', 'tanggal_valuta_x', 'tanggal_valuta_y', defaultX: 90, defaultY: 10),
        PrintFieldDef('Tanggal Jatuh Tempo', 'tanggal_jatuh_tempo_x', 'tanggal_jatuh_tempo_y', defaultX: 90, defaultY: 20),
        PrintFieldDef('Cara Bayar Bunga', 'cara_bayar_bunga_x', 'cara_bayar_bunga_y', defaultX: 90, defaultY: 30),
        PrintFieldDef('Nama Kantor', 'nama_kantor_x', 'nama_kantor_y', defaultX: 90, defaultY: 40),
        PrintFieldDef('Nama Produk', 'nama_produk_x', 'nama_produk_y', defaultX: 90, defaultY: 50),
        PrintFieldDef('Nama AO', 'nama_ao_x', 'nama_ao_y', defaultX: 90, defaultY: 60),
        PrintFieldDef('Logo', 'logo_x', 'logo_y', defaultX: 125, defaultY: 10),
        PrintFieldDef('Tanda Tangan', 'tanda_tangan_x', 'tanda_tangan_y', defaultX: 90, defaultY: 75),
        PrintFieldDef('QR Code', 'qr_code_x', 'qr_code_y', defaultX: 140, defaultY: 75),
      ],
    );
  }
}

class FormatPrintPage extends StatelessWidget {
  final FormatPrintConfig config;

  const FormatPrintPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FormatPrintNotifier(context: context, config: config),
      child: Consumer<FormatPrintNotifier>(
        builder: (context, value, _) => SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(value: value),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(child: Text(value.errorMessage!))
                              : _FormatTable(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _FormatEditor(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FormatPrintNotifier extends ChangeNotifier {
  final BuildContext context;
  final FormatPrintConfig config;

  FormatPrintNotifier({required this.context, required this.config}) {
    init();
  }

  final keyForm = GlobalKey<FormState>();
  final keyword = TextEditingController();
  final Map<String, TextEditingController> controllers = {};
  final Map<String, bool> fieldVisible = {};
  List<Map<String, dynamic>> list = [];
  Map<String, dynamic>? selected;
  bool isLoading = true;
  bool dialog = false;
  bool editData = false;
  bool fontSizeVisible = true;
  String statusData = 'A';
  String? errorMessage;
  bool isSuperAdmin = false;
  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  Future<void> init() async {
    _ensureControllers();
    final pref = Pref();
    isSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(config.routePath)) {
        current = item;
        break;
      }
    }
    canCreate = isSuperAdmin || (current?.canCreate ?? false);
    canUpdate = isSuperAdmin || (current?.canUpdate ?? false);
    canDelete = isSuperAdmin || (current?.canDelete ?? false);
    await getList();
  }

  void _ensureControllers() {
    for (final field in config.baseFields) {
      controllers.putIfAbsent(field.field, () => TextEditingController());
    }
    for (final field in config.printFields) {
      controllers.putIfAbsent(field.xField, () => TextEditingController());
      controllers.putIfAbsent(field.yField, () => TextEditingController());
      fieldVisible.putIfAbsent(field.key, () => true);
    }
  }

  Future<void> getList() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        config.keyField: keyword.text.trim(),
        config.nameField: keyword.text.trim(),
        'status_data': statusData,
        'page': 1,
        'limit': 100,
      };
      final value = await Setuprepository.fetch(config.listUrl, body);
      if (!PrintSetupRepository.isSuccess(value)) {
        throw Exception(PrintSetupRepository.message(value, 'Gagal memuat data'));
      }
      list = PrintSetupRepository.rows(value).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      list.sort((a, b) => (a[config.keyField] ?? '').toString().compareTo((b[config.keyField] ?? '').toString()));
    } catch (e) {
      list = [];
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void pilihStatus(String? value) {
    statusData = value ?? '';
    notifyListeners();
  }

  void refreshPreview() {
    notifyListeners();
  }

  void tambah() {
    if (!canCreate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses tambah ${config.title}.');
      return;
    }
    clear();
    dialog = true;
    notifyListeners();
  }

  Future<void> edit(Map<String, dynamic> row) async {
    if (!canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update ${config.title}.');
      return;
    }
    try {
      DialogCustom().showLoading(context);
      final value = await Setuprepository.fetch(config.detailUrl, {config.keyField: (row[config.keyField] ?? '').toString()});
      if (context.mounted) Navigator.pop(context);
      selected = PrintSetupRepository.map(value).isEmpty ? row : PrintSetupRepository.map(value);
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
      selected = row;
    }
    _fill(selected ?? row);
    editData = true;
    dialog = true;
    notifyListeners();
  }

  void clear() {
    selected = null;
    editData = false;
    fontSizeVisible = true;
    for (final controller in controllers.values) {
      controller.clear();
    }
    for (final field in config.printFields) {
      controllers[field.xField]?.text = _fmt(field.defaultX);
      controllers[field.yField]?.text = _fmt(field.defaultY);
      fieldVisible[field.key] = true;
    }
    controllers['font_size']?.text = '10';
    controllers['jumlah_baris']?.text = '30';
  }

  void _fill(Map<String, dynamic> data) {
    fontSizeVisible = _printFlag(data['font_size_flag'], fallback: true);
    for (final field in config.baseFields) {
      controllers[field.field]?.text = (data[field.field] ?? '').toString();
    }
    for (final field in config.printFields) {
      final x = data[field.xField];
      final y = data[field.yField];
      controllers[field.xField]?.text = _fmt(PrintValue.toDouble(x, field.defaultX));
      controllers[field.yField]?.text = _fmt(PrintValue.toDouble(y, field.defaultY));
      fieldVisible[field.key] = _fieldIsVisible(config, field, data);
    }
  }

  void tutup() {
    dialog = false;
    notifyListeners();
  }

  void toggleField(PrintFieldDef field, bool? visible) {
    fieldVisible[field.key] = visible ?? false;
    notifyListeners();
  }

  void updateFieldPosition(PrintFieldDef field, double x, double y) {
    controllers[field.xField]?.text = _fmt(x.clamp(0, config.paperWidthMm - field.widthMm));
    controllers[field.yField]?.text = _fmt(y.clamp(0, config.paperHeightMm - field.heightMm));
    fieldVisible[field.key] = true;
    notifyListeners();
  }

  Future<void> save() async {
    if (!(keyForm.currentState?.validate() ?? false)) return;
    DialogCustom().showLoading(context);
    try {
      final body = _buildBody();
      final value = await Setuprepository.fetch(editData ? config.updateUrl : config.createUrl, body);
      if (context.mounted) Navigator.pop(context);
      if (!PrintSetupRepository.isSuccess(value)) {
        throw Exception(PrintSetupRepository.message(value, 'Gagal menyimpan data'));
      }
      informationDialog(context, 'Informasi', editData ? 'Data berhasil diupdate.' : 'Data berhasil ditambahkan.');
      dialog = false;
      clear();
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{};
    for (final field in config.baseFields) {
      final text = controllers[field.field]?.text.trim() ?? '';
      if (field.numeric) {
        if (text.isEmpty) {
          body[field.field] = null;
        } else if (field.integer) {
          body[field.field] = int.tryParse(text) ?? 0;
        } else {
          body[field.field] = double.tryParse(text) ?? 0;
        }
      } else {
        body[field.field] = text;
      }
    }
    for (final field in config.printFields) {
      final visible = fieldVisible[field.key] ?? true;
      if (config.hasVisibilityFlags) {
        body['${field.key}_flag'] = visible;
        // Preserve positions while disabled, so enabling again restores the layout.
        body[field.xField] = double.tryParse(controllers[field.xField]?.text.trim() ?? '') ?? field.defaultX;
        body[field.yField] = double.tryParse(controllers[field.yField]?.text.trim() ?? '') ?? field.defaultY;
      } else {
        body[field.xField] = visible ? double.tryParse(controllers[field.xField]?.text.trim() ?? '') : null;
        body[field.yField] = visible ? double.tryParse(controllers[field.yField]?.text.trim() ?? '') : null;
      }
    }
    if (config.hasVisibilityFlags) {
      body['font_size_flag'] = fontSizeVisible;
      body['qr_code_size'] = 10; // 1 x 1 cm, in the gateway's mm units.
    }
    return body;
  }

  void confirmDelete(Map<String, dynamic> row) {
    if (!canDelete) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses hapus ${config.title}.');
      return;
    }
    final code = (row[config.keyField] ?? '').toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Hapus ${config.title} $code?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              remove(row);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> remove(Map<String, dynamic> row) async {
    DialogCustom().showLoading(context);
    try {
      final value = await Setuprepository.fetch(config.deleteUrl, {config.keyField: (row[config.keyField] ?? '').toString()});
      if (context.mounted) Navigator.pop(context);
      if (!PrintSetupRepository.isSuccess(value)) {
        throw Exception(PrintSetupRepository.message(value, 'Gagal menghapus data'));
      }
      informationDialog(context, 'Informasi', 'Data berhasil dihapus.');
      dialog = false;
      clear();
      await getList();
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      informationDialog(context, 'Warning', e.toString());
    }
  }

  String _fmt(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  @override
  void dispose() {
    keyword.dispose();
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _Header extends StatelessWidget {
  final FormatPrintNotifier value;

  const _Header({required this.value});

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
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value.config.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value.config.subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              controller: value.keyword,
              onSubmitted: (_) => value.getList(),
              decoration: InputDecoration(
                hintText: 'Cari kode / nama format',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              value: value.statusData,
              decoration: _decoration('Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua')),
                DropdownMenuItem(value: 'A', child: Text('Aktif')),
                DropdownMenuItem(value: 'D', child: Text('Hapus')),
              ],
              onChanged: value.pilihStatus,
            ),
          ),
          ElevatedButton(
            onPressed: value.getList,
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
            child: const Text('Cari', style: TextStyle(color: Colors.white)),
          ),
          if (value.canCreate)
            ElevatedButton.icon(
              onPressed: value.tambah,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(120, 50)),
            ),
        ],
      ),
    );
  }
}

class _FormatTable extends StatelessWidget {
  final FormatPrintNotifier value;

  const _FormatTable({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) return const Center(child: Text('Data masih kosong.'));
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
              DataColumn(label: Text('Kode')),
              DataColumn(label: Text('Nama Format')),
              DataColumn(label: Text('Ukuran')),
              DataColumn(label: Text('Font')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Created By')),
              DataColumn(label: Text('Created At')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: value.list.map((row) {
              return DataRow(cells: [
                DataCell(Text((row[value.config.keyField] ?? '').toString())),
                DataCell(SizedBox(width: 260, child: Text((row[value.config.nameField] ?? '').toString(), overflow: TextOverflow.ellipsis))),
                DataCell(Text((row['ukuran_kertas'] ?? '').toString())),
                DataCell(Text((row['font_size'] ?? '').toString())),
                DataCell(_StatusChip(code: (row['status_data'] ?? '').toString())),
                DataCell(Text((row['created_by'] ?? '').toString())),
                DataCell(Text((row['created_at'] ?? '').toString())),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value.canUpdate)
                      ElevatedButton(
                        onPressed: () => value.edit(row),
                        style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                        child: const Text('Edit', style: TextStyle(color: Colors.white)),
                      ),
                    if (value.canUpdate && value.canDelete) const SizedBox(width: 8),
                    if (value.canDelete)
                      ElevatedButton(
                        onPressed: () => value.confirmDelete(row),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _FormatEditor extends StatelessWidget {
  final FormatPrintNotifier value;

  const _FormatEditor({required this.value});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 1180,
            height: double.infinity,
            color: Colors.white,
            child: Form(
              key: value.keyForm,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 520,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  value.editData ? 'Edit ${value.config.title}' : 'Tambah ${value.config.title}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(onPressed: value.tutup, icon: const Icon(Icons.close)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...value.config.baseFields.map((field) => _input(value, field)),
                          if (value.config.hasVisibilityFlags)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Gunakan Font Size'),
                              value: value.fontSizeVisible,
                              onChanged: (enabled) {
                                value.fontSizeVisible = enabled ?? false;
                                value.refreshPreview();
                              },
                            ),
                          const SizedBox(height: 8),
                          const Text('Field Print', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...value.config.printFields.map((field) => _positionRow(value, field)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: value.save,
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size.fromHeight(50)),
                            child: Text(value.editData ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white)),
                          ),
                          if (value.editData && value.canDelete) ...[
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: value.selected == null ? null : () => value.confirmDelete(value.selected!),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(50)),
                              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF7F9FC),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Preview Layout Print', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Geser field di area preview, atau isi koordinat X/Y dalam mm di panel kiri.',
                              style: TextStyle(color: Colors.grey.shade700)),
                          const SizedBox(height: 16),
                          Expanded(child: _PrintPreview(value: value)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(FormatPrintNotifier value, BaseFieldDef field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: value.controllers[field.field],
        onChanged: (_) => value.refreshPreview(),
        readOnly: value.editData && field.field == value.config.keyField,
        maxLength: field.maxLength,
        keyboardType: field.numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: field.numeric ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
        validator: (text) {
          final raw = (text ?? '').trim();
          if (field.required && raw.isEmpty) return 'Wajib diisi';
          if (field.maxLength != null && raw.length > field.maxLength!) return 'Maksimal ${field.maxLength} karakter';
          return null;
        },
        decoration: _decoration(field.label).copyWith(hintText: field.hint.isEmpty ? null : field.hint, counterText: ''),
      ),
    );
  }

  Widget _positionRow(FormatPrintNotifier value, PrintFieldDef field) {
    final visible = value.fieldVisible[field.key] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Checkbox(value: visible, onChanged: (v) => value.toggleField(field, v), activeColor: colorPrimary),
          Expanded(child: Text(field.isQrCode ? '${field.label} (1 × 1 cm)' : field.label, style: const TextStyle(fontWeight: FontWeight.w600))),
          SizedBox(
            width: 84,
            child: TextFormField(
              controller: value.controllers[field.xField],
              enabled: visible,
              validator: (text) {
                if (!visible || !field.isQrCode) return null;
                final position = double.tryParse(text ?? '');
                final maximum = value.config.paperWidthMm - field.widthMm;
                if (position == null || position < 0 || position > maximum) {
                  return '0–${maximum.toInt()} mm';
                }
                return null;
              },
              onChanged: (_) => value.refreshPreview(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: _decoration('X'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: TextFormField(
              controller: value.controllers[field.yField],
              enabled: visible,
              validator: (text) {
                if (!visible || !field.isQrCode) return null;
                final position = double.tryParse(text ?? '');
                final maximum = value.config.paperHeightMm - field.heightMm;
                if (position == null || position < 0 || position > maximum) {
                  return '0–${maximum.toInt()} mm';
                }
                return null;
              },
              onChanged: (_) => value.refreshPreview(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: _decoration('Y'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintPreview extends StatelessWidget {
  final FormatPrintNotifier value;
  const _PrintPreview({required this.value});
  @override
  Widget build(BuildContext context) => FormatLayoutPreview(
        config: value.config,
        data: {
          'font_size': value.controllers['font_size']?.text,
          if (value.config.hasVisibilityFlags) ...{
            'font_size_flag': value.fontSizeVisible,
            'qr_code_size': 10,
          },
          for (final field in value.config.printFields) ...{
            if (value.config.hasVisibilityFlags) '${field.key}_flag': value.fieldVisible[field.key] ?? true,
            field.xField: (value.fieldVisible[field.key] ?? true) ? value.controllers[field.xField]?.text : null,
            field.yField: (value.fieldVisible[field.key] ?? true) ? value.controllers[field.yField]?.text : null,
          },
        },
        onMove: value.updateFieldPosition,
      );
}

class FormatLayoutPreview extends StatelessWidget {
  final FormatPrintConfig config;
  final Map<String, dynamic> data;
  final void Function(PrintFieldDef, double, double)? onMove;

  const FormatLayoutPreview({super.key, required this.config, required this.data, this.onMove});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 24 || constraints.maxHeight <= 24) return const SizedBox.shrink();
        final qrSize = PrintValue.toDouble(data['qr_code_size'], 10);
        final qrSizeMm = qrSize.isFinite && qrSize > 0 ? qrSize : 10.0;
        final useFontSize = !config.hasVisibilityFlags || _printFlag(data['font_size_flag'], fallback: true);
        final previewFontSize = useFontSize ? PrintValue.toDouble(data['font_size'], 10) : 10.0;
        final scaleX = (constraints.maxWidth - 24) / config.paperWidthMm;
        final scaleY = (constraints.maxHeight - 24) / config.paperHeightMm;
        final scale = scaleX < scaleY ? scaleX : scaleY;
        final width = config.paperWidthMm * scale;
        final height = config.paperHeightMm * scale;
        return Center(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black54),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 8))],
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _GridPainter(scale: scale))),
                ...config.printFields.where((field) => _fieldIsVisible(config, field, data)).map((field) {
                  final x = double.tryParse((data[field.xField] ?? '').toString()) ?? field.defaultX;
                  final y = double.tryParse((data[field.yField] ?? '').toString()) ?? field.defaultY;
                  return Positioned(
                    left: x * scale,
                    top: y * scale,
                    child: GestureDetector(
                      onPanUpdate: onMove == null
                          ? null
                          : (detail) {
                              onMove!(field, x + detail.delta.dx / scale, y + detail.delta.dy / scale);
                            },
                      child: field.isQrCode
                          ? Tooltip(
                              message: 'QR Code · $qrSizeMm × $qrSizeMm mm (penanda layout)',
                              child: Container(
                                width: qrSizeMm * scale,
                                height: qrSizeMm * scale,
                                color: Colors.white,
                                child: Icon(Icons.qr_code, size: qrSizeMm * scale, color: Colors.black),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                  color: colorPrimary.withOpacity(0.12),
                                  border: Border.all(color: colorPrimary),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(field.label,
                                  style: TextStyle(
                                      fontSize: previewFontSize.clamp(8, 18),
                                      fontWeight: FontWeight.w600)),
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double scale;

  const _GridPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.16)
      ..strokeWidth = 1;
    final step = 10 * scale;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.scale != scale;
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999), border: Border.all(color: color)),
      child: Text(PrintValue.statusText(code), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

InputDecoration _decoration(String label) =>
    InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), counterText: '');
