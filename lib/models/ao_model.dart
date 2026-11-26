class AoModel {
  final String id;
  final String kodeAo;
  final String nomorEmployee;
  final String namaAo;
  final String noHp;
  final int roleAo;
  final String roleAoTxt;
  final String kodeKantor;
  final String statusData;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;
  final String deletedAt;
  final String deletedBy;

  const AoModel({
    required this.id,
    required this.kodeAo,
    required this.nomorEmployee,
    required this.namaAo,
    required this.noHp,
    required this.roleAo,
    required this.roleAoTxt,
    required this.kodeKantor,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.deletedAt,
    required this.deletedBy,
  });

  factory AoModel.empty() {
    return const AoModel(
      id: '',
      kodeAo: '',
      nomorEmployee: '',
      namaAo: '',
      noHp: '',
      roleAo: 1,
      roleAoTxt: 'MARKETING',
      kodeKantor: '',
      statusData: 'A',
      createdAt: '',
      createdBy: '',
      updatedAt: '',
      updatedBy: '',
      deletedAt: '',
      deletedBy: '',
    );
  }

  factory AoModel.fromJson(Map<String, dynamic> json) {
    final role = _toInt(json['role_ao'], 1);
    return AoModel(
      id: (json['id'] ?? '').toString(),
      kodeAo: (json['kode_ao'] ?? json['kode'] ?? '').toString(),
      nomorEmployee: (json['nomor_employee'] ?? json['nomor_employe'] ?? json['employee_no'] ?? json['no_employee'] ?? '').toString(),
      namaAo: (json['nama_ao'] ?? json['nama'] ?? '').toString(),
      noHp: (json['no_hp'] ?? json['nohp'] ?? json['phone'] ?? '').toString(),
      roleAo: role,
      roleAoTxt: (json['role_ao_txt'] ?? _roleText(role)).toString(),
      kodeKantor: (json['kode_kantor'] ?? json['kd_kantor'] ?? '').toString(),
      statusData: (json['status_data'] ?? 'A').toString(),
      createdAt: _dateToString(json['created_at']),
      createdBy: (json['created_by'] ?? '').toString(),
      updatedAt: _dateToString(json['updated_at']),
      updatedBy: (json['updated_by'] ?? '').toString(),
      deletedAt: _dateToString(json['deleted_at']),
      deletedBy: (json['deleted_by'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kode_ao': kodeAo,
        'nomor_employee': nomorEmployee,
        'nama_ao': namaAo,
        'no_hp': noHp,
        'role_ao': roleAo,
        'role_ao_txt': roleAoTxt,
        'kode_kantor': kodeKantor,
        'status_data': statusData,
        'created_at': createdAt,
        'created_by': createdBy,
        'updated_at': updatedAt,
        'updated_by': updatedBy,
        'deleted_at': deletedAt,
        'deleted_by': deletedBy,
      };

  AoModel copyWith({
    String? id,
    String? kodeAo,
    String? nomorEmployee,
    String? namaAo,
    String? noHp,
    int? roleAo,
    String? roleAoTxt,
    String? kodeKantor,
    String? statusData,
    String? createdAt,
    String? createdBy,
    String? updatedAt,
    String? updatedBy,
    String? deletedAt,
    String? deletedBy,
  }) {
    final nextRole = roleAo ?? this.roleAo;
    return AoModel(
      id: id ?? this.id,
      kodeAo: kodeAo ?? this.kodeAo,
      nomorEmployee: nomorEmployee ?? this.nomorEmployee,
      namaAo: namaAo ?? this.namaAo,
      noHp: noHp ?? this.noHp,
      roleAo: nextRole,
      roleAoTxt: roleAoTxt ?? (roleAo == null ? this.roleAoTxt : _roleText(nextRole)),
      kodeKantor: kodeKantor ?? this.kodeKantor,
      statusData: statusData ?? this.statusData,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  String get statusText {
    switch (statusData.toUpperCase()) {
      case 'A':
        return 'Aktif';
      case 'N':
        return 'Belum Aktif';
      case 'C':
        return 'Tutup';
      case 'D':
        return 'Hapus';
      case 'B':
        return 'Blokir';
      default:
        return statusData;
    }
  }

  static String _roleText(int role) {
    switch (role) {
      case 1:
        return 'MARKETING';
      case 2:
        return 'COLLECTOR';
      case 3:
        return 'MARKETING & COLLECTOR';
      default:
        return role.toString();
    }
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static String _dateToString(dynamic value) {
    if (value == null) return '';
    final raw = value.toString();
    if (raw == '<nil>') return '';
    return raw;
  }
}
