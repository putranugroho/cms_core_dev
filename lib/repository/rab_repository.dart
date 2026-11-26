import 'package:cms_core/models/rab_model.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';

class RabRepository {
  static bool _ok(dynamic v) => v is Map && ((v['code'] ?? '') == '000' || (v['status'] ?? '').toString().toLowerCase().contains('success'));
  static String _msg(dynamic v, String fallback) => v is Map ? (v['message'] ?? fallback).toString() : fallback;
  static String _url(bool marketing, String action) => marketing ? NetworkURL.rabMarketing(action) : NetworkURL.rabKantor(action);
  static Map<String, dynamic> _data(dynamic v) => v is Map && v['data'] is Map ? Map<String, dynamic>.from(v['data']) : {};

  static Future<RabListResult> list({required bool marketing, String keyword = '', int? bulan, int? tahun, String status = '',
    int page = 1, int limit = 10}) async {
    final body = <String,dynamic>{'kode_kantor': keyword, 'nama_kantor': keyword, 'bulan': bulan, 'tahun': tahun,
      'status': status, 'status_data': 'A', 'page': page, 'limit': limit};
    if (marketing) { body['kode_ao'] = keyword; body['nama_ao'] = keyword; }
    final v = await Setuprepository.fetch(_url(marketing, 'list'), body);
    if (!_ok(v)) throw Exception(_msg(v, 'Gagal memuat data RAB'));
    final d = _data(v); final rows = d['data'] is List ? d['data'] as List : const [];
    return RabListResult(items: rows.whereType<Map>().map((e) => RabModel.fromJson(Map<String,dynamic>.from(e))).toList(),
      total: (d['total'] as num?)?.toInt() ?? rows.length, page: (d['page'] as num?)?.toInt() ?? page, limit: (d['limit'] as num?)?.toInt() ?? limit);
  }
  static Future<RabModel> detail(bool marketing, String id) async { final v=await Setuprepository.fetch(_url(marketing,'detail'),{'id':id}); if(!_ok(v)) throw Exception(_msg(v,'Gagal mengambil detail RAB')); return RabModel.fromJson(_data(v)); }
  static Future<void> save(bool marketing, bool edit, Map<String,dynamic> body) async { final v=await Setuprepository.fetch(_url(marketing,edit?'update':'create'),body); if(!_ok(v)) throw Exception(_msg(v,'Gagal menyimpan RAB')); }
  static Future<void> delete(bool marketing, String id) async { final v=await Setuprepository.fetch(_url(marketing,'delete'),{'id':id}); if(!_ok(v)) throw Exception(_msg(v,'Gagal menghapus RAB')); }
  static Future<void> authorize(bool marketing, String id, String action, String note) async { final v=await Setuprepository.fetch(_url(marketing,'otorisasi'),{'id':id,'action':action,'keterangan':note}); if(!_ok(v)) throw Exception(_msg(v,'Gagal mengotorisasi RAB')); }
}
