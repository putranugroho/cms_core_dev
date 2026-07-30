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

  static int _intId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    final parsed = int.tryParse(value.toString());
    if (parsed != null) return parsed;
    return value.toString().hashCode.abs();
  }

  static String _s(dynamic value) => value?.toString() ?? '';

  static String _statusKantor(dynamic value) {
    final v = value?.toString() ?? '';
    if (v == '1') return 'P';
    if (v == '2') return 'C';
    if (v == '3') return 'D';
    if (v == '4') return 'E';
    return v;
  }

  int get statusKantorCore {
    if (statusKantor == 'P') return 1;
    if (statusKantor == 'C') return 2;
    if (statusKantor == 'D') return 3;
    if (statusKantor == 'E') return 4;
    return int.tryParse(statusKantor) ?? 2;
  }

  String get namaStatusKantor {
    if (statusKantor == 'P' || statusKantor == '1') return 'Pusat';
    if (statusKantor == 'C' || statusKantor == '2') return 'Cabang';
    if (statusKantor == 'D' || statusKantor == '3') return 'Anak Cabang';
    if (statusKantor == 'E' || statusKantor == '4') return 'Outlet/Gudang';
    return statusKantor;
  }

  factory KantorModel.fromJson(Map<String, dynamic> json) => KantorModel(
        id: _intId(json['id']),
        uuid: _s(json['id']),
        kodePt: _s(json['kode_pt'] ?? json['bprid']),
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
        fax: json['fax'] ?? json['nomor_fax'] ?? '',
        statusAktif: _s(json['status_aktif']),
        statusData: _s(json['status_data']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kode_pt': kodePt,
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
        'telp': telp,
        'fax': fax,
        'status_aktif': statusAktif,
        'status_data': statusData,
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
      );

  @override
  bool operator ==(Object other) => identical(this, other) || other is KantorModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
