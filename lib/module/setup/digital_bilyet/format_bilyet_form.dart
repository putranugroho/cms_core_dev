// lib/module/format_bilyet/format_bilyet_form.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'format_bilyet_model.dart';
import 'format_bilyet_paper.dart';

const Color _kPrimary = Color(0xffD52A0B);
const Color _kPreviewBg = Color(0xffF7F8FC);
const Color _kFieldBlue = Color(0xff1E88E5);

/// Buka dialog tambah/edit format bilyet. Return true kalau berhasil disimpan.
Future<bool?> showFormatBilyetForm(
  BuildContext context, {
  FormatBilyetModel? initial,
  required Future<String?> Function(FormatBilyetModel data) onSimpan,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FormatBilyetFormDialog(initial: initial, onSimpan: onSimpan),
  );
}

/// State edit satu field cetak. [x]/[y] (mm) adalah sumber kebenaran; controller
/// hanya tampilan di panel kiri dan disinkronkan dua arah.
class _FieldEdit {
  final FormatBilyetField base;
  bool aktif;
  double x;
  double y;
  final TextEditingController xCtrl;
  final TextEditingController yCtrl;

  /// Judul / footnote saja: isi teks & ukuran font (pt).
  final TextEditingController teksCtrl;
  final TextEditingController fontCtrl;

  _FieldEdit(this.base)
      : aktif = base.aktif || base.wajib,
        x = base.x,
        y = base.y,
        xCtrl = TextEditingController(text: formatMm(base.x)),
        yCtrl = TextEditingController(text: formatMm(base.y)),
        teksCtrl = TextEditingController(text: base.teks),
        fontCtrl = TextEditingController(text: base.fontSize > 0 ? formatMm(base.fontSize) : '');

  FormatBilyetField toField() => base.copyWith(
        aktif: aktif,
        x: x,
        y: y,
        teks: teksCtrl.text.trim(),
        fontSize: _parseNum(fontCtrl.text) ?? 0,
      );

  void dispose() {
    xCtrl.dispose();
    yCtrl.dispose();
    teksCtrl.dispose();
    fontCtrl.dispose();
  }
}

double? _parseNum(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

class _FormatBilyetFormDialog extends StatefulWidget {
  final FormatBilyetModel? initial;
  final Future<String?> Function(FormatBilyetModel data) onSimpan;

  const _FormatBilyetFormDialog({this.initial, required this.onSimpan});

  @override
  State<_FormatBilyetFormDialog> createState() => _FormatBilyetFormDialogState();
}

class _FormatBilyetFormDialogState extends State<_FormatBilyetFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _kode;
  late final TextEditingController _nama;
  late final TextEditingController _lebar;
  late final TextEditingController _tinggi;
  late final TextEditingController _font;
  late String _ukuran;

  /// Gambar latar bilyet: data URI yang disimpan + byte-nya untuk preview.
  String _bgBilyet = '';
  Uint8List? _bgBytes;
  int _bgOpacity = 100;

  /// Ukuran asli gambar latar (px) untuk cek rasio terhadap kertas.
  Size? _bgSize;

  /// false = tampilan Fit (gambar utuh), true = Hasil Cetak (direntangkan memenuhi kertas).
  bool _hasilCetak = false;

  Future<void> _ukurLatar() async {
    final bytes = _bgBytes;
    if (bytes == null) {
      setState(() => _bgSize = null);
      return;
    }
    final size = await ukurGambar(bytes);
    // Abaikan hasil kalau gambarnya sudah diganti/dihapus selama pengukuran.
    if (mounted && identical(bytes, _bgBytes)) setState(() => _bgSize = size);
  }
  late final List<_FieldEdit> _fields;

  bool _isSaving = false;
  _FieldEdit? _dragging;

  bool get _isEdit => (widget.initial?.id ?? 0) != 0;

  @override
  void initState() {
    super.initState();
    final m = widget.initial ?? const FormatBilyetModel();
    _kode = TextEditingController(text: m.kodeFormat);
    _nama = TextEditingController(text: m.namaFormat);
    _lebar = TextEditingController(text: formatMm(m.lebarKertas));
    _tinggi = TextEditingController(text: formatMm(m.tinggiKertas));
    _font = TextEditingController(text: formatMm(m.fontSize));
    _ukuran = UkuranKertasPreset.byNama(m.ukuranKertas)?.nama ?? UkuranKertasPreset.kustom;
    _fields = m.fields.map(_FieldEdit.new).toList();
    _bgBilyet = m.bgBilyet;
    _bgBytes = m.bgBytes;
    _bgOpacity = m.bgOpacity;
    if (_bgBytes != null) WidgetsBinding.instance.addPostFrameCallback((_) => _ukurLatar());
  }

  @override
  void dispose() {
    for (final c in [_kode, _nama, _lebar, _tinggi, _font]) {
      c.dispose();
    }
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  double get _lebarMm => _parseNum(_lebar.text) ?? 0;
  double get _tinggiMm => _parseNum(_tinggi.text) ?? 0;
  double get _fontPt => _parseNum(_font.text) ?? 0;

  void _pilihUkuran(String? nama) {
    if (nama == null) return;
    setState(() {
      _ukuran = nama;
      final preset = UkuranKertasPreset.byNama(nama);
      if (preset != null) {
        _lebar.text = formatMm(preset.lebar);
        _tinggi.text = formatMm(preset.tinggi);
      }
    });
  }

  // Drag di preview

  void _onDrag(_FieldEdit f, Offset deltaPx, double pxPerMm) {
    setState(() {
      _dragging = f;
      f.x = (f.x + deltaPx.dx / pxPerMm).clamp(0, _lebarMm).toDouble();
      f.y = (f.y + deltaPx.dy / pxPerMm).clamp(0, _tinggiMm).toDouble();
      f.xCtrl.text = formatMm(f.x);
      f.yCtrl.text = formatMm(f.y);
    });
  }

  void _onDragEnd(_FieldEdit f) {
    setState(() {
      // Snap ke 0.5 mm supaya angka di panel kiri rapi.
      f.x = (f.x * 2).round() / 2;
      f.y = (f.y * 2).round() / 2;
      f.xCtrl.text = formatMm(f.x);
      f.yCtrl.text = formatMm(f.y);
      _dragging = null;
    });
  }

  // Simpan

  Future<void> _simpan() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = FormatBilyetModel(
      id: widget.initial?.id ?? 0,
      kodeFormat: _kode.text.trim().toUpperCase(),
      namaFormat: _nama.text.trim(),
      // Merk kertas tidak lagi diisi dari form; nilai lama (kalau ada) dibiarkan.
      merkKertas: widget.initial?.merkKertas ?? '',
      ukuranKertas: _ukuran,
      lebarKertas: _lebarMm,
      tinggiKertas: _tinggiMm,
      fontSize: _fontPt,
      fields: _fields.map((f) => f.toField()).toList(),
      bgBilyet: _bgBilyet,
      bgOpacity: _bgOpacity,
    );

    setState(() => _isSaving = true);
    final err = await widget.onSimpan(data);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (err == null) {
      Navigator.pop(context, true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Gagal Menyimpan'),
        content: Text(err),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  // UI

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.expand(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 460, child: _buildFormPanel()),
            Expanded(child: _buildPreviewPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Format Bilyet Deposito' : 'Tambah Format Bilyet Deposito',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: _isSaving ? null : () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              children: [
                _textField(
                  _kode,
                  'Kode Format Bilyet',
                  required: true,
                  maxLength: 50,
                  formatters: [_UpperCaseFormatter()],
                ),
                _textField(_nama, 'Nama Format Bilyet', required: true, maxLength: 200),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DropdownButtonFormField<String>(
                    value: _ukuran,
                    isExpanded: true,
                    decoration: _decoration('Ukuran Kertas'),
                    items: [
                      for (final p in UkuranKertasPreset.list)
                        DropdownMenuItem(
                          value: p.nama,
                          child: Text(
                            '${p.nama}  (${formatMm(p.lebar)} x ${formatMm(p.tinggi)} mm)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const DropdownMenuItem(
                        value: UkuranKertasPreset.kustom,
                        child: Text('Kustom (isi lebar & tinggi)', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: _pilihUkuran,
                  ),
                ),
                // Lebar & tinggi hanya diisi manual untuk ukuran Kustom; preset sudah
                // menentukan ukurannya sendiri.
                if (_ukuran == UkuranKertasPreset.kustom)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ukuranField(_lebar, 'Lebar (mm)')),
                      const SizedBox(width: 12),
                      Expanded(child: _ukuranField(_tinggi, 'Tinggi (mm)')),
                    ],
                  ),
                _textField(
                  _font,
                  'Font Size (pt)',
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = _parseNum(v ?? '');
                    if (n == null || n < 4 || n > 72) return 'Font size 4 - 72 pt';
                    return null;
                  },
                ),
                // Judul & footnote: teks bebas dengan ukuran font sendiri.
                for (final f in _fields)
                  if (f.base.isTeksBebas) _buildTeksBebas(f),
                _buildBackgroundPicker(),
                const SizedBox(height: 8),
                const Text('Field Print', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'Posisi X/Y dalam mm dari pojok kiri-atas kertas.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                for (final f in _fields) _buildFieldRow(f),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Isian yang bisa diisi berlatar putih; yang read-only/nonaktif transparan.
  // GAMBAR LATAR (bg_bilyet)

  static const int _maxBgBytes = 2 * 1024 * 1024; // sama dengan batas di web service

  Future<void> _pilihBackground() async {
    final XFile? file;
    try {
      // Dibatasi ~3000 px supaya tetap tajam saat dicetak tapi ukurannya tidak berlebihan.
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 85,
      );
    } catch (e) {
      _showPesan('Gagal memilih gambar: $e');
      return;
    }
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final mime = _mimeGambar(bytes);
    if (mime == null) {
      _showPesan('Format gambar harus PNG, JPG, atau WEBP.');
      return;
    }
    if (bytes.length > _maxBgBytes) {
      _showPesan('Ukuran gambar maksimal 2 MB (sekarang ${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB).');
      return;
    }
    setState(() {
      _bgBytes = bytes;
      _bgBilyet = 'data:$mime;base64,${base64Encode(bytes)}';
      _bgSize = null;
    });
    _ukurLatar();
  }

  /// Tipe gambar dari byte awal file (tidak bergantung ekstensi/nama file).
  static String? _mimeGambar(Uint8List b) {
    bool awal(List<int> sig, [int offset = 0]) =>
        b.length >= offset + sig.length && List.generate(sig.length, (i) => b[offset + i]).join(',') == sig.join(',');
    if (awal([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (awal([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (awal([0x52, 0x49, 0x46, 0x46]) && awal([0x57, 0x45, 0x42, 0x50], 8)) return 'image/webp';
    return null;
  }

  void _showPesan(String pesan) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Gambar Latar'),
        content: Text(pesan),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  Widget _buildBackgroundPicker() {
    final ada = _bgBytes != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffBDBDBD)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xffF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xffE5E7EB)),
                ),
                child: ada
                    ? Image.memory(_bgBytes!, fit: BoxFit.cover, gaplessPlayback: true)
                    : const Icon(Icons.image_outlined, color: Colors.black38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gambar Latar Bilyet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      ada
                          ? '${(_bgBytes!.length / 1024).toStringAsFixed(0)} KB • di-fit ke kertas, rasio tetap'
                          : 'Opsional. PNG/JPG/WEBP maks 2 MB, di-fit ke kertas tanpa gepeng',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isSaving ? null : _pilihBackground,
                child: Text(ada ? 'Ganti' : 'Pilih'),
              ),
              if (ada)
                IconButton(
                  tooltip: 'Hapus gambar latar',
                  onPressed: _isSaving
                      ? null
                      : () => setState(() {
                            _bgBytes = null;
                            _bgBilyet = '';
                            _bgSize = null;
                            _hasilCetak = false;
                          }),
                  icon: const Icon(Icons.delete_outline, color: Color(0xffC94B6E)),
                ),
            ],
          ),
          // Kepekatan latar (bg_opacity): makin kecil makin pudar, seperti watermark.
          if (ada) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 4),
                const Text('Kepekatan', style: TextStyle(fontSize: 13, color: Colors.black54)),
                Expanded(
                  child: Slider(
                    value: _bgOpacity.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$_bgOpacity%',
                    activeColor: _kPrimary,
                    onChanged: _isSaving ? null : (v) => setState(() => _bgOpacity = v.round()),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('$_bgOpacity%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, {bool editable = true}) => InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: editable ? Colors.white : Colors.transparent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      );

  Widget _textField(
    TextEditingController c,
    String label, {
    bool required = false,
    int? maxLength,
    List<TextInputFormatter>? formatters,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLength: maxLength,
        inputFormatters: formatters,
        onChanged: onChanged,
        decoration: _decoration(label),
        validator: validator ?? (required ? (v) => (v ?? '').trim().isEmpty ? '$label wajib diisi' : null : null),
      ),
    );
  }

  Widget _ukuranField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        onChanged: (_) => setState(() {}),
        decoration: _decoration(label),
        validator: (v) {
          final n = _parseNum(v ?? '');
          if (n == null || n <= 0 || n > 1000) return '1 - 1000 mm';
          return null;
        },
      ),
    );
  }

  /// Isian judul / footnote: teks + ukuran font (pt). Judul wajib diisi (selalu dicetak);
  /// footnote diisi = otomatis aktif, dikosongkan = nonaktif. Posisinya diatur seperti field
  /// lain (X/Y atau geser di preview).
  Widget _buildTeksBebas(_FieldEdit f) {
    final wajib = f.base.wajib;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: f.teksCtrl,
              maxLength: 200,
              decoration: _decoration(wajib ? '${f.base.label} *' : f.base.label).copyWith(counterText: ''),
              onChanged: (v) => setState(() => f.aktif = wajib || v.trim().isNotEmpty),
              validator: (v) => wajib && (v ?? '').trim().isEmpty ? '${f.base.label} wajib diisi' : null,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: TextFormField(
              controller: f.fontCtrl,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: _decoration('Ukuran (pt)'),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (f.teksCtrl.text.trim().isEmpty) return null;
                final n = _parseNum(v ?? '');
                if (n == null || n < 4 || n > 72) return '4 - 72 pt';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(_FieldEdit f) {
    final active = _dragging == f;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xffE3F2FD) : Colors.white,
        border: Border.all(color: active ? _kFieldBlue : const Color(0xffE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Tooltip(
            message: f.base.wajib
                ? 'Wajib dicetak, tidak bisa dinonaktifkan'
                : f.base.isTeksBebas
                    ? 'Aktif otomatis kalau ${f.base.label.toLowerCase()} diisi'
                    : '',
            child: Checkbox(
              value: f.aktif,
              activeColor: _kFieldBlue,
              // QR Code wajib: selalu aktif. Judul/footnote: ikut isi teksnya. Checkbox terkunci.
              onChanged: f.base.wajib || f.base.isTeksBebas ? null : (v) => setState(() => f.aktif = v ?? false),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    f.base.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: f.aktif ? Colors.black87 : Colors.black38,
                    ),
                  ),
                ),
                if (f.base.wajib) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Wajib',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 78, child: _coordField(f, isX: true)),
          const SizedBox(width: 8),
          SizedBox(width: 78, child: _coordField(f, isX: false)),
        ],
      ),
    );
  }

  Widget _coordField(_FieldEdit f, {required bool isX}) {
    return TextFormField(
      controller: isX ? f.xCtrl : f.yCtrl,
      enabled: f.aktif,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: isX ? 'X' : 'Y',
        isDense: true,
        filled: true,
        fillColor: f.aktif ? Colors.white : Colors.transparent,
        errorStyle: const TextStyle(height: 0.8, fontSize: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      onChanged: (v) {
        final n = _parseNum(v);
        if (n == null) return;
        setState(() => isX ? f.x = n : f.y = n);
      },
      validator: (v) {
        if (!f.aktif) return null;
        final n = _parseNum(v ?? '');
        final max = isX ? _lebarMm : _tinggiMm;
        if (n == null || n < 0 || n > max) return '0-${formatMm(max)}';
        return null;
      },
    );
  }

  // Preview

  Widget _buildPreviewPanel() {
    final lebar = _lebarMm;
    final tinggi = _tinggiMm;
    final font = _fontPt;
    final valid = lebar > 0 && tinggi > 0 && lebar <= 1000 && tinggi <= 1000 && font > 0;

    return Container(
      color: _kPreviewBg,
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preview Layout Print', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
            'Geser field di area preview, atau isi koordinat X/Y dalam mm di panel kiri.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          if (_bgBytes != null) ...[
            const SizedBox(height: 14),
            _buildPilihanTampilan(),
            if (valid && _bgSize != null && rasioLatarBeda(_bgSize!, lebar, tinggi)) ...[
              const SizedBox(height: 10),
              _buildPeringatanRasio(lebar, tinggi),
            ],
          ],
          const SizedBox(height: 20),
          Expanded(
            child: valid
                ? _buildPaper(lebar, tinggi, font)
                : const Center(
                    child: Text('Isi ukuran kertas & font size yang valid untuk melihat preview'),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            valid ? _previewCaption(lebar, tinggi, font) : '',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// Dua tampilan gambar latar: Fit (gambar utuh, rasio asli) dan Hasil Cetak (direntangkan
  /// memenuhi kertas, sama seperti aplikasi pencetak).
  Widget _buildPilihanTampilan() {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: _kPrimary,
        selectedForegroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
      ),
      segments: const [
        ButtonSegment(value: false, icon: Icon(Icons.fit_screen_outlined, size: 18), label: Text('Fit (gambar utuh)')),
        ButtonSegment(value: true, icon: Icon(Icons.print_outlined, size: 18), label: Text('Hasil Cetak')),
      ],
      selected: {_hasilCetak},
      onSelectionChanged: (v) => setState(() => _hasilCetak = v.first),
    );
  }

  Widget _buildPeringatanRasio(double lebar, double tinggi) {
    final g = _bgSize!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              'Rasio gambar (${g.width.round()} x ${g.height.round()} px = ${_rasio(g.width / g.height)}) '
              'tidak sebanding dengan kertas (${formatMm(lebar)} x ${formatMm(tinggi)} mm = ${_rasio(lebar / tinggi)}). '
              'Saat dicetak gambar akan tertarik. Cek tampilan Hasil Cetak.',
              style: const TextStyle(fontSize: 12, color: Color(0xff92400E)),
            ),
          ),
          if (!_hasilCetak)
            TextButton(
              onPressed: () => setState(() => _hasilCetak = true),
              child: const Text('Lihat hasil cetak'),
            ),
        ],
      ),
    );
  }

  static String _rasio(double r) => r.toStringAsFixed(2).replaceAll('.', ',');

  String _previewCaption(double lebar, double tinggi, double font) {
    final base = 'Kertas ${formatMm(lebar)} x ${formatMm(tinggi)} mm  •  Font ${formatMm(font)} pt  •  Grid 10 mm';
    final d = _dragging;
    if (d == null) return base;
    return '$base  •  ${d.base.label}: X ${formatMm(d.x)} mm, Y ${formatMm(d.y)} mm';
  }

  Widget _buildPaper(double lebar, double tinggi, double font) {
    return FormatBilyetPaper(
      lebarMm: lebar,
      tinggiMm: tinggi,
      fontPt: font,
      fields: [for (final f in _fields) f.toField()],
      background: _bgBytes,
      backgroundOpacity: _bgOpacity / 100,
      backgroundFit: _hasilCetak ? BoxFit.fill : BoxFit.contain,
      highlightKey: _dragging?.base.key,
      onDrag: (key, delta, pxPerMm) => _onDrag(_fieldByKey(key), delta, pxPerMm),
      onDragEnd: (key) => _onDragEnd(_fieldByKey(key)),
    );
  }

  _FieldEdit _fieldByKey(String key) => _fields.firstWhere((f) => f.base.key == key);
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
