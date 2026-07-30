import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/menu/menu_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/pref/pref.dart';
import 'package:accounting_kantor_gl_useraccess/repository/core_users_repository.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _search = TextEditingController();
  List<CoreUserModel> _users = [];
  CoreUserModel? _selected;
  bool _loading = true;
  bool _actionLoading = false;
  bool _currentIsSuperAdmin = false;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;
  bool _canForceLogout = false;

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
      if (item.matchesRoute(MenuNotifier.routeUsers)) {
        current = item;
        break;
      }
    }
    _canCreate = _currentIsSuperAdmin || (current?.canCreate ?? false);
    _canUpdate = _currentIsSuperAdmin || (current?.canUpdate ?? false);
    _canDelete = _currentIsSuperAdmin || (current?.canDelete ?? false);
    _canForceLogout = _currentIsSuperAdmin || (current?.canForceLogout ?? false);
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final list = await CoreUsersRepository.listUsers(keyword: _search.text);
      if (!mounted) return;
      setState(() {
        _users = list;
        if (_selected != null) {
          final found = list.where((e) => e.userid == _selected!.userid);
          _selected = found.isEmpty ? null : found.first;
        }
      });
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({CoreUserModel? user}) async {
    if (user == null && !_canCreate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses tambah user.');
      return;
    }
    if (user != null && !_canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses update user.');
      return;
    }

    CoreUserModel detail = user ?? CoreUserModel.empty();
    if (user != null) {
      try {
        detail = await CoreUsersRepository.detailUser(user.userid);
      } catch (e) {
        if (mounted) informationDialog(context, 'Warning', e.toString());
        return;
      }
    }

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserFormDialog(
        user: detail,
        isEdit: user != null,
        currentIsSuperAdmin: _currentIsSuperAdmin,
      ),
    );
    if (saved == true) await _loadUsers();
  }

  Future<bool> _confirm(String title, String message, String yesText) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(yesText)),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _setActive(bool active) async {
    final user = _selected;
    if (user == null) {
      informationDialog(context, 'Informasi', 'Pilih user terlebih dahulu.');
      return;
    }
    if (!_canDelete) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses mengaktifkan/nonaktifkan user.');
      return;
    }
    final ok = await _confirm(
      active ? 'Aktifkan user?' : 'Nonaktifkan user?',
      active ? 'User ${user.userid} akan diaktifkan kembali.' : 'User ${user.userid} akan dinonaktifkan dan session aktifnya ditutup.',
      active ? 'Aktifkan' : 'Nonaktifkan',
    );
    if (!ok) return;

    setState(() => _actionLoading = true);
    try {
      await CoreUsersRepository.setActive(user.userid, active);
      if (mounted) informationDialog(context, 'Informasi', active ? 'User berhasil diaktifkan.' : 'User berhasil dinonaktifkan.');
      await _loadUsers();
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _forceLogout() async {
    final user = _selected;
    if (user == null) {
      informationDialog(context, 'Informasi', 'Pilih user terlebih dahulu.');
      return;
    }
    if (!_canForceLogout) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses paksa logout user.');
      return;
    }
    final ok = await _confirm('Paksa logout?', 'Tutup semua session aktif milik ${user.userid}?', 'Logout');
    if (!ok) return;

    setState(() => _actionLoading = true);
    try {
      await CoreUsersRepository.forceLogout(user.userid);
      if (mounted) informationDialog(context, 'Informasi', 'Force logout berhasil.');
      await _loadUsers();
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _unlock() async {
    final user = _selected;
    if (user == null) {
      informationDialog(context, 'Informasi', 'Pilih user terlebih dahulu.');
      return;
    }
    if (!_canUpdate) {
      informationDialog(context, 'Akses Ditolak', 'Anda tidak memiliki akses unlock user.');
      return;
    }
    final ok = await _confirm('Buka lock user?', 'Reset counter salah password dan buka lock ${user.userid}?', 'Unlock');
    if (!ok) return;

    setState(() => _actionLoading = true);
    try {
      await CoreUsersRepository.unlock(user.userid);
      if (mounted) informationDialog(context, 'Informasi', 'User berhasil di-unlock.');
      await _loadUsers();
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Color _statusColor(CoreUserModel user) {
    if (!user.isActive) return Colors.red;
    if (user.isLocked) return Colors.orange;
    return Colors.green;
  }

  String _statusText(CoreUserModel user) {
    if (!user.isActive) return 'NONAKTIF';
    if (user.isLocked) return 'LOCKED';
    return 'AKTIF';
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
                      Text('Login User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Kelola akun login CMS Core, status akun, session, dan super admin.', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Cari userid / nama',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _loadUsers(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _canCreate ? () => _openForm() : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah User'),
                  style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          if (_actionLoading) const LinearProgressIndicator(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selected == null ? 'Pilih user dari tabel untuk aksi cepat.' : 'Terpilih: ${_selected!.userid} - ${_selected!.namauser}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                _ActionButton(label: 'Update', icon: Icons.edit, enabled: _selected != null && _canUpdate, onTap: () => _openForm(user: _selected)),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  label: _selected?.isActive == false ? 'Aktifkan' : 'Nonaktifkan',
                                  icon: _selected?.isActive == false ? Icons.check_circle : Icons.block,
                                  enabled: _selected != null && _canDelete,
                                  color: _selected?.isActive == false ? Colors.green : Colors.red,
                                  onTap: () => _setActive(!(_selected?.isActive ?? true)),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(label: 'Force Logout', icon: Icons.logout, enabled: _selected != null && _canForceLogout, color: Colors.orange, onTap: _forceLogout),
                                const SizedBox(width: 8),
                                _ActionButton(label: 'Unlock', icon: Icons.lock_open, enabled: _selected != null && _canUpdate, color: Colors.indigo, onTap: _unlock),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: _users.isEmpty
                                ? const Center(child: Text('Data user masih kosong.'))
                                : Scrollbar(
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SingleChildScrollView(
                                        child: DataTable(
                                          showCheckboxColumn: false,
                                          headingRowColor: MaterialStateProperty.all(colorPrimary),
                                          columns: const [
                                            DataColumn(label: _HeaderText('User ID')),
                                            DataColumn(label: _HeaderText('Nama User')),
                                            DataColumn(label: _HeaderText('Kantor')),
                                            DataColumn(label: _HeaderText('BPR')),
                                            DataColumn(label: _HeaderText('Expired')),
                                            DataColumn(label: _HeaderText('Status')),
                                            DataColumn(label: _HeaderText('Super Admin')),
                                            DataColumn(label: _HeaderText('Salah Pass')),
                                            DataColumn(label: _HeaderText('Last Login')),
                                          ],
                                          rows: _users.map((user) {
                                            final selected = _selected?.userid == user.userid;
                                            return DataRow(
                                              selected: selected,
                                              onSelectChanged: (_) => setState(() => _selected = user),
                                              cells: [
                                                DataCell(Text(user.userid, style: const TextStyle(fontWeight: FontWeight.bold))),
                                                DataCell(SizedBox(width: 220, child: Text(user.namauser, overflow: TextOverflow.ellipsis))),
                                                DataCell(Text(user.kodeKantor)),
                                                DataCell(Text(user.bprId)),
                                                DataCell(Text(_formatDate(user.tglExpired))),
                                                DataCell(_StatusChip(label: _statusText(user), color: _statusColor(user))),
                                                DataCell(Icon(user.isSuperAdmin ? Icons.verified_user : Icons.person, color: user.isSuperAdmin ? Colors.green : Colors.grey)),
                                                DataCell(Text(user.wrongPasswordCount.toString())),
                                                DataCell(Text(_formatDate(user.lastLoginAt))),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty || raw == '<nil>') return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(raw.replaceFirst(' ', 'T')));
    } catch (_) {
      return raw;
    }
  }
}

class _UserFormDialog extends StatefulWidget {
  final CoreUserModel user;
  final bool isEdit;
  final bool currentIsSuperAdmin;

  const _UserFormDialog({required this.user, required this.isEdit, required this.currentIsSuperAdmin});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _userid;
  late final TextEditingController _nama;
  late final TextEditingController _password;
  late final TextEditingController _kodeKantor;
  late final TextEditingController _bprId;
  late final TextEditingController _tglExpired;
  bool _isActive = true;
  bool _isSuperAdmin = false;
  bool _obscure = true;
  bool _saving = false;
  List<CoreAccessModel> _existingAccess = [];

  @override
  void initState() {
    super.initState();
    _userid = TextEditingController(text: widget.user.userid);
    _nama = TextEditingController(text: widget.user.namauser);
    _password = TextEditingController();
    _kodeKantor = TextEditingController(text: widget.user.kodeKantor);
    _bprId = TextEditingController(text: widget.user.bprId);
    _tglExpired = TextEditingController(text: _dateOnly(widget.user.tglExpired));
    _isActive = widget.user.isActive;
    _isSuperAdmin = widget.user.isSuperAdmin;
    if (widget.isEdit) _loadAccess();
  }

  Future<void> _loadAccess() async {
    try {
      _existingAccess = await CoreUsersRepository.userAccess(widget.user.userid);
    } catch (_) {
      _existingAccess = [];
    }
  }

  @override
  void dispose() {
    _userid.dispose();
    _nama.dispose();
    _password.dispose();
    _kodeKantor.dispose();
    _bprId.dispose();
    _tglExpired.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    try {
      if (_tglExpired.text.trim().isNotEmpty) {
        initial = DateTime.parse(_tglExpired.text.trim());
      }
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      _tglExpired.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await CoreUsersRepository.saveUser(
        userid: _userid.text,
        password: _password.text,
        namauser: _nama.text,
        kodeKantor: _kodeKantor.text,
        bprId: _bprId.text,
        tglExpired: _tglExpired.text,
        isActive: _isActive,
        isSuperAdmin: _isSuperAdmin,
        fasilitas: widget.isEdit ? _existingAccess : <CoreAccessModel>[],
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 620,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.isEdit ? 'Update Login User' : 'Tambah Login User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _userid,
                  readOnly: widget.isEdit,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'User ID', border: OutlineInputBorder()),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'User ID wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nama,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Nama User', border: OutlineInputBorder()),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Nama user wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: widget.isEdit ? 'Password baru (kosongkan jika tidak diubah)' : 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (!widget.isEdit && (v ?? '').trim().isEmpty) return 'Password wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _kodeKantor,
                        decoration: const InputDecoration(labelText: 'Kode Kantor', border: OutlineInputBorder()),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Kode kantor wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bprId,
                        decoration: const InputDecoration(labelText: 'BPR ID', border: OutlineInputBorder()),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'BPR ID wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _tglExpired,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(labelText: 'Tanggal Expired', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_month)),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('User aktif'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _isSuperAdmin,
                  onChanged: widget.currentIsSuperAdmin ? (v) => setState(() => _isSuperAdmin = v) : null,
                  title: const Text('Super admin'),
                  subtitle: const Text('Super admin otomatis dapat semua fasilitas dan dapat menyalakan/mematikan CMS Core.'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Batal'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
                        child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateOnly(String raw) {
    if (raw.trim().isEmpty || raw == '<nil>') return '';
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(raw.replaceFirst(' ', 'T')));
    } catch (_) {
      if (raw.length >= 10) return raw.substring(0, 10);
      return raw;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.enabled, required this.onTap, this.color = colorPrimary});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(99), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
