import 'package:cms_core/models/index.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/SetupRepository.dart';

class HrisRepository {
  static Future<List<KantorModel>> listKantor({String bprId = ''}) async {
    final users = await Pref().getUsers();
    final effectiveBprId = bprId.trim().isNotEmpty
        ? bprId.trim()
        : users.kodePt.trim().isNotEmpty
            ? users.kodePt.trim()
            : '609999';

    final decoded = await Setuprepository.fetch(
      NetworkURL.hrisInquiryKantor(),
      {'bpr_id': effectiveBprId},
    );

    final code = (decoded['code'] ?? '').toString();
    final status = (decoded['status'] ?? '').toString().toLowerCase();
    if (code != '000' && !status.contains('success')) {
      throw Exception((decoded['message'] ?? 'Gagal mengambil data kantor HRIS').toString());
    }

    final wrapper = decoded['data'];
    final data = wrapper is Map ? wrapper['data'] : null;
    final bpr = data is Map && data['bpr'] is Map ? Map<String, dynamic>.from(data['bpr'] as Map) : <String, dynamic>{};
    final offices = data is Map && data['offices'] is List ? data['offices'] as List : const [];

    return offices
        .whereType<Map>()
        .map((e) => KantorModel.fromHrisJson(Map<String, dynamic>.from(e), bpr: bpr, fallbackBprId: effectiveBprId))
        .toList()
      ..sort((a, b) => a.kodeKantor.compareTo(b.kodeKantor));
  }


  static Future<List<HrisEmployeeModel>> searchEmployee({String bprId = '', required String search}) async {
    final users = await Pref().getUsers();
    final effectiveBprId = bprId.trim().isNotEmpty
        ? bprId.trim()
        : users.kodePt.trim().isNotEmpty
            ? users.kodePt.trim()
            : '609999';
    final keyword = search.trim();
    if (keyword.isEmpty) return [];

    final decoded = await Setuprepository.fetch(
      NetworkURL.hrisInquiryEmployee(),
      {'bpr_id': effectiveBprId, 'search': keyword},
    );

    final code = (decoded['code'] ?? '').toString();
    final status = (decoded['status'] ?? '').toString().toLowerCase();
    if (code != '000' && !status.contains('success')) {
      throw Exception((decoded['message'] ?? 'Gagal mengambil data employee HRIS').toString());
    }

    final wrapper = decoded['data'];
    final data = wrapper is Map ? wrapper['data'] : null;
    final employees = data is Map && data['employees'] is List ? data['employees'] as List : const [];

    return employees
        .whereType<Map>()
        .map((e) => HrisEmployeeModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

}
