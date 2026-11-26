class DepositPenaltyModel {
  final String id;
  final int jumlahHari;
  final double rate;
  final double nominal;
  final double nilai;
  final bool bungaBerjalanDibayar;
  final int urutan;
  final Map<String, dynamic> raw;

  const DepositPenaltyModel({
    required this.id,
    required this.jumlahHari,
    required this.rate,
    required this.nominal,
    required this.nilai,
    required this.bungaBerjalanDibayar,
    required this.urutan,
    required this.raw,
  });

  factory DepositPenaltyModel.fromJson(Map<String, dynamic> json) {
    final nilai = _dbl(json['nilai']);
    final rate = _dbl(json['rate']);
    final nominal = _dbl(json['nominal']);
    return DepositPenaltyModel(
      id: _str(json['id']),
      jumlahHari: _int(json['jumlah_hari']),
      rate: rate,
      nominal: nominal,
      nilai: nilai,
      bungaBerjalanDibayar: _bool(json['bunga_berjalan_dibayar'], true),
      urutan: _int(json['urutan']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  static String _str(dynamic value, [String def = '']) {
    if (value == null) return def;
    final text = value.toString();
    return text.isEmpty ? def : text;
  }

  static int _int(dynamic value, [int def = 0]) {
    if (value == null) return def;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? def;
  }

  static double _dbl(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final text = value.toString().trim();
    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(text)) {
      return double.tryParse(text.replaceAll('.', '')) ?? 0;
    }
    return double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  static bool _bool(dynamic value, [bool def = false]) {
    if (value == null) return def;
    if (value is bool) return value;
    final text = value.toString().toLowerCase();
    if (text == 'true' || text == '1' || text == 'y' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'n' || text == 'no') return false;
    return def;
  }
}

class DepositProductModel {
  final String id;
  final String kodeProduk;
  final String singkatanProduk;
  final String namaProduk;
  final String statusData;
  final int jangkaWaktu;
  final String jenisJangkaWaktu;
  final String pembayaranBunga;
  final int faktorPembagi;
  final String pencadanganBungaAcrual;
  final bool pencairanBebasKapanSaja;
  final bool pencairanAbnormalPinalti;
  final String perhitunganPinalti;
  final double minimalPinalti;
  final List<DepositPenaltyModel> penalti;
  final String bungaDepositoPI;
  final double rateDeposito;
  final double minimalNominalDeposito;
  final double maksimalNominalDeposito;
  final double maksimalSpread;
  final double maksimalDepositoTidakKenaPajak;
  final double ratePajak;
  final String sbbDeposito;
  final String sbbBiayaBunga;
  final String sbbTitipanPajak;
  final String sbbMaterai;
  final String sbbTitipanAcrualBunga;
  final String sbbTitipanPencairanPokok;
  final String sbbTitipanPencairanBunga;
  final String sbbPenalti;
  final String sbbTitipanBungaJatuhTempo;
  final String sbbSubsidiTax;
  final Map<String, dynamic> raw;

  const DepositProductModel({
    required this.id,
    required this.kodeProduk,
    required this.singkatanProduk,
    required this.namaProduk,
    required this.statusData,
    required this.jangkaWaktu,
    required this.jenisJangkaWaktu,
    required this.pembayaranBunga,
    required this.faktorPembagi,
    required this.pencadanganBungaAcrual,
    required this.pencairanBebasKapanSaja,
    required this.pencairanAbnormalPinalti,
    required this.perhitunganPinalti,
    required this.minimalPinalti,
    required this.penalti,
    required this.bungaDepositoPI,
    required this.rateDeposito,
    required this.minimalNominalDeposito,
    required this.maksimalNominalDeposito,
    required this.maksimalSpread,
    required this.maksimalDepositoTidakKenaPajak,
    required this.ratePajak,
    required this.sbbDeposito,
    required this.sbbBiayaBunga,
    required this.sbbTitipanPajak,
    required this.sbbMaterai,
    required this.sbbTitipanAcrualBunga,
    required this.sbbTitipanPencairanPokok,
    required this.sbbTitipanPencairanBunga,
    required this.sbbPenalti,
    required this.sbbTitipanBungaJatuhTempo,
    required this.sbbSubsidiTax,
    required this.raw,
  });

  String get namaProduct => namaProduk;

  factory DepositProductModel.fromJson(Map<String, dynamic> json) {
    final rawPenalti = json['penalti'];
    final penaltyRows = rawPenalti is List
        ? rawPenalti
            .whereType<Map>()
            .map((e) => DepositPenaltyModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <DepositPenaltyModel>[];

    return DepositProductModel(
      id: _str(json['id']),
      kodeProduk: _str(json['kode_produk']),
      singkatanProduk: _str(json['singkatan_produk']),
      namaProduk: _str(json['nama_produk'] ?? json['nama_product']),
      statusData: _str(json['status_data'], 'A'),
      jangkaWaktu: _int(json['jangka_waktu']),
      jenisJangkaWaktu: _str(json['jenis_jangka_waktu'], 'BULAN'),
      pembayaranBunga: _str(json['pembayaran_bunga'], 'CASH_BASIS'),
      faktorPembagi: _int(json['faktor_pembagi'], 365),
      pencadanganBungaAcrual: _str(json['pencadangan_bunga_acrual']),
      pencairanBebasKapanSaja: _bool(json['pencairan_bebas_kapan_saja'], true),
      pencairanAbnormalPinalti: _bool(json['pencairan_abnormal_pinalti']),
      perhitunganPinalti: _str(json['perhitungan_pinalti']),
      minimalPinalti: _dbl(json['minimal_pinalti']),
      penalti: penaltyRows,
      bungaDepositoPI: _str(json['bunga_deposito_P_I'] ?? json['bunga_deposito_p_i'], 'TIAP_JATUH_TEMPO'),
      rateDeposito: _dbl(json['rate_deposito']),
      minimalNominalDeposito: _dbl(json['minimal_nominal_deposito']),
      maksimalNominalDeposito: _dbl(json['maksimal_nominal_deposito']),
      maksimalSpread: _dbl(json['maksimal_spread']),
      maksimalDepositoTidakKenaPajak: _dbl(json['maksimal_deposito_tidak_kena_pajak']),
      ratePajak: _dbl(json['rate_pajak']),
      sbbDeposito: _str(json['sbb_deposito']),
      sbbBiayaBunga: _str(json['sbb_biaya_bunga']),
      sbbTitipanPajak: _str(json['sbb_titipan_pajak']),
      sbbMaterai: _str(json['sbb_materai']),
      sbbTitipanAcrualBunga: _str(json['sbb_titipan_acrual_bunga']),
      sbbTitipanPencairanPokok: _str(json['sbb_titipan_pencairan_pokok']),
      sbbTitipanPencairanBunga: _str(json['sbb_titipan_pencairan_bunga']),
      sbbPenalti: _str(json['sbb_penalti']),
      sbbTitipanBungaJatuhTempo: _str(json['sbb_titipan_bunga_jatuh_tempo']),
      sbbSubsidiTax: _str(json['sbb_subsidi_tax']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  String get statusText => statusData.toUpperCase() == 'A' ? 'Aktif' : statusData.toUpperCase() == 'D' ? 'Hapus' : statusData;

  static String _str(dynamic value, [String def = '']) {
    if (value == null) return def;
    final text = value.toString();
    return text.isEmpty ? def : text;
  }

  static int _int(dynamic value, [int def = 0]) {
    if (value == null) return def;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? def;
  }

  static double _dbl(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final text = value.toString().trim();
    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(text)) {
      return double.tryParse(text.replaceAll('.', '')) ?? 0;
    }
    return double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  static bool _bool(dynamic value, [bool def = false]) {
    if (value == null) return def;
    if (value is bool) return value;
    final text = value.toString().toLowerCase();
    if (text == 'true' || text == '1' || text == 'y' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'n' || text == 'no') return false;
    return def;
  }
}
