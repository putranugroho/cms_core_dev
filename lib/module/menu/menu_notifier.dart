import 'dart:async';
import 'dart:convert';

import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/auth/login_page.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:flutter/material.dart';

import '../../utils/button_custom.dart';
import '../../utils/informationdialog.dart';

class CoreMenuItem {
  final String title;
  final String routePath;
  final int page;
  final String icon;
  final String section;
  final String? parentTitle;
  final CoreAccessModel? access;

  const CoreMenuItem({
    required this.title,
    required this.routePath,
    required this.page,
    required this.icon,
    required this.section,
    this.parentTitle,
    this.access,
  });
}

class MenuNotifier extends ChangeNotifier {
  final BuildContext context;

  MenuNotifier({required this.context}) {
    Setuprepository.sessionFailure.addListener(_onSessionFailure);
    getProfile();
  }

  static const String routeKantor = '/setup/kantor';
  static const String routeGl = '/setup/gl';
  static const String routeUsers = '/admin/users';
  static const String routeUserAccess = '/admin/user-access';
  static const String routeAo = '/master/ao';
  static const String routeSandi = '/setup/sandi';
  static const String routeProductTabungan = '/setup/product-tabungan';
  static const String routeProductDeposito = '/setup/product-deposito';
  static const String routeProductKredit = '/setup/product-kredit';
  static const String routeFormatBuku = '/setup/format-buku';
  static const String routeFormatCover = '/setup/format-cover';
  static const String routeFormatBilyet = '/setup/format-bilyet';
  static const String routeSandiTransaksiBuku = '/setup/sandi-transaksi-buku';
  static const String routeAgunan = '/setup/agunan';
  static const String routeRak = '/setup/rak';
  static const String routeRateRak = '/setup/rak/relasi';
  static const String routePpap = '/setup/bobot-ppap';
  static const String routePajakAgregat = '/setup/pajak-agregat';
  static const String routeSetupInventaris = '/setup/inventaris';
  static const String routeAba = '/master/aba';
  static const String routeMitraBisnis = '/master/mitra-bisnis';
  static const String routeInventaris = '/master/inventaris';
  static const String routePenempatanInventaris = '/master/inventaris/penempatan';
  static const String routeKelompokAset = '/setup/kelompok-aset';
  static const String routeRevaluasiInventaris = '/master/inventaris/revaluasi';
  static const String routePenghapusanInventaris = '/master/inventaris/penghapusan';
  static const String routeRabMarketingRealisasi = '/master/rab-marketing/realisasi';
  static const String routeRabKantorRealisasi = '/master/rab-kantor/realisasi';
  static const String routeRabMarketing = '/master/rab-marketing';
  static const String routeRabKantor = '/master/rab-kantor';
  static const String routeKelompokPihakKetiga = '/setup/kelompok-pihak-ketiga';
  static const String routeDataPihakKetiga = '/setup/data-pihak-ketiga';

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
    if (_isAutoLoggingOut) return;
    _startPeriodicHeartbeat();

    isLoading = false;
    notifyListeners();
  }

  void _buildMenuItems() {
    final all = <CoreMenuItem>[
      const CoreMenuItem(title: 'Prod Tabungan', routePath: routeProductTabungan, page: 7, icon: 'saving', section: 'SETUP'),
      const CoreMenuItem(title: 'Format Cover Buku', routePath: routeFormatCover, page: 10, icon: 'print', section: 'SETUP'),
      const CoreMenuItem(title: 'Format Buku Tab', routePath: routeFormatBuku, page: 9, icon: 'print', section: 'SETUP'),
      const CoreMenuItem(title: 'Sandi Trans Buku', routePath: routeSandiTransaksiBuku, page: 12, icon: 'sandi', section: 'SETUP'),
      const CoreMenuItem(title: 'Prod Deposito', routePath: routeProductDeposito, page: 8, icon: 'deposito', section: 'SETUP'),
      const CoreMenuItem(title: 'Format Bilyet Dep', routePath: routeFormatBilyet, page: 11, icon: 'print', section: 'SETUP'),
      const CoreMenuItem(title: 'Prod Kredit', routePath: routeProductKredit, page: 18, icon: 'loan', section: 'SETUP'),
      const CoreMenuItem(title: 'Agunan', routePath: routeAgunan, page: 13, icon: 'collateral', section: 'SETUP'),
      const CoreMenuItem(title: 'Jam Operasional', routePath: '/setup/jam-operasional', page: 33, icon: 'clock', section: 'SETUP'),
      const CoreMenuItem(title: 'Hari Libur', routePath: '/setup/hari-libur', page: 34, icon: 'calendar-x', section: 'SETUP'),
      const CoreMenuItem(title: 'Jenis Inventaris', routePath: routeSetupInventaris, page: 19, icon: 'inventory', section: 'SETUP'),
      const CoreMenuItem(title: 'Kantor link ke HRIS', routePath: routeKantor, page: 1, icon: 'building', section: 'SETUP'),
      const CoreMenuItem(title: 'Sandi BI', routePath: routeSandi, page: 6, icon: 'sandi', section: 'SETUP'),
      const CoreMenuItem(title: 'GL', routePath: routeGl, page: 2, icon: 'accounting', section: 'SETUP'),
      const CoreMenuItem(title: 'SBB RAK', routePath: routeRak, page: 14, icon: 'rak', section: 'SETUP', parentTitle: 'RAK'),
      const CoreMenuItem(title: 'Rate RAK', routePath: routeRateRak, page: 15, icon: 'rak', section: 'SETUP', parentTitle: 'RAK'),
      const CoreMenuItem(title: 'PPAP', routePath: routePpap, page: 16, icon: 'ppap', section: 'SETUP'),
      const CoreMenuItem(title: 'Pajak Agregat', routePath: routePajakAgregat, page: 17, icon: 'tax', section: 'SETUP'),
      const CoreMenuItem(title: 'Kelompok Pihak Ketiga', routePath: routeKelompokPihakKetiga, page: 25, icon: 'group', section: 'SETUP'),
      const CoreMenuItem(title: 'Login User', routePath: routeUsers, page: 3, icon: 'group', section: 'MASTER', parentTitle: 'User Login & Akses'),
      const CoreMenuItem(
          title: 'User Access', routePath: routeUserAccess, page: 4, icon: 'user', section: 'MASTER', parentTitle: 'User Login & Akses'),
      const CoreMenuItem(title: 'Account Officer', routePath: routeAo, page: 5, icon: 'ao', section: 'MASTER'),
      const CoreMenuItem(title: 'ABA', routePath: routeAba, page: 20, icon: 'bank', section: 'MASTER'),
      const CoreMenuItem(title: 'Mitra Bisnis', routePath: routeMitraBisnis, page: 21, icon: 'group', section: 'MASTER'),
      const CoreMenuItem(title: 'Data Inventaris', routePath: routeInventaris, page: 22, icon: 'inventory', section: 'MASTER', parentTitle: 'Inventaris'),
      const CoreMenuItem(title: 'Penempatan Inventaris', routePath: routePenempatanInventaris, page: 30, icon: 'inventory', section: 'MASTER', parentTitle: 'Inventaris'),
      const CoreMenuItem(title: 'Revaluasi', routePath: routeRevaluasiInventaris, page: 28, icon: 'inventory', section: 'MASTER', parentTitle: 'Inventaris'),
      const CoreMenuItem(title: 'Penghapusan Inventaris', routePath: routePenghapusanInventaris, page: 29, icon: 'inventory', section: 'MASTER', parentTitle: 'Inventaris'),
      const CoreMenuItem(title: 'Kelompok Aset', routePath: routeKelompokAset, page: 27, icon: 'inventory', section: 'SETUP'),
      const CoreMenuItem(title: 'Target', routePath: routeRabMarketing, page: 23, icon: 'group', section: 'MASTER', parentTitle: 'RAB Marketing'),
      const CoreMenuItem(title: 'Realisasi', routePath: routeRabMarketingRealisasi, page: 31, icon: 'group', section: 'MASTER', parentTitle: 'RAB Marketing'),
      const CoreMenuItem(title: 'Target', routePath: routeRabKantor, page: 24, icon: 'building', section: 'MASTER', parentTitle: 'RAB Kantor'),
      const CoreMenuItem(title: 'Realisasi', routePath: routeRabKantorRealisasi, page: 32, icon: 'building', section: 'MASTER', parentTitle: 'RAB Kantor'),
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

  void _onSessionFailure() {
    final message = Setuprepository.sessionFailure.value;
    if (message != null) unawaited(_handleSessionFailure(message));
  }

  Future<void> _handleSessionFailure(String message) async {
    if (_isAutoLoggingOut) return;
    _isAutoLoggingOut = true;
    await _logoutLocal(showMessage: true, message: message);
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
        users = await Pref().getUsers();
        cmsCoreEnabled = PrefValue.boolFromDynamic(data['cms_core_enabled'], defaultValue: cmsCoreEnabled);
        idleTimeoutMinutes = PrefValue.intFromDynamic(data['idle_timeout_minutes'], idleTimeoutMinutes);
        fasilitas = await Pref().getCoreAccessList();
        _buildMenuItems();
        if (!silent) notifyListeners();
      }
    } else if (Setuprepository.isSessionFailure(value)) {
      await _handleSessionFailure(value?['message']?.toString() ?? 'Session berakhir');
    } else if (!silent && context.mounted) {
      informationDialog(context, 'Informasi', value?['message']?.toString() ?? 'Gagal memeriksa session. Silakan coba kembali.');
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
    Setuprepository.sessionFailure.removeListener(_onSessionFailure);
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
