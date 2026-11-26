import 'package:flutter/foundation.dart';

@immutable
class KantorModel {
  const KantorModel({
    required this.id,
    required this.kodePt,
    required this.kodeKantor,
    required this.kodeInduk,
    required this.namaKantor,
    required this.statusKantor,
    required this.alamat,
    required this.kelurahan,
    required this.kecamatan,
    required this.kota,
    required this.provinsi,
    required this.kodePos,
    required this.telp,
    required this.fax,
    this.statusAktif = '',
    this.statusData = '',
    this.uuid = '',
    this.pimpinanCabang = '',
    this.managerOperasional = '',
    this.managerMarketing = '',
    this.kodeKantorBi = '',
  });

  final int id;
  final String kodePt;
  final String kodeKantor;
  final String kodeInduk;
  final String namaKantor;
  final String statusKantor;
  final String alamat;
  final String kelurahan;
  final String kecamatan;
  final String kota;
  final String provinsi;
  final String kodePos;
  final dynamic telp;
  final dynamic fax;
  final String statusAktif;
  final String statusData;
  final String uuid;
  final String pimpinanCabang;
  final String managerOperasional;
  final String managerMarketing;
  final String kodeKantorBi;

  static int _intId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    final parsed = int.tryParse(value.toString());
    if (parsed != null) return parsed;
    return value.toString().hashCode.abs();
  }

  static String _s(dynamic value) {
    final text = value?.toString() ?? '';
    return text == 'null' ? '' : text;
  }

  static String _statusKantor(dynamic value) {
    final v = _s(value).trim().toUpperCase();
    if (v == '1' || v == 'P' || v == 'PUSAT' || v == 'KANTOR_PUSAT') return 'P';
    if (v == '2' || v == 'C' || v == 'CABANG') return 'C';
    if (v == '3' || v == 'D' || v == 'CAB.PEMBANTU' || v == 'CABANG_PEMBANTU' || v == 'ANAK_CABANG') return 'D';
    if (v == '4' || v == 'E' || v == 'KAS' || v == 'OUTLET' || v == 'GUDANG') return 'E';
    return v;
  }

  int get statusKantorCore {
    final v = statusKantor.toUpperCase();
    if (v == 'P' || v == 'PUSAT') return 1;
    if (v == 'C' || v == 'CABANG') return 2;
    if (v == 'D' || v == 'CAB.PEMBANTU' || v == 'CABANG_PEMBANTU' || v == 'ANAK_CABANG') return 3;
    if (v == 'E' || v == 'KAS' || v == 'OUTLET' || v == 'GUDANG') return 4;
    return int.tryParse(statusKantor) ?? 2;
  }

  String get namaStatusKantor {
    switch (statusKantorCore) {
      case 1:
        return 'Pusat';
      case 2:
        return 'Cabang';
      case 3:
        return 'Cab. Pembantu';
      case 4:
        return 'Kas';
      default:
        return statusKantor;
    }
  }

  String get namaStatusAktif {
    final v = statusAktif.toUpperCase();
    if (v == 'A') return 'Aktif';
    if (v == 'N') return 'Nonaktif';
    if (v == 'C') return 'Tutup';
    return statusAktif.isEmpty ? '-' : statusAktif;
  }

  factory KantorModel.fromJson(Map<String, dynamic> json) => KantorModel(
        id: _intId(json['id']),
        uuid: _s(json['id']),
        kodePt: _s(json['bpr_id'] ?? json['kode_pt'] ?? json['bprid']),
        kodeKantor: _s(json['kode_kantor']),
        kodeInduk: _s(json['kode_induk']),
        namaKantor: _s(json['nama_kantor'] ?? json['nama']),
        statusKantor: _statusKantor(json['status_kantor']),
        alamat: _s(json['alamat']),
        kelurahan: _s(json['kelurahan']),
        kecamatan: _s(json['kecamatan']),
        kota: _s(json['kota']),
        provinsi: _s(json['provinsi']),
        kodePos: _s(json['kode_pos']),
        telp: json['telp'] ?? '',
        fax: json['nomor_fax'] ?? json['fax'] ?? '',
        statusAktif: _s(json['status_aktif']),
        statusData: _s(json['status_data']),
        pimpinanCabang: _s(json['pimpinan_cabang']),
        managerOperasional: _s(json['manager_operasional']),
        managerMarketing: _s(json['manager_marketing']),
        kodeKantorBi: _s(json['kode_kantor_bi'] ?? json['kode_bi'] ?? json['bi_code']),
      );

  factory KantorModel.fromHrisJson(Map<String, dynamic> json, {Map<String, dynamic> bpr = const {}, String fallbackBprId = ''}) {
    final bprId = _s(bpr['code'] ?? bpr['bpr_id'] ?? bpr['id']).isNotEmpty ? _s(bpr['code'] ?? bpr['bpr_id'] ?? bpr['id']) : fallbackBprId;
    return KantorModel(
      id: _intId(json['id']),
      uuid: _s(json['id']),
      kodePt: bprId,
      kodeKantor: _s(json['branch_code'] ?? json['kode_kantor'] ?? json['code']),
      kodeInduk: _s(json['parent_branch_code'] ?? json['parent_code'] ?? json['branch_parent_code'] ?? json['kode_induk']),
      namaKantor: _s(json['name'] ?? json['nama_kantor'] ?? json['nama']),
      statusKantor: _statusKantor(json['branch_type'] ?? json['status_kantor']),
      alamat: _s(json['address'] ?? json['alamat']),
      kelurahan: _s(json['kelurahan'] ?? json['village']),
      kecamatan: _s(json['kecamatan'] ?? json['district']),
      kota: _s(json['kota'] ?? json['city']),
      provinsi: _s(json['provinsi'] ?? json['province']),
      kodePos: _s(json['kode_pos'] ?? json['postal_code']),
      telp: json['phone'] ?? json['telp'] ?? '',
      fax: json['fax'] ?? json['nomor_fax'] ?? '',
      statusAktif: 'A',
      statusData: 'A',
      pimpinanCabang: _s(json['pimpinan_cabang'] ?? json['branch_leader']),
      managerOperasional: _s(json['manager_operasional'] ?? json['operation_manager']),
      managerMarketing: _s(json['manager_marketing'] ?? json['marketing_manager']),
      kodeKantorBi: _s(json['kode_kantor_bi'] ?? json['kode_bi'] ?? json['bi_code'] ?? json['branch_bi_code']),
    );
  }

  Map<String, dynamic> toOfficePayload() => {
        'kode_kantor': kodeKantor.trim(),
        'nama_kantor': namaKantor.trim(),
        'status_kantor': statusKantorCore,
        'status_aktif': statusAktif.trim().isEmpty ? 'A' : statusAktif.trim(),
        'kode_induk': kodeInduk.trim(),
        'alamat': alamat.trim(),
        'kelurahan': kelurahan.trim(),
        'kecamatan': kecamatan.trim(),
        'kota': kota.trim(),
        'provinsi': provinsi.trim(),
        'kode_pos': kodePos.trim(),
        'kode_kantor_bi': kodeKantorBi.trim(),
        'bpr_id': kodePt.trim(),
        'telp': _s(telp).trim(),
        'nomor_fax': _s(fax).trim(),
        'pimpinan_cabang': pimpinanCabang.trim(),
        'manager_operasional': managerOperasional.trim(),
        'manager_marketing': managerMarketing.trim(),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'kode_pt': kodePt,
        'bpr_id': kodePt,
        'kode_kantor': kodeKantor,
        'kode_induk': kodeInduk,
        'nama_kantor': namaKantor,
        'status_kantor': statusKantor,
        'alamat': alamat,
        'kelurahan': kelurahan,
        'kecamatan': kecamatan,
        'kota': kota,
        'provinsi': provinsi,
        'kode_pos': kodePos,
        'kode_kantor_bi': kodeKantorBi,
        'telp': telp,
        'nomor_fax': fax,
        'status_aktif': statusAktif,
        'status_data': statusData,
        'pimpinan_cabang': pimpinanCabang,
        'manager_operasional': managerOperasional,
        'manager_marketing': managerMarketing,
      };

  KantorModel clone() => copyWith();

  KantorModel copyWith({
    int? id,
    String? kodePt,
    String? kodeKantor,
    String? kodeInduk,
    String? namaKantor,
    String? statusKantor,
    String? alamat,
    String? kelurahan,
    String? kecamatan,
    String? kota,
    String? provinsi,
    String? kodePos,
    dynamic telp,
    dynamic fax,
    String? statusAktif,
    String? statusData,
    String? uuid,
    String? pimpinanCabang,
    String? managerOperasional,
    String? managerMarketing,
    String? kodeKantorBi,
  }) =>
      KantorModel(
        id: id ?? this.id,
        kodePt: kodePt ?? this.kodePt,
        kodeKantor: kodeKantor ?? this.kodeKantor,
        kodeInduk: kodeInduk ?? this.kodeInduk,
        namaKantor: namaKantor ?? this.namaKantor,
        statusKantor: statusKantor ?? this.statusKantor,
        alamat: alamat ?? this.alamat,
        kelurahan: kelurahan ?? this.kelurahan,
        kecamatan: kecamatan ?? this.kecamatan,
        kota: kota ?? this.kota,
        provinsi: provinsi ?? this.provinsi,
        kodePos: kodePos ?? this.kodePos,
        telp: telp ?? this.telp,
        fax: fax ?? this.fax,
        statusAktif: statusAktif ?? this.statusAktif,
        statusData: statusData ?? this.statusData,
        uuid: uuid ?? this.uuid,
        pimpinanCabang: pimpinanCabang ?? this.pimpinanCabang,
        managerOperasional: managerOperasional ?? this.managerOperasional,
        managerMarketing: managerMarketing ?? this.managerMarketing,
        kodeKantorBi: kodeKantorBi ?? this.kodeKantorBi,
      );

  @override
  bool operator ==(Object other) => identical(this, other) || other is KantorModel && kodeKantor == other.kodeKantor && kodePt == other.kodePt;

  @override
  int get hashCode => Object.hash(kodeKantor, kodePt);
}
