import 'dart:convert';

import 'package:cms_core/models/index.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/repository/SetupRepository.dart';

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
    return _listData(value).whereType<Map>().map((e) => CoreUserModel.fromJson(Map<String, dynamic>.from(e))).toList();
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
    return raw.whereType<Map>().map((e) => CoreAccessModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<List<CoreAccessModel>> masterMenu() async {
    final value = await Setuprepository.fetch(
      NetworkURL.coreMasterMenu(),
      {'action': 'list', 'type': ''},
    );
    if (!isSuccess(value)) {
      throw Exception(_message(value, 'Gagal mengambil master menu'));
    }
    final rows = _listData(value);
    final configuredRoutes = rows.whereType<Map>().map((row) => (row['route_path'] ?? '').toString().trim().toLowerCase()).toSet();
    final list = rows.whereType<Map>().where((row) {
      final active = row['is_active'];
      if (active == null) return true;
      if (active is bool) return active;
      if (active is num) return active != 0;
      return ['true', '1', 'y', 'yes', 'aktif', 'active'].contains(active.toString().trim().toLowerCase());
    }).map((row) {
      final item = CoreAccessModel.fromJson(Map<String, dynamic>.from(row));
      return item.copyWith(menuId: item.masterMenuId);
    }).toList();

    bool hasRoute(String route) => configuredRoutes.contains(route.trim().toLowerCase()) || list.any((item) => item.matchesRoute(route));

    // Fallback lokal sampai master_menu pusat menambahkan menu AO.
    final hasAo = hasRoute('/master/ao');
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

    final hasSandi = hasRoute('/setup/sandi');
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

    final hasProductTabungan = hasRoute('/setup/product-tabungan');
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

    final hasProductDeposito = hasRoute('/setup/product-deposito');
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

    final hasProductKredit = hasRoute('/setup/product-kredit');
    if (!hasProductKredit) {
      list.add(
        const CoreAccessModel(
          id: null,
          menuId: null,
          userid: '',
          modul: 'SETUP',
          menu: 'Prod Kredit',
          submenu: 'Prod Kredit',
          subsubmenu: '',
          routePath: '/setup/product-kredit',
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
      if (!hasRoute(menu.routePath)) {
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
    bool includeActive = true,
    bool changePassword = true,
    required bool isSuperAdmin,
    required List<CoreAccessModel> fasilitas,
    String hrisEmployeeId = '',
    String hrisEmployeeNo = '',
    String hrisEmployeeName = '',
  }) async {
    final body = <String, dynamic>{
      'userid': userid.trim().toUpperCase(),
      'namauser': namauser.trim().toUpperCase(),
      'kode_kantor': kodeKantor.trim(),
      'bpr_id': bprId.trim(),
      'tgl_expired': _normalizeDate(tglExpired),
      'is_super_admin': isSuperAdmin,
      'fasilitas': fasilitas.map((e) => e.toJson()).toList(),
    };

    // Jangan kirim is_active saat hanya update User Access.
    // Status aktif/nonaktif existing user dikelola lewat endpoint /users/aktif dan /users/nonaktif
    // supaya payload access yang stale tidak mengubah user aktif menjadi nonaktif lagi.
    if (includeActive) {
      body['is_active'] = isActive;
    }

    if (hrisEmployeeId.trim().isNotEmpty) {
      body['hris_employee_id'] = hrisEmployeeId.trim();
    }
    if (hrisEmployeeNo.trim().isNotEmpty) {
      body['employee_no'] = hrisEmployeeNo.trim();
    }
    if (hrisEmployeeName.trim().isNotEmpty) {
      body['hris_employee_name'] = hrisEmployeeName.trim().toUpperCase();
    }

    // Password hanya dikirim kalau memang diminta secara eksplisit.
    // Ini mencegah browser/autofill/web state mengisi field password secara tidak sengaja
    // lalu backend mengubah password user ketika admin hanya update data/access.
    if (changePassword && password.trim().isNotEmpty) {
      body['password'] = password.trim();
      body['change_password'] = true;
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
    final body = <String, dynamic>{
      'userid': user.userid.trim().toUpperCase(),
      'access_only': true,
      'fasilitas': fasilitas.map((e) => e.toJson()).toList(),
    };

    final value = await Setuprepository.fetch(NetworkURL.coreUsersSave(), body);
    if (!isSuccess(value)) {
      throw Exception(_message(value, 'Gagal menyimpan user access'));
    }
    return _mapData(value);
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
    var value = raw.trim();
    if (value.isEmpty || value == '<nil>') return '';

    // Middleware menerima format tanpa timezone: yyyy-MM-dd HH:mm:ss.
    // Data detail bisa datang sebagai ISO/RFC3339 atau string timestamp PostgreSQL,
    // jadi normalisasi ke format yang konsisten sebelum save user/access.
    value = value.replaceFirst('T', ' ');
    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})(?:\s+(\d{2}:\d{2}:\d{2}))?').firstMatch(value);
    if (match != null) {
      final date = match.group(1)!;
      final time = match.group(2) ?? '23:59:59';
      return '$date $time';
    }

    final parsed = DateTime.tryParse(raw.trim().replaceFirst(' ', 'T'));
    if (parsed != null) {
      String two(int v) => v.toString().padLeft(2, '0');
      return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)} ${two(parsed.hour)}:${two(parsed.minute)}:${two(parsed.second)}';
    }

    return value.endsWith('Z') ? value.substring(0, value.length - 1) : value;
  }

  static String prettyJson(dynamic value) => const JsonEncoder.withIndent('  ').convert(value);
}
