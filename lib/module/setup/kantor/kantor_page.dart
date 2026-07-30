import 'package:accounting_kantor_gl_useraccess/models/index.dart';
import 'package:accounting_kantor_gl_useraccess/module/setup/kantor/kantor_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/utils/button_custom.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class KantorPage extends StatelessWidget {
  const KantorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KantorNotifier(context: context),
      child: Consumer<KantorNotifier>(
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
                              'Kantor',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: TextField(
                              controller: value.keyword,
                              onSubmitted: (_) => value.getKantor(),
                              decoration: InputDecoration(
                                hintText: 'Cari kode / nama kantor',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: value.getKantor,
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                            child: const Text('Cari', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: value.tambah,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Tambah Kantor', style: TextStyle(color: Colors.white)),
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
                              : _KantorTable(value: value),
                    ),
                  ],
                ),
                if (value.dialog) _KantorForm(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KantorTable extends StatelessWidget {
  const _KantorTable({required this.value});

  final KantorNotifier value;

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) {
      return const Center(child: Text('Tidak ada data kantor.'));
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
              DataColumn(label: Text('Kode')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Status Kantor')),
              DataColumn(label: Text('Status Aktif')),
              DataColumn(label: Text('Alamat')),
              DataColumn(label: Text('Kota')),
              DataColumn(label: Text('Telp')),
              DataColumn(label: Text('Fax')),
              DataColumn(label: Text('Kode Pos')),
              DataColumn(label: Text('BPR ID')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: value.list.map((KantorModel data) {
              return DataRow(
                cells: [
                  DataCell(Text(data.kodeKantor)),
                  DataCell(Text(data.namaKantor)),
                  DataCell(Text(data.namaStatusKantor)),
                  DataCell(Text(data.statusAktif)),
                  DataCell(SizedBox(width: 220, child: Text(data.alamat, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(data.kota)),
                  DataCell(Text(data.telp?.toString() ?? '')),
                  DataCell(Text(data.fax?.toString() ?? '')),
                  DataCell(Text(data.kodePos)),
                  DataCell(Text(data.kodePt)),
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

class _KantorForm extends StatelessWidget {
  const _KantorForm({required this.value});

  final KantorNotifier value;

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
                          value.editData ? 'Edit Kantor' : 'Tambah Kantor',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(onPressed: value.tutup, icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _textField('Kode Kantor', value.kode, required: true, readOnly: value.editData),
                  _textField('Nama Kantor', value.nama, required: true),
                  DropdownButtonFormField<int>(
                    value: value.statusKantor,
                    decoration: _decoration('Status Kantor'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Pusat')),
                      DropdownMenuItem(value: 2, child: Text('Cabang')),
                      DropdownMenuItem(value: 3, child: Text('Anak Cabang')),
                      DropdownMenuItem(value: 4, child: Text('Outlet/Gudang')),
                    ],
                    onChanged: value.pilihStatusKantor,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: value.statusAktif,
                    decoration: _decoration('Status Aktif'),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('Aktif')),
                      DropdownMenuItem(value: 'N', child: Text('Nonaktif')),
                    ],
                    onChanged: value.pilihStatusAktif,
                  ),
                  const SizedBox(height: 14),
                  _textField('BPR ID', value.bprid, required: true),
                  _textField('Kota', value.kota),
                  _textField('Kode Pos', value.kodepos, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                  _textField('No. Telp', value.notelp),
                  _textField('No. Fax', value.fax),
                  _textField('Alamat', value.alamat, required: true, maxLines: 3),
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
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null : null,
        decoration: _decoration(label),
      ),
    );
  }
}
