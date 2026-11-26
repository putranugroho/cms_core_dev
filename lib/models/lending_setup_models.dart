
class LendingValue {
  static String text(dynamic value) => (value ?? '').toString();

  static double toDouble(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().replaceAll(',', '.')) ?? fallback;
  }

  static bool toBool(dynamic value, [bool fallback = false]) {
    if (value is bool) return value;
    final raw = (value ?? '').toString().trim().toLowerCase();
    if (raw == 'true' || raw == '1' || raw == 'y' || raw == 'yes') return true;
    if (raw == 'false' || raw == '0' || raw == 'n' || raw == 'no') return false;
    return fallback;
  }

  static String statusText(String code) {
    switch (code.toUpperCase()) {
      case 'A':
        return 'Aktif';
      case 'D':
        return 'Hapus';
      default:
        return code.isEmpty ? '-' : code;
    }
  }
}

class AgunanSetupModel {
  final String id;
  final String kodeAgunan;
  final String keterangan;
  final double bobotPengurang;
  final String kategori;
  final String statusData;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;

  const AgunanSetupModel({
    required this.id,
    required this.kodeAgunan,
    required this.keterangan,
    required this.bobotPengurang,
    this.kategori = '',
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory AgunanSetupModel.fromJson(Map<String, dynamic> json) => AgunanSetupModel(
        id: LendingValue.text(json['id']),
        kodeAgunan: LendingValue.text(json['kode_agunan']),
        keterangan: LendingValue.text(json['keterangan']),
        bobotPengurang: LendingValue.toDouble(json['bobot_pengurang']),
        kategori: LendingValue.text(json['kategori']),
        statusData: LendingValue.text(json['status_data']),
        createdAt: LendingValue.text(json['created_at']),
        createdBy: LendingValue.text(json['created_by']),
        updatedAt: LendingValue.text(json['updated_at']),
        updatedBy: LendingValue.text(json['updated_by']),
      );
}

class BobotPpapModel {
  final String id;
  final String coll;
  final double bobot;
  final double bdr;
  final bool faktorPengurang;
  final String statusData;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;

  const BobotPpapModel({
    required this.id,
    required this.coll,
    required this.bobot,
    required this.bdr,
    required this.faktorPengurang,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory BobotPpapModel.fromJson(Map<String, dynamic> json) => BobotPpapModel(
        id: LendingValue.text(json['id']),
        coll: LendingValue.text(json['coll']),
        bobot: LendingValue.toDouble(json['bobot']),
        bdr: LendingValue.toDouble(json['bdr']),
        faktorPengurang: LendingValue.toBool(json['faktor_pengurang']),
        statusData: LendingValue.text(json['status_data']),
        createdAt: LendingValue.text(json['created_at']),
        createdBy: LendingValue.text(json['created_by']),
        updatedAt: LendingValue.text(json['updated_at']),
        updatedBy: LendingValue.text(json['updated_by']),
      );
}

class RakRelasiModel {
  final String id;
  final String kodeKantor;
  final String kodeKantorLawan;
  final double rate;
  final String statusData;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;

  const RakRelasiModel({
    required this.id,
    required this.kodeKantor,
    required this.kodeKantorLawan,
    required this.rate,
    required this.statusData,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory RakRelasiModel.fromJson(Map<String, dynamic> json) => RakRelasiModel(
        id: LendingValue.text(json['id']),
        kodeKantor: LendingValue.text(json['kode_kantor']),
        kodeKantorLawan: LendingValue.text(json['kode_kantor_lawan']),
        rate: LendingValue.toDouble(json['rate']),
        statusData: LendingValue.text(json['status_data']),
        createdAt: LendingValue.text(json['created_at']),
        createdBy: LendingValue.text(json['created_by']),
        updatedAt: LendingValue.text(json['updated_at']),
        updatedBy: LendingValue.text(json['updated_by']),
      );
}
