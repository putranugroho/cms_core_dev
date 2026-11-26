// lib/module/format_bilyet/format_bilyet_page.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'format_bilyet_model.dart';
import 'format_bilyet_form.dart';
import 'format_bilyet_notifier.dart';
import 'format_bilyet_paper.dart';

// Palet Medfo (dipakai lokal supaya tidak bergantung pada isi colors.dart).
const Color _kPrimary = Color(0xffD52A0B);
const Color _kBg = Color(0xffFFF7F3);
const Color _kBorder = Color(0xffF3E1D9);
const Color _kMuted = Color(0xff6B7280);

/// Satu BPR hanya punya satu format bilyet, jadi halaman ini bukan daftar/tabel:
///  - belum ada format -> ajakan "Buat Format Bilyet"
///  - sudah ada        -> kartu detail (kiri) + preview layout cetak (kanan)
class DigitalBilyetPage extends StatelessWidget {
  const DigitalBilyetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FormatBilyetNotifier(),
      child: Consumer<FormatBilyetNotifier>(
        builder: (context, n, _) => SafeArea(
          child: Scaffold(
            backgroundColor: _kBg,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(n),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildBody(context, n),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FormatBilyetNotifier n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      color: _kPrimary,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Format Bilyet Digital",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: n.isLoading ? null : n.loadData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, FormatBilyetNotifier n) {
    if (n.isLoading && n.format == null) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (n.errorMessage != null) {
      return Align(alignment: Alignment.topCenter, child: _buildErrorBanner(n));
    }

    final format = n.format;
    if (format == null) return _buildEmptyState(context, n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (n.jumlahFormat > 1) ...[
          _buildDuplikatBanner(n.jumlahFormat),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final detail = _buildDetailCard(context, n, format);
            final preview = _buildPreviewCard(n, format, n.bgBytes);
            // Layar sempit: detail di atas, preview di bawah.
            if (c.maxWidth < 900) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  detail,
                  const SizedBox(height: 20),
                  Expanded(child: preview),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 360, child: SingleChildScrollView(child: detail)),
                const SizedBox(width: 20),
                Expanded(child: preview),
              ],
            );
          }),
        ),
      ],
    );
  }

  // Belum ada format

  Widget _buildEmptyState(BuildContext context, FormatBilyetNotifier n) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(36),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(color: Color(0xffFEF2EE), shape: BoxShape.circle),
              child: const Icon(Icons.print_outlined, size: 36, color: _kPrimary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada format bilyet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Atur ukuran kertas, font, dan posisi tiap field yang dicetak di bilyet deposito. '
              'Format ini dipakai Medfo mobile saat mencetak bilyet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _kMuted, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: n.access.create ? () => _bukaForm(context, n) : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Buat Format Bilyet'),
              style: _primaryButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  // Sudah ada format

  Widget _buildDetailCard(BuildContext context, FormatBilyetNotifier n, FormatBilyetModel f) {
    final aktif = f.fields.where((e) => e.aktif).length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xffFEF2EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: _kPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.namaFormat,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(f.kodeFormat, style: const TextStyle(fontSize: 13, color: _kMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 16),
          _infoRow('Ukuran Kertas', f.ukuranLabel),
          _infoRow('Font', '${formatMm(f.fontSize)} pt'),
          _infoRow('Gambar Latar', f.bgBilyet.isEmpty ? 'Tidak ada' : 'Ada, kepekatan ${f.bgOpacity}%'),
          _infoRow('Field dicetak', '$aktif dari ${f.fields.length} field'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: n.isLoading || !n.access.update ? null : () => _bukaForm(context, n, initial: f),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Format'),
            style: _primaryButtonStyle(),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: n.isLoading || !n.access.delete ? null : () => _konfirmasiHapus(context, n, f),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus Format'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xffC94B6E),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: _kMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(FormatBilyetNotifier n, FormatBilyetModel f, Uint8List? bgBytes) {
    final rasioBeda = n.bgSize != null && rasioLatarBeda(n.bgSize!, f.lebarKertas, f.tinggiKertas);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Preview Layout Cetak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Kertas ${formatMm(f.lebarKertas)} x ${formatMm(f.tinggiKertas)} mm  •  '
                      'Font ${formatMm(f.fontSize)} pt  •  Grid 10 mm',
                      style: const TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
              ),
              // Fit = gambar latar utuh; Hasil Cetak = direntangkan seperti aplikasi pencetak.
              if (bgBytes != null)
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: _kPrimary,
                    selectedForegroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(value: false, label: Text('Fit')),
                    ButtonSegment(value: true, label: Text('Hasil Cetak')),
                  ],
                  selected: {n.hasilCetak},
                  onSelectionChanged: (v) => n.setHasilCetak(v.first),
                ),
            ],
          ),
          if (rasioBeda) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xffFFFBEB),
                border: Border.all(color: const Color(0xffFDE68A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xffD97706)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rasio gambar latar tidak sebanding dengan kertas, gambar akan tertarik saat dicetak. '
                      'Cek tampilan Hasil Cetak.',
                      style: TextStyle(fontSize: 12, color: Color(0xff92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xffF7F8FC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FormatBilyetPaper(
                lebarMm: f.lebarKertas,
                tinggiMm: f.tinggiKertas,
                fontPt: f.fontSize,
                fields: f.fields,
                background: bgBytes,
                backgroundOpacity: f.bgOpacity / 100,
                backgroundFit: n.hasilCetak ? BoxFit.fill : BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Banner

  Widget _buildDuplikatBanner(int jumlah) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffFFFBEB),
        border: Border.all(color: const Color(0xffFDE68A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xffD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ada $jumlah format tersimpan dari data lama. Yang dipakai adalah format yang '
              'terakhir diedit (ditampilkan di bawah).',
              style: const TextStyle(fontSize: 13, color: Color(0xff92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(FormatBilyetNotifier n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffFEF2F2),
        border: Border.all(color: const Color(0xffFECACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xffDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              n.errorMessage!,
              style: const TextStyle(fontSize: 13, color: Color(0xff991B1B)),
            ),
          ),
          TextButton(onPressed: n.loadData, child: const Text('Coba lagi')),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      );

  ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

  Future<void> _bukaForm(BuildContext context, FormatBilyetNotifier n,
      {FormatBilyetModel? initial}) async {
    if (n.isLoading) return;
    final ok = await showFormatBilyetForm(context, initial: initial, onSimpan: n.simpan);
    if (ok == true && context.mounted) {
      _showSuccessDialog(
        context,
        initial == null ? 'Format bilyet berhasil disimpan' : 'Format bilyet berhasil diperbarui',
      );
    }
  }

  Future<void> _konfirmasiHapus(
      BuildContext context, FormatBilyetNotifier n, FormatBilyetModel data) async {
    if (n.isLoading) return; // cegah double-tap saat proses berjalan
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Format Bilyet"),
        content: Text("Hapus format ${data.kodeFormat} - ${data.namaFormat}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Color(0xffC94B6E))),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final err = await n.hapus(data);
    if (!context.mounted) return;
    if (err == null) {
      _showSuccessDialog(context, 'Format bilyet ${data.kodeFormat} dihapus');
    } else {
      _showErrorDialog(context, err);
    }
  }

  // Popup hasil
  // Gaya sama dengan menu lain (Deposito Digital, Jaminan, dll).

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xffD52A0B), Color(0xff1A5D4A)]),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              const Text("BERHASIL!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade50, borderRadius: BorderRadius.circular(50)),
                child: Icon(Icons.close_rounded, color: Colors.red.shade600, size: 32),
              ),
              const SizedBox(height: 20),
              const Text("GAGAL!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
