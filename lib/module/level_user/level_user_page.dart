import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/menu/menu_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:accounting_kantor_gl_useraccess/repository/core_users_repository.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
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
  CoreUserModel? _selectedUser;
  bool _loading = true;
  bool _loadingDetail = false;
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
    setState(() => _loading = true);
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
      });
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
      final key = item.routePath.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(item.copyWith(canView: false, canCreate: false, canUpdate: false, canDelete: false, canApprove: false, canForceLogout: false, flag: 'false'));
    }
    out.sort((a, b) => a.routePath.compareTo(b.routePath));
    return out;
  }

  Future<void> _selectUser(CoreUserModel user) async {
    setState(() {
      _selectedUser = user;
      _loadingDetail = true;
      _draftAccess = [];
    });

    try {
      final detailRaw = await CoreUsersRepository.detailRaw(user.userid);
      final detail = CoreUserModel.fromJson(detailRaw);
      final existing = <String, CoreAccessModel>{};
      final rawAccess = detailRaw['fasilitas'];
      if (rawAccess is List) {
        for (final item in rawAccess.whereType<Map>()) {
          final access = CoreAccessModel.fromJson(Map<String, dynamic>.from(item));
          existing[access.routePath.trim().toLowerCase()] = access;
        }
      }

      final draft = _masterMenus.map((menu) {
        final old = existing[menu.routePath.trim().toLowerCase()];
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

      if (!mounted) return;
      setState(() {
        _selectedUser = detail;
        _draftAccess = draft;
      });
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  void _updateAccess(int index, CoreAccessModel item) {
    setState(() => _draftAccess[index] = item);
  }

  void _setView(int index, bool value) {
    final item = _draftAccess[index];
    if (!value) {
      _updateAccess(index, item.copyWith(canView: false, canCreate: false, canUpdate: false, canDelete: false, canApprove: false, canForceLogout: false, flag: 'false'));
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

  Future<void> _saveAccess() async {
    final user = _selectedUser;
    if (user == null) {
      informationDialog(context, 'Informasi', 'Pilih user terlebih dahulu.');
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

    final selected = _draftAccess.where((e) => e.canView).toList();
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
          e.modul.toLowerCase().contains(q) ||
          e.routePath.toLowerCase().contains(q);
    }).toList();
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
                                              subtitle: Text('${user.namauser}\nKantor: ${user.kodeKantor}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                              trailing: Icon(user.isActive ? Icons.check_circle : Icons.block, color: user.isActive ? Colors.green : Colors.red),
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
                                                      Text('${_selectedUser!.userid} - ${_selectedUser!.namauser}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _selectedUser!.isSuperAdmin
                                                            ? 'SUPER ADMIN: otomatis dapat semua fasilitas tanpa perlu checkbox.'
                                                            : 'Centang menu dan action yang boleh dipakai user ini.',
                                                        style: TextStyle(color: _selectedUser!.isSuperAdmin ? Colors.green : Colors.black54),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: (_saving || _selectedUser!.isSuperAdmin || !_canUpdate) ? null : _saveAccess,
                                                  icon: const Icon(Icons.save),
                                                  label: const Text('Simpan Access'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
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
                                            : _AccessTable(
                                                disabled: _selectedUser!.isSuperAdmin || !_canUpdate,
                                                access: _filteredAccess,
                                                sourceAccess: _draftAccess,
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

class _AccessTable extends StatelessWidget {
  final bool disabled;
  final List<CoreAccessModel> access;
  final List<CoreAccessModel> sourceAccess;
  final void Function(int index, bool value) onViewChanged;
  final void Function(int index, String action, bool value) onActionChanged;

  const _AccessTable({
    required this.disabled,
    required this.access,
    required this.sourceAccess,
    required this.onViewChanged,
    required this.onActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (sourceAccess.isEmpty) {
      return const Center(child: Text('Master menu belum tersedia.'));
    }
    if (access.isEmpty) {
      return const Center(child: Text('Menu tidak ditemukan.'));
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(colorPrimary),
            columns: const [
              DataColumn(label: _HeaderText('Menu')),
              DataColumn(label: _HeaderText('Route')),
              DataColumn(label: _HeaderText('View')),
              DataColumn(label: _HeaderText('Tambah')),
              DataColumn(label: _HeaderText('Update')),
              DataColumn(label: _HeaderText('Delete')),
              DataColumn(label: _HeaderText('Approve')),
              DataColumn(label: _HeaderText('Force Logout')),
            ],
            rows: access.map((item) {
              final index = sourceAccess.indexWhere((e) => e.routePath == item.routePath);
              return DataRow(cells: [
                DataCell(SizedBox(width: 180, child: Text(_menuTitle(item), overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 220, child: Text(item.routePath, overflow: TextOverflow.ellipsis))),
                DataCell(_SwitchCell(value: item.canView, disabled: disabled, onChanged: (v) { if (index >= 0) onViewChanged(index, v); })),
                DataCell(_SwitchCell(value: item.canCreate, disabled: disabled || !item.canView, onChanged: (v) { if (index >= 0) onActionChanged(index, 'create', v); })),
                DataCell(_SwitchCell(value: item.canUpdate, disabled: disabled || !item.canView, onChanged: (v) { if (index >= 0) onActionChanged(index, 'update', v); })),
                DataCell(_SwitchCell(value: item.canDelete, disabled: disabled || !item.canView, onChanged: (v) { if (index >= 0) onActionChanged(index, 'delete', v); })),
                DataCell(_SwitchCell(value: item.canApprove, disabled: disabled || !item.canView, onChanged: (v) { if (index >= 0) onActionChanged(index, 'approve', v); })),
                DataCell(_SwitchCell(value: item.canForceLogout, disabled: disabled || !item.canView, onChanged: (v) { if (index >= 0) onActionChanged(index, 'force_logout', v); })),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _menuTitle(CoreAccessModel item) {
    if (item.menu.trim().isNotEmpty) return item.menu;
    if (item.submenu.trim().isNotEmpty) return item.submenu;
    return item.routePath;
  }
}

class _SwitchCell extends StatelessWidget {
  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  const _SwitchCell({required this.value, required this.disabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(value: value, onChanged: disabled ? null : onChanged, activeColor: colorPrimary);
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
