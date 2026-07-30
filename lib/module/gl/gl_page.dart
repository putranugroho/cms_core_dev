import 'package:accounting_kantor_gl_useraccess/models/core_coa_model.dart';
import 'package:accounting_kantor_gl_useraccess/module/gl/gl_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/utils/button_custom.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class GlPage extends StatelessWidget {
  const GlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GlNotifier(context: context),
      child: Consumer<GlNotifier>(
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
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'GL / COA',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: TextField(
                              controller: value.keyword,
                              onSubmitted: (_) => value.getCoa(),
                              decoration: InputDecoration(
                                hintText: 'Cari kode / nama COA',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: value.getCoa,
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                            child: const Text('Cari', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: value.tambah,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Tambah COA', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(child: Text(value.errorMessage!))
                              : _CoaTable(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _CoaForm(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoaTable extends StatelessWidget {
  const _CoaTable({required this.value});

  final GlNotifier value;

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) {
      return const Center(child: Text('Tidak ada data COA.'));
    }

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
              DataColumn(label: Text('Kode COA')),
              DataColumn(label: Text('Nama COA')),
              DataColumn(label: Text('Tipe')),
              DataColumn(label: Text('Level')),
              DataColumn(label: Text('Parent')),
              DataColumn(label: Text('Posting')),
              DataColumn(label: Text('Special')),
              DataColumn(label: Text('OJK')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: value.list.map((CoreCoaModel data) {
              return DataRow(
                cells: [
                  DataCell(Text(data.kodeCoa)),
                  DataCell(SizedBox(width: 240, child: Text(data.namaCoa, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(data.tipeCoa?.toString() ?? '')),
                  DataCell(Text(data.levelCoa?.toString() ?? '')),
                  DataCell(Text(data.parentCoa)),
                  DataCell(Text(data.postingType)),
                  DataCell(Text(data.specialType)),
                  DataCell(Text(data.ojkCode)),
                  DataCell(Text(data.statusData)),
                  DataCell(
                    ElevatedButton(
                      onPressed: () => value.edit(data),
                      style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                      child: const Text('Aksi', style: TextStyle(color: Colors.white)),
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

class _CoaForm extends StatelessWidget {
  const _CoaForm({required this.value});

  final GlNotifier value;

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
                          value.editData ? 'Edit COA' : 'Tambah COA',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(onPressed: value.tutup, icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _textField('Kode COA', value.kodeCoa, required: true, readOnly: value.editData),
                  _textField('Nama COA', value.namaCoa, required: true),
                  DropdownButtonFormField<int>(
                    value: value.tipeCoa,
                    decoration: _decoration('Tipe COA'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1')),
                      DropdownMenuItem(value: 2, child: Text('2')),
                      DropdownMenuItem(value: 3, child: Text('3')),
                      DropdownMenuItem(value: 4, child: Text('4')),
                      DropdownMenuItem(value: 5, child: Text('5')),
                    ],
                    onChanged: value.pilihTipeCoa,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: value.levelCoa,
                    decoration: _decoration('Level COA'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1')),
                      DropdownMenuItem(value: 2, child: Text('2')),
                      DropdownMenuItem(value: 3, child: Text('3')),
                      DropdownMenuItem(value: 4, child: Text('4')),
                      DropdownMenuItem(value: 5, child: Text('5')),
                    ],
                    onChanged: value.pilihLevelCoa,
                  ),
                  const SizedBox(height: 14),
                  _textField('Parent COA', value.parentCoa),
                  DropdownButtonFormField<String>(
                    value: value.postingType,
                    decoration: _decoration('Posting Type'),
                    items: const [
                      DropdownMenuItem(value: 'I', child: Text('I')),
                      DropdownMenuItem(value: 'D', child: Text('D')),
                      DropdownMenuItem(value: 'Y', child: Text('Y')),
                      DropdownMenuItem(value: 'N', child: Text('N')),
                    ],
                    onChanged: value.pilihPostingType,
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 20),
                  ButtonPrimary(onTap: value.cek, name: 'Simpan'),
                  if (value.editData) ...[
                    const SizedBox(height: 12),
                    ButtonDanger(onTap: value.confirm, name: 'Hapus'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        inputFormatters: inputFormatters,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null : null,
        decoration: _decoration(label),
      ),
    );
  }
}
