import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/master/ao/ao_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/utils/button_custom.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
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
                                Text('Master data Marketing & Collector', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: TextField(
                              controller: value.keyword,
                              onSubmitted: (_) => value.getAo(),
                              decoration: InputDecoration(
                                hintText: 'Cari kode / nama / no HP',
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
              DataColumn(label: Text('Nama AO')),
              DataColumn(label: Text('No HP')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Kode Kantor')),
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
                  DataCell(Text(data.noHp)),
                  DataCell(Text(data.roleAoTxt)),
                  DataCell(Text(data.kodeKantor)),
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
          width: 540,
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
                  _textField(
                    'Kode AO',
                    value.kodeAo,
                    required: true,
                    readOnly: value.editData,
                    maxLength: 20,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]'))],
                  ),
                  _textField('Nama AO', value.namaAo, required: true, maxLength: 200),
                  _textField(
                    'No HP',
                    value.noHp,
                    required: true,
                    maxLength: 20,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
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
                  _kantorDropdown(value),
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


  Widget _kantorDropdown(AoNotifier value) {
    if (value.isLoadingKantor) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          readOnly: true,
          decoration: _decoration('Kantor AO').copyWith(
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );
    }

    if (value.listKantor.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(8),
            color: Colors.red.shade50,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Data kantor tidak tersedia. Muat ulang dari endpoint list kantor.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: value.getKantorList,
                child: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<KantorModel>(
        value: value.kantorModel,
        isExpanded: true,
        decoration: _decoration('Kantor AO'),
        items: value.listKantor
            .map(
              (e) => DropdownMenuItem<KantorModel>(
                value: e,
                child: Text(
                  '(${e.kodeKantor}) ${e.namaKantor.isNotEmpty ? e.namaKantor : e.kodeKantor}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: value.pilihKantor,
        validator: (v) => v == null ? 'Pilih kantor AO' : null,
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
        textCapitalization: label == 'Nama AO' ? TextCapitalization.characters : TextCapitalization.none,
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
