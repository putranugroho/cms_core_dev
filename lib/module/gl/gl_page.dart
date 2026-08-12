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
              DataColumn(label: Text('Gol. Akun')),
              DataColumn(label: Text('No. COA')),
              DataColumn(label: Text('Header')),
              DataColumn(label: Text('Buku Besar')),
              DataColumn(label: Text('Sub Buku Besar')),
              DataColumn(label: Text('Level')),
              DataColumn(label: Text('Parent')),
              DataColumn(label: Text('Posting')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: value.list.map((CoreCoaModel data) {
              final indent = (((data.levelCoa ?? 1) - 1).clamp(0, 2) as num).toDouble() * 18.0;
              return DataRow(
                cells: [
                  DataCell(Text(data.tipeCoaText)),
                  DataCell(Padding(
                    padding: EdgeInsets.only(left: indent),
                    child: Text(data.kodeCoa, style: const TextStyle(fontWeight: FontWeight.w600)),
                  )),
                  DataCell(SizedBox(width: 180, child: Text(value.headerName(data), overflow: TextOverflow.ellipsis))),
                  DataCell(SizedBox(width: 220, child: Text(value.bukuBesarName(data), overflow: TextOverflow.ellipsis))),
                  DataCell(SizedBox(width: 240, child: Text(value.subBukuBesarName(data), overflow: TextOverflow.ellipsis))),
                  DataCell(Text(data.levelCoaText)),
                  DataCell(Text(data.parentCoa)),
                  DataCell(Text(data.postingType)),
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
                    decoration: _decoration('Golongan Akun / Tipe COA'),
                    items: GlNotifier.tipeOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text('$e - ${value.tipeText(e)}')))
                        .toList(),
                    onChanged: value.pilihTipeCoa,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: value.levelCoa,
                    decoration: _decoration('Jenis / Level COA'),
                    items: GlNotifier.levelOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text('$e - ${value.levelText(e)}')))
                        .toList(),
                    onChanged: value.pilihLevelCoa,
                  ),
                  const SizedBox(height: 14),
                  if (value.parentRequired) _parentDropdown() else _noParentInfo(),
                  const SizedBox(height: 14),
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

  Widget _parentDropdown() {
    return DropdownButtonFormField<String>(
      value: value.parentDropdownValue,
      decoration: _decoration(value.parentLabel),
      isExpanded: true,
      items: value.parentOptions
          .map((e) => DropdownMenuItem(
                value: e.kodeCoa,
                child: Text('${e.kodeCoa} - ${e.namaCoa}', overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: value.parentOptions.isEmpty ? null : value.pilihParentCoa,
      validator: (_) {
        if (!value.parentRequired) return null;
        if (value.parentOptions.isEmpty) return 'Data ${value.parentLabel.toLowerCase()} belum tersedia';
        if (value.parentCoa.text.trim().isEmpty) return '${value.parentLabel} wajib dipilih';
        return null;
      },
    );
  }

  Widget _noParentInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Level Header tidak membutuhkan parent COA.'),
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
