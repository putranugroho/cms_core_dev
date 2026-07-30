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
    return CoreAccessModel(
      id: _toIntNullable(json['id']),
      menuId: _toIntNullable(json['menu_id']),
      userid: (json['userid'] ?? '').toString(),
      modul: (json['modul'] ?? '').toString(),
      menu: (json['menu'] ?? '').toString(),
      submenu: (json['submenu'] ?? '').toString(),
      subsubmenu: (json['subsubmenu'] ?? '').toString(),
      routePath: (json['route_path'] ?? '').toString(),
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

  Map<String, dynamic> toJson() => {
        'id': menuId ?? id,
        'menu_id': menuId ?? id,
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

  bool matchesRoute(String route) => routePath.trim().toLowerCase() == route.trim().toLowerCase();

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
