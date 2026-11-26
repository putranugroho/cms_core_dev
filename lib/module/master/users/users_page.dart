import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/core_users_repository.dart';
import 'package:cms_core/repository/hris_repository.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/informationdialog.dart';
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
        existingUsers: _users,
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
                                    _selected == null
                                        ? 'Pilih user dari tabel untuk aksi cepat.'
                                        : 'Terpilih: ${_selected!.userid} - ${_selected!.namauser}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                _ActionButton(
                                    label: 'Update',
                                    icon: Icons.edit,
                                    enabled: _selected != null && _canUpdate,
                                    onTap: () => _openForm(user: _selected)),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  label: _selected?.isActive == false ? 'Aktifkan' : 'Nonaktifkan',
                                  icon: _selected?.isActive == false ? Icons.check_circle : Icons.block,
                                  enabled: _selected != null && _canDelete,
                                  color: _selected?.isActive == false ? Colors.green : Colors.red,
                                  onTap: () => _setActive(!(_selected?.isActive ?? true)),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                    label: 'Force Logout',
                                    icon: Icons.logout,
                                    enabled: _selected != null && _canForceLogout,
                                    color: Colors.orange,
                                    onTap: _forceLogout),
                                const SizedBox(width: 8),
                                _ActionButton(
                                    label: 'Unlock',
                                    icon: Icons.lock_open,
                                    enabled: _selected != null && _canUpdate,
                                    color: Colors.indigo,
                                    onTap: _unlock),
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
                                                DataCell(Icon(user.isSuperAdmin ? Icons.verified_user : Icons.person,
                                                    color: user.isSuperAdmin ? Colors.green : Colors.grey)),
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
  final List<CoreUserModel> existingUsers;

  const _UserFormDialog({required this.user, required this.isEdit, required this.currentIsSuperAdmin, required this.existingUsers});

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
  late final TextEditingController _hrisEmployeeId;
  late final TextEditingController _hrisEmployeeNo;
  final TextEditingController _employeeSearch = TextEditingController();

  bool _isActive = true;
  bool _isSuperAdmin = false;
  bool _obscure = true;
  bool _changePassword = false;
  bool _saving = false;
  bool _loadingEmployee = false;
  bool _loadingKantor = true;
  bool _renewingKodeKantor = false;

  List<CoreAccessModel> _existingAccess = [];
  List<KantorModel> _kantorOptions = [];
  List<HrisEmployeeModel> _employeeResults = [];
  HrisEmployeeModel? _selectedEmployee;

  String _currentBprId = '';
  String? _kantorError;
  String? _employeeError;

  bool get _formUnlocked => widget.isEdit || _selectedEmployee != null;

  @override
  void initState() {
    super.initState();
    _userid = TextEditingController(text: widget.user.userid);
    _nama = TextEditingController(text: widget.user.namauser);
    _password = TextEditingController();
    _kodeKantor = TextEditingController(text: widget.user.kodeKantor);
    _bprId = TextEditingController(text: widget.user.bprId);
    _tglExpired = TextEditingController(text: _dateOnly(widget.user.tglExpired));
    _hrisEmployeeId = TextEditingController(text: widget.user.hrisEmployeeId);
    _hrisEmployeeNo = TextEditingController(text: widget.user.hrisEmployeeNo);
    _isActive = widget.user.isActive;
    _isSuperAdmin = widget.user.isSuperAdmin;
    _initBprAndKantor();
    if (widget.isEdit) _loadAccess();
  }

  Future<void> _initBprAndKantor() async {
    setState(() {
      _loadingKantor = true;
      _kantorError = null;
    });

    try {
      final loginUser = await Pref().getUsers();
      final loginBprId = loginUser.kodePt.trim();
      _currentBprId = widget.user.bprId.trim().isNotEmpty
          ? widget.user.bprId.trim()
          : loginBprId.isNotEmpty
              ? loginBprId
              : '609999';
      _bprId.text = _currentBprId;

      final offices = await HrisRepository.listKantor(bprId: _currentBprId);
      if (!mounted) return;
      setState(() {
        _kantorOptions = offices;
        if (_kodeKantor.text.trim().isEmpty && offices.isNotEmpty) {
          final defaultOffice = offices.where((e) => e.kodeKantor == loginUser.kodeKantor).toList();
          _kodeKantor.text = defaultOffice.isNotEmpty ? defaultOffice.first.kodeKantor : offices.first.kodeKantor;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _kantorError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingKantor = false);
    }
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
    _hrisEmployeeId.dispose();
    _hrisEmployeeNo.dispose();
    _employeeSearch.dispose();
    super.dispose();
  }

  Future<void> _searchEmployee() async {
    final keyword = _employeeSearch.text.trim();
    if (keyword.length < 2) {
      setState(() {
        _employeeResults = [];
        _employeeError = 'Masukkan minimal 2 karakter nama / employee no / no HP.';
        _selectedEmployee = null;
        _hrisEmployeeId.clear();
        _hrisEmployeeNo.clear();
      });
      return;
    }

    setState(() {
      _loadingEmployee = true;
      _employeeError = null;
      _employeeResults = [];
      _selectedEmployee = null;
      _hrisEmployeeId.clear();
      _hrisEmployeeNo.clear();
    });

    try {
      final rows = await HrisRepository.searchEmployee(bprId: _currentBprId, search: keyword);
      if (!mounted) return;
      setState(() {
        _employeeResults = rows;
        _employeeError = rows.isEmpty ? 'Employee tidak ditemukan di HRIS. User baru belum bisa dibuat.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _employeeError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingEmployee = false);
    }
  }

  Future<CoreUserModel?> _findUserUsingEmployee(HrisEmployeeModel employee) async {
    CoreUserModel? fromList = _matchUserUsingEmployee(widget.existingUsers, employee);
    if (fromList != null) return fromList;

    final query = employee.employeeNo.trim().isNotEmpty ? employee.employeeNo.trim() : employee.name.trim();
    if (query.length < 2) return null;

    try {
      final rows = await CoreUsersRepository.listUsers(keyword: query);
      return _matchUserUsingEmployee(rows, employee);
    } catch (_) {
      return null;
    }
  }

  CoreUserModel? _matchUserUsingEmployee(List<CoreUserModel> users, HrisEmployeeModel employee) {
    final employeeId = employee.id.trim().toUpperCase();
    final employeeNo = employee.employeeNo.trim().toUpperCase();
    final employeeName = employee.name.trim().toUpperCase();
    final employeeOffice = employee.officeCode.trim().toUpperCase();

    for (final user in users) {
      if (widget.isEdit && user.userid.trim().toUpperCase() == widget.user.userid.trim().toUpperCase()) continue;

      final userHrisId = user.hrisEmployeeId.trim().toUpperCase();
      final userEmployeeNo = user.hrisEmployeeNo.trim().toUpperCase();
      final userId = user.userid.trim().toUpperCase();
      final userName = user.namauser.trim().toUpperCase();
      final userOffice = user.kodeKantor.trim().toUpperCase();

      if (employeeId.isNotEmpty && userHrisId.isNotEmpty && userHrisId == employeeId) return user;
      if (employeeNo.isNotEmpty && userEmployeeNo.isNotEmpty && userEmployeeNo == employeeNo) return user;
      if (employeeNo.isNotEmpty && userId == employeeNo) return user;
      if (employeeName.isNotEmpty && employeeOffice.isNotEmpty && userName == employeeName && userOffice == employeeOffice) return user;
    }
    return null;
  }

  Future<void> _selectEmployee(HrisEmployeeModel employee) async {
    setState(() => _loadingEmployee = true);
    final usedBy = await _findUserUsingEmployee(employee);
    if (!mounted) return;
    if (usedBy != null) {
      setState(() {
        _loadingEmployee = false;
        _selectedEmployee = null;
        _hrisEmployeeId.clear();
        _hrisEmployeeNo.clear();
        _employeeError = 'Employee ${employee.employeeNo} - ${employee.name} sudah digunakan oleh user ${usedBy.userid}. Tidak boleh membuat login user ganda untuk employee yang sama.';
      });
      return;
    }

    setState(() {
      _loadingEmployee = false;
      _selectedEmployee = employee;
      _employeeError = null;
      _hrisEmployeeId.text = employee.id.trim();
      _hrisEmployeeNo.text = employee.employeeNo.trim();
      _nama.text = employee.name.trim().toUpperCase();
      if (_userid.text.trim().isEmpty && employee.employeeNo.trim().isNotEmpty) {
        _userid.text = employee.employeeNo.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_\-]'), '');
      }
      if (employee.officeCode.trim().isNotEmpty) {
        _kodeKantor.text = employee.officeCode.trim();
      }
    });
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
    if (!widget.isEdit && _selectedEmployee == null) {
      informationDialog(context, 'Warning', 'Cari dan pilih employee HRIS terlebih dahulu sebelum membuat user login.');
      return;
    }
    if (!widget.isEdit && (_hrisEmployeeId.text.trim().isEmpty || _nama.text.trim().isEmpty)) {
      informationDialog(context, 'Warning', 'Employee ID dan Nama User wajib terisi dari hasil inquiry HRIS.');
      return;
    }
    if (!widget.isEdit && _selectedEmployee != null) {
      final usedBy = await _findUserUsingEmployee(_selectedEmployee!);
      if (usedBy != null) {
        informationDialog(context, 'Warning', 'Employee ini sudah digunakan oleh user ${usedBy.userid}. Tidak boleh membuat login user ganda untuk employee yang sama.');
        return;
      }
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    final employeeNameForSave = _nama.text.trim();
    setState(() => _saving = true);
    try {
      await CoreUsersRepository.saveUser(
        userid: _userid.text,
        password: _password.text,
        namauser: employeeNameForSave,
        kodeKantor: _kodeKantor.text.trim().split(' - ').first.trim(),
        bprId: _bprId.text.trim().isNotEmpty ? _bprId.text : _currentBprId,
        tglExpired: _tglExpired.text,
        isActive: _isActive,
        changePassword: !widget.isEdit || _changePassword,
        isSuperAdmin: _isSuperAdmin,
        fasilitas: widget.isEdit ? _existingAccess : <CoreAccessModel>[],
        hrisEmployeeId: _hrisEmployeeId.text,
        hrisEmployeeNo: _hrisEmployeeNo.text,
        hrisEmployeeName: employeeNameForSave,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _formDecoration(
    String label, {
    String? helperText,
    Widget? suffixIcon,
    bool readOnly = false,
    bool enabled = true,
  }) {
    final locked = readOnly || !enabled;
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: locked ? const Color(0xFFF1F5F9) : Colors.white,
    );
  }

  Widget _employeeInquirySection() {
    if (widget.isEdit) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Inquiry Employee HRIS', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'User baru hanya bisa dibuat dari employee yang terdaftar di HRIS. Cari berdasarkan nama, employee no, atau no HP.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _employeeSearch,
                  textInputAction: TextInputAction.search,
                  decoration: _formDecoration('Cari Employee HRIS', suffixIcon: const Icon(Icons.search)),
                  onSubmitted: (_) => _searchEmployee(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _loadingEmployee ? null : _searchEmployee,
                icon: _loadingEmployee
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
                label: const Text('Cari'),
                style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white, minimumSize: const Size(90, 50)),
              ),
            ],
          ),
          if (_employeeError != null) ...[
            const SizedBox(height: 8),
            Text(_employeeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (_employeeResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 190),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.white),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _employeeResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final employee = _employeeResults[i];
                  final selected = _selectedEmployee?.id == employee.id && employee.id.isNotEmpty;
                  return ListTile(
                    dense: true,
                    selected: selected,
                    selectedTileColor: colorPrimary.withOpacity(0.08),
                    leading: Icon(selected ? Icons.check_circle : Icons.person_search, color: selected ? Colors.green : colorPrimary),
                    title: Text(employee.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Kantor: ${employee.officeText} • Status: ${employee.employeeStatus.isEmpty ? '-' : employee.employeeStatus}'),
                    onTap: () => _selectEmployee(employee),
                  );
                },
              ),
            ),
          ],
          if (_selectedEmployee != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Employee dipilih: ${_selectedEmployee!.title}\nKantor: ${_selectedEmployee!.officeText}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _renewKodeKantorFromHris() async {
    if (_selectedEmployee != null && _selectedEmployee!.officeCode.trim().isNotEmpty) {
      setState(() => _kodeKantor.text = _selectedEmployee!.officeCode.trim());
      informationDialog(context, 'Informasi', 'Kode kantor diperbarui dari employee HRIS yang dipilih.');
      return;
    }

    final query = _hrisEmployeeNo.text.trim().isNotEmpty ? _hrisEmployeeNo.text.trim() : _userid.text.trim();
    if (query.length < 2) {
      informationDialog(context, 'Warning', 'User ID / Employee No minimal 2 karakter untuk renew kode kantor dari HRIS.');
      return;
    }

    setState(() => _renewingKodeKantor = true);
    try {
      final rows = await HrisRepository.searchEmployee(bprId: _currentBprId, search: query);
      HrisEmployeeModel? selected;
      for (final row in rows) {
        final userId = _userid.text.trim().toUpperCase();
        if (row.employeeNo.trim().toUpperCase() == userId || row.id.trim().toUpperCase() == _hrisEmployeeId.text.trim().toUpperCase()) {
          selected = row;
          break;
        }
      }
      selected ??= rows.isNotEmpty ? rows.first : null;

      if (selected == null || selected.officeCode.trim().isEmpty) {
        informationDialog(context, 'Warning', 'Kode kantor tidak ditemukan dari HRIS untuk user ini.');
        return;
      }

      setState(() {
        _selectedEmployee = selected;
        _hrisEmployeeId.text = selected!.id.trim();
        _hrisEmployeeNo.text = selected.employeeNo.trim();
        _kodeKantor.text = selected.officeCode.trim();
      });
      informationDialog(context, 'Informasi', 'Kode kantor berhasil diperbarui dari HRIS: ${selected.officeText}.');
    } catch (e) {
      informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _renewingKodeKantor = false);
    }
  }

  Widget _kantorDropdown() {
    return TextFormField(
      controller: _kodeKantor,
      readOnly: true,
      decoration: _formDecoration(
        'Kode Kantor',
        helperText: 'Otomatis dari response inquiry employee HRIS. Tekan Renew jika perlu ambil ulang dari HRIS.',
        readOnly: true,
        enabled: _formUnlocked,
        suffixIcon: IconButton(
          tooltip: 'Renew kode kantor dari HRIS',
          onPressed: _formUnlocked && !_renewingKodeKantor ? _renewKodeKantorFromHris : null,
          icon: _renewingKodeKantor
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh),
        ),
      ),
      validator: (v) => (v ?? '').trim().isEmpty ? 'Kode kantor wajib terisi dari HRIS' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        color: Colors.white,
        child: SizedBox(
          width: 680,
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
                _employeeInquirySection(),
                if (!widget.isEdit) const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: IgnorePointer(
                    ignoring: !_formUnlocked,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!widget.isEdit) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _hrisEmployeeId,
                                  readOnly: true,
                                  decoration: _formDecoration('Employee ID HRIS', readOnly: true),
                                  validator: (_) => _hrisEmployeeId.text.trim().isEmpty ? 'Pilih employee HRIS' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _hrisEmployeeNo,
                                  readOnly: true,
                                  decoration: _formDecoration('Employee No', readOnly: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _userid,
                          readOnly: widget.isEdit,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _formDecoration('User ID Login', helperText: 'Boleh berbeda dari employee ID / employee no.', readOnly: widget.isEdit, enabled: _formUnlocked),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'User ID wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nama,
                          readOnly: !widget.isEdit,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _formDecoration('Nama User / Nama Employee HRIS', helperText: 'Untuk user baru otomatis dari HRIS dan tidak bisa diubah.', readOnly: !widget.isEdit, enabled: _formUnlocked),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Nama user wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        if (widget.isEdit) ...[
                          CheckboxListTile(
                            value: _changePassword,
                            onChanged: _formUnlocked
                                ? (v) => setState(() {
                                      _changePassword = v ?? false;
                                      if (!_changePassword) _password.clear();
                                    })
                                : null,
                            title: const Text('Ubah password'),
                            subtitle: const Text('Password hanya dikirim jika opsi ini dicentang.'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          enabled: _formUnlocked && (!widget.isEdit || _changePassword),
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: const <String>[],
                          decoration: _formDecoration(
                            widget.isEdit ? 'Password baru' : 'Password',
                            enabled: _formUnlocked && (!widget.isEdit || _changePassword),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (!widget.isEdit && (v ?? '').trim().isEmpty) return 'Password wajib diisi';
                            if (widget.isEdit && _changePassword && (v ?? '').trim().isEmpty) return 'Password baru wajib diisi';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _kantorDropdown(),
                        const SizedBox(height: 6),
                        Text(
                          _currentBprId.isEmpty ? 'BPR mengikuti user login.' : 'BPR otomatis mengikuti user login: $_currentBprId',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _tglExpired,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _formDecoration('Tanggal Expired', readOnly: true, suffixIcon: const Icon(Icons.calendar_month)),
                        ),
                        const SizedBox(height: 14),
                        if (!widget.isEdit)
                          SwitchListTile(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            title: const Text('User aktif'),
                            contentPadding: EdgeInsets.zero,
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.35)),
                            ),
                            child: const Text(
                              'Status aktif/nonaktif tidak diubah dari form ini. Gunakan tombol Aktifkan/Nonaktifkan di list user.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: _isSuperAdmin,
                          onChanged: widget.currentIsSuperAdmin ? (v) => setState(() => _isSuperAdmin = v) : null,
                          title: const Text('Super admin'),
                          subtitle: const Text('Super admin otomatis dapat semua fasilitas dan dapat menyalakan/mematikan CMS Core.'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Batal'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving || !_formUnlocked ? null : _save,
                        style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
