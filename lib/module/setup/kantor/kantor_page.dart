import 'package:cms_core/models/index.dart';
import 'package:cms_core/module/setup/kantor/kantor_notifier.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:flutter/material.dart';
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
            backgroundColor: const Color(0xFFF7F9FC),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kantor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('List kantor dari HRIS. Gunakan Sinkronisasi untuk create/update kantor core. BPR: ${value.bprIdLogin}',
                                    style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: value.keyword,
                              onSubmitted: (_) => value.searchLocal(),
                              decoration: InputDecoration(
                                hintText: 'Cari kode / nama kantor HRIS',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: value.searchLocal,
                            icon: const Icon(Icons.search, color: Colors.white),
                            label: const Text('Cari', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: value.refreshHris,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh HRIS'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(130, 50)),
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
                    _PaginationBar(value: value),
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
      return const Center(child: Text('Tidak ada data kantor HRIS.'));
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
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Kode Kantor')),
              DataColumn(label: Text('Nama Kantor')),
              DataColumn(label: Text('Level Kantor')),
              DataColumn(label: Text('Kota')),
              DataColumn(label: Text('Telepon')),
              DataColumn(label: Text('BPR ID')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: List.generate(value.list.length, (index) {
              final data = value.list[index];
              return DataRow(
                cells: [
                  DataCell(Text('${((value.page - 1) * value.limit) + index + 1}')),
                  DataCell(Text(data.kodeKantor, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(SizedBox(width: 260, child: Text(data.namaKantor, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(data.namaStatusKantor)),
                  DataCell(Text(data.kota.isEmpty ? '-' : data.kota)),
                  DataCell(Text((data.telp ?? '').toString().isEmpty ? '-' : data.telp.toString())),
                  DataCell(Text(data.kodePt)),
                  DataCell(
                    ElevatedButton.icon(
                      onPressed: () => value.sinkronisasi(data),
                      icon: const Icon(Icons.sync, color: Colors.white, size: 16),
                      label: const Text('Sinkronisasi', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.value});

  final KantorNotifier value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: [
          Expanded(child: Text('Menampilkan ${value.fromRow}-${value.toRow} dari ${value.total} data HRIS • Halaman ${value.page}')),
          OutlinedButton(onPressed: value.hasPrev ? value.prevPage : null, child: const Text('Sebelumnya')),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: value.hasNext ? value.nextPage : null,
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
            child: const Text('Selanjutnya', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          width: MediaQuery.of(context).size.width > 980 ? 720 : MediaQuery.of(context).size.width * 0.95,
          height: double.infinity,
          color: Colors.white,
          child: Form(
            key: value.keyForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value.editData ? 'Sinkronisasi / Update Kantor' : 'Sinkronisasi / Tambah Kantor',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              value.selectedHris == null
                                  ? 'Pilih data kantor HRIS.'
                                  : '${value.selectedHris!.kodeKantor} - ${value.selectedHris!.namaKantor}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(onPressed: value.tutup, icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                if (value.isSyncLoading) const LinearProgressIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _field(value, 'Kd Ktr', 'kode_kantor', required: true),
                        _field(value, 'Nama Ktr', 'nama_kantor', required: true, wide: true),
                        _statusKantorField(value),
                        _statusAktifField(value),
                        if (value.showKodeIndukField) _kodeIndukField(value),
                        _field(value, 'Alamat', 'alamat', wide: true),
                        _field(value, 'Kel', 'kelurahan'),
                        _field(value, 'Kec', 'kecamatan'),
                        _field(value, 'Kab/Kota', 'kota'),
                        _field(value, 'Provinsi', 'provinsi'),
                        _field(value, 'Kd Pos', 'kode_pos'),
                        _field(value, 'Kd Ktr BI', 'kode_kantor_bi'),
                        _field(value, 'BPR ID', 'bpr_id', required: true),
                        _field(value, 'Telepon', 'telp'),
                        _field(value, 'Nomor Fax', 'nomor_fax'),
                        _employeeField(context, value, 'Pincab', 'pimpinan_cabang'),
                        _employeeField(context, value, 'Mgr Ops', 'manager_operasional'),
                        _employeeField(context, value, 'Mgr Mkt', 'manager_marketing'),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(onPressed: value.tutup, child: const Text('Batal')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: value.isSyncLoading ? null : value.simpan,
                        style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                        child: Text(value.editData ? 'Update Kantor' : 'Simpan Kantor', style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(KantorNotifier value, String label, String key, {bool required = false, bool wide = false}) {
    final readonly = value.isHrisReadonly(key);
    final isRequired = required || value.isRequiredField(key);

    return SizedBox(
      width: wide ? 620 : 300,
      child: TextFormField(
        controller: value.c(key),
        readOnly: readonly,
        validator: (v) => value.validateField(key, v),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          helperText: readonly ? 'HRIS' : null,
          helperMaxLines: 2,
          filled: true,
          fillColor: readonly ? Colors.grey.shade100 : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _employeeField(BuildContext context, KantorNotifier value, String label, String key, {bool required = false}) {
    final isRequired = required || value.isRequiredField(key);
    return SizedBox(
      width: 300,
      child: TextFormField(
        controller: value.c(key),
        readOnly: true,
        validator: (v) => value.validateField(key, v),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          helperText: 'HRIS Employee',
          helperMaxLines: 2,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            tooltip: 'Cari Pegawai HRIS',
            icon: const Icon(Icons.person_search),
            onPressed: () => _showEmployeeDialog(context, value, label, key),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _showEmployeeDialog(BuildContext context, KantorNotifier value, String label, String key) async {
    final search = TextEditingController();
    Future<List<HrisEmployeeModel>>? future;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void runSearch() {
            setDialogState(() => future = value.searchEmployee(search.text.trim()));
          }

          return AlertDialog(
            title: Text('Cari Pegawai HRIS - $label'),
            content: SizedBox(
              width: 650,
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cari berdasarkan nama, employee no, atau no HP. Pilihan akan mengisi field $label.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: search,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            labelText: 'Cari Employee HRIS',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onSubmitted: (_) => runSearch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: runSearch,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: const Text('Cari', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(90, 50)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: future == null
                        ? const Center(child: Text('Masukkan keyword lalu tekan Cari.'))
                        : FutureBuilder<List<HrisEmployeeModel>>(
                            future: future,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)));
                              }
                              final rows = snapshot.data ?? const <HrisEmployeeModel>[];
                              if (rows.isEmpty) return const Center(child: Text('Employee tidak ditemukan.'));

                              return ListView.separated(
                                itemCount: rows.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, index) {
                                  final employee = rows[index];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.person_search),
                                    title: Text(employee.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                        'Kantor: ${employee.officeText} • Status: ${employee.employeeStatus.isEmpty ? '-' : employee.employeeStatus}'),
                                    onTap: () {
                                      value.pilihEmployeeUntukJabatan(key, employee);
                                      Navigator.pop(dialogContext);
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup')),
            ],
          );
        },
      ),
    );

    search.dispose();
  }

  Widget _statusKantorField(KantorNotifier value) {
    final readonly = value.isHrisReadonly('status_kantor');
    if (readonly) {
      return _field(value, 'Level Ktr', 'status_kantor', required: true);
    }

    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<int>(
        value: value.statusKantorCodeFromForm(),
        decoration: InputDecoration(
          labelText: 'Level Ktr *',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 - Pusat')),
          DropdownMenuItem(value: 2, child: Text('2 - Cabang')),
          DropdownMenuItem(value: 3, child: Text('3 - Cab. Pembantu')),
          DropdownMenuItem(value: 4, child: Text('4 - Kas')),
        ],
        validator: (v) => v == null ? 'Wajib dipilih' : null,
        onChanged: value.setStatusKantor,
      ),
    );
  }

  Widget _kodeIndukField(KantorNotifier value) {
    final options = value.kantorIndukOptions;

    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<String>(
        value: value.kodeIndukDropdownValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Ktr Induk *',
          helperText: 'List HRIS',
          helperMaxLines: 2,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: options
            .map((item) => DropdownMenuItem<String>(
                  value: item.key,
                  child: Text(item.value, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        validator: (v) => value.validateField('kode_induk', v),
        onChanged: options.isEmpty ? null : value.setKodeInduk,
      ),
    );
  }

  Widget _statusAktifField(KantorNotifier value) {
    final readonly = value.isHrisReadonly('status_aktif');
    if (readonly) {
      return _field(value, 'Status Aktif', 'status_aktif', required: true);
    }

    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<String>(
        value: value.statusAktifCodeFromForm(),
        decoration: InputDecoration(
          labelText: 'Status Aktif *',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: const [
          DropdownMenuItem(value: 'A', child: Text('A - Aktif')),
          DropdownMenuItem(value: 'N', child: Text('N - Nonaktif')),
          DropdownMenuItem(value: 'C', child: Text('C - Tutup')),
        ],
        validator: (v) => v == null || v.trim().isEmpty ? 'Wajib dipilih' : null,
        onChanged: value.setStatusAktif,
      ),
    );
  }
}
