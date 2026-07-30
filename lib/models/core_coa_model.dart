class CoreCoaModel {
  CoreCoaModel({
    required this.id,
    required this.kodeCoa,
    required this.namaCoa,
    required this.tipeCoa,
    required this.levelCoa,
    required this.parentCoa,
    required this.postingType,
    required this.specialType,
    required this.ojkCode,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  final String id;
  final String kodeCoa;
  final String namaCoa;
  final int? tipeCoa;
  final int? levelCoa;
  final String parentCoa;
  final String postingType;
  final String specialType;
  final String ojkCode;
  final String statusData;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;

  static String _s(dynamic value) => value?.toString() ?? '';
  static int? _i(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  factory CoreCoaModel.fromJson(Map<String, dynamic> json) => CoreCoaModel(
        id: _s(json['id']),
        kodeCoa: _s(json['kode_coa']),
        namaCoa: _s(json['nama_coa']),
        tipeCoa: _i(json['tipe_coa']),
        levelCoa: _i(json['level_coa']),
        parentCoa: _s(json['parent_coa']),
        postingType: _s(json['posting_type']),
        specialType: _s(json['special_type']),
        ojkCode: _s(json['ojk_code']),
        statusData: _s(json['status_data']),
        createdAt: _s(json['created_at']),
        createdBy: _s(json['created_by']),
        updatedAt: _s(json['updated_at']),
        updatedBy: _s(json['updated_by']),
      );
}
