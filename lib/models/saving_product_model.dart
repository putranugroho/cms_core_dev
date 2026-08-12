class SavingProductModel {
  final String id;
  final String kodeProduk;
  final String namaProduk;
  final String jenisTabungan;
  final String statusData;
  final String tipeRate;
  final double rateBunga;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;
  final Map<String, dynamic> raw;

  SavingProductModel({
    required this.id,
    required this.kodeProduk,
    required this.namaProduk,
    required this.jenisTabungan,
    required this.statusData,
    required this.tipeRate,
    required this.rateBunga,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.raw,
  });

  factory SavingProductModel.fromJson(Map<String, dynamic> json) {
    return SavingProductModel(
      id: _str(json['id']),
      kodeProduk: _str(json['kode_produk']),
      namaProduk: _str(json['nama_produk']),
      jenisTabungan: _str(json['jenis_tabungan']),
      statusData: _str(json['status_data'], 'A'),
      tipeRate: _str(json['tipe_rate'], 'STATIK'),
      rateBunga: _dbl(json['rate_bunga']),
      createdAt: _str(json['created_at']),
      createdBy: _str(json['created_by']),
      updatedAt: _str(json['updated_at']),
      updatedBy: _str(json['updated_by']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  String get statusText {
    switch (statusData.toUpperCase()) {
      case 'A':
        return 'Aktif';
      case 'D':
        return 'Hapus';
      default:
        return statusData.isEmpty ? '-' : statusData;
    }
  }

  static String _str(dynamic value, [String def = '']) {
    if (value == null) return def;
    return value.toString();
  }

  static double _dbl(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
