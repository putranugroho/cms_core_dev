import 'dart:convert';

import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/repository/lending_setup_repository.dart';

/// Tipe isian yang dikenal form agunan (CSR frontend, lib/kategori-custom.ts).
const List<String> tipeFieldKategori = ['teks', 'angka', 'nominal', 'tanggal', 'dropdown', 'checkbox'];

const Map<String, String> labelTipeField = {
  'teks': 'Teks',
  'angka': 'Angka',
  'nominal': 'Nominal (Rp)',
  'tanggal': 'Tanggal',
  'dropdown': 'Pilihan (dropdown)',
  'checkbox': 'Checkbox (maks 4 pilihan)',
};

const int maksOpsiCheckbox = 4;

/// Kategori agunan disimpan di request-kategori dengan awalan kode ini,
/// karena tabelnya dipakai bersama modul lain.
const String awalanKategoriAgunan = 'AGN-';

/// Satu field_N. Disimpan sebagai JSON:
/// {"key","label","tipe","wajib","opsi","nonaktif"}.
/// Field yang dihapus tidak dibuang dari daftar, cukup [nonaktif] = true,
/// supaya nomor field_N (dan isian agunan lama yang memakainya) tidak bergeser.
class FieldKategori {
  String key;
  String label;
  String tipe;
  bool wajib;
  List<String> opsi;
  bool nonaktif;

  FieldKategori({
    required this.key,
    this.label = '',
    this.tipe = 'teks',
    this.wajib = false,
    List<String>? opsi,
    this.nonaktif = false,
  }) : opsi = opsi ?? [];

  bool get butuhOpsi => tipe == 'dropdown' || tipe == 'checkbox';

  factory FieldKategori.dariJson(dynamic raw, int nomor) {
    dynamic v = raw;
    if (v is String) {
      try {
        v = jsonDecode(v);
      } catch (_) {
        v = {'label': v};
      }
    }
    final m = v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    // Contoh Postman memakai "nama"; format kita memakai "label".
    final label = (m['label'] ?? m['nama'] ?? '').toString();
    final tipe = (m['tipe'] ?? 'teks').toString();
    return FieldKategori(
      key: (m['key'] ?? 'f$nomor').toString(),
      label: label,
      tipe: tipeFieldKategori.contains(tipe) ? tipe : 'teks',
      wajib: m['wajib'] == true,
      opsi: m['opsi'] is List ? (m['opsi'] as List).map((e) => e.toString()).toList() : [],
      nonaktif: m['nonaktif'] == true,
    );
  }

  Map<String, dynamic> keJson() => {
        'key': key,
        'label': label.trim(),
        'tipe': tipe,
        'wajib': wajib,
        if (butuhOpsi) 'opsi': opsi.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        if (nonaktif) 'nonaktif': true,
      };
}

class KategoriAgunanModel {
  final String kode; // kode lengkap, mis. AGN-MESIN
  final String nama;
  final int jumlahField;
  final String statusData;
  final String createdAt;
  final List<FieldKategori> fields;

  const KategoriAgunanModel({
    required this.kode,
    required this.nama,
    this.jumlahField = 0,
    this.statusData = 'A',
    this.createdAt = '',
    this.fields = const [],
  });

  String get kodePendek => kode.startsWith(awalanKategoriAgunan) ? kode.substring(awalanKategoriAgunan.length) : kode;

  factory KategoriAgunanModel.dariJson(Map<String, dynamic> j) {
    final fields = <FieldKategori>[];
    for (var n = 1; j.containsKey('field_$n'); n++) {
      fields.add(FieldKategori.dariJson(j['field_$n'], n));
    }
    return KategoriAgunanModel(
      kode: (j['kode_kategori'] ?? '').toString(),
      nama: (j['nama_kategori'] ?? '').toString(),
      jumlahField: int.tryParse((j['jumlah_field'] ?? fields.length).toString()) ?? fields.length,
      statusData: (j['status_data'] ?? 'A').toString(),
      createdAt: (j['created_at'] ?? '').toString(),
      fields: fields,
    );
  }
}

class KategoriAgunanRepository {
  static Future<List<KategoriAgunanModel>> list({String keyword = ''}) async {
    final value = await Setuprepository.fetch(NetworkURL.requestKategoriList(), {
      'kode_kategori': '',
      'nama_kategori': keyword.trim(),
      'page': 1,
      'limit': 100,
    });
    if (!LendingSetupRepository.isSuccess(value)) {
      throw Exception(LendingSetupRepository.message(value, 'Gagal memuat kategori agunan'));
    }
    return LendingSetupRepository.rows(value)
        .whereType<Map>()
        .map((e) => KategoriAgunanModel.dariJson(Map<String, dynamic>.from(e)))
        .where((e) => e.kode.startsWith(awalanKategoriAgunan))
        .toList();
  }

  static Future<KategoriAgunanModel> detail(String kode) async {
    final value = await Setuprepository.fetch(NetworkURL.requestKategoriDetail(), {'kode_kategori': kode});
    if (!LendingSetupRepository.isSuccess(value)) {
      throw Exception(LendingSetupRepository.message(value, 'Gagal mengambil detail kategori'));
    }
    return KategoriAgunanModel.dariJson(LendingSetupRepository.map(value));
  }

  static Future<void> simpan({
    required bool isEdit,
    required String kode,
    required String nama,
    required List<FieldKategori> fields,
  }) async {
    // field_1..N berurutan tanpa celah, termasuk field nonaktif (lihat FieldKategori).
    final body = <String, dynamic>{'kode_kategori': kode, 'nama_kategori': nama};
    for (var i = 0; i < fields.length; i++) {
      body['field_${i + 1}'] = fields[i].keJson();
    }
    final value = await Setuprepository.fetch(
      isEdit ? NetworkURL.requestKategoriUpdate() : NetworkURL.requestKategoriCreate(),
      body,
    );
    if (!LendingSetupRepository.isSuccess(value)) {
      throw Exception(LendingSetupRepository.message(value, 'Gagal menyimpan kategori'));
    }
  }

  static Future<void> hapus(String kode) async {
    final value = await Setuprepository.fetch(NetworkURL.requestKategoriDelete(), {'kode_kategori': kode});
    if (!LendingSetupRepository.isSuccess(value)) {
      throw Exception(LendingSetupRepository.message(value, 'Gagal menghapus kategori'));
    }
  }
}
