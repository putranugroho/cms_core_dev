import 'dart:convert';

import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/network/network.dart';
import 'package:accounting_kantor_gl_useraccess/repository/SetupRepository.dart';

class CoreUsersRepository {
  static String _message(dynamic value, [String fallback = '']) {
    if (value is Map && value['message'] != null) return value['message'].toString();
    return fallback;
  }

  static bool isSuccess(dynamic value) {
    if (value is! Map) return false;
    final code = (value['code'] ?? '').toString();
    final status = (value['status'] ?? '').toString().toLowerCase();
    return code == '000' || status.contains('success');
  }

  static List<dynamic> _listData(dynamic value) {
    if (value is Map && value['data'] is List) return value['data'] as List;
    return [];
  }

  static Map<String, dynamic> _mapData(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    return <String, dynamic>{};
  }

  static Future<List<CoreUserModel>> listUsers({String keyword = ''}) async {
    final value = await Setuprepository.fetch(
      NetworkURL.coreUsersList(),
      {'keyword': keyword.trim()},
    );
    return _listData(value)
        .whereType<Map>()
        .map((e) => CoreUserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Map<String, dynamic>> detailRaw(String userid) async {
    final value = await Setuprepository.fetch(
      NetworkURL.coreUsersDetail(),
      {'userid': userid.trim().toUpperCase()},
    );
    if (!isSuccess(value)) {
      throw Exception(_message(value, 'Gagal mengambil detail user'));
    }
    return _mapData(value);
  }

  static Future<CoreUserModel> detailUser(String userid) async {
    return CoreUserModel.fromJson(await detailRaw(userid));
  }

  static Future<List<CoreAccessModel>> userAccess(String userid) async {
    final data = await detailRaw(userid);
    final raw = data['fasilitas'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => CoreAccessModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<CoreAccessModel>> masterMenu() async {
    final value = await Setuprepository.fetch(
      NetworkURL.coreMasterMenu(),
      {'action': 'list', 'type': ''},
    );
    final rows = _listData(value);
    final list = rows
        .whereType<Map>()
        .map((e) => CoreAccessModel.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.routePath.trim().isNotEmpty)
        .toList();

    // Fallback lokal sampai master_menu pusat menambahkan menu AO.
    final hasAo = list.any((e) => e.matchesRoute('/master/ao'));
    if (!hasAo) {
      list.add(
        const CoreAccessModel(
          id: null,
          menuId: null,
          userid: '',
          modul: 'MASTER',
          menu: 'Account Officer',
          submenu: 'Account Officer',
          subsubmenu: '',
          routePath: '/master/ao',
          canView: false,
          canCreate: false,
          canUpdate: false,
          canDelete: false,
          canApprove: false,
          canForceLogout: false,
          flag: '',
        ),
      );
    }


    final hasSandi = list.any((e) => e.matchesRoute('/setup/sandi'));
    if (!hasSandi) {
      list.add(
        const CoreAccessModel(
          id: null,
          menuId: null,
          userid: '',
          modul: 'SETUP',
          menu: 'Sandi BI/OJK',
          submenu: 'Sandi BI/OJK',
          subsubmenu: '',
          routePath: '/setup/sandi',
          canView: false,
          canCreate: false,
          canUpdate: false,
          canDelete: false,
          canApprove: false,
          canForceLogout: false,
          flag: '',
        ),
      );
    }



    final hasProductTabungan = list.any((e) => e.matchesRoute('/setup/product-tabungan'));
    if (!hasProductTabungan) {
      list.add(
        const CoreAccessModel(
          id: null,
          menuId: null,
          userid: '',
          modul: 'SETUP',
          menu: 'Prod Tabungan',
          submenu: 'Prod Tabungan',
          subsubmenu: '',
          routePath: '/setup/product-tabungan',
          canView: false,
          canCreate: false,
          canUpdate: false,
          canDelete: false,
          canApprove: false,
          canForceLogout: false,
          flag: '',
        ),
      );
    }

    final hasProductDeposito = list.any((e) => e.matchesRoute('/setup/product-deposito'));
    if (!hasProductDeposito) {
      list.add(
        const CoreAccessModel(
          id: null,
          menuId: null,
          userid: '',
          modul: 'SETUP',
          menu: 'Prod Deposito',
          submenu: 'Prod Deposito',
          subsubmenu: '',
          routePath: '/setup/product-deposito',
          canView: false,
          canCreate: false,
          canUpdate: false,
          canDelete: false,
          canApprove: false,
          canForceLogout: false,
          flag: '',
        ),
      );
    }


    final fallbackMenus = <CoreAccessModel>[
      const CoreAccessModel(
        id: null,
        menuId: null,
        userid: '',
        modul: 'SETUP',
        menu: 'Format Buku Tabungan',
        submenu: 'Format Buku Tabungan',
        subsubmenu: '',
        routePath: '/setup/format-buku',
        canView: false,
        canCreate: false,
        canUpdate: false,
        canDelete: false,
        canApprove: false,
        canForceLogout: false,
        flag: '',
      ),
      const CoreAccessModel(
        id: null,
        menuId: null,
        userid: '',
        modul: 'SETUP',
        menu: 'Format Cover Buku',
        submenu: 'Format Cover Buku',
        subsubmenu: '',
        routePath: '/setup/format-cover',
        canView: false,
        canCreate: false,
        canUpdate: false,
        canDelete: false,
        canApprove: false,
        canForceLogout: false,
        flag: '',
      ),
      const CoreAccessModel(
        id: null,
        menuId: null,
        userid: '',
        modul: 'SETUP',
        menu: 'Format Bilyet Deposito',
        submenu: 'Format Bilyet Deposito',
        subsubmenu: '',
        routePath: '/setup/format-bilyet',
        canView: false,
        canCreate: false,
        canUpdate: false,
        canDelete: false,
        canApprove: false,
        canForceLogout: false,
        flag: '',
      ),
      const CoreAccessModel(
        id: null,
        menuId: null,
        userid: '',
        modul: 'SETUP',
        menu: 'Sandi Transaksi Buku',
        submenu: 'Sandi Transaksi Buku',
        subsubmenu: '',
        routePath: '/setup/sandi-transaksi-buku',
        canView: false,
        canCreate: false,
        canUpdate: false,
        canDelete: false,
        canApprove: false,
        canForceLogout: false,
        flag: '',
      ),
      const CoreAccessModel(
        id: null,
        menuId: null,
        userid: '',
        modul: 'SETUP',
        menu: 'Agunan',
        submenu: 'Agunan',
        subsubmenu: '',
        routePath: '/setup/agunan',
        canView: false,
        canCreate: false,
        canUpdate: false,
        canDelete: false,
        canApprove: false,
        canForceLogout: false,
        flag: '',
      ),
      const CoreAccessModel(
        id: null,
        menuId: null,
        userid: '',
        modul: 'SETUP',
        menu: 'RAK',
        submenu: 'RAK',
        subsubmenu: '',
        routePath: '/setup/rak',
        canView: false,
        canCreate: false,
        canUpdate: false,
        canDelete: false,
        canApprove: false,
        canForceLogout: false,
        flag: '',
      ),
      const CoreAccessModel(
        id: null,
        menuId: null,
        userid: '',
        modul: 'SETUP',
        menu: 'Rate RAK',
        submenu: 'Rate RAK',
        subsubmenu: '',
        routePath: '/setup/rak/relasi',
        canView: false,
        canCreate: false,
        canUpdate: false,
        canDelete: false,
        canApprove: false,
        canForceLogout: false,
        flag: '',
      ),
      const CoreAccessModel(
        id: null,
        menuId: null,
        userid: '',
        modul: 'SETUP',
        menu: 'PPAP',
        submenu: 'PPAP',
        subsubmenu: '',
        routePath: '/setup/bobot-ppap',
        canView: false,
        canCreate: false,
        canUpdate: false,
        canDelete: false,
        canApprove: false,
        canForceLogout: false,
        flag: '',
      ),
    ];

    for (final menu in fallbackMenus) {
      if (!list.any((e) => e.matchesRoute(menu.routePath))) {
        list.add(menu);
      }
    }

    return list;
  }

  static Future<Map<String, dynamic>> saveUser({
    required String userid,
    required String password,
    required String namauser,
    required String kodeKantor,
    required String bprId,
    required String tglExpired,
    required bool isActive,
    required bool isSuperAdmin,
    required List<CoreAccessModel> fasilitas,
  }) async {
    final body = <String, dynamic>{
      'userid': userid.trim().toUpperCase(),
      'namauser': namauser.trim().toUpperCase(),
      'kode_kantor': kodeKantor.trim(),
      'bpr_id': bprId.trim(),
      'tgl_expired': _normalizeDate(tglExpired),
      'is_active': isActive,
      'is_super_admin': isSuperAdmin,
      'fasilitas': fasilitas.map((e) => e.toJson()).toList(),
    };

    if (password.trim().isNotEmpty) {
      body['password'] = password.trim();
    }

    final value = await Setuprepository.fetch(NetworkURL.coreUsersSave(), body);
    if (!isSuccess(value)) {
      throw Exception(_message(value, 'Gagal menyimpan user'));
    }
    return _mapData(value);
  }

  static Future<Map<String, dynamic>> saveUserAccessOnly({
    required CoreUserModel user,
    required List<CoreAccessModel> fasilitas,
  }) async {
    return saveUser(
      userid: user.userid,
      password: '',
      namauser: user.namauser,
      kodeKantor: user.kodeKantor,
      bprId: user.bprId,
      tglExpired: user.tglExpired,
      isActive: user.isActive,
      isSuperAdmin: user.isSuperAdmin,
      fasilitas: fasilitas,
    );
  }

  static Future<Map<String, dynamic>> setActive(String userid, bool active) async {
    final url = active ? NetworkURL.coreUsersAktif() : NetworkURL.coreUsersNonaktif();
    final value = await Setuprepository.fetch(url, {'userid': userid.trim().toUpperCase()});
    if (!isSuccess(value)) {
      throw Exception(_message(value, active ? 'Gagal mengaktifkan user' : 'Gagal menonaktifkan user'));
    }
    return _mapData(value);
  }

  static Future<Map<String, dynamic>> forceLogout(String userid) async {
    final value = await Setuprepository.fetch(
      NetworkURL.coreUsersForceLogout(),
      {'userid': userid.trim().toUpperCase()},
    );
    if (!isSuccess(value)) {
      throw Exception(_message(value, 'Gagal force logout user'));
    }
    return _mapData(value);
  }

  static Future<Map<String, dynamic>> unlock(String userid) async {
    final value = await Setuprepository.fetch(
      NetworkURL.coreUsersUnlock(),
      {'userid': userid.trim().toUpperCase()},
    );
    if (!isSuccess(value)) {
      throw Exception(_message(value, 'Gagal unlock user'));
    }
    return _mapData(value);
  }

  static String _normalizeDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.contains(':')) return value.replaceFirst('T', ' ');
    return '$value 23:59:59';
  }

  static String prettyJson(dynamic value) => const JsonEncoder.withIndent('  ').convert(value);
}
