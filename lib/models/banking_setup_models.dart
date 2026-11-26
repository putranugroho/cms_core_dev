import 'package:cms_core/models/new_menu_models.dart';

class BankingPage<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  const BankingPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });
  bool get hasNext => page * limit < total;
}

class PartyGroupModel {
  final Map<String, dynamic> raw;
  const PartyGroupModel(this.raw);
  String get kode => bankingText(raw['kode_kelompok']);
  String get nama => bankingText(raw['nama_kelompok']);
  String get nomorSbb => bankingText(raw['nomor_sbb']);
  String get namaSbb => bankingText(raw['nama_sbb']);
}

class ThirdPartyModel {
  final Map<String, dynamic> raw;
  const ThirdPartyModel(this.raw);
  String get kode => bankingText(raw['kode_pihak_ketiga']);
  String get nama => bankingText(raw['nama_perusahaan']);
  String get kodeKelompok => bankingText(raw['kode_kelompok']);
  String get namaKelompok => bankingText(raw['nama_kelompok']);
  String get namaBank => bankingText(raw['nama_bank']);
  String field(String key) => bankingText(raw[key]);
}

String bankingText(dynamic value) =>
    value == null ? '' : value.toString().trim();

const partyInputKeys = <String>[
  'kode_pihak_ketiga',
  'kode_kelompok',
  'nama_perusahaan',
  'alamat',
  'kelurahan',
  'kecamatan',
  'kota',
  'provinsi',
  'kode_pos',
  'npwp',
  'no_telp',
  'email',
  'sandi_bank',
  'nomor_rekening',
  'nama_pic_1',
  'jabatan_1',
  'no_hp_1',
  'email_1',
  'nama_pic_2',
  'jabatan_2',
  'no_hp_2',
  'email_2',
];

String? validateBankingCode(String? value, int digits) =>
    RegExp('^[0-9]{$digits}\$').hasMatch(value ?? '')
    ? null
    : 'Isi tepat $digits digit angka';

String? validateBankingEmail(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
      ? null
      : 'Format email tidak valid';
}

String bankingDate(String value) =>
    value.length >= 10 ? value.substring(0, 10) : value;

bool abaIsDraft(AbaModel value) => value.statusRekening.toUpperCase() == 'N';

// Nominal and ARO are editable; maturity and session office remain server-owned.
Map<String, dynamic> abaFormPayload({
  required String nomorRekening,
  required String nomorSbb,
  required String jenis,
  required String namaBank,
  required String sandiBank,
  required String tanggalBuka,
  required int tenor,
  required String tenorUnit,
  required double rate,
  double nominal = 0,
  String aro = 'N',
  AbaModel? original,
}) => {
  'nomor_rekening': nomorRekening.trim(),
  'nomor_sbb': nomorSbb.trim(),
  'jenis_rekening': jenis,
  'nama_bank': namaBank.trim(),
  'sandi_bank': sandiBank.trim(),
  'tanggal_buka': tanggalBuka.trim(),
  'jangka_waktu': jenis == 'D' ? tenor : 0,
  'jenis_jangka_waktu': jenis == 'D' ? tenorUnit : '',
  'suku_bunga': jenis == 'D' ? rate : 0.0,
  if (jenis == 'D') 'nominal': nominal,
  if (jenis == 'D') 'aro': aro,
  'terkait': original?.terkait ?? false,
  'coll': original?.coll ?? 'LANCAR',
  'ppap': original?.ppap ?? 0.0,
};

Map<String, dynamic> partyGroupFormPayload(Map<String, String> fields) => {
  for (final key in ['kode_kelompok', 'nama_kelompok', 'nomor_sbb'])
    key: (fields[key] ?? '').trim(),
};

Map<String, dynamic> thirdPartyFormPayload(Map<String, String> fields) => {
  for (final key in partyInputKeys) key: (fields[key] ?? '').trim(),
};

ThirdPartyModel mitraFormModel(Map<String, dynamic> raw) => ThirdPartyModel({
  ...raw,
  'kode_pihak_ketiga': raw['kode_mitra'] ?? raw['kode_pihak_ketiga'],
  'nama_perusahaan': raw['nama_mitra'] ?? raw['nama_perusahaan'],
  'kode_kelompok': raw['kelompok'] ?? raw['kode_kelompok'],
  'nama_pic_1': raw['nama_pic'] ?? raw['nama_pic_1'],
  'no_hp_1': raw['nomor_hp_pic'] ?? raw['no_hp_1'],
  'no_telp': raw['nomor_telp_pic'] ?? raw['no_telp'],
  'sandi_bank': raw['bank_rekening'] ?? raw['sandi_bank'],
});

Map<String, dynamic> mitraFormPayload(Map<String, dynamic> body) {
  final result = Map<String, dynamic>.from(body);
  const aliases = {
    'kode_pihak_ketiga': 'kode_mitra', 'nama_perusahaan': 'nama_mitra',
    'kode_kelompok': 'kelompok', 'nama_pic_1': 'nama_pic',
    'no_hp_1': 'nomor_hp_pic', 'no_telp': 'nomor_telp_pic',
    'sandi_bank': 'bank_rekening',
  };
  for (final entry in aliases.entries) {
    result[entry.value] = result.remove(entry.key);
  }
  return result;
}
