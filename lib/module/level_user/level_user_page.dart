import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/core_users_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';

class LevelUserPage extends StatefulWidget {
  const LevelUserPage({super.key});

  @override
  State<LevelUserPage> createState() => _LevelUserPageState();
}

class _LevelUserPageState extends State<LevelUserPage> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _menuSearch = TextEditingController();

  List<CoreUserModel> _users = [];
  List<CoreAccessModel> _masterMenus = [];
  List<CoreAccessModel> _draftAccess = [];
  List<CoreAccessModel> _unlistedAccess = [];
  int _detailRequestId = 0;
  CoreUserModel? _selectedUser;
  bool _loading = true;
  bool _loadingDetail = false;
  bool _detailLoaded = false;
  bool _saving = false;
  bool _currentIsSuperAdmin = false;
  bool _canUpdate = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final pref = Pref();
    _currentIsSuperAdmin = await pref.getIsSuperAdmin();
    final access = await pref.getCoreAccessList();
    CoreAccessModel? current;
    for (final item in access) {
      if (item.matchesRoute(MenuNotifier.routeUserAccess)) {
        current = item;
        break;
      }
    }
    _canUpdate = _currentIsSuperAdmin || (current?.canUpdate ?? false);
    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _detailLoaded = false;
    });
    try {
      final users = await CoreUsersRepository.listUsers(keyword: _search.text);
      final menus = await CoreUsersRepository.masterMenu();
      if (!mounted) return;
      setState(() {
        _users = users;
        _masterMenus = _dedupeMenus(menus);
        if (_selectedUser != null) {
          final found = _users.where((e) => e.userid == _selectedUser!.userid);
          _selectedUser = found.isEmpty ? null : found.first;
        }
        if (_selectedUser == null) {
          _detailRequestId++;
          _draftAccess = [];
          _unlistedAccess = [];
          _loadingDetail = false;
        }
      });
      final selected = _selectedUser;
      if (selected != null) await _selectUser(selected);
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CoreAccessModel> _dedupeMenus(List<CoreAccessModel> source) {
    final seen = <String>{};
    final out = <CoreAccessModel>[];
    for (final item in source) {
      if (item.matchesRoute('/master/agunan')) continue;
      if (item.menu.trim().isEmpty && item.submenu.trim().isEmpty && item.routePath.trim().isEmpty) continue;
      final key = item.accessKey;
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(item.copyWith(
          menuId: item.masterMenuId,
          canView: false, canCreate: false, canUpdate: false, canDelete: false, canApprove: false, canForceLogout: false, flag: 'false'));
    }
    return out;
  }

  Future<void> _selectUser(CoreUserModel user) async {
    final requestId = ++_detailRequestId;
    setState(() {
      _selectedUser = user;
      _loadingDetail = true;
      _detailLoaded = false;
      _draftAccess = [];
      _unlistedAccess = [];
    });

    try {
      final detailRaw = await CoreUsersRepository.detailRaw(user.userid);
      final detail = CoreUserModel.fromJson(detailRaw);
      final existing = <CoreAccessModel>[];
      final rawAccess = detailRaw['fasilitas'];
      if (rawAccess is List) {
        for (final item in rawAccess.whereType<Map>()) {
          final access = CoreAccessModel.fromJson(Map<String, dynamic>.from(item));
          existing.add(access);
        }
      }

      final draft = _masterMenus.map((menu) {
        CoreAccessModel? old;
        for (final access in existing) {
          if (menu.representsSameMenu(access)) {
            old = access;
            break;
          }
        }
        if (old == null) return menu;
        return menu.copyWith(
          userid: detail.userid,
          canView: old.canView,
          canCreate: old.canCreate,
          canUpdate: old.canUpdate,
          canDelete: old.canDelete,
          canApprove: old.canApprove,
          canForceLogout: old.canForceLogout,
          flag: old.canView.toString(),
        );
      }).toList();

      if (!mounted || requestId != _detailRequestId) return;
      setState(() {
        _selectedUser = detail;
        _draftAccess = draft;
        _detailLoaded = true;
        // Keep saved permissions not present in this catalogue until explicitly managed.
        _unlistedAccess = existing.where((access) => !_masterMenus.any((menu) => menu.representsSameMenu(access))).toList();
      });
    } catch (e) {
      if (mounted && requestId == _detailRequestId) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted && requestId == _detailRequestId) setState(() => _loadingDetail = false);
    }
  }

  void _updateAccess(int index, CoreAccessModel item) {
    setState(() => _draftAccess[index] = item);
  }

  void _setView(int index, bool value) {
    final item = _draftAccess[index];
    if (!value) {
      _updateAccess(
          index,
          item.copyWith(
              canView: false, canCreate: false, canUpdate: false, canDelete: false, canApprove: false, canForceLogout: false, flag: 'false'));
      return;
    }
    _updateAccess(index, item.copyWith(canView: true, flag: 'true'));
  }

  void _setAction(int index, String action, bool value) {
    final item = _draftAccess[index];
    var next = item.copyWith(canView: value ? true : item.canView, flag: value ? 'true' : item.flag);
    switch (action) {
      case 'create':
        next = next.copyWith(canCreate: value);
        break;
      case 'update':
        next = next.copyWith(canUpdate: value);
        break;
      case 'delete':
        next = next.copyWith(canDelete: value);
        break;
      case 'approve':
        next = next.copyWith(canApprove: value);
        break;
      case 'force_logout':
        next = next.copyWith(canForceLogout: value);
        break;
    }
    _updateAccess(index, next);
  }

  String _groupKey(CoreAccessModel item) {
    final modul = item.modul.trim().toUpperCase();
    return modul.isEmpty ? 'LAINNYA' : modul;
  }

  String _groupTitle(CoreAccessModel item) => _groupKey(item);

  String _childTitle(CoreAccessModel item) {
    final parts = <String>[];
    for (final value in [item.menu, item.submenu, item.subsubmenu]) {
      final title = value.trim();
      if (title.isEmpty) continue;
      if (parts.isNotEmpty && parts.last.toLowerCase() == title.toLowerCase()) continue;
      parts.add(title);
    }
    return parts.isEmpty ? item.routePath : parts.join(' / ');
  }

  List<_AccessGroup> get _groupedAccess {
    final q = _menuSearch.text.trim().toLowerCase();
    final groups = <String, _AccessGroup>{};

    for (final item in _draftAccess) {
      final groupKey = _groupKey(item);
      final groupTitle = _groupTitle(item);
      groups.putIfAbsent(groupKey, () => _AccessGroup(key: groupKey, title: groupTitle, items: <CoreAccessModel>[]));
      groups[groupKey]!.items.add(item);
    }

    if (q.isEmpty) return groups.values.toList();

    return groups.values.where((group) {
      final groupMatch = group.title.toLowerCase().contains(q);
      final childMatch = group.items.any((item) {
        return _childTitle(item).toLowerCase().contains(q) ||
            item.modul.toLowerCase().contains(q) ||
            item.menu.toLowerCase().contains(q) ||
            item.submenu.toLowerCase().contains(q) ||
            item.subsubmenu.toLowerCase().contains(q) ||
            item.routePath.toLowerCase().contains(q);
      });
      return groupMatch || childMatch;
    }).toList();
  }

  bool _groupEnabled(_AccessGroup group) {
    return group.items.any((item) => item.canView || item.canCreate || item.canUpdate || item.canDelete);
  }

  void _setGroupAccess(_AccessGroup group, bool enabled) {
    final targets = group.items.map((e) => e.accessKey).toSet();
    if (targets.isEmpty) return;

    setState(() {
      for (var i = 0; i < _draftAccess.length; i++) {
        final item = _draftAccess[i];
        final key = item.accessKey;
        if (!targets.contains(key)) continue;

        if (enabled) {
          _draftAccess[i] = item.copyWith(
            canView: true,
            canCreate: true,
            canUpdate: true,
            canDelete: true,
            canApprove: false,
            canForceLogout: false,
            flag: 'true',
          );
        } else {
          _draftAccess[i] = item.copyWith(
            canView: false,
            canCreate: false,
            canUpdate: false,
            canDelete: false,
            canApprove: false,
            canForceLogout: false,
            flag: 'false',
          );
        }
      }
    });
  }

  void _setAllFilteredView(bool value) {
    final targets = _filteredAccess.map((e) => e.accessKey).toSet();
    if (targets.isEmpty) return;

    setState(() {
      for (var i = 0; i < _draftAccess.length; i++) {
        final item = _draftAccess[i];
        final key = item.accessKey;
        if (!targets.contains(key)) continue;

        if (value) {
          _draftAccess[i] = item.copyWith(canView: true, flag: 'true');
        } else {
          _draftAccess[i] = item.copyWith(
            canView: false,
            canCreate: false,
            canUpdate: false,
            canDelete: false,
            canApprove: false,
            canForceLogout: false,
            flag: 'false',
          );
        }
      }
    });
  }

  Future<void> _saveAccess() async {
    final user = _selectedUser;
    if (user == null) {
      informationDialog(context, 'Informasi', 'Pilih user terlebih dahulu.');
      return;
    }
    if (!_detailLoaded || _loading || _saving) {
      informationDialog(context, 'Informasi', 'Tunggu data akses user berhasil dimuat sebelum menyimpan.');
      return;
    }
    if (user.isSuperAdmin) {
      informationDialog(context, 'Informasi', 'User super admin otomatis mendapat semua fasilitas tanpa perlu dipilih.');
      return;
    }
    if (!_canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update User Access.');
      return;
    }

    final selected = [
      ..._unlistedAccess.where((e) => e.canView),
      ..._draftAccess.where((e) => e.canView).map((e) => e.copyWith(canApprove: false, canForceLogout: false)),
    ];
    setState(() => _saving = true);
    try {
      await CoreUsersRepository.saveUserAccessOnly(user: user, fasilitas: selected);
      if (mounted) informationDialog(context, 'Informasi', 'User access berhasil disimpan.');
      await _selectUser(user);
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<CoreAccessModel> get _filteredAccess {
    final q = _menuSearch.text.trim().toLowerCase();
    if (q.isEmpty) return _draftAccess;
    return _draftAccess.where((e) {
      return e.menu.toLowerCase().contains(q) ||
          e.submenu.toLowerCase().contains(q) ||
          e.subsubmenu.toLowerCase().contains(q) ||
          e.modul.toLowerCase().contains(q) ||
          e.routePath.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _detailRequestId++;
    _search.dispose();
    _menuSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 86,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Access', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Atur fasilitas/menu dan action permission akun CMS Core.', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _loadAll,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          if (_saving || _loadingDetail) const LinearProgressIndicator(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 340,
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: TextField(
                                    controller: _search,
                                    decoration: InputDecoration(
                                      hintText: 'Cari user',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _loadAll),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    onSubmitted: (_) => _loadAll(),
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: _users.isEmpty
                                      ? const Center(child: Text('User kosong.'))
                                      : ListView.separated(
                                          itemCount: _users.length,
                                          separatorBuilder: (_, __) => const Divider(height: 1),
                                          itemBuilder: (_, i) {
                                            final user = _users[i];
                                            final selected = _selectedUser?.userid == user.userid;
                                            return ListTile(
                                              selected: selected,
                                              selectedTileColor: colorPrimary.withOpacity(0.08),
                                              onTap: () => _selectUser(user),
                                              leading: CircleAvatar(
                                                backgroundColor: user.isSuperAdmin ? Colors.green : colorPrimary,
                                                child: Icon(user.isSuperAdmin ? Icons.verified_user : Icons.person, color: Colors.white),
                                              ),
                                              title: Text(user.userid, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              subtitle:
                                                  Text('${user.namauser}\nKantor: ${user.kodeKantor}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                              trailing: Icon(user.isActive ? Icons.check_circle : Icons.block,
                                                  color: user.isActive ? Colors.green : Colors.red),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                            child: _selectedUser == null
                                ? const Center(child: Text('Pilih user untuk mengatur access.'))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('${_selectedUser!.userid} - ${_selectedUser!.namauser}',
                                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _selectedUser!.isSuperAdmin
                                                            ? 'SUPER ADMIN: otomatis dapat semua fasilitas tanpa perlu checkbox.'
                                                            : 'Satu section untuk setiap modul. Toggle modul mengatur View, Tambah, Ubah, dan Hapus semua menu di dalamnya.',
                                                        style: TextStyle(color: _selectedUser!.isSuperAdmin ? Colors.green : Colors.black54),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Builder(
                                                  builder: (_) {
                                                    final actionDisabled = _saving || _loadingDetail || !_detailLoaded || _selectedUser!.isSuperAdmin || !_canUpdate;
                                                    return ElevatedButton.icon(
                                                      onPressed: actionDisabled ? null : _saveAccess,
                                                      icon: const Icon(Icons.save),
                                                      label: const Text('Simpan Access'),
                                                      style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),
                                            TextField(
                                              controller: _menuSearch,
                                              decoration: InputDecoration(
                                                hintText: 'Cari menu / route',
                                                prefixIcon: const Icon(Icons.search),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Expanded(
                                        child: _loadingDetail
                                            ? const Center(child: CircularProgressIndicator())
                                            : _GroupedAccessList(
                                                disabled: _selectedUser!.isSuperAdmin || !_canUpdate,
                                                groups: _groupedAccess,
                                                sourceAccess: _draftAccess,
                                                groupEnabled: _groupEnabled,
                                                childTitleBuilder: _childTitle,
                                                onGroupChanged: _setGroupAccess,
                                                onViewChanged: _setView,
                                                onActionChanged: _setAction,
                                              ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccessGroup {
  final String key;
  final String title;
  final List<CoreAccessModel> items;

  const _AccessGroup({required this.key, required this.title, required this.items});
}

class _GroupedAccessList extends StatelessWidget {
  final bool disabled;
  final List<_AccessGroup> groups;
  final List<CoreAccessModel> sourceAccess;
  final bool Function(_AccessGroup group) groupEnabled;
  final String Function(CoreAccessModel item) childTitleBuilder;
  final void Function(_AccessGroup group, bool value) onGroupChanged;
  final void Function(int index, bool value) onViewChanged;
  final void Function(int index, String action, bool value) onActionChanged;

  const _GroupedAccessList({
    required this.disabled,
    required this.groups,
    required this.sourceAccess,
    required this.groupEnabled,
    required this.childTitleBuilder,
    required this.onGroupChanged,
    required this.onViewChanged,
    required this.onActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (sourceAccess.isEmpty) {
      return const Center(child: Text('Master menu belum tersedia.'));
    }
    if (groups.isEmpty) {
      return const Center(child: Text('Menu tidak ditemukan.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final group = groups[i];
        final enabled = groupEnabled(group);
        return _AccessGroupCard(
          disabled: disabled,
          group: group,
          enabled: enabled,
          sourceAccess: sourceAccess,
          childTitleBuilder: childTitleBuilder,
          onGroupChanged: onGroupChanged,
          onViewChanged: onViewChanged,
          onActionChanged: onActionChanged,
        );
      },
    );
  }
}

class _AccessGroupCard extends StatelessWidget {
  final bool disabled;
  final _AccessGroup group;
  final bool enabled;
  final List<CoreAccessModel> sourceAccess;
  final String Function(CoreAccessModel item) childTitleBuilder;
  final void Function(_AccessGroup group, bool value) onGroupChanged;
  final void Function(int index, bool value) onViewChanged;
  final void Function(int index, String action, bool value) onActionChanged;

  const _AccessGroupCard({
    required this.disabled,
    required this.group,
    required this.enabled,
    required this.sourceAccess,
    required this.childTitleBuilder,
    required this.onGroupChanged,
    required this.onViewChanged,
    required this.onActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeMenuCount = group.items.where((item) => item.canView).length;
    return Container(
      decoration: BoxDecoration(
        color: enabled ? colorPrimary.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: enabled ? colorPrimary.withOpacity(0.45) : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Switch(
                  value: enabled,
                  activeColor: colorPrimary,
                  onChanged: disabled ? null : (v) => onGroupChanged(group, v),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(
                        enabled
                            ? '$activeMenuCount dari ${group.items.length} menu memiliki akses View.'
                            : '${group.items.length} menu. Aktifkan modul ini untuk menampilkan menu dan memberi akses dasar.',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Icon(enabled ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: enabled ? colorPrimary : Colors.black45),
              ],
            ),
          ),
          if (enabled) ...[
            const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 950,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AccessHeaderRow(),
                    ...group.items.map((item) {
                      final index = sourceAccess.indexWhere((e) => e.accessKey == item.accessKey);
                      return _AccessChildRow(
                        disabled: disabled,
                        item: item,
                        index: index,
                        title: childTitleBuilder(item),
                        onViewChanged: onViewChanged,
                        onActionChanged: onActionChanged,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessHeaderRow extends StatelessWidget {
  const _AccessHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorPrimary.withOpacity(0.12),
      child: const Row(
        children: [
          SizedBox(width: 300, child: Text('Menu / Submenu', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 240, child: Text('Route', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 80, child: Text('View', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 90, child: Text('Tambah', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 90, child: Text('Ubah', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 90, child: Text('Hapus', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _AccessChildRow extends StatelessWidget {
  final bool disabled;
  final CoreAccessModel item;
  final int index;
  final String title;
  final void Function(int index, bool value) onViewChanged;
  final void Function(int index, String action, bool value) onActionChanged;

  const _AccessChildRow({
    required this.disabled,
    required this.item,
    required this.index,
    required this.title,
    required this.onViewChanged,
    required this.onActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final indexValid = index >= 0;
    final permissionDisabled = disabled || !indexValid;
    final actionDisabled = permissionDisabled || !item.canView;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: Tooltip(
              message: title,
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(
            width: 240,
            child: Text(
              item.routePath.trim().isEmpty ? '—' : item.routePath,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 80,
            child: _SwitchCell(
              value: item.canView,
              disabled: permissionDisabled,
              onChanged: (v) => onViewChanged(index, v),
            ),
          ),
          SizedBox(
            width: 90,
            child: _SwitchCell(
              value: item.canCreate,
              disabled: actionDisabled,
              onChanged: (v) => onActionChanged(index, 'create', v),
            ),
          ),
          SizedBox(
            width: 90,
            child: _SwitchCell(
              value: item.canUpdate,
              disabled: actionDisabled,
              onChanged: (v) => onActionChanged(index, 'update', v),
            ),
          ),
          SizedBox(
            width: 90,
            child: _SwitchCell(
              value: item.canDelete,
              disabled: actionDisabled,
              onChanged: (v) => onActionChanged(index, 'delete', v),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchCell extends StatelessWidget {
  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  const _SwitchCell({required this.value, required this.disabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Checkbox(
        value: value,
        activeColor: colorPrimary,
        onChanged: disabled ? null : (v) => onChanged(v ?? false),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
  }
}
