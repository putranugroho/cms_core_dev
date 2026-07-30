import 'dart:async';
import 'dart:convert';

import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/auth/login_page.dart';
import 'package:accounting_kantor_gl_useraccess/network/network.dart';
import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:accounting_kantor_gl_useraccess/repository/SetupRepository.dart';
import 'package:flutter/material.dart';

import '../../utils/button_custom.dart';
import '../../utils/informationdialog.dart';

class CoreMenuItem {
  final String title;
  final String routePath;
  final int page;
  final String icon;
  final CoreAccessModel? access;

  const CoreMenuItem({
    required this.title,
    required this.routePath,
    required this.page,
    required this.icon,
    this.access,
  });
}

class MenuNotifier extends ChangeNotifier {
  final BuildContext context;

  MenuNotifier({required this.context}) {
    getProfile();
  }

  static const String routeKantor = '/setup/kantor';
  static const String routeGl = '/setup/gl';
  static const String routeUsers = '/admin/users';
  static const String routeUserAccess = '/admin/user-access';
  static const String routeAo = '/master/ao';
  static const String routeSandi = '/setup/sandi';

  UserModel? users;
  List<CoreAccessModel> fasilitas = [];
  List<CoreMenuItem> menuItems = [];
  bool isLoading = true;
  bool isSuperAdmin = false;
  bool cmsCoreEnabled = true;
  bool isCmsCoreLoading = false;
  bool _isAutoLoggingOut = false;
  int idleTimeoutMinutes = 30;
  int page = 1;
  DateTime? _lastHeartbeat;
  Timer? _heartbeatTimer;

  Duration get idleDuration => Duration(minutes: idleTimeoutMinutes <= 0 ? 30 : idleTimeoutMinutes);

  Future<void> getProfile() async {
    isLoading = true;
    notifyListeners();

    final pref = Pref();
    users = await pref.getUsers();
    isSuperAdmin = await pref.getIsSuperAdmin();
    cmsCoreEnabled = await pref.getCmsCoreEnabled();
    idleTimeoutMinutes = await pref.getIdleTimeoutMinutes();
    fasilitas = await pref.getCoreAccessList();
    _buildMenuItems();

    await heartbeat(force: true, silent: true);
    _startPeriodicHeartbeat();

    isLoading = false;
    notifyListeners();
  }

  void _buildMenuItems() {
    final all = <CoreMenuItem>[
      CoreMenuItem(title: 'Kantor', routePath: routeKantor, page: 1, icon: 'building'),
      CoreMenuItem(title: 'GL / COA', routePath: routeGl, page: 2, icon: 'accounting'),
      CoreMenuItem(title: 'Login User', routePath: routeUsers, page: 3, icon: 'group'),
      CoreMenuItem(title: 'User Access', routePath: routeUserAccess, page: 4, icon: 'user'),
      CoreMenuItem(title: 'Account Officer', routePath: routeAo, page: 5, icon: 'ao'),
      CoreMenuItem(title: 'Sandi BI/OJK', routePath: routeSandi, page: 6, icon: 'sandi'),
    ];

    if (isSuperAdmin) {
      menuItems = all;
    } else {
      menuItems = all.where((item) => _hasRoute(item.routePath)).toList();
    }

    if (menuItems.isNotEmpty && !menuItems.any((e) => e.page == page)) {
      page = menuItems.first.page;
    }
  }

  bool _hasRoute(String routePath) {
    if (isSuperAdmin) return true;
    return fasilitas.any((e) => e.matchesRoute(routePath) && e.canView);
  }

  bool canView(String routePath) => _hasRoute(routePath);

  bool canCreate(String routePath) {
    if (isSuperAdmin) return true;
    return fasilitas.any((e) => e.matchesRoute(routePath) && e.canCreate);
  }

  bool canUpdate(String routePath) {
    if (isSuperAdmin) return true;
    return fasilitas.any((e) => e.matchesRoute(routePath) && e.canUpdate);
  }

  bool canDelete(String routePath) {
    if (isSuperAdmin) return true;
    return fasilitas.any((e) => e.matchesRoute(routePath) && e.canDelete);
  }

  bool canForceLogout(String routePath) {
    if (isSuperAdmin) return true;
    return fasilitas.any((e) => e.matchesRoute(routePath) && e.canForceLogout);
  }

  void gantimenu(int value) {
    final allowed = menuItems.any((e) => e.page == value);
    if (!allowed) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses ke menu ini.');
      return;
    }
    page = value;
    notifyListeners();
  }

  Future<void> onActivity() async {
    await Pref().setLastActivityNow();
    final now = DateTime.now();
    if (_lastHeartbeat == null || now.difference(_lastHeartbeat!).inMinutes >= 2) {
      await heartbeat(silent: true);
    }
  }

  void _startPeriodicHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) => heartbeat(silent: true));
  }

  Future<void> heartbeat({bool force = false, bool silent = false}) async {
    final sessionToken = await Pref().getSessionToken();
    if (sessionToken.isEmpty) return;

    if (!force && _lastHeartbeat != null && DateTime.now().difference(_lastHeartbeat!).inSeconds < 30) {
      return;
    }

    final value = await Setuprepository.setup(
      token,
      NetworkURL.sessionHeartbeat(),
      jsonEncode({}),
    );
    _lastHeartbeat = DateTime.now();

    if ((value?['code'] ?? '').toString() == '000') {
      final data = value['data'];
      if (data is Map) {
        await Pref().updateCoreSession(Map<String, dynamic>.from(data));
        cmsCoreEnabled = PrefValue.boolFromDynamic(data['cms_core_enabled'], defaultValue: cmsCoreEnabled);
        idleTimeoutMinutes = PrefValue.intFromDynamic(data['idle_timeout_minutes'], idleTimeoutMinutes);
        fasilitas = await Pref().getCoreAccessList();
        _buildMenuItems();
        if (!silent) notifyListeners();
      }
    } else {
      await _logoutLocal(showMessage: !silent, message: value?['message']?.toString() ?? 'Session berakhir');
    }
  }

  Future<void> autoLogoutByIdle() async {
    if (_isAutoLoggingOut) return;
    _isAutoLoggingOut = true;
    await Setuprepository.setup(token, NetworkURL.authLogout(), jsonEncode({'userid': users?.userid ?? ''}));
    await _logoutLocal(showMessage: true, message: 'Session berakhir karena idle timeout.');
  }

  Future<void> _logoutLocal({bool showMessage = false, String? message}) async {
    _heartbeatTimer?.cancel();
    await Pref().remove();
    if (showMessage && message != null && context.mounted) {
      informationDialog(context, 'Informasi', message);
    }
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> confirmLogout() async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Anda yakin keluar aplikasi?",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ButtonSecondary(
                        onTap: () => Navigator.pop(context),
                        name: "Tidak",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ButtonPrimary(
                        onTap: () async {
                          Navigator.pop(context);
                          await Setuprepository.setup(
                            token,
                            NetworkURL.authLogout(),
                            jsonEncode({'userid': users?.userid ?? ''}),
                          );
                          await _logoutLocal();
                        },
                        name: "Ya",
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> confirmToggleCmsCore() async {
    if (!isSuperAdmin) {
      informationDialog(context, 'Akses Ditolak', 'Hanya super admin yang dapat menyalakan atau mematikan CMS Core.');
      return;
    }

    final nextStatus = !cmsCoreEnabled;
    final title = nextStatus ? 'Aktifkan CMS Core?' : 'Matikan CMS Core?';
    final message = nextStatus
        ? 'User biasa akan dapat mengakses CMS Core kembali sesuai fasilitasnya. Lanjutkan?'
        : 'Semua user biasa akan dipaksa logout dan tidak bisa mengakses CMS Core. Proses gateway/core tetap berjalan normal. Lanjutkan?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(nextStatus ? 'Aktifkan' : 'Matikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    isCmsCoreLoading = true;
    notifyListeners();
    final value = await Setuprepository.setup(
      token,
      NetworkURL.cmsCoreToggle(),
      jsonEncode({'cms_core_enabled': nextStatus}),
    );
    isCmsCoreLoading = false;

    if ((value?['code'] ?? '').toString() == '000') {
      final data = value['data'];
      if (data is Map && data.containsKey('cms_core_enabled')) {
        cmsCoreEnabled = PrefValue.boolFromDynamic(data['cms_core_enabled'], defaultValue: nextStatus);
        await Pref().updateCoreSession({'cms_core_enabled': cmsCoreEnabled});
      } else {
        cmsCoreEnabled = nextStatus;
        await Pref().updateCoreSession({'cms_core_enabled': cmsCoreEnabled});
      }
      informationDialog(context, 'Informasi', value?['message']?.toString() ?? 'Status CMS Core berhasil diubah');
    } else {
      informationDialog(context, 'Warning', value?['message']?.toString() ?? 'Gagal mengubah status CMS Core');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

class PrefValue {
  static bool boolFromDynamic(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return defaultValue;
    return text == 'true' || text == '1' || text == 'y' || text == 'yes' || text == 'aktif' || text == 'active';
  }

  static int intFromDynamic(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }
}
