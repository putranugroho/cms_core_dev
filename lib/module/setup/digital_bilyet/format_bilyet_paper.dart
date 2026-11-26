// lib/module/format_bilyet/format_bilyet_paper.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'format_bilyet_model.dart';

const Color _kFieldBlue = Color(0xff1E88E5);

/// 1 pt = 1/72 inch = 25.4/72 mm.
const double _mmPerPt = 25.4 / 72;

/// Ukuran QR di preview (mm). Hanya penanda lokasi, ukuran aslinya ditentukan saat cetak.
const double _qrPreviewMm = 18;

/// Angka mm/pt untuk tampilan: maksimal 1 desimal, tanpa ".0".
String formatMm(double v) {
  final r = (v * 10).round() / 10;
  return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
}

/// Kertas bilyet yang digambar sesuai skala: ukuran kertas (mm), posisi field (mm), dan
/// font (pt) memakai satu skala px/mm yang sama, jadi proporsinya sama dengan hasil cetak.
///
/// Dipakai di form (bisa digeser lewat [onDrag]/[onDragEnd]) dan di halaman ringkasan
/// (read-only, tanpa callback).
class FormatBilyetPaper extends StatelessWidget {
  final double lebarMm;
  final double tinggiMm;
  final double fontPt;
  final List<FormatBilyetField> fields;

  /// Gambar latar kertas (bg_bilyet), digambar di bawah semua field (lihat [backgroundFit]).
  final Uint8List? background;

  /// Kepekatan [background] 0.0-1.0 (dari bg_opacity 0-100).
  final double backgroundOpacity;

  /// Cara gambar latar ditempatkan: [BoxFit.fill] = sama dengan hasil cetak (direntangkan),
  /// [BoxFit.contain] = gambar utuh dengan rasio asli.
  final BoxFit backgroundFit;

  /// Key field yang sedang digeser (ditandai lebih tebal).
  final String? highlightKey;
  final void Function(String key, Offset deltaPx, double pxPerMm)? onDrag;
  final void Function(String key)? onDragEnd;

  const FormatBilyetPaper({
    super.key,
    required this.lebarMm,
    required this.tinggiMm,
    required this.fontPt,
    required this.fields,
    this.background,
    this.backgroundOpacity = 1,
    this.backgroundFit = BoxFit.fill,
    this.highlightKey,
    this.onDrag,
    this.onDragEnd,
  });

  bool get _interaktif => onDrag != null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final pxPerMm = math.min(c.maxWidth / lebarMm, c.maxHeight / tinggiMm);
      final fontPx = fontPt * _mmPerPt * pxPerMm;

      return Center(
        child: Container(
          width: lebarMm * pxPerMm,
          height: tinggiMm * pxPerMm,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          // Border di foreground supaya tidak memakan area dalam: (0,0) mm tepat di pojok kertas.
          foregroundDecoration: BoxDecoration(border: Border.all(color: const Color(0xffBDBDBD))),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // [backgroundFit]:
              //  - BoxFit.fill    = HASIL CETAK: aplikasi pencetak merentangkan gambar memenuhi
              //                     kertas, jadi gambar tertarik kalau rasionya beda dengan kertas.
              //  - BoxFit.contain = tampilan bantu: gambar utuh dengan rasio asli, di tengah.
              if (background != null && backgroundOpacity > 0)
                Positioned.fill(
                  // Opacity di atas kertas putih = gambar memudar ke putih, sama seperti hasil cetak.
                  child: Opacity(
                    opacity: backgroundOpacity.clamp(0.0, 1.0),
                    child: Image.memory(
                      background!,
                      fit: backgroundFit,
                      alignment: Alignment.center,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              Positioned.fill(child: CustomPaint(painter: _GridPainter(pxPerMm))),
              for (final f in fields)
                if (f.aktif) _buildField(f, pxPerMm, fontPx),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildField(FormatBilyetField f, double pxPerMm, double fontPx) {
    final highlight = highlightKey == f.key;
    Widget child = f.isQr
        ? SizedBox.square(
            dimension: _qrPreviewMm * pxPerMm,
            child: FittedBox(child: Icon(Icons.qr_code_2, color: highlight ? _kFieldBlue : Colors.black87)),
          )
        : Container(
            color: _kFieldBlue.withValues(alpha: highlight ? 0.25 : 0.10),
            // foregroundDecoration: border digambar di atas teks tanpa menggeser posisinya,
            // jadi pojok kiri-atas teks tetap tepat di koordinat X/Y.
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: _kFieldBlue.withValues(alpha: 0.7), width: 0.8),
            ),
            // Judul / footnote: tampil isi teksnya dengan ukuran font sendiri.
            child: Text(
              f.isTeksBebas && f.teks.isNotEmpty ? f.teks : f.label,
              style: TextStyle(
                fontSize: f.isTeksBebas ? f.fontPt(fontPt) * _mmPerPt * pxPerMm : fontPx,
                fontWeight: f.key == 'judul' ? FontWeight.bold : FontWeight.normal,
                height: 1.0,
                color: Colors.black87,
              ),
            ),
          );

    if (_interaktif) {
      child = MouseRegion(
        cursor: highlight ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: Tooltip(
          message: '${f.label}  X ${formatMm(f.x)} mm, Y ${formatMm(f.y)} mm',
          waitDuration: const Duration(milliseconds: 500),
          child: GestureDetector(
            // Hitung gerakan sejak pointer ditekan (bukan sejak lewat slop) supaya field
            // ikut tepat di bawah kursor.
            dragStartBehavior: DragStartBehavior.down,
            onPanUpdate: (d) => onDrag!(f.key, d.delta, pxPerMm),
            onPanEnd: (_) => onDragEnd?.call(f.key),
            child: child,
          ),
        ),
      );
    }

    return Positioned(left: f.x * pxPerMm, top: f.y * pxPerMm, child: child);
  }
}

/// Garis bantu tiap 10 mm.
class _GridPainter extends CustomPainter {
  final double pxPerMm;
  _GridPainter(this.pxPerMm);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffECEFF1)
      ..strokeWidth = 1;
    final step = 10 * pxPerMm;
    if (step < 4) return;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.pxPerMm != pxPerMm;
}

/// Selisih rasio gambar latar vs kertas yang masih dianggap sebanding (2%). Di atas itu gambar
/// akan terlihat tertarik saat dicetak (direntangkan memenuhi kertas).
const double toleransiRasioLatar = 0.02;

/// true kalau gambar berukuran [gambar] (px) akan tertarik saat direntangkan ke kertas
/// [lebarMm] x [tinggiMm].
bool rasioLatarBeda(Size gambar, double lebarMm, double tinggiMm) {
  if (gambar.width <= 0 || gambar.height <= 0 || lebarMm <= 0 || tinggiMm <= 0) return false;
  final rasioGambar = gambar.width / gambar.height;
  final rasioKertas = lebarMm / tinggiMm;
  return (rasioGambar / rasioKertas - 1).abs() > toleransiRasioLatar;
}

/// Ukuran asli (px) gambar latar, null kalau gagal dibaca.
Future<Size?> ukurGambar(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    frame.image.dispose();
    codec.dispose();
    return size;
  } catch (_) {
    return null;
  }
}
