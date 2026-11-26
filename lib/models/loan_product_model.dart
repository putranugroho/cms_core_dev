class LoanProductModel {
  final Map<String, dynamic> raw;
  final String id;
  final String kodeProduk;
  final String namaProduk;
  final String jenisLoan;
  final String metodePerhitunganBunga;
  final int jangkaWaktuMin;
  final int jangkaWaktuMax;
  final bool agunan;
  final double biayaAdministrasi;
  final double rateProvisi;
  final bool perhitunganDendaHarian;
  final double rateDenda;
  final String basePerhitunganDenda;
  final bool penaltiPelunasanDipercepat;
  final String basePerhitunganPenalty;
  final bool provisiDiAcru;
  final String statusData;

  final String sbbLoan;
  final String sbbBunga;
  final String sbbPad;
  final String sbbPpapColl1;
  final String sbbPpapCollLebih1;
  final String sbbBiayaAdministrasi;
  final String sbbProvisi;
  final String sbbTitipanNotaris;
  final String sbbAsuransiJiwa;
  final String sbbTitipanTunai;
  final String sbbPenalty;
  final String sbbMaterai;
  final String sbbTitipanDroping;
  final String sbbTitipanAsuransiAgunan;
  final String sbbKomitmen;
  final String sbbKontijensi;
  final String sbbWriteOff;
  final String sbbTitipanProvisi;

  LoanProductModel({
    required this.raw,
    required this.id,
    required this.kodeProduk,
    required this.namaProduk,
    required this.jenisLoan,
    required this.metodePerhitunganBunga,
    required this.jangkaWaktuMin,
    required this.jangkaWaktuMax,
    required this.agunan,
    required this.biayaAdministrasi,
    required this.rateProvisi,
    required this.perhitunganDendaHarian,
    required this.rateDenda,
    required this.basePerhitunganDenda,
    required this.penaltiPelunasanDipercepat,
    required this.basePerhitunganPenalty,
    required this.provisiDiAcru,
    required this.statusData,
    required this.sbbLoan,
    required this.sbbBunga,
    required this.sbbPad,
    required this.sbbPpapColl1,
    required this.sbbPpapCollLebih1,
    required this.sbbBiayaAdministrasi,
    required this.sbbProvisi,
    required this.sbbTitipanNotaris,
    required this.sbbAsuransiJiwa,
    required this.sbbTitipanTunai,
    required this.sbbPenalty,
    required this.sbbMaterai,
    required this.sbbTitipanDroping,
    required this.sbbTitipanAsuransiAgunan,
    required this.sbbKomitmen,
    required this.sbbKontijensi,
    required this.sbbWriteOff,
    required this.sbbTitipanProvisi,
  });

  factory LoanProductModel.fromJson(Map<String, dynamic> json) {
    return LoanProductModel(
      raw: json,
      id: _s(json['id']),
      kodeProduk: _s(json['kode_produk']),
      namaProduk: _s(json['nama_produk'] ?? json['nama_product']),
      jenisLoan: _s(json['jenis_loan'], 'INSTALLMENT'),
      metodePerhitunganBunga: _s(json['metode_perhitungan_bunga'], 'FLAT'),
      jangkaWaktuMin: _i(json['jangka_waktu_min']),
      jangkaWaktuMax: _i(json['jangka_waktu_max']),
      agunan: _b(json['agunan']),
      biayaAdministrasi: _d(json['biaya_administrasi']),
      rateProvisi: _d(json['rate_provisi']),
      perhitunganDendaHarian: _b(json['perhitungan_denda_harian']),
      rateDenda: _d(json['rate_denda']),
      basePerhitunganDenda: _s(json['base_perhitungan_denda'], 'POKOK_BUNGA'),
      penaltiPelunasanDipercepat: _b(json['penalti_pelunasan_dipercepat']),
      basePerhitunganPenalty: _s(json['base_perhitungan_penalty'], 'PERSEN_OS'),
      provisiDiAcru: _b(json['provisi_di_acru']),
      statusData: _s(json['status_data'], 'A'),
      sbbLoan: _s(json['sbb_loan']),
      sbbBunga: _s(json['sbb_bunga']),
      sbbPad: _s(json['sbb_pad']),
      sbbPpapColl1: _s(json['sbb_ppap_coll_1']),
      sbbPpapCollLebih1: _s(json['sbb_ppap_coll_lebih_1']),
      sbbBiayaAdministrasi: _s(json['sbb_biaya_administrasi']),
      sbbProvisi: _s(json['sbb_provisi']),
      sbbTitipanNotaris: _s(json['sbb_titipan_notaris']),
      sbbAsuransiJiwa: _s(json['sbb_asuransi_jiwa']),
      sbbTitipanTunai: _s(json['sbb_titipan_tunai']),
      sbbPenalty: _s(json['sbb_penalty']),
      sbbMaterai: _s(json['sbb_materai']),
      sbbTitipanDroping: _s(json['sbb_titipan_droping']),
      sbbTitipanAsuransiAgunan: _s(json['sbb_titipan_asuransi_agunan']),
      sbbKomitmen: _s(json['sbb_komitmen']),
      sbbKontijensi: _s(json['sbb_kontijensi']),
      sbbWriteOff: _s(json['sbb_write_off']),
      sbbTitipanProvisi: _s(json['sbb_titipan_provisi']),
    );
  }

  static String _s(dynamic v, [String def = '']) {
    if (v == null) return def;
    final text = v.toString().trim();
    return text.isEmpty ? def : text;
  }

  static int _i(dynamic v, [int def = 0]) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9-]'), '')) ?? def;
  }

  static double _d(dynamic v, [double def = 0]) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    final text = v.toString().trim().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(text) ?? def;
  }

  static bool _b(dynamic v, [bool def = false]) {
    if (v == null) return def;
    if (v is bool) return v;
    final text = v.toString().trim().toLowerCase();
    if (['true', '1', 'y', 'yes', 'ya'].contains(text)) return true;
    if (['false', '0', 'n', 'no', 'tidak'].contains(text)) return false;
    return def;
  }
}

class LoanProductListResult {
  final List<LoanProductModel> items;
  final int total;

  const LoanProductListResult({required this.items, required this.total});
}
