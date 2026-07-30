import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/setup/sandi/sandi_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/utils/button_custom.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SandiPage extends StatelessWidget {
  const SandiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SandiNotifier(context: context),
      child: Consumer<SandiNotifier>(
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
                                Text('Sandi BI/OJK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Kode referensi SLIK & APOLO', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: TextField(
                              controller: value.keyword,
                              onSubmitted: (_) => value.getSandi(),
                              decoration: InputDecoration(
                                hintText: 'Cari kode / nama sandi',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 280,
                            child: DropdownButtonFormField<SandiGroupModel?>(
                              value: value.filterGroupModel,
                              isExpanded: true,
                              decoration: _decoration('Group'),
                              items: [
                                const DropdownMenuItem<SandiGroupModel?>(value: null, child: Text('Semua Group')),
                                ...value.listGroup.map(
                                  (e) => DropdownMenuItem<SandiGroupModel?>(
                                    value: e,
                                    child: Text('${e.group} - ${e.nama}', overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ],
                              onChanged: value.pilihFilterGroup,
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: DropdownButtonFormField<String>(
                              value: value.filterStatus,
                              decoration: _decoration('Status'),
                              items: const [
                                DropdownMenuItem(value: '', child: Text('Semua')),
                                DropdownMenuItem(value: 'A', child: Text('Aktif')),
                                DropdownMenuItem(value: 'D', child: Text('Hapus')),
                              ],
                              onChanged: value.pilihFilterStatus,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: value.getSandi,
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
                            child: const Text('Cari', style: TextStyle(color: Colors.white)),
                          ),
                          OutlinedButton.icon(
                            onPressed: value.getGroupList,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reload Group'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(130, 50)),
                          ),
                          if (value.canCreate)
                            ElevatedButton.icon(
                              onPressed: value.tambah,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Tambah Sandi', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(150, 50)),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(child: Text(value.errorMessage!))
                              : _SandiTable(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _SandiForm(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SandiTable extends StatelessWidget {
  const _SandiTable({required this.value});

  final SandiNotifier value;

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) return const Center(child: Text('Tidak ada data sandi.'));

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
              DataColumn(label: Text('Group')),
              DataColumn(label: Text('Kode')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Favorit')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Created By')),
              DataColumn(label: Text('Created At')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: value.list.map((SandiModel data) {
              return DataRow(
                cells: [
                  DataCell(SizedBox(width: 230, child: Text(data.group, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(data.kode)),
                  DataCell(SizedBox(width: 320, child: Text(data.nama, overflow: TextOverflow.ellipsis))),
                  DataCell(Icon(data.pavorit ? Icons.star : Icons.star_border, color: data.pavorit ? Colors.orange : Colors.grey)),
                  DataCell(_StatusChip(text: data.statusText, code: data.status)),
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

class _SandiForm extends StatelessWidget {
  const _SandiForm({required this.value});

  final SandiNotifier value;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.25),
        alignment: Alignment.centerRight,
        child: Container(
          width: 560,
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
                          value.editData ? 'Edit Sandi BI/OJK' : 'Tambah Sandi BI/OJK',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(onPressed: value.tutup, icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<SandiGroupModel>(
                    value: value.groupModel,
                    isExpanded: true,
                    decoration: _decoration('Group Sandi'),
                    items: value.listGroup
                        .map(
                          (e) => DropdownMenuItem<SandiGroupModel>(
                            value: e,
                            child: Text('${e.group} - ${e.nama}', overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: value.editData ? null : value.pilihGroup,
                    validator: (_) => value.group.text.trim().isEmpty ? 'Pilih group sandi' : null,
                  ),
                  if (value.groupError != null) ...[
                    const SizedBox(height: 6),
                    Text(value.groupError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  if (value.listGroup.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Group sandi belum termuat. Klik Reload Group atau cek endpoint group/list.', style: TextStyle(color: Colors.orange)),
                  ],
                  const SizedBox(height: 14),
                  _textField('Kode', value.kode, required: true, readOnly: value.editData, maxLength: 50),
                  _textField('Nama', value.nama, required: true, maxLength: 250, maxLines: 2),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: value.pavorit,
                    onChanged: value.togglePavorit,
                    title: const Text('Jadikan favorit'),
                  ),
                  if (value.editData)
                    DropdownButtonFormField<String>(
                      value: value.status,
                      decoration: _decoration('Status'),
                      items: const [
                        DropdownMenuItem(value: 'A', child: Text('Aktif')),
                        DropdownMenuItem(value: 'D', child: Text('Hapus')),
                      ],
                      onChanged: value.pilihStatus,
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

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool readOnly = false,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: (v) {
          final text = (v ?? '').trim();
          if (required && text.isEmpty) return 'Wajib diisi';
          if (maxLength != null && text.length > maxLength) return 'Maksimal $maxLength karakter';
          return null;
        },
        decoration: _decoration(label),
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
      case 'D':
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
