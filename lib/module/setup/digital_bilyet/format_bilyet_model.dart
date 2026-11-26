// lib/models/format_bilyet_model.dart
import 'dart:convert';
import 'dart:typed_data';

/// Satu field cetak bilyet. [x]/[y] dalam mm dari pojok kiri-atas kertas.
class FormatBilyetField {
  final String key;
  final String label;
  final bool aktif;
  final double x;
  final double y;

  /// Judul / footnote: teks yang dicetak apa adanya (diisi di form, bukan dari data deposito).
  final String teks;

  /// Judul / footnote: ukuran font sendiri (pt), 0 = ikut font size format.
  final double fontSize;

  const FormatBilyetField({
    required this.key,
    required this.label,
    this.aktif = true,
    this.x = 0,
    this.y = 0,
    this.teks = '',
    this.fontSize = 0,
  });

  /// Field yang digambar sebagai gambar (bukan teks) di preview.
  bool get isQr => key == 'qr_code';

  /// Field yang wajib dicetak di setiap bilyet: tidak bisa dinonaktifkan.
  static const Set<String> keyWajib = {'qr_code', 'judul'};

  bool get wajib => keyWajib.contains(key);

  /// Field teks bebas (judul & footnote): isi dan ukuran font diatur sendiri.
  static const Set<String> keyTeksBebas = {'judul', 'footnote'};

  bool get isTeksBebas => keyTeksBebas.contains(key);

  /// Ukuran font yang dipakai saat dicetak: milik field sendiri, atau font size format.
  double fontPt(double fontFormat) => isTeksBebas && fontSize > 0 ? fontSize : fontFormat;

  factory FormatBilyetField.fromJson(Map<String, dynamic> json) {
    return FormatBilyetField(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      aktif: json['aktif'] == true,
      x: _toDouble(json['x']),
      y: _toDouble(json['y']),
      teks: (json['teks'] ?? '').toString(),
      fontSize: _toDouble(json['font_size']),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'aktif': aktif,
        'x': x,
        'y': y,
        if (isTeksBebas) 'teks': teks,
        if (isTeksBebas) 'font_size': fontSize,
      };

  FormatBilyetField copyWith({bool? aktif, double? x, double? y, String? teks, double? fontSize}) {
    return FormatBilyetField(
      key: key,
      label: label,
      aktif: wajib || (aktif ?? this.aktif), // field wajib selalu aktif
      x: x ?? this.x,
      y: y ?? this.y,
      teks: teks ?? this.teks,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

/// Ukuran kertas siap pakai (mm). "Kustom" = isi lebar/tinggi sendiri.
class UkuranKertasPreset {
  final String nama;
  final double lebar;
  final double tinggi;
  const UkuranKertasPreset(this.nama, this.lebar, this.tinggi);

  static const String kustom = 'Kustom';

  static const List<UkuranKertasPreset> list = [
    UkuranKertasPreset('A4', 210, 297),
    UkuranKertasPreset('A4 Landscape', 297, 210),
    UkuranKertasPreset('A5', 148, 210),
    UkuranKertasPreset('A5 Landscape', 210, 148),
    UkuranKertasPreset('F4', 215, 330),
    UkuranKertasPreset('Letter', 216, 279),
  ];

  static UkuranKertasPreset? byNama(String nama) {
    for (final p in list) {
      if (p.nama == nama) return p;
    }
    return null;
  }
}

class FormatBilyetModel {
  final int id;
  final String kodeFormat;
  final String namaFormat;
  final String merkKertas;
  final String ukuranKertas;
  final double lebarKertas;
  final double tinggiKertas;
  final double fontSize;
  final List<FormatBilyetField> fields;

  /// Gambar latar kertas (data URI base64, mis. "data:image/png;base64,..."), '' = tanpa latar.
  /// Saat dicetak, gambar direntangkan memenuhi seluruh kertas (BoxFit.fill) di bawah semua field,
  /// jadi gambar tertarik kalau rasionya beda dengan kertas. Preview CMS punya tampilan "Fit"
  /// (gambar utuh) dan "Hasil Cetak" (direntangkan).
  final String bgBilyet;

  /// Kepekatan gambar latar 0-100 (100 = asli, makin kecil makin pudar seperti watermark).
  final int bgOpacity;

  const FormatBilyetModel({
    this.id = 0,
    this.kodeFormat = '',
    this.namaFormat = '',
    this.merkKertas = '',
    this.ukuranKertas = UkuranKertasPreset.kustom,
    this.lebarKertas = 160,
    this.tinggiKertas = 95,
    this.fontSize = 10,
    this.fields = defaultFields,
    this.bgBilyet = '',
    this.bgOpacity = 100,
  });

  /// Daftar field cetak bilyet beserta posisi awalnya (mm).
  ///
  /// Hanya field yang datanya memang bisa diisi Medfo mobile saat mencetak deposito digital.
  /// Nama AO, Alamat Nasabah, Cara Bayar Bunga, dan Nama Kantor sengaja tidak ada: datanya tidak
  /// tersedia saat cetak (atau selalu sama), dan field tanpa data berbahaya karena tercetak
  /// kosong. Field yang dihapus dari daftar ini otomatis hilang dari format lama saat format
  /// diedit & disimpan. QR Code wajib (lihat [FormatBilyetField.keyWajib]). Materai tidak ada di
  /// sini: e-meterai dibubuhkan langsung ke PDF di portal e-meterai, bukan dicetak dari data.
  static const List<FormatBilyetField> defaultFields = [
    // Teks bebas (lihat [FormatBilyetField.keyTeksBebas]). Judul wajib diisi; footnote aktif kalau diisi.
    FormatBilyetField(key: 'judul', label: 'Judul', x: 10, y: 2, fontSize: 14),
    FormatBilyetField(key: 'nomor_bilyet', label: 'Nomor Bilyet', x: 10, y: 10),
    FormatBilyetField(key: 'nomor_deposito', label: 'Nomor Deposito', x: 10, y: 20),
    FormatBilyetField(key: 'nama_nasabah', label: 'Nama Nasabah', x: 10, y: 30),
    FormatBilyetField(key: 'nomor_cif', label: 'Nomor CIF', x: 10, y: 40),
    FormatBilyetField(key: 'nominal_deposito', label: 'Nominal Deposito', x: 10, y: 50),
    FormatBilyetField(key: 'terbilang', label: 'Terbilang', x: 10, y: 60),
    FormatBilyetField(key: 'rate_bunga', label: 'Rate Bunga', x: 10, y: 70),
    FormatBilyetField(key: 'tanggal_valuta', label: 'Tanggal Valuta', x: 90, y: 10),
    FormatBilyetField(key: 'tanggal_jatuh_tempo', label: 'Tanggal Jatuh Tempo', x: 90, y: 20),
    FormatBilyetField(key: 'nama_produk', label: 'Nama Produk', x: 90, y: 30),
    // Tanda tangan = garis tanda tangan; boleh dinonaktifkan kalau tidak dipakai.
    FormatBilyetField(key: 'tanda_tangan', label: 'Tanda Tangan', x: 90, y: 75),
    FormatBilyetField(key: 'logo', label: 'Logo', x: 125, y: 10),
    // Wajib (selalu aktif).
    FormatBilyetField(key: 'qr_code', label: 'QR Code', x: 140, y: 75),
    FormatBilyetField(key: 'footnote', label: 'Footnote', aktif: false, x: 10, y: 89, fontSize: 7),
  ];

  /// Gabungkan field tersimpan dengan [defaultFields]: urutan & label ikut default,
  /// field baru (belum pernah disimpan) muncul dengan posisi default & nonaktif.
  static List<FormatBilyetField> mergeWithDefault(List<FormatBilyetField> saved) {
    final byKey = {for (final f in saved) f.key: f};
    final merged = <FormatBilyetField>[
      for (final d in defaultFields)
        byKey[d.key] == null
            // Teks bebas tanpa isi tidak ikut dicetak, jadi selalu mulai nonaktif.
            ? d.copyWith(aktif: saved.isEmpty && !d.isTeksBebas)
            : d.copyWith(
                aktif: byKey[d.key]!.aktif,
                x: byKey[d.key]!.x,
                y: byKey[d.key]!.y,
                teks: byKey[d.key]!.teks,
                fontSize: byKey[d.key]!.fontSize > 0 ? byKey[d.key]!.fontSize : d.fontSize,
              ),
    ];
    return merged;
  }

  factory FormatBilyetModel.fromJson(Map<String, dynamic> json) {
    final raw = json['fields'];
    final saved = <FormatBilyetField>[
      if (raw is List)
        for (final e in raw)
          if (e is Map) FormatBilyetField.fromJson(Map<String, dynamic>.from(e)),
    ];
    return FormatBilyetModel(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      kodeFormat: (json['kode_format'] ?? '').toString(),
      namaFormat: (json['nama_format'] ?? '').toString(),
      merkKertas: (json['merk_kertas'] ?? '').toString(),
      ukuranKertas: (json['ukuran_kertas'] ?? '').toString(),
      lebarKertas: _toDouble(json['lebar_kertas']),
      tinggiKertas: _toDouble(json['tinggi_kertas']),
      fontSize: _toDouble(json['font_size']),
      fields: mergeWithDefault(saved),
      bgBilyet: (json['bg_bilyet'] ?? '').toString(),
      // Data lama / tidak dikirim = 100 (tidak transparan).
      bgOpacity: json['bg_opacity'] == null ? 100 : _toDouble(json['bg_opacity']).round().clamp(0, 100),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kode_format': kodeFormat,
        'nama_format': namaFormat,
        'merk_kertas': merkKertas,
        'ukuran_kertas': ukuranKertas,
        'lebar_kertas': lebarKertas,
        'tinggi_kertas': tinggiKertas,
        'font_size': fontSize,
        'fields': fields.map((f) => f.toJson()).toList(),
        'bg_bilyet': bgBilyet,
        'bg_opacity': bgOpacity,
      };

  /// Byte gambar latar dari data URI, null kalau kosong/rusak.
  Uint8List? get bgBytes => decodeBgBilyet(bgBilyet);

  static Uint8List? decodeBgBilyet(String dataUri) {
    final i = dataUri.indexOf(',');
    if (dataUri.isEmpty || i < 0) return null;
    try {
      return base64Decode(dataUri.substring(i + 1));
    } catch (_) {
      return null;
    }
  }

  String get ukuranLabel {
    String fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    final ukuran = '${fmt(lebarKertas)} x ${fmt(tinggiKertas)} mm';
    return ukuranKertas.isEmpty || ukuranKertas == UkuranKertasPreset.kustom
        ? ukuran
        : '$ukuranKertas ($ukuran)';
  }
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse((v ?? '').toString()) ?? 0;
}
