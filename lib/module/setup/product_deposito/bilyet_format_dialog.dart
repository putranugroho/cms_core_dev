import '../digital_bilyet/format_bilyet_model.dart';
import '../digital_bilyet/format_bilyet_paper.dart';
import 'package:cms_core/models/banking_setup_models.dart';
import 'package:cms_core/module/shared/banking_widgets.dart';
import 'package:cms_core/module/setup/format_print/format_print_pages.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/repository/print_setup_repository.dart';
import 'package:flutter/material.dart';

Future<String?> pickBilyetFormat(BuildContext context) async {
  final row = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => BankingLookupDialog<Map<String, dynamic>>(
      title: 'Pilih Format Bilyet',
      label: (row) => (row['kode_format_bilyet'] ?? '').toString(),
      subtitle: (row) => (row['nama_format_bilyet'] ?? '').toString(),
      load: (keyword, page) async {
        const limit = 30;
        final response = await Setuprepository.fetch(NetworkURL.formatBilyetList(), {
          'kode_format_bilyet': keyword,
          'nama_format_bilyet': keyword,
          'status_data': 'A',
          'page': page,
          'limit': limit,
        });
        if (!PrintSetupRepository.isSuccess(response)) {
          throw Exception(PrintSetupRepository.message(response, 'Gagal memuat format bilyet'));
        }
        final rows = PrintSetupRepository.rows(response).whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)).toList();
        final data = response['data'];
        final total = data is Map ? int.tryParse('${data['total']}') : null;
        return BankingPage<Map<String, dynamic>>(
          items: rows,
          total: total ?? ((page - 1) * limit + rows.length + (rows.length == limit ? 1 : 0)),
          page: page,
          limit: limit,
        );
      },
    ),
  );
  final code = (row?['kode_format_bilyet'] ?? '').toString().trim();
  return code.isEmpty ? null : code;
}

Future<void> showBilyetFormat(BuildContext context, String code) => showDialog<void>(
  context: context,
  builder: (_) => _BilyetPreviewDialog(code: code),
);

class _BilyetPreviewDialog extends StatefulWidget {
  final String code;
  const _BilyetPreviewDialog({required this.code});
  @override
  State<_BilyetPreviewDialog> createState() => _BilyetPreviewDialogState();
}

class _BilyetPreviewDialogState extends State<_BilyetPreviewDialog> {
  late Future<Map<String, dynamic>> _detail;

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await Setuprepository.fetch(NetworkURL.formatBilyetDetail(), {
      'kode_format_bilyet': widget.code,
    });
    if (!PrintSetupRepository.isSuccess(response)) {
      throw Exception(PrintSetupRepository.message(response, 'Gagal memuat detail bilyet'));
    }
    final data = PrintSetupRepository.map(response);
    if (data.isEmpty) throw Exception('Format bilyet tidak ditemukan.');
    return data;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Format Bilyet — ${widget.code}'),
    content: SizedBox(
      width: 900,
      height: MediaQuery.of(context).size.height * 0.65,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${snapshot.error}', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => setState(() => _detail = _load()), child: const Text('Coba Lagi')),
            ]));
          }
          final data = snapshot.data!;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text((data['nama_format_bilyet'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Ukuran kertas: ${data['ukuran_kertas'] ?? '-'}'),
            const SizedBox(height: 8),
            const Text('Preview posisi field sesuai editor Format Bilyet (160 × 95 mm). Baca saja; isi transaksi dan QR ditampilkan sebagai penanda layout.'),
            const SizedBox(height: 12),
            Expanded(child: FormatLayoutPreview(config: FormatPrintConfig.formatBilyet(), data: data)),
          ]);
        },
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
  );
}


Future<void> showDigitalBilyetFormat(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _DigitalBilyetPreviewDialog(),
);

class _DigitalBilyetPreviewDialog extends StatefulWidget {
  const _DigitalBilyetPreviewDialog();
  @override
  State<_DigitalBilyetPreviewDialog> createState() => _DigitalBilyetPreviewDialogState();
}

class _DigitalBilyetPreviewDialogState extends State<_DigitalBilyetPreviewDialog> {
  late Future<FormatBilyetModel> _detail;
  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<FormatBilyetModel> _load() async {
    // Session headers select the BPR. The backend orders legacy duplicates
    // newest first, exactly as the Digital Bilyet setup editor does.
    final response = await Setuprepository.fetch('$url/setup/format-bilyet-digital/list', {});
    if (response is! Map || response['code']?.toString() != '000') {
      throw Exception(response is Map ? response['message'] ?? 'Gagal memuat format bilyet digital' : 'Respons format bilyet digital tidak valid');
    }
    final rows = response['data'];
    if (rows is! List) throw Exception('Respons format bilyet digital tidak valid');
    if (rows.isEmpty) throw Exception('Format Bilyet Digital untuk BPR ini belum dibuat. Buat dahulu melalui Setup > Format Bilyet > Format Bilyet Digital.');
    if (rows.first is! Map) throw Exception('Data format bilyet digital tidak valid');
    final format = FormatBilyetModel.fromJson(Map<String, dynamic>.from(rows.first as Map));
    if (!format.lebarKertas.isFinite || !format.tinggiKertas.isFinite || format.lebarKertas <= 0 || format.tinggiKertas <= 0) {
      throw Exception('Ukuran kertas format bilyet digital tidak valid. Periksa konfigurasi format.');
    }
    return format;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Format Bilyet Digital'),
    content: SizedBox(
      width: 900,
      height: MediaQuery.of(context).size.height * 0.65,
      child: FutureBuilder<FormatBilyetModel>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${snapshot.error}', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => setState(() => _detail = _load()), child: const Text('Coba Lagi')),
            ]));
          }
          final f = snapshot.data!;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${f.kodeFormat} — ${f.namaFormat}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Ukuran kertas: ${f.lebarKertas} × ${f.tinggiKertas} mm'),
            const SizedBox(height: 8),
            const Text('Preview layout digital sesuai pengaturan BPR. Data transaksi dan QR berupa penanda layout.'),
            const SizedBox(height: 12),
            Expanded(child: FormatBilyetPaper(
              lebarMm: f.lebarKertas,
              tinggiMm: f.tinggiKertas,
              fontPt: f.fontSize,
              fields: f.fields,
              background: f.bgBytes,
              backgroundOpacity: f.bgOpacity / 100,
              backgroundFit: BoxFit.fill,
            )),
          ]);
        },
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
  );
}
