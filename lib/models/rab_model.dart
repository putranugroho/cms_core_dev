class RabModel {
  final Map<String, dynamic> raw;
  final String id, kodeKantor, namaKantor, kodeAo, namaAo, status, statusTxt, statusData, createdAt, createdBy, updatedAt, updatedBy;
  final int bulan, tahun, targetTabungan, realisasiTabungan;
  final double targetKredit, targetDeposito, realisasiKredit, realisasiDeposito;

  const RabModel({required this.raw, required this.id, required this.kodeKantor, required this.namaKantor, required this.kodeAo,
    required this.namaAo, required this.bulan, required this.tahun, required this.targetTabungan, required this.targetKredit,
    required this.targetDeposito, required this.realisasiTabungan, required this.realisasiKredit, required this.realisasiDeposito,
    required this.status, required this.statusTxt, required this.statusData, required this.createdAt, required this.createdBy,
    required this.updatedAt, required this.updatedBy});

  static String _s(dynamic v) => v?.toString() ?? '';
  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(_s(v)) ?? 0;
  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse(_s(v)) ?? 0;
  factory RabModel.fromJson(Map<String, dynamic> j) => RabModel(raw: j, id: _s(j['id']), kodeKantor: _s(j['kode_kantor']),
    namaKantor: _s(j['nama_kantor']), kodeAo: _s(j['kode_ao']), namaAo: _s(j['nama_ao']), bulan: _i(j['bulan']),
    tahun: _i(j['tahun']), targetTabungan: _i(j['target_tabungan']), targetKredit: _d(j['target_kredit']),
    targetDeposito: _d(j['target_deposito']), realisasiTabungan: _i(j['realisasi_tabungan']),
    realisasiKredit: _d(j['realisasi_kredit']), realisasiDeposito: _d(j['realisasi_deposito']), status: _s(j['status']),
    statusTxt: _s(j['status_txt']), statusData: _s(j['status_data']), createdAt: _s(j['created_at']), createdBy: _s(j['created_by']),
    updatedAt: _s(j['updated_at']), updatedBy: _s(j['updated_by']));
  String get displayStatus => statusTxt.isNotEmpty ? statusTxt : status == 'A' ? 'APPROVED' : status == 'R' ? 'REJECTED' : 'DRAFT';
}

class RabListResult {
  final List<RabModel> items;
  final int total, page, limit;
  const RabListResult({required this.items, required this.total, required this.page, required this.limit});
}
