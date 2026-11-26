import 'dart:convert';

class CoreAccessModel {
  final int? id;
  final int? menuId;
  final String userid;
  final String modul;
  final String menu;
  final String submenu;
  final String subsubmenu;
  final String routePath;
  final bool canView;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;
  final bool canApprove;
  final bool canForceLogout;
  final String flag;

  const CoreAccessModel({
    this.id,
    this.menuId,
    required this.userid,
    required this.modul,
    required this.menu,
    required this.submenu,
    required this.subsubmenu,
    required this.routePath,
    required this.canView,
    required this.canCreate,
    required this.canUpdate,
    required this.canDelete,
    required this.canApprove,
    required this.canForceLogout,
    required this.flag,
  });

  factory CoreAccessModel.fromJson(Map<String, dynamic> json) {
    final routePath = (json['route_path'] ?? '').toString();
    final menuName = _normalizeMenuName((json['menu'] ?? '').toString(), routePath);
    final submenuName = _normalizeMenuName((json['submenu'] ?? '').toString(), routePath);
    return CoreAccessModel(
      id: _toIntNullable(json['id']),
      menuId: _toIntNullable(json['menu_id']),
      userid: (json['userid'] ?? '').toString(),
      modul: (json['modul'] ?? '').toString(),
      menu: menuName,
      submenu: submenuName,
      subsubmenu: (json['subsubmenu'] ?? '').toString(),
      routePath: routePath,
      canView: _toBool(json['can_view'] ?? json['flag'], defaultValue: true),
      canCreate: _toBool(json['can_create']),
      canUpdate: _toBool(json['can_update']),
      canDelete: _toBool(json['can_delete']),
      canApprove: _toBool(json['can_approve']),
      canForceLogout: _toBool(json['can_force_logout']),
      flag: (json['flag'] ?? '').toString(),
    );
  }


  CoreAccessModel copyWith({
    int? id,
    int? menuId,
    String? userid,
    String? modul,
    String? menu,
    String? submenu,
    String? subsubmenu,
    String? routePath,
    bool? canView,
    bool? canCreate,
    bool? canUpdate,
    bool? canDelete,
    bool? canApprove,
    bool? canForceLogout,
    String? flag,
  }) {
    return CoreAccessModel(
      id: id ?? this.id,
      menuId: menuId ?? this.menuId,
      userid: userid ?? this.userid,
      modul: modul ?? this.modul,
      menu: menu ?? this.menu,
      submenu: submenu ?? this.submenu,
      subsubmenu: subsubmenu ?? this.subsubmenu,
      routePath: routePath ?? this.routePath,
      canView: canView ?? this.canView,
      canCreate: canCreate ?? this.canCreate,
      canUpdate: canUpdate ?? this.canUpdate,
      canDelete: canDelete ?? this.canDelete,
      canApprove: canApprove ?? this.canApprove,
      canForceLogout: canForceLogout ?? this.canForceLogout,
      flag: flag ?? this.flag,
    );
  }

  // id on a user-access row belongs to that row; menu_id identifies the master.
  int? get masterMenuId {
    final reference = menuId;
    if (reference != null && reference > 0) return reference;
    final sourceId = id;
    return userid.trim().isEmpty && sourceId != null && sourceId > 0 ? sourceId : null;
  }

  String get hierarchyKey => jsonEncode([
        modul.trim().toLowerCase(),
        menu.trim().toLowerCase(),
        submenu.trim().toLowerCase(),
        subsubmenu.trim().toLowerCase(),
      ]);

  String get accessKey {
    final sourceId = masterMenuId;
    if (sourceId != null) return 'menu:${modul.trim().toLowerCase()}:$sourceId';
    if (menu.trim().isNotEmpty || submenu.trim().isNotEmpty) return 'hierarchy:$hierarchyKey';
    if (routePath.trim().isNotEmpty) return 'route:${routePath.trim().toLowerCase()}';
    return 'hierarchy:$hierarchyKey';
  }

  bool representsSameMenu(CoreAccessModel other) {
    final sourceId = masterMenuId;
    final otherId = other.masterMenuId;
    if (sourceId != null && otherId != null) {
      return sourceId == otherId && modul.trim().toLowerCase() == other.modul.trim().toLowerCase();
    }
    if (menu.trim().isNotEmpty && other.menu.trim().isNotEmpty) return hierarchyKey == other.hierarchyKey;
    return routePath.trim().isNotEmpty && other.routePath.trim().isNotEmpty && matchesRoute(other.routePath);
  }

  Map<String, dynamic> toJson() => {
        'id': masterMenuId,
        'menu_id': masterMenuId,
        'userid': userid,
        'modul': modul,
        'menu': menu,
        'submenu': submenu,
        'subsubmenu': subsubmenu,
        'route_path': routePath,
        'can_view': canView,
        'can_create': canCreate,
        'can_update': canUpdate,
        'can_delete': canDelete,
        'can_approve': canApprove,
        'can_force_logout': canForceLogout,
        'flag': flag,
      };

  bool matchesRoute(String route) => routePath.trim().isNotEmpty && routePath.trim().toLowerCase() == route.trim().toLowerCase();


  static String _normalizeMenuName(String value, String routePath) {
    final trimmed = value.trim();
    final isAoRoute = routePath.trim().toLowerCase() == '/master/ao';
    final isOldAoName = trimmed.toLowerCase() == 'ao / kolektor' || trimmed.toLowerCase() == 'ao/kolektor';
    if (isAoRoute || isOldAoName) return 'Account Officer';
    return value;
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return defaultValue;
    return text == 'true' || text == '1' || text == 'y' || text == 'yes' || text == 'aktif' || text == 'active';
  }

  static int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
