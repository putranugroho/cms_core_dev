class SandiModel {
  final String id;
  final String group;
  final String kode;
  final String nama;
  final bool pavorit;
  final String status;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;

  const SandiModel({
    required this.id,
    required this.group,
    required this.kode,
    required this.nama,
    required this.pavorit,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory SandiModel.empty() {
    return const SandiModel(
      id: '',
      group: '',
      kode: '',
      nama: '',
      pavorit: false,
      status: 'A',
      createdAt: '',
      createdBy: '',
      updatedAt: '',
      updatedBy: '',
    );
  }

  factory SandiModel.fromJson(Map<String, dynamic> json) {
    return SandiModel(
      id: (json['id'] ?? '').toString(),
      group: (json['group'] ?? '').toString(),
      kode: (json['kode'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      pavorit: _toBool(json['pavorit'] ?? json['favorit']),
      status: (json['status'] ?? 'A').toString(),
      createdAt: _dateToString(json['created_at']),
      createdBy: (json['created_by'] ?? '').toString(),
      updatedAt: _dateToString(json['updated_at']),
      updatedBy: (json['updated_by'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group': group,
        'kode': kode,
        'nama': nama,
        'pavorit': pavorit,
        'status': status,
        'created_at': createdAt,
        'created_by': createdBy,
        'updated_at': updatedAt,
        'updated_by': updatedBy,
      };

  String get statusText {
    switch (status.toUpperCase()) {
      case 'A':
        return 'Aktif';
      case 'D':
        return 'Hapus';
      default:
        return status;
    }
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'y' || text == 'yes';
  }

  static String _dateToString(dynamic value) {
    if (value == null) return '';
    final raw = value.toString();
    if (raw == '<nil>' || raw.toLowerCase() == 'null') return '';
    return raw;
  }
}

class SandiGroupModel {
  final String id;
  final String group;
  final String nama;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;

  const SandiGroupModel({
    required this.id,
    required this.group,
    required this.nama,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory SandiGroupModel.fromJson(Map<String, dynamic> json) {
    return SandiGroupModel(
      id: (json['id'] ?? '').toString(),
      group: (json['group'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      createdAt: _dateToString(json['created_at']),
      createdBy: (json['created_by'] ?? '').toString(),
      updatedAt: _dateToString(json['updated_at']),
      updatedBy: (json['updated_by'] ?? '').toString(),
    );
  }

  static String _dateToString(dynamic value) {
    if (value == null) return '';
    final raw = value.toString();
    if (raw == '<nil>' || raw.toLowerCase() == 'null') return '';
    return raw;
  }
}
