import 'package:flutter/foundation.dart';

@immutable
class CoaModel {
  const CoaModel({
    required this.id,
    required this.golAcc,
    required this.jnsAcc,
    required this.nobb,
    required this.nosbb,
    required this.namaSbb,
    required this.typePosting,
    required this.sbbKhusus,
    required this.createddate,
    required this.isDeleted,
    required this.kodePt,
    required this.kodeKantor,
    required this.limitDebet,
    required this.limitKredit,
    required this.akunPerantara,
    required this.hutang,
    required this.piutang,
  });

  final int id;
  final String golAcc;
  final String jnsAcc;
  final String nobb;
  final String nosbb;
  final String namaSbb;
  final String typePosting;
  final String sbbKhusus;
  final String createddate;
  final String isDeleted;
  final String kodePt;
  final String kodeKantor;
  final String limitDebet;
  final String limitKredit;
  final String akunPerantara;
  final String hutang;
  final String piutang;

  static String _s(dynamic value, [String def = '']) => value == null ? def : value.toString();
  static int _id(dynamic value) => int.tryParse(_s(value)) ?? 0;
  static int _i(dynamic value, [int def = 0]) => int.tryParse(_s(value)) ?? def;

  static String _legacyType(dynamic tipeCoa, dynamic golAcc) {
    final old = _s(golAcc);
    if (old.isNotEmpty && old != 'null') return old;
    final value = _i(tipeCoa);
    if (value <= 0) return '1';
    return value.toString();
  }

  static String _legacyLevel(dynamic levelCoa, dynamic jnsAcc) {
    final old = _s(jnsAcc);
    if (old == 'A' || old == 'B' || old == 'C') return old;
    switch (_i(levelCoa, 3)) {
      case 1:
        return 'A';
      case 2:
        return 'B';
      default:
        return 'C';
    }
  }

  factory CoaModel.fromJson(Map<String, dynamic> json) {
    final kodeCoa = _s(json['kode_coa'], _s(json['nosbb']));
    final level = _legacyLevel(json['level_coa'], json['jns_acc']);
    final parent = _s(json['parent_coa'], _s(json['nobb']));
    final nobbValue = level == 'A' ? _s(json['nobb'], kodeCoa) : (parent.isEmpty ? _s(json['nobb']) : parent);

    return CoaModel(
      id: _id(json['id']),
      golAcc: _legacyType(json['tipe_coa'], json['gol_acc']),
      jnsAcc: level,
      nobb: nobbValue,
      nosbb: kodeCoa,
      namaSbb: _s(json['nama_coa'], _s(json['nama_sbb'])),
      typePosting: _s(json['posting_type'], _s(json['type_posting'], 'I')),
      sbbKhusus: _s(json['special_type'], _s(json['sbb_khusus'])),
      createddate: _s(json['created_at'], _s(json['createddate'])),
      isDeleted: _s(json['is_deleted'], _s(json['status_data']) == 'D' ? 'Y' : 'N'),
      kodePt: _s(json['kode_pt'], '001'),
      kodeKantor: _s(json['kode_kantor'], '001'),
      limitDebet: _s(json['limit_debet'], '0'),
      limitKredit: _s(json['limit_kredit'], '0'),
      akunPerantara: _s(json['akun_perantara'], 'N'),
      hutang: _s(json['hutang'], 'N'),
      piutang: _s(json['piutang'], 'N'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gol_acc': golAcc,
        'jns_acc': jnsAcc,
        'nobb': nobb,
        'nosbb': nosbb,
        'nama_sbb': namaSbb,
        'type_posting': typePosting,
        'sbb_khusus': sbbKhusus,
        'createddate': createddate,
        'is_deleted': isDeleted,
        'kode_pt': kodePt,
        'kode_kantor': kodeKantor,
        'limit_debet': limitDebet,
        'limit_kredit': limitKredit,
        'akun_perantara': akunPerantara,
        'hutang': hutang,
        'piutang': piutang,
        'kode_coa': nosbb,
        'nama_coa': namaSbb,
        'tipe_coa': int.tryParse(golAcc),
        'level_coa': jnsAcc == 'A' ? 1 : jnsAcc == 'B' ? 2 : 3,
        'parent_coa': jnsAcc == 'A' ? '' : nobb,
        'posting_type': typePosting,
        'special_type': sbbKhusus,
      };

  CoaModel copyWith({
    int? id,
    String? golAcc,
    String? jnsAcc,
    String? nobb,
    String? nosbb,
    String? namaSbb,
    String? typePosting,
    String? sbbKhusus,
    String? createddate,
    String? isDeleted,
    String? kodePt,
    String? kodeKantor,
    String? limitDebet,
    String? limitKredit,
    String? akunPerantara,
    String? hutang,
    String? piutang,
  }) =>
      CoaModel(
        id: id ?? this.id,
        golAcc: golAcc ?? this.golAcc,
        jnsAcc: jnsAcc ?? this.jnsAcc,
        nobb: nobb ?? this.nobb,
        nosbb: nosbb ?? this.nosbb,
        namaSbb: namaSbb ?? this.namaSbb,
        typePosting: typePosting ?? this.typePosting,
        sbbKhusus: sbbKhusus ?? this.sbbKhusus,
        createddate: createddate ?? this.createddate,
        isDeleted: isDeleted ?? this.isDeleted,
        kodePt: kodePt ?? this.kodePt,
        kodeKantor: kodeKantor ?? this.kodeKantor,
        limitDebet: limitDebet ?? this.limitDebet,
        limitKredit: limitKredit ?? this.limitKredit,
        akunPerantara: akunPerantara ?? this.akunPerantara,
        hutang: hutang ?? this.hutang,
        piutang: piutang ?? this.piutang,
      );
}
