class CoreUserModel {
  final int? id;
  final String userid;
  final String namauser;
  final String kodeKantor;
  final String bprId;
  final String tglExpired;
  final bool isActive;
  final bool isSuperAdmin;
  final int wrongPasswordCount;
  final bool isLocked;
  final String hrisEmployeeId;
  final String hrisEmployeeNo;
  final String hrisEmployeeName;
  final String lastLoginAt;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;

  const CoreUserModel({
    this.id,
    required this.userid,
    required this.namauser,
    required this.kodeKantor,
    required this.bprId,
    required this.tglExpired,
    required this.isActive,
    required this.isSuperAdmin,
    required this.wrongPasswordCount,
    required this.isLocked,
    required this.hrisEmployeeId,
    required this.hrisEmployeeNo,
    required this.hrisEmployeeName,
    required this.lastLoginAt,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory CoreUserModel.empty() {
    return const CoreUserModel(
      id: null,
      userid: '',
      namauser: '',
      kodeKantor: '',
      bprId: '',
      tglExpired: '',
      isActive: true,
      isSuperAdmin: false,
      wrongPasswordCount: 0,
      isLocked: false,
      hrisEmployeeId: '',
      hrisEmployeeNo: '',
      hrisEmployeeName: '',
      lastLoginAt: '',
      createdAt: '',
      createdBy: '',
      updatedAt: '',
      updatedBy: '',
    );
  }

  factory CoreUserModel.fromJson(Map<String, dynamic> json) {
    return CoreUserModel(
      id: _toIntNullable(json['id']),
      userid: (json['userid'] ?? json['users_id'] ?? '').toString(),
      namauser: (json['namauser'] ?? json['nama_users'] ?? '').toString(),
      kodeKantor: (json['kode_kantor'] ?? json['kdkantor'] ?? json['kd_kantor'] ?? '').toString(),
      bprId: (json['bpr_id'] ?? json['bprid'] ?? '').toString(),
      tglExpired: _dateToString(json['tgl_expired'] ?? json['tglexp']),
      isActive: _toBool(json['is_active'] ?? json['status_aktif'], defaultValue: true),
      isSuperAdmin: _toBool(json['is_super_admin']),
      wrongPasswordCount: _toInt(json['wrong_password_count'], 0),
      isLocked: _toBool(json['is_locked']),
      hrisEmployeeId: (json['hris_employee_id'] ?? json['employee_id'] ?? '').toString(),
      hrisEmployeeNo: (json['employee_no'] ?? json['hris_employee_no'] ?? json['nomor_employee'] ?? json['nomor_employe'] ?? '').toString(),
      hrisEmployeeName: (json['hris_employee_name'] ?? json['employee_name'] ?? '').toString(),
      lastLoginAt: _dateToString(json['last_login_at']),
      createdAt: _dateToString(json['created_at']),
      createdBy: (json['created_by'] ?? '').toString(),
      updatedAt: _dateToString(json['updated_at']),
      updatedBy: (json['updated_by'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userid': userid,
        'namauser': namauser,
        'kode_kantor': kodeKantor,
        'bpr_id': bprId,
        'tgl_expired': tglExpired,
        'is_active': isActive,
        'is_super_admin': isSuperAdmin,
        'wrong_password_count': wrongPasswordCount,
        'is_locked': isLocked,
        'hris_employee_id': hrisEmployeeId,
        'employee_no': hrisEmployeeNo,
        'hris_employee_name': hrisEmployeeName,
        'last_login_at': lastLoginAt,
        'created_at': createdAt,
        'created_by': createdBy,
        'updated_at': updatedAt,
        'updated_by': updatedBy,
      };

  CoreUserModel copyWith({
    int? id,
    String? userid,
    String? namauser,
    String? kodeKantor,
    String? bprId,
    String? tglExpired,
    bool? isActive,
    bool? isSuperAdmin,
    int? wrongPasswordCount,
    bool? isLocked,
    String? hrisEmployeeId,
    String? hrisEmployeeNo,
    String? hrisEmployeeName,
    String? lastLoginAt,
    String? createdAt,
    String? createdBy,
    String? updatedAt,
    String? updatedBy,
  }) {
    return CoreUserModel(
      id: id ?? this.id,
      userid: userid ?? this.userid,
      namauser: namauser ?? this.namauser,
      kodeKantor: kodeKantor ?? this.kodeKantor,
      bprId: bprId ?? this.bprId,
      tglExpired: tglExpired ?? this.tglExpired,
      isActive: isActive ?? this.isActive,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      wrongPasswordCount: wrongPasswordCount ?? this.wrongPasswordCount,
      isLocked: isLocked ?? this.isLocked,
      hrisEmployeeId: hrisEmployeeId ?? this.hrisEmployeeId,
      hrisEmployeeNo: hrisEmployeeNo ?? this.hrisEmployeeNo,
      hrisEmployeeName: hrisEmployeeName ?? this.hrisEmployeeName,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return defaultValue;
    return text == 'true' || text == '1' || text == 'y' || text == 'yes' || text == 'a' || text == 'aktif' || text == 'active';
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _dateToString(dynamic value) {
    if (value == null) return '';
    final raw = value.toString();
    if (raw == '<nil>') return '';
    return raw;
  }
}
