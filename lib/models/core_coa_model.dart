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
    this.hutang = 'N',
    this.piutang = 'N',
    this.akunPerantara = 'N',
    this.sbbKhusus = 'N',
    this.labarugiBerjalan = 'N',
    this.labarugiTahunLalu = 'N',
    this.isDeleted = 'N',
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

  // Legacy ACT/MTD flags. These are optional in the new core endpoint, but
  // the CMS-Core GL screen still needs to display and submit them for
  // compatibility with the ACT-style COA form.
  final String hutang;
  final String piutang;
  final String akunPerantara;
  final String sbbKhusus;
  final String labarugiBerjalan;
  final String labarugiTahunLalu;
  final String isDeleted;

  static String _s(dynamic value) => value?.toString() ?? '';

  static int? _i(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String _yn(dynamic value) {
    final text = (value ?? '').toString().trim().toUpperCase();
    if (text == 'Y' || text == 'YES' || text == 'TRUE' || text == '1') return 'Y';
    return 'N';
  }

  static int? _tipeFromText(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    switch (text) {
      case '1':
      case 'aktiva':
        return 1;
      case '2':
      case 'pasiva':
        return 2;
      case '3':
      case 'pendapatan':
        return 3;
      case '4':
      case 'biaya':
        return 4;
      case '5':
      case 'pos adm debet':
      case 'pos administrative':
      case 'pos administrasi':
        return 5;
      case '6':
      case 'pos adm kredit':
        return 6;
      default:
        return _i(value);
    }
  }

  static int? _levelFromText(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    switch (text) {
      case '1':
      case 'header':
        return 1;
      case '2':
      case 'buku besar':
        return 2;
      case '3':
      case 'sub buku besar':
        return 3;
      default:
        return _i(value);
    }
  }

  static String _deriveParent(String kodeCoa, int? level, dynamic rawParent) {
    final parent = _s(rawParent).trim();
    if (parent.isNotEmpty && parent.toLowerCase() != 'null') return parent;

    final code = kodeCoa.trim();
    if (code.length < 12) return '';
    if (level == 2) return '${code.substring(0, 3)}000000000';
    if (level == 3) return '${code.substring(0, 6)}000000';
    return '';
  }

  static String tipeText(int? value) {
    switch (value) {
      case 1:
        return 'Aktiva';
      case 2:
        return 'Pasiva';
      case 3:
        return 'Pendapatan';
      case 4:
        return 'Biaya';
      case 5:
        return 'Pos Adm Debet';
      case 6:
        return 'Pos Adm Kredit';
      default:
        return '-';
    }
  }

  static String levelText(int? value) {
    switch (value) {
      case 1:
        return 'Header';
      case 2:
        return 'Buku Besar';
      case 3:
        return 'Sub Buku Besar';
      default:
        return '-';
    }
  }

  String get tipeCoaText => tipeText(tipeCoa);
  String get levelCoaText => levelText(levelCoa);

  String get postingYN {
    final text = postingType.trim().toUpperCase();
    if (text == 'I' || text == 'Y' || text == 'INTERAKTIF') return 'Y';
    return 'N';
  }

  String get nonaktifYN {
    if (statusData.trim().toUpperCase() == 'D') return 'Y';
    return _yn(isDeleted);
  }

  String get labaRugiText {
    if (labarugiBerjalan == 'Y') return 'Berjalan';
    if (labarugiTahunLalu == 'Y') return 'Tahun Lalu';
    return '-';
  }

  factory CoreCoaModel.fromJson(Map<String, dynamic> json) {
    final kodeCoa = _s(json['kode_coa'] ?? json['nosbb'] ?? json['no_coa']).trim();
    final namaCoa = _s(json['nama_coa'] ?? json['nama_sbb'] ?? json['namasbb']).trim();
    final tipe = _tipeFromText(json['tipe_coa'] ?? json['gol_acc'] ?? json['golongan']);
    final level = _levelFromText(json['level_coa'] ?? json['jns_acc'] ?? json['jenis_akun']);
    final isDeleted = _yn(json['is_deleted']);
    final status = _s(json['status_data']).trim();

    return CoreCoaModel(
      id: _s(json['id']),
      kodeCoa: kodeCoa,
      namaCoa: namaCoa,
      tipeCoa: tipe,
      levelCoa: level,
      parentCoa: _deriveParent(kodeCoa, level, json['parent_coa']),
      postingType: _s(json['posting_type'] ?? json['type_posting']).trim(),
      specialType: _s(json['special_type'] ?? json['sbb_khusus']).trim(),
      ojkCode: _s(json['ojk_code']),
      statusData: status.isNotEmpty ? status : (isDeleted == 'Y' ? 'D' : 'A'),
      createdAt: _s(json['created_at'] ?? json['createddate']),
      createdBy: _s(json['created_by']),
      updatedAt: _s(json['updated_at']),
      updatedBy: _s(json['updated_by']),
      hutang: _yn(json['hutang']),
      piutang: _yn(json['piutang']),
      akunPerantara: _yn(json['perantara'] ?? json['akun_perantara']),
      sbbKhusus: _yn(json['sbb_khusus'] ?? json['special_type']),
      labarugiBerjalan: _yn(json['labarugi_berjalan']),
      labarugiTahunLalu: _yn(json['labarugi_tahun_lalu']),
      isDeleted: isDeleted,
    );
  }
}
