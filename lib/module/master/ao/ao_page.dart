import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/master/ao/ao_notifier.dart';
import 'package:cms_core/utils/button_custom.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AoPage extends StatelessWidget {
  const AoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AoNotifier(context: context),
      child: Consumer<AoNotifier>(
        builder: (context, value, child) => SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const SizedBox(
                            width: 260,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Account Officer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Master data Account Officer', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 280,
                            child: TextField(
                              controller: value.keyword,
                              onSubmitted: (_) => value.getAo(),
                              decoration: InputDecoration(
                                hintText: 'Cari kode / employee / nama / no HP',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 190,
                            child: DropdownButtonFormField<int>(
                              value: value.filterRoleAo ?? 0,
                              decoration: _decoration('Role'),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Semua Role')),
                                DropdownMenuItem(value: 1, child: Text('Marketing')),
                                DropdownMenuItem(value: 2, child: Text('Collector')),
                                DropdownMenuItem(value: 3, child: Text('Marketing & Collector')),
                              ],
                              onChanged: value.pilihFilterRole,
                            ),
                          ),
                          SizedBox(
                            width: 170,
                            child: DropdownButtonFormField<String>(
                              value: value.filterStatusData,
                              decoration: _decoration('Status'),
                              items: const [
                                DropdownMenuItem(value: '', child: Text('Semua Status')),
                                DropdownMenuItem(value: 'A', child: Text('Aktif')),
                                DropdownMenuItem(value: 'N', child: Text('Belum Aktif')),
                                DropdownMenuItem(value: 'C', child: Text('Tutup')),
                                DropdownMenuItem(value: 'B', child: Text('Blokir')),
                                DropdownMenuItem(value: 'D', child: Text('Hapus')),
                              ],
                              onChanged: value.pilihFilterStatus,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: value.getAo,
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
                            child: const Text('Cari', style: TextStyle(color: Colors.white)),
                          ),
                          if (value.canCreate)
                            ElevatedButton.icon(
                              onPressed: value.tambah,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Tambah AO', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(140, 50)),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(child: Text(value.errorMessage!))
                              : _AoTable(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _AoForm(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AoTable extends StatelessWidget {
  const _AoTable({required this.value});

  final AoNotifier value;

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) return const Center(child: Text('Tidak ada data AO.'));

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(colorPrimary),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            columns: const [
              DataColumn(label: Text('Kode AO')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Employee No')),
              DataColumn(label: Text('Kode Kantor')),
              DataColumn(label: Text('No HP')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Created By')),
              DataColumn(label: Text('Created At')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: value.list.map((AoModel data) {
              return DataRow(
                cells: [
                  DataCell(Text(data.kodeAo)),
                  DataCell(SizedBox(width: 240, child: Text(data.namaAo, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(data.nomorEmployee)),
                  DataCell(Text(data.kodeKantor)),
                  DataCell(Text(data.noHp)),
                  DataCell(Text(data.roleAoTxt)),
                  DataCell(_StatusChip(text: data.statusText, code: data.statusData)),
                  DataCell(Text(data.createdBy)),
                  DataCell(Text(data.createdAt)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (value.canUpdate)
                          ElevatedButton(
                            onPressed: () => value.edit(data),
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                            child: const Text('Edit', style: TextStyle(color: Colors.white)),
                          ),
                        if (value.canUpdate && value.canDelete) const SizedBox(width: 8),
                        if (value.canDelete)
                          ElevatedButton(
                            onPressed: () => value.confirmDelete(data),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _AoForm extends StatelessWidget {
  const _AoForm({required this.value});

  final AoNotifier value;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        alignment: Alignment.centerRight,
        child: Container(
          width: 620,
          height: double.infinity,
          color: Colors.white,
          child: Form(
            key: value.keyForm,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          value.editData ? 'Edit Account Officer' : 'Tambah Account Officer',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(onPressed: value.tutup, icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!value.editData) ...[
                    _employeeInquirySection(value),
                    const SizedBox(height: 16),
                  ],
                  _textField('Nama', value.namaAo, required: true, readOnly: true, maxLength: 200),
                  _textField('Employee No', value.nomorEmployee, required: true, readOnly: true, maxLength: 50),
                  _kodeKantorField(value),
                  _textField(
                    'Kode AO',
                    value.kodeAo,
                    required: true,
                    readOnly: value.editData,
                    maxLength: 20,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]'))],
                  ),
                  DropdownButtonFormField<int>(
                    value: value.roleAo,
                    decoration: _decoration('Role AO'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Marketing')),
                      DropdownMenuItem(value: 2, child: Text('Collector')),
                      DropdownMenuItem(value: 3, child: Text('Marketing & Collector')),
                    ],
                    onChanged: value.pilihRole,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    'No HP',
                    value.noHp,
                    required: true,
                    maxLength: 20,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                  ),
                  const SizedBox(height: 20),
                  ButtonPrimary(onTap: value.cek, name: value.editData ? 'Update' : 'Simpan'),
                  if (value.editData && value.canDelete) ...[
                    const SizedBox(height: 12),
                    ButtonDanger(onTap: () => value.selected == null ? null : value.confirmDelete(value.selected!), name: 'Hapus'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _employeeInquirySection(AoNotifier value) {
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
          const Text(
            'AO baru diambil dari employee HRIS. Cari berdasarkan nama, employee no, atau no HP, lalu pilih employee untuk auto-fill Nama, Employee No, Kode Kantor, dan No HP.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: value.employeeSearch,
                  decoration: _decoration('Cari employee HRIS').copyWith(prefixIcon: const Icon(Icons.search)),
                  onSubmitted: (_) => value.searchEmployee(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: value.loadingEmployee ? null : value.searchEmployee,
                style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
                child: value.loadingEmployee
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Cari', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          if (value.employeeError != null) ...[
            const SizedBox(height: 8),
            Text(value.employeeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (value.employeeResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 210),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: value.employeeResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final employee = value.employeeResults[index];
                  final selected = value.selectedEmployee?.id == employee.id && employee.id.isNotEmpty;
                  return ListTile(
                    dense: true,
                    selected: selected,
                    selectedTileColor: colorPrimary.withOpacity(0.08),
                    leading: Icon(selected ? Icons.check_circle : Icons.person_outline, color: selected ? colorPrimary : null),
                    title: Text(employee.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Kantor: ${employee.officeText} • Status: ${employee.employeeStatus.isEmpty ? '-' : employee.employeeStatus}'),
                    onTap: () => value.pilihEmployee(employee),
                  );
                },
              ),
            ),
          ],
          if (value.selectedEmployee != null) ...[
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
                      'Employee dipilih: ${value.selectedEmployee!.title}\nKantor: ${value.selectedEmployee!.officeText}',
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

  Widget _kodeKantorField(AoNotifier value) {
    final helper = value.selectedEmployee != null
        ? 'Otomatis dari response inquiry employee HRIS: ${value.selectedEmployee!.officeText}'
        : 'Otomatis dari employee HRIS. Untuk edit data lama, nilai mengikuti data AO existing.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: value.kodeKantor,
        readOnly: true,
        decoration: _decoration('Kode Kantor').copyWith(
          helperText: helper,
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          errorText: value.kantorError,
        ),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Kode kantor wajib terisi dari HRIS' : null,
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool readOnly = false,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        textCapitalization: label == 'Nama' ? TextCapitalization.characters : TextCapitalization.none,
        decoration: _decoration(label).copyWith(
          filled: readOnly,
          fillColor: readOnly ? const Color(0xFFF1F5F9) : null,
        ),
        validator: (v) {
          final text = (v ?? '').trim();
          if (required && text.isEmpty) return 'Wajib diisi';
          if (maxLength != null && text.length > maxLength) return 'Maksimal $maxLength karakter';
          return null;
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final String code;

  const _StatusChip({required this.text, required this.code});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (code.toUpperCase()) {
      case 'A':
        color = Colors.green;
        break;
      case 'B':
        color = Colors.orange;
        break;
      case 'D':
      case 'C':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

InputDecoration _decoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    counterText: '',
  );
}
