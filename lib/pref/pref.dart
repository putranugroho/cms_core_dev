import 'dart:convert';
import 'dart:math';

import 'package:cms_core/models/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  static const Duration idleDuration = Duration(minutes: 30);

  static String id = "id";
  static String userid = "userid";
  static String empId = "emp_id";
  static String pass = "pass";
  static String namauser = "namauser";
  static String batch = "batch";
  static String kodePt = "kode_pt";
  static String kodeKantor = "kode_kantor";
  static String kodeInduk = "kode_induk";
  static String tglexp = "tglexp";
  static String lvluser = "lvluser";
  static String terminalId = "terminal_id";
  static String aktivasi = "aktivasi";
  static String aksesKasir = "akses_kasir";
  static String sbbKasir = "sbb_kasir";
  static String namaSbb = "nama_sbb";
  static String fhoto1 = "fhoto_1";
  static String fhoto2 = "fhoto_2";
  static String fhoto3 = "fhoto_3";
  static String limitAkses = "limit_akses";
  static String maksimalTransaksi = "maksimal_transaksi";
  static String levelOtor = "level_otor";
  static String bedaKantor = "beda_kantor";
  static String minOtor = "min_otor";
  static String maxOtor = "max_otor";
  static String createddate = "createddate";
  static String isDeleted = "is_deleted";
  static String backDate = "back_date";

  static String sessionToken = "core_session_token";
  static String deviceId = "core_device_id";
  static String isSuperAdmin = "core_is_super_admin";
  static String cmsCoreEnabled = "core_cms_core_enabled";
  static String idleTimeoutMinutes = "core_idle_timeout_minutes";
  static String fasilitas = "core_fasilitas";
  static String lastActivityAt = "core_last_activity_at";

  Future<void> simpan(UserModel users) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setInt(Pref.id, users.id);
    pref.setString(Pref.userid, users.userid);
    pref.setString(Pref.empId, users.empId);
    pref.setString(Pref.pass, users.pass);
    pref.setString(Pref.namauser, users.namauser);
    pref.setString(Pref.batch, users.batch);
    pref.setString(Pref.kodePt, users.kodePt);
    pref.setString(Pref.kodeKantor, users.kodeKantor);
    pref.setString(Pref.kodeInduk, users.kodeInduk);
    pref.setString(Pref.tglexp, users.tglexp);
    pref.setString(Pref.lvluser, users.lvluser);
    pref.setString(Pref.terminalId, users.terminalId);
    pref.setString(Pref.aktivasi, users.aktivasi);
    pref.setString(Pref.aksesKasir, users.aksesKasir);
    pref.setString(Pref.sbbKasir, users.sbbKasir);
    pref.setString(Pref.namaSbb, users.namaSbb);
    pref.setString(Pref.fhoto1, users.fhoto1);
    pref.setString(Pref.fhoto2, users.fhoto2);
    pref.setString(Pref.fhoto3, users.fhoto3);
    pref.setString(Pref.levelOtor, users.levelOtor);
    pref.setString(Pref.bedaKantor, users.bedaKantor);
    pref.setString(Pref.minOtor, users.minOtor);
    pref.setString(Pref.maxOtor, users.maxOtor);
    pref.setString(Pref.createddate, users.createddate);
    pref.setString(Pref.isDeleted, users.isDeleted);
    pref.setString(Pref.backDate, users.backDate);
    pref.setString(Pref.limitAkses, users.limitAkses);
    pref.setString(Pref.maksimalTransaksi, users.maksimalTransaksi);
  }

  Future<void> simpanCoreLogin(Map<String, dynamic> data) async {
    final pref = await SharedPreferences.getInstance();
    final userId = (data['userid'] ?? data['users_id'] ?? '').toString();
    final nama = (data['namauser'] ?? data['nama_users'] ?? '').toString();
    final kodeKantorValue = (data['kode_kantor'] ?? data['kdkantor'] ?? '').toString();
    final bprId = (data['bpr_id'] ?? data['bprid'] ?? '').toString();
    final session = (data['session_token'] ?? '').toString();
    final currentDeviceId = (data['device_id'] ?? await getOrCreateDeviceId()).toString();
    final access = data['fasilitas'] is List ? data['fasilitas'] as List : [];

    await pref.setInt(Pref.id, userId.isEmpty ? 0 : 1);
    await pref.setString(Pref.userid, userId);
    await pref.setString(Pref.empId, userId);
    await pref.setString(Pref.pass, '');
    await pref.setString(Pref.namauser, nama);
    await pref.setString(Pref.batch, '');
    await pref.setString(Pref.kodePt, bprId);
    await pref.setString(Pref.kodeKantor, kodeKantorValue);
    await pref.setString(Pref.kodeInduk, kodeKantorValue);
    await pref.setString(Pref.tglexp, (data['tgl_expired'] ?? '').toString());
    await pref.setString(Pref.lvluser, data['is_super_admin'] == true ? 'SUPER_ADMIN' : 'USER');
    await pref.setString(Pref.terminalId, currentDeviceId);
    await pref.setString(Pref.aktivasi, 'Y');
    await pref.setString(Pref.aksesKasir, 'N');
    await pref.setString(Pref.sbbKasir, '');
    await pref.setString(Pref.namaSbb, '');
    await pref.setString(Pref.fhoto1, '');
    await pref.setString(Pref.fhoto2, '');
    await pref.setString(Pref.fhoto3, '');
    await pref.setString(Pref.levelOtor, '');
    await pref.setString(Pref.bedaKantor, 'N');
    await pref.setString(Pref.minOtor, '');
    await pref.setString(Pref.maxOtor, '');
    await pref.setString(Pref.createddate, '');
    await pref.setString(Pref.isDeleted, 'N');
    await pref.setString(Pref.backDate, 'N');
    await pref.setString(Pref.limitAkses, 'N');
    await pref.setString(Pref.maksimalTransaksi, '0');

    await pref.setString(Pref.sessionToken, session);
    await pref.setString(Pref.deviceId, currentDeviceId);
    await pref.setBool(Pref.isSuperAdmin, _toBool(data['is_super_admin']));
    await pref.setBool(Pref.cmsCoreEnabled, _toBool(data['cms_core_enabled'], defaultValue: true));
    await pref.setInt(Pref.idleTimeoutMinutes, _toInt(data['idle_timeout_minutes'], 30));
    await pref.setString(Pref.fasilitas, jsonEncode(access));
    await setLastActivityNow();
  }

  Future<void> updateCoreSession(Map<String, dynamic> data) async {
    final pref = await SharedPreferences.getInstance();
    if (data.containsKey('userid') || data.containsKey('users_id')) {
      await pref.setString(Pref.userid, (data['userid'] ?? data['users_id'] ?? '').toString());
    }
    if (data.containsKey('kode_kantor') || data.containsKey('kdkantor')) {
      await pref.setString(Pref.kodeKantor, (data['kode_kantor'] ?? data['kdkantor'] ?? '').toString());
    }
    if (data.containsKey('bpr_id') || data.containsKey('bprid')) {
      await pref.setString(Pref.kodePt, (data['bpr_id'] ?? data['bprid'] ?? '').toString());
    }
    if (data.containsKey('cms_core_enabled')) {
      await pref.setBool(Pref.cmsCoreEnabled, _toBool(data['cms_core_enabled'], defaultValue: true));
    }
    if (data.containsKey('idle_timeout_minutes')) {
      await pref.setInt(Pref.idleTimeoutMinutes, _toInt(data['idle_timeout_minutes'], 30));
    }
    if (data['fasilitas'] is List) {
      await pref.setString(Pref.fasilitas, jsonEncode(data['fasilitas']));
    }
    await setLastActivityNow();
  }

  Future<void> remove() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final keepDevice = pref.getString(Pref.deviceId);
    for (final key in [
      Pref.id,
      Pref.userid,
      Pref.empId,
      Pref.pass,
      Pref.namauser,
      Pref.batch,
      Pref.kodePt,
      Pref.kodeKantor,
      Pref.kodeInduk,
      Pref.tglexp,
      Pref.lvluser,
      Pref.terminalId,
      Pref.aktivasi,
      Pref.aksesKasir,
      Pref.sbbKasir,
      Pref.namaSbb,
      Pref.fhoto1,
      Pref.fhoto2,
      Pref.fhoto3,
      Pref.levelOtor,
      Pref.bedaKantor,
      Pref.minOtor,
      Pref.maxOtor,
      Pref.createddate,
      Pref.isDeleted,
      Pref.limitAkses,
      Pref.maksimalTransaksi,
      Pref.backDate,
      Pref.sessionToken,
      Pref.isSuperAdmin,
      Pref.cmsCoreEnabled,
      Pref.idleTimeoutMinutes,
      Pref.fasilitas,
      Pref.lastActivityAt,
    ]) {
      await pref.remove(key);
    }
    if (keepDevice != null && keepDevice.isNotEmpty) {
      await pref.setString(Pref.deviceId, keepDevice);
    }
  }

  Future<UserModel> getUsers() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    UserModel users = UserModel(
      id: pref.getInt(Pref.id) ?? 0,
      userid: pref.getString(Pref.userid) ?? "",
      empId: pref.getString(Pref.empId) ?? "",
      pass: pref.getString(Pref.pass) ?? "",
      namauser: pref.getString(Pref.namauser) ?? "",
      batch: pref.getString(Pref.batch) ?? "",
      kodePt: pref.getString(Pref.kodePt) ?? "",
      kodeKantor: pref.getString(Pref.kodeKantor) ?? "",
      kodeInduk: pref.getString(Pref.kodeInduk) ?? "",
      tglexp: pref.getString(Pref.tglexp) ?? "",
      lvluser: pref.getString(Pref.lvluser) ?? "",
      terminalId: pref.getString(Pref.terminalId) ?? "",
      aktivasi: pref.getString(Pref.aktivasi) ?? "",
      aksesKasir: pref.getString(Pref.aksesKasir) ?? "",
      sbbKasir: pref.getString(Pref.sbbKasir) ?? "",
      namaSbb: pref.getString(Pref.namaSbb) ?? "",
      fhoto1: pref.getString(Pref.fhoto1) ?? "",
      fhoto2: pref.getString(Pref.fhoto2) ?? "",
      fhoto3: pref.getString(Pref.fhoto3) ?? "",
      levelOtor: pref.getString(Pref.levelOtor) ?? "",
      bedaKantor: pref.getString(Pref.bedaKantor) ?? "",
      minOtor: pref.getString(Pref.minOtor) ?? "",
      maxOtor: pref.getString(Pref.maxOtor) ?? "",
      limitAkses: pref.getString(Pref.limitAkses) ?? "",
      maksimalTransaksi: pref.getString(Pref.maksimalTransaksi) ?? "",
      createddate: pref.getString(Pref.createddate) ?? "",
      isDeleted: pref.getString(Pref.isDeleted) ?? "",
      backDate: pref.getString(Pref.backDate) ?? "",
    );
    return users;
  }

  Future<String> getSessionToken() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(Pref.sessionToken) ?? '';
  }

  Future<String> getOrCreateDeviceId() async {
    final pref = await SharedPreferences.getInstance();
    final existing = pref.getString(Pref.deviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random().nextInt(999999999);
    final value = 'cms-core-${DateTime.now().microsecondsSinceEpoch}-$random';
    await pref.setString(Pref.deviceId, value);
    return value;
  }

  Future<bool> getIsSuperAdmin() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(Pref.isSuperAdmin) ?? false;
  }

  Future<bool> getCmsCoreEnabled() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(Pref.cmsCoreEnabled) ?? true;
  }

  Future<int> getIdleTimeoutMinutes() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getInt(Pref.idleTimeoutMinutes) ?? 30;
  }

  Future<String> getFasilitas() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(Pref.fasilitas) ?? '[]';
  }

  Future<List<CoreAccessModel>> getCoreAccessList() async {
    final raw = await getFasilitas();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map>().map((e) => CoreAccessModel.fromJson(Map<String, dynamic>.from(e))).where((e) => e.canView).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> hasRouteAccess(String routePath) async {
    if (await getIsSuperAdmin()) return true;
    final list = await getCoreAccessList();
    return list.any((e) => e.matchesRoute(routePath) && e.canView);
  }

  Future<void> setLastActivityNow() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setInt(Pref.lastActivityAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isSessionExpired([Duration? fallback]) async {
    final pref = await SharedPreferences.getInstance();
    final last = pref.getInt(Pref.lastActivityAt) ?? 0;
    if (last == 0) return false;
    final minutes = pref.getInt(Pref.idleTimeoutMinutes);
    final duration = minutes == null ? (fallback ?? idleDuration) : Duration(minutes: minutes);
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)) > duration;
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return defaultValue;
    return text == 'true' || text == '1' || text == 'y' || text == 'yes' || text == 'aktif' || text == 'active';
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }
}
