class SetupInventarisSbbRow {
  final String kode;
  final String label;
  final String nosbb;

  const SetupInventarisSbbRow({required this.kode, required this.label, this.nosbb = ''});

  SetupInventarisSbbRow copyWith({String? nosbb}) {
    return SetupInventarisSbbRow(kode: kode, label: label, nosbb: nosbb ?? this.nosbb);
  }

  Map<String, dynamic> toJson() => {'kode': kode, 'nosbb': nosbb.trim()};
}

const List<SetupInventarisSbbRow> kSetupInventarisSbbRows = [
  SetupInventarisSbbRow(kode: 'ASET', label: 'Aset'),
  SetupInventarisSbbRow(kode: 'SUSUT', label: 'Akumulasi Penyusutan'),
  SetupInventarisSbbRow(kode: 'PPNM', label: 'PPN Masuk'),
  SetupInventarisSbbRow(kode: 'PPNK', label: 'PPN Keluar'),
  SetupInventarisSbbRow(kode: 'KRK', label: 'Kerugian Penilaian Kembali'),
  SetupInventarisSbbRow(kode: 'KTK', label: 'Keuntungan Penilaian Kembali'),
  SetupInventarisSbbRow(kode: 'KPA', label: 'Kerugian Penjualan Aset'),
  SetupInventarisSbbRow(kode: 'KTA', label: 'Keuntungan Penjualan Aset'),
  SetupInventarisSbbRow(kode: 'BPR', label: 'Biaya Perbaikan'),
  SetupInventarisSbbRow(kode: 'BSUS', label: 'Biaya Penyusutan'),
];


class BankProfileModel {
  final Map<String, dynamic> raw;
  final String kodeBank;
  final String nama;
  final String namaBpr;
  final String bprId;
  final String jenis;
  final String tipe;
  final String active;
  final String registrationStatus;

  const BankProfileModel({
    required this.raw,
    required this.kodeBank,
    required this.nama,
    required this.namaBpr,
    required this.bprId,
    required this.jenis,
    required this.tipe,
    required this.active,
    required this.registrationStatus,
  });

  String get displayName => nama.isNotEmpty ? nama : namaBpr;

  factory BankProfileModel.fromJson(Map<String, dynamic> json) {
    return BankProfileModel(
      raw: json,
      kodeBank: _s(json['kode_bank'] ?? json['sandi_bank'] ?? json['kode']),
      nama: _s(json['nama']),
      namaBpr: _s(json['nama_bpr'] ?? json['nama_bank']),
      bprId: _s(json['bpr_id']),
      jenis: _s(json['jenis']),
      tipe: _s(json['tipe']),
      active: _s(json['active']),
      registrationStatus: _s(json['registration_status']),
    );
  }
}

class SetupInventarisModel {
  final Map<String, dynamic> raw;
  final String id;
  final String groupInventaris;
  final String kode;
  final String keterangan;
  final String nosbb;
  final String nosbbNama;
  final int masaManfaatBulan;
  final String keteranganGroup;
  final String statusData;
  final String createdAt;
  final String createdBy;

  const SetupInventarisModel({
    required this.raw,
    required this.id,
    required this.groupInventaris,
    required this.kode,
    required this.keterangan,
    required this.nosbb,
    required this.nosbbNama,
    required this.masaManfaatBulan,
    required this.keteranganGroup,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
  });

  String get labelGroup => keteranganGroup.isNotEmpty ? keteranganGroup : keterangan;

  factory SetupInventarisModel.fromJson(Map<String, dynamic> json) {
    return SetupInventarisModel(
      raw: json,
      id: _s(json['id']),
      groupInventaris: _s(json['group_inventaris']),
      kode: _s(json['kode']),
      keterangan: _s(json['keterangan']),
      nosbb: _s(json['nosbb']),
      nosbbNama: _s(json['nosbb_nama'] ?? json['nama_sbb'] ?? json['nama_coa'] ?? json['namasbb']),
      masaManfaatBulan: _i(json['masa_manfaat_bulan']),
      keteranganGroup: _s(json['keterangan_group']),
      statusData: _s(json['status_data'], 'A'),
      createdAt: _s(json['created_at']),
      createdBy: _s(json['created_by']),
    );
  }
}

class AbaModel {
  final Map<String, dynamic> raw;
  final String id;
  final String nomorRekening;
  final String nomorSbb;
  final String jenisRekening;
  final String namaBank;
  final String sandiBank;
  final double nominal;
  final int jangkaWaktu;
  final String jenisJangkaWaktu;
  final String tanggalBuka;
  final String tanggalJatuhTempo;
  final double sukuBunga;
  final bool terkait;
  final String coll;
  final double ppap;
  final String officeCode;
  final String statusRekening;
  final String statusOtorisasi;
  final String statusData;
  final String createdAt;
  final String createdBy;

  const AbaModel({
    required this.raw,
    required this.id,
    required this.nomorRekening,
    required this.nomorSbb,
    required this.jenisRekening,
    required this.namaBank,
    required this.sandiBank,
    required this.nominal,
    required this.jangkaWaktu,
    required this.jenisJangkaWaktu,
    required this.tanggalBuka,
    required this.tanggalJatuhTempo,
    required this.sukuBunga,
    required this.terkait,
    required this.coll,
    required this.ppap,
    required this.officeCode,
    required this.statusRekening,
    required this.statusOtorisasi,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
  });

  String get jenisLabel {
    switch (jenisRekening.toUpperCase()) {
      case 'G':
        return 'Giro';
      case 'T':
        return 'Tabungan';
      case 'D':
        return 'Deposito';
      default:
        return jenisRekening;
    }
  }

  factory AbaModel.fromJson(Map<String, dynamic> json) {
    return AbaModel(
      raw: json,
      id: _s(json['id']),
      nomorRekening: _s(json['nomor_rekening']),
      nomorSbb: _s(json['nomor_sbb']),
      jenisRekening: _s(json['jenis_rekening'], 'G').toUpperCase(),
      namaBank: _s(json['nama_bank']),
      sandiBank: _s(json['sandi_bank']),
      nominal: _d(json['nominal']),
      jangkaWaktu: _i(json['jangka_waktu']),
      jenisJangkaWaktu: _s(json['jenis_jangka_waktu']).toUpperCase(),
      tanggalBuka: _s(json['tanggal_buka']),
      tanggalJatuhTempo: _s(json['tanggal_jatuh_tempo']),
      sukuBunga: _d(json['suku_bunga']),
      terkait: _b(json['terkait']),
      coll: _s(json['coll']),
      ppap: _d(json['ppap']),
      officeCode: _s(json['office_code'] ?? json['kode_kantor']),
      statusRekening: _s(json['status_rekening']),
      statusOtorisasi: _s(json['status_otorisasi']),
      statusData: _s(json['status_data']),
      createdAt: _s(json['created_at']),
      createdBy: _s(json['created_by']),
    );
  }
}

class MitraBisnisModel {
  final Map<String, dynamic> raw;
  final String id;
  final String kodeMitra;
  final String kelompok;
  final String namaMitra;
  final String alamat;
  final String kota;
  final String kodePos;
  final String npwp;
  final String namaPic;
  final String nomorHpPic;
  final String nomorTelpPic;
  final String email;
  final String nomorRekening;
  final String bankRekening;
  final String statusData;
  final String createdAt;
  final String createdBy;

  const MitraBisnisModel({
    required this.raw,
    required this.id,
    required this.kodeMitra,
    required this.kelompok,
    required this.namaMitra,
    required this.alamat,
    required this.kota,
    required this.kodePos,
    required this.npwp,
    required this.namaPic,
    required this.nomorHpPic,
    required this.nomorTelpPic,
    required this.email,
    required this.nomorRekening,
    required this.bankRekening,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
  });

  factory MitraBisnisModel.fromJson(Map<String, dynamic> json) {
    return MitraBisnisModel(
      raw: json,
      id: _s(json['id']),
      kodeMitra: _s(json['kode_mitra']),
      kelompok: _s(json['kelompok']),
      namaMitra: _s(json['nama_mitra']),
      alamat: _s(json['alamat']),
      kota: _s(json['kota']),
      kodePos: _s(json['kode_pos']),
      npwp: _s(json['npwp']),
      namaPic: _s(json['nama_pic']),
      nomorHpPic: _s(json['nomor_hp_pic']),
      nomorTelpPic: _s(json['nomor_telp_pic']),
      email: _s(json['email']),
      nomorRekening: _s(json['nomor_rekening']),
      bankRekening: _s(json['bank_rekening']),
      statusData: _s(json['status_data'], 'A'),
      createdAt: _s(json['created_at']),
      createdBy: _s(json['created_by']),
    );
  }
}

class MasterInventarisAsetModel {
  final Map<String, dynamic> raw;
  final String id;
  final String kodeInventaris;
  final String namaInventaris;
  final String kelompokAset;
  final String kelompokAsetLabel;
  final String groupAset;
  final String lokasi;
  final String alamat;
  final String kelurahan;
  final String kecamatan;
  final String kota;
  final String kodeKantor;
  final String namaKantor;
  final String statusAset;
  final String statusAsetLabel;
  final bool penyusutan;
  final int masaPenyusutan;
  final String kondisiAset;
  final String kondisiAsetLabel;
  final String keterangan;
  final String tanggalBeli;
  final String nomorDokumen;
  final String tanggalKirim;
  final double hargaBeli;
  final double discount;
  final double biaya;
  final double ppnNominal;
  final double totalPerolehan;
  final double nilaiSusutPerbulan;
  final String awalPenyusutan;
  final String namaMitra;
  final String rekeningMitra;
  final String statusData;
  final String createdAt;
  final String createdBy;

  const MasterInventarisAsetModel({
    required this.raw,
    required this.id,
    required this.kodeInventaris,
    required this.namaInventaris,
    required this.kelompokAset,
    required this.kelompokAsetLabel,
    required this.groupAset,
    required this.lokasi,
    required this.alamat,
    required this.kelurahan,
    required this.kecamatan,
    required this.kota,
    required this.kodeKantor,
    required this.namaKantor,
    required this.statusAset,
    required this.statusAsetLabel,
    required this.penyusutan,
    required this.masaPenyusutan,
    required this.kondisiAset,
    required this.kondisiAsetLabel,
    required this.keterangan,
    required this.tanggalBeli,
    required this.nomorDokumen,
    required this.tanggalKirim,
    required this.hargaBeli,
    required this.discount,
    required this.biaya,
    required this.ppnNominal,
    required this.totalPerolehan,
    required this.nilaiSusutPerbulan,
    required this.awalPenyusutan,
    required this.namaMitra,
    required this.rekeningMitra,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
  });

  factory MasterInventarisAsetModel.fromJson(Map<String, dynamic> json) {
    return MasterInventarisAsetModel(
      raw: json,
      id: _s(json['id']),
      kodeInventaris: _s(json['kode_inventaris']),
      namaInventaris: _s(json['nama_inventaris']),
      kelompokAset: _s(json['kelompok_aset']),
      kelompokAsetLabel: _s(json['kelompok_aset_label']),
      groupAset: _s(json['group_aset']),
      lokasi: _s(json['lokasi_aset'] ?? json['lokasi']),
      alamat: _s(json['alamat']),
      kelurahan: _s(json['kelurahan']),
      kecamatan: _s(json['kecamatan']),
      kota: _s(json['kota']),
      kodeKantor: _s(json['kode_kantor']),
      namaKantor: _s(json['nama_kantor']),
      statusAset: _s(json['status_aset'], 'O'),
      statusAsetLabel: _s(json['status_aset_label']),
      penyusutan: _b(json['penyusutan']),
      masaPenyusutan: _i(json['masa_penyusutan']),
      kondisiAset: _s(json['kondisi_aset']),
      kondisiAsetLabel: _s(json['kondisi_aset_label']),
      keterangan: _s(json['keterangan']),
      tanggalBeli: _s(json['tanggal_beli']),
      nomorDokumen: _s(json['nomor_dokumen']),
      tanggalKirim: _s(json['tanggal_kirim']),
      hargaBeli: _d(json['harga_beli']),
      discount: _d(json['discount']),
      biaya: _d(json['biaya']),
      ppnNominal: _d(json['ppn_nominal']),
      totalPerolehan: _d(json['total_perolehan']),
      nilaiSusutPerbulan: _d(json['nilai_susut_perbulan']),
      awalPenyusutan: _s(json['awal_penyusutan']),
      namaMitra: _s(json['nama_mitra']),
      rekeningMitra: _s(json['rekening_mitra']),
      statusData: _s(json['status_data']),
      createdAt: _s(json['created_at']),
      createdBy: _s(json['created_by']),
    );
  }
}

String _s(dynamic v, [String def = '']) {
  if (v == null) return def;
  final text = v.toString().trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? def : text;
}

int _i(dynamic v, [int def = 0]) {
  if (v == null) return def;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9-]'), '')) ?? def;
}

double _d(dynamic v, [double def = 0]) {
  if (v == null) return def;
  if (v is num) return v.toDouble();
  final text = v.toString().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.-]'), '');
  return double.tryParse(text) ?? def;
}

bool _b(dynamic v, [bool def = false]) {
  if (v == null) return def;
  if (v is bool) return v;
  if (v is num) return v == 1;
  final text = v.toString().trim().toLowerCase();
  if (['true', '1', 'y', 'yes', 'ya'].contains(text)) return true;
  if (['false', '0', 'n', 'no', 'tidak', ''].contains(text)) return false;
  return def;
}
