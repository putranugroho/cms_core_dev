class PrintValue {
  static double toDouble(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? fallback;
  }

  static int toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static String toText(dynamic value) => (value ?? '').toString();

  static String statusText(String code) {
    switch (code.toUpperCase()) {
      case 'A':
        return 'Aktif';
      case 'D':
        return 'Hapus';
      default:
        return code.isEmpty ? '-' : code;
    }
  }
}

class FormatBukuModel {
  final String id;
  final String kodeFormat;
  final String namaFormat;
  final String merkBuku;
  final String ukuranKertas;
  final int jumlahBaris;
  final double marginAtas;
  final double marginBawah;
  final double marginKiri;
  final double marginKanan;
  final double tanggalX;
  final double tanggalY;
  final double keteranganX;
  final double keteranganY;
  final double debetX;
  final double debetY;
  final double kreditX;
  final double kreditY;
  final double saldoX;
  final double saldoY;
  final double fontSize;
  final String statusData;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;

  const FormatBukuModel({
    required this.id,
    required this.kodeFormat,
    required this.namaFormat,
    required this.merkBuku,
    required this.ukuranKertas,
    required this.jumlahBaris,
    required this.marginAtas,
    required this.marginBawah,
    required this.marginKiri,
    required this.marginKanan,
    required this.tanggalX,
    required this.tanggalY,
    required this.keteranganX,
    required this.keteranganY,
    required this.debetX,
    required this.debetY,
    required this.kreditX,
    required this.kreditY,
    required this.saldoX,
    required this.saldoY,
    required this.fontSize,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory FormatBukuModel.fromJson(Map<String, dynamic> json) {
    return FormatBukuModel(
      id: PrintValue.toText(json['id']),
      kodeFormat: PrintValue.toText(json['kode_format']),
      namaFormat: PrintValue.toText(json['nama_format']),
      merkBuku: PrintValue.toText(json['merk_buku']),
      ukuranKertas: PrintValue.toText(json['ukuran_kertas']),
      jumlahBaris: PrintValue.toInt(json['jumlah_baris'], 0),
      marginAtas: PrintValue.toDouble(json['margin_atas']),
      marginBawah: PrintValue.toDouble(json['margin_bawah']),
      marginKiri: PrintValue.toDouble(json['margin_kiri']),
      marginKanan: PrintValue.toDouble(json['margin_kanan']),
      tanggalX: PrintValue.toDouble(json['tanggal_x']),
      tanggalY: PrintValue.toDouble(json['tanggal_y']),
      keteranganX: PrintValue.toDouble(json['keterangan_x']),
      keteranganY: PrintValue.toDouble(json['keterangan_y']),
      debetX: PrintValue.toDouble(json['debet_x']),
      debetY: PrintValue.toDouble(json['debet_y']),
      kreditX: PrintValue.toDouble(json['kredit_x']),
      kreditY: PrintValue.toDouble(json['kredit_y']),
      saldoX: PrintValue.toDouble(json['saldo_x']),
      saldoY: PrintValue.toDouble(json['saldo_y']),
      fontSize: PrintValue.toDouble(json['font_size'], 10),
      statusData: PrintValue.toText(json['status_data']),
      createdAt: PrintValue.toText(json['created_at']),
      createdBy: PrintValue.toText(json['created_by']),
      updatedAt: PrintValue.toText(json['updated_at']),
      updatedBy: PrintValue.toText(json['updated_by']),
    );
  }
}

class FormatCoverModel {
  final String id;
  final String kodeFormatCover;
  final String namaFormatCover;
  final String merkBuku;
  final String ukuranKertas;
  final double nomorRekeningX;
  final double nomorRekeningY;
  final double namaNasabahX;
  final double namaNasabahY;
  final double nomorCifX;
  final double nomorCifY;
  final double alamatX;
  final double alamatY;
  final double namaKantorX;
  final double namaKantorY;
  final double namaProdukX;
  final double namaProdukY;
  final double tanggalTerbitX;
  final double tanggalTerbitY;
  final double logoX;
  final double logoY;
  final double fontSize;
  final String statusData;
  final String createdAt;
  final String createdBy;

  const FormatCoverModel({
    required this.id,
    required this.kodeFormatCover,
    required this.namaFormatCover,
    required this.merkBuku,
    required this.ukuranKertas,
    required this.nomorRekeningX,
    required this.nomorRekeningY,
    required this.namaNasabahX,
    required this.namaNasabahY,
    required this.nomorCifX,
    required this.nomorCifY,
    required this.alamatX,
    required this.alamatY,
    required this.namaKantorX,
    required this.namaKantorY,
    required this.namaProdukX,
    required this.namaProdukY,
    required this.tanggalTerbitX,
    required this.tanggalTerbitY,
    required this.logoX,
    required this.logoY,
    required this.fontSize,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
  });

  factory FormatCoverModel.fromJson(Map<String, dynamic> json) {
    return FormatCoverModel(
      id: PrintValue.toText(json['id']),
      kodeFormatCover: PrintValue.toText(json['kode_format_cover']),
      namaFormatCover: PrintValue.toText(json['nama_format_cover']),
      merkBuku: PrintValue.toText(json['merk_buku']),
      ukuranKertas: PrintValue.toText(json['ukuran_kertas']),
      nomorRekeningX: PrintValue.toDouble(json['nomor_rekening_x']),
      nomorRekeningY: PrintValue.toDouble(json['nomor_rekening_y']),
      namaNasabahX: PrintValue.toDouble(json['nama_nasabah_x']),
      namaNasabahY: PrintValue.toDouble(json['nama_nasabah_y']),
      nomorCifX: PrintValue.toDouble(json['nomor_cif_x']),
      nomorCifY: PrintValue.toDouble(json['nomor_cif_y']),
      alamatX: PrintValue.toDouble(json['alamat_x']),
      alamatY: PrintValue.toDouble(json['alamat_y']),
      namaKantorX: PrintValue.toDouble(json['nama_kantor_x']),
      namaKantorY: PrintValue.toDouble(json['nama_kantor_y']),
      namaProdukX: PrintValue.toDouble(json['nama_produk_x']),
      namaProdukY: PrintValue.toDouble(json['nama_produk_y']),
      tanggalTerbitX: PrintValue.toDouble(json['tanggal_terbit_x']),
      tanggalTerbitY: PrintValue.toDouble(json['tanggal_terbit_y']),
      logoX: PrintValue.toDouble(json['logo_x']),
      logoY: PrintValue.toDouble(json['logo_y']),
      fontSize: PrintValue.toDouble(json['font_size'], 10),
      statusData: PrintValue.toText(json['status_data']),
      createdAt: PrintValue.toText(json['created_at']),
      createdBy: PrintValue.toText(json['created_by']),
    );
  }
}

class FormatBilyetModel {
  final String id;
  final String kodeFormatBilyet;
  final String namaFormatBilyet;
  final String merkKertas;
  final String ukuranKertas;
  final Map<String, double> positions;
  final double fontSize;
  final String statusData;
  final String createdAt;
  final String createdBy;

  const FormatBilyetModel({
    required this.id,
    required this.kodeFormatBilyet,
    required this.namaFormatBilyet,
    required this.merkKertas,
    required this.ukuranKertas,
    required this.positions,
    required this.fontSize,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
  });

  factory FormatBilyetModel.fromJson(Map<String, dynamic> json) {
    final keys = [
      'nomor_bilyet',
      'nomor_deposito',
      'nama_nasabah',
      'nomor_cif',
      'alamat_nasabah',
      'nominal_deposito',
      'terbilang',
      'rate_bunga',
      'tanggal_valuta',
      'tanggal_jatuh_tempo',
      'cara_bayar_bunga',
      'nama_kantor',
      'nama_produk',
      'nama_ao',
      'logo',
      'tanda_tangan',
      'qr_code',
    ];
    final positions = <String, double>{};
    for (final key in keys) {
      positions['${key}_x'] = PrintValue.toDouble(json['${key}_x']);
      positions['${key}_y'] = PrintValue.toDouble(json['${key}_y']);
    }
    return FormatBilyetModel(
      id: PrintValue.toText(json['id']),
      kodeFormatBilyet: PrintValue.toText(json['kode_format_bilyet']),
      namaFormatBilyet: PrintValue.toText(json['nama_format_bilyet']),
      merkKertas: PrintValue.toText(json['merk_kertas']),
      ukuranKertas: PrintValue.toText(json['ukuran_kertas']),
      positions: positions,
      fontSize: PrintValue.toDouble(json['font_size'], 10),
      statusData: PrintValue.toText(json['status_data']),
      createdAt: PrintValue.toText(json['created_at']),
      createdBy: PrintValue.toText(json['created_by']),
    );
  }
}

class SandiTransaksiBukuModel {
  final String id;
  final String kodeSandiTransaksi;
  final String namaSandiTransaksi;
  final String simbolPrint;
  final String keterangan;
  final String statusData;
  final String createdAt;
  final String createdBy;

  const SandiTransaksiBukuModel({
    required this.id,
    required this.kodeSandiTransaksi,
    required this.namaSandiTransaksi,
    required this.simbolPrint,
    required this.keterangan,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
  });

  factory SandiTransaksiBukuModel.fromJson(Map<String, dynamic> json) {
    return SandiTransaksiBukuModel(
      id: PrintValue.toText(json['id']),
      kodeSandiTransaksi: PrintValue.toText(json['kode_sandi_transaksi']),
      namaSandiTransaksi: PrintValue.toText(json['nama_sandi_transaksi']),
      simbolPrint: PrintValue.toText(json['simbol_print']),
      keterangan: PrintValue.toText(json['keterangan']),
      statusData: PrintValue.toText(json['status_data']),
      createdAt: PrintValue.toText(json['created_at']),
      createdBy: PrintValue.toText(json['created_by']),
    );
  }
}

class KodeTransaksiTabunganModel {
  final int id;
  final bool isActive;
  final String kdtrn;
  final String keterangan;
  final String kodeBuku;
  final String kodePadaBuku;
  final String stsRec;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;

  const KodeTransaksiTabunganModel({
    required this.id,
    required this.isActive,
    required this.kdtrn,
    required this.keterangan,
    required this.kodeBuku,
    required this.kodePadaBuku,
    required this.stsRec,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory KodeTransaksiTabunganModel.fromJson(Map<String, dynamic> json) {
    return KodeTransaksiTabunganModel(
      id: PrintValue.toInt(json['id']),
      isActive: json['is_active'] == true || json['is_active'].toString().toLowerCase() == 'true',
      kdtrn: PrintValue.toText(json['kdtrn']),
      keterangan: PrintValue.toText(json['keterangan']),
      kodeBuku: PrintValue.toText(json['kode_buku']),
      kodePadaBuku: PrintValue.toText(json['kode_pada_buku']),
      stsRec: PrintValue.toText(json['sts_rec']),
      createdAt: PrintValue.toText(json['created_at']),
      createdBy: PrintValue.toText(json['created_by']),
      updatedAt: PrintValue.toText(json['updated_at']),
      updatedBy: PrintValue.toText(json['updated_by']),
    );
  }

  String get localKey => '$id-$kdtrn';
}
