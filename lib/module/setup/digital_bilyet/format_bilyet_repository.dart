import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/network/network.dart';
import 'format_bilyet_model.dart';
class FormatBilyetRepository {
  /// Return: {'success': bool, 'message': String, 'data': List<FormatBilyetModel>}
  static Future<Map<String, dynamic>> list({
    required String bprId,
    required String userLogin,
  }) async {
    final res = await _post(
      '$url/setup/format-bilyet-digital/list',
      {'bpr_id': bprId, 'user_login': userLogin},
    );
    if (res['success'] != true) return res;

    final raw = res['data'];
    final items = <FormatBilyetModel>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(FormatBilyetModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return {'success': true, 'message': res['message'], 'data': items};
  }

  /// Insert kalau [data.id] == 0, selain itu update.
  static Future<Map<String, dynamic>> simpan({
    required String bprId,
    required String userLogin,
    required FormatBilyetModel data,
  }) {
    final endpoint = data.id == 0 ? '$url/setup/format-bilyet-digital/create' : '$url/setup/format-bilyet-digital/update';
    return _post(endpoint, {
      ...data.toJson(),
      'bpr_id': bprId,
      'user_login': userLogin,
    });
  }

  static Future<Map<String, dynamic>> hapus({
    required String bprId,
    required String userLogin,
    required int id,
  }) {
    return _post('$url/setup/format-bilyet-digital/delete', {
      'bpr_id': bprId,
      'user_login': userLogin,
      'id': id,
    });
  }


static Future<Map<String,dynamic>> _post(String endpoint,Map<String,dynamic> body)async{
 try{final res=await Setuprepository.fetch(endpoint,body);if(res is! Map)return {'success':false,'message':'Respons tidak valid'};return {'success':res['code']=='000','message':res['message']??'Permintaan gagal','data':res['data']};}catch(e){return {'success':false,'message':e.toString()};}
}
}
