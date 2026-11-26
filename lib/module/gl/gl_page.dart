import 'package:cms_core/models/core_coa_model.dart';
import 'package:cms_core/module/gl/gl_notifier.dart';
import 'package:cms_core/utils/button_custom.dart';
import 'package:cms_core/utils/colors.dart';
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
            backgroundColor: const Color(0xFFF8F3FA),
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Chart of Account',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: TextField(
                              controller: value.keyword,
                              onSubmitted: (_) => value.searchMasterGl(),
                              decoration: InputDecoration(
                                hintText: 'Cari No. COA / nama COA',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _TopButton(text: 'Cari', onTap: value.searchMasterGl),
                          const SizedBox(width: 12),
                          _TopButton(text: 'Tambah COA', onTap: value.tambah),
                          const SizedBox(width: 12),
                          _TopButton(text: 'Otorisasi', onTap: value.confirmotorisasi),
                        ],
                      ),
                    ),
                    Expanded(
                      child: value.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : value.errorMessage != null
                              ? Center(child: Text(value.errorMessage!))
                              : Column(
                                  children: [
                                    Expanded(child: _CoaTable(value: value)),
                                    _PaginationBar(value: value),
                                  ],
                                ),
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.value});

  final GlNotifier value;

  @override
  Widget build(BuildContext context) {
    final start = value.list.isEmpty ? 0 : ((value.currentPage - 1) * value.pageLimit) + 1;
    final end = value.list.isEmpty ? 0 : start + value.list.length - 1;
    final totalText = value.totalRows > 0 ? ' dari ${value.totalRows}' : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3FA),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Menampilkan $start-$end$totalText data • Halaman ${value.currentPage} / ${value.totalPages}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          OutlinedButton.icon(
            onPressed: value.hasPrevPage ? value.previousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Sebelumnya'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: value.hasNextPage ? value.nextPage : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Selanjutnya'),
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _TopButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorPrimary,
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CoaTable extends StatelessWidget {
  const _CoaTable({required this.value});

  final GlNotifier value;

  @override
  Widget build(BuildContext context) {
    if (value.list.isEmpty) return const Center(child: Text('Tidak ada data Chart of Account.'));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(colorPrimary),
          headingTextStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          dataTextStyle: const TextStyle(color: Colors.black87, fontSize: 12),
          columnSpacing: 14,
          horizontalMargin: 10,
          columns: const [
            DataColumn(label: Text('No')),
            DataColumn(label: Text('Gol. Akun')),
            DataColumn(label: Text('No. COA')),
            DataColumn(label: Text('Header')),
            DataColumn(label: Text('Buku Besar')),
            DataColumn(label: Text('Sub Buku Besar')),
            DataColumn(label: Text('Posting')),
            DataColumn(label: Text('Laba Rugi')),
            DataColumn(label: Text('Nonaktif')),
            DataColumn(label: Text('Action')),
          ],
          rows: List.generate(value.list.length, (index) {
            final data = value.list[index];
            return DataRow(
              cells: [
                DataCell(Text('${((value.currentPage - 1) * value.pageLimit) + index + 1}')),
                DataCell(SizedBox(width: 100, child: Text(data.tipeCoaText, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 120, child: Text(data.kodeCoa, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 200, child: Text(value.headerName(data), overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 200, child: Text(value.bukuBesarName(data), overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 220, child: Text(value.subBukuBesarName(data), overflow: TextOverflow.ellipsis))),
                DataCell(Text(data.postingYN)),
                DataCell(Text(data.labaRugiText)),
                DataCell(Text(data.nonaktifYN)),
                DataCell(
                  ElevatedButton(
                    onPressed: () => value.edit(data),
                    style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
                    child: const Text('Aksi', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          }),
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
        color: Colors.black.withOpacity(0.2),
        alignment: Alignment.centerRight,
        child: Container(
          width: 600,
          height: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Form(
            key: value.keyForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.editData ? 'Ubah / Hapus Chart of Account' : 'Tambah Chart of Account',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    InkWell(
                      onTap: value.tutup,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                        child: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _label('Golongan Akun', required: true),
                      _dropdown<String>(
                        hint: 'Pilih Golongan Akun',
                        value: value.golongan,
                        items: value.listGol,
                        enabled: !value.editData,
                        onChanged: value.pilihGolongan,
                      ),
                      const SizedBox(height: 16),
                      _label('Jenis Akun', required: true),
                      _dropdown<String>(
                        hint: 'Pilih Jenis Akun',
                        value: value.jnsAcc,
                        items: value.listJns,
                        enabled: !value.editData,
                        onChanged: value.pilihJenis,
                      ),
                      const SizedBox(height: 16),
                      if (value.jnsAcc == 'Header') _HeaderForm(value: value),
                      if (value.jnsAcc == 'Buku Besar') _BukuBesarForm(value: value),
                      if (value.jnsAcc == 'Sub Buku Besar') _SubBukuBesarForm(value: value),
                      if (value.jnsAcc != null) ...[
                        const SizedBox(height: 20),
                        ButtonPrimary(onTap: value.cek, name: value.editData ? 'Simpan Perubahan' : 'Simpan'),
                        if (value.editData) ...[
                          const SizedBox(height: 16),
                          ButtonDanger(onTap: value.confirm, name: 'Hapus'),
                        ],
                      ],
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

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
    String Function(T)? itemText,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: _decoration(hint, filled: !enabled),
      items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(itemText == null ? e.toString() : itemText(e)))).toList(),
      validator: (v) => v == null ? 'Wajib diisi' : null,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _HeaderForm extends StatelessWidget {
  final GlNotifier value;

  const _HeaderForm({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('No. Header', required: true),
        Row(
          children: [
            SizedBox(
              width: 150,
              child: TextFormField(
                controller: value.noHeader,
                maxLength: 3,
                enabled: !value.editData,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => value.updateHeader(),
                validator: _required,
                decoration: _decoration('Nomor Header', filled: value.editData).copyWith(counterText: ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _resultField(value.resulttext, 'Nomor Header')),
          ],
        ),
        const SizedBox(height: 16),
        _label('Nama Header', required: true),
        _nameField(value),
        const SizedBox(height: 16),
        _LabaRugiFlags(value: value),
      ],
    );
  }
}

class _BukuBesarForm extends StatelessWidget {
  final GlNotifier value;

  const _BukuBesarForm({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Nomor Header', required: true),
                  _resultField(value.noHeader, 'Nomor Header'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Pilih Header', required: true),
                  DropdownButtonFormField<CoreCoaModel>(
                    value: value.header,
                    isExpanded: true,
                    decoration: _decoration('Pilih Header'),
                    items: value.headerOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text('${e.kodeCoa} - ${e.namaCoa}', overflow: TextOverflow.ellipsis)))
                        .toList(),
                    validator: (v) => v == null ? 'Wajib dipilih' : null,
                    onChanged: value.editData ? null : value.pilihHeader,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('No. Buku Besar', required: true),
        Row(
          children: [
            SizedBox(
              width: 110,
              child: TextFormField(
                controller: value.noBb,
                maxLength: 3,
                enabled: !value.editData,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => value.updatebb(),
                validator: _required,
                decoration: _decoration('Nomor ...', filled: value.editData).copyWith(counterText: ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _resultField(value.resulttext, 'Nomor Buku Besar')),
          ],
        ),
        const SizedBox(height: 16),
        _label('Nama Buku Besar', required: true),
        _nameField(value),
        const SizedBox(height: 16),
        _LabaRugiFlags(value: value),
      ],
    );
  }
}

class _SubBukuBesarForm extends StatelessWidget {
  final GlNotifier value;

  const _SubBukuBesarForm({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Pilih Buku Besar', required: true),
        DropdownButtonFormField<CoreCoaModel>(
          value: value.bukuBesar,
          isExpanded: true,
          decoration: _decoration('Pilih Buku Besar'),
          items: value.bukuBesarOptions
              .map((e) => DropdownMenuItem(value: e, child: Text('${e.kodeCoa} - ${e.namaCoa}', overflow: TextOverflow.ellipsis)))
              .toList(),
          validator: (v) => v == null ? 'Wajib dipilih' : null,
          onChanged: value.editData ? null : value.pilihBB,
        ),
        const SizedBox(height: 16),
        _label('No. Sub Buku Besar', required: true),
        Row(
          children: [
            SizedBox(
              width: 130,
              child: TextFormField(
                controller: value.noSbb,
                maxLength: 6,
                enabled: !value.editData,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => value.updateSbb(),
                validator: _required,
                decoration: _decoration('Nomor ...', filled: value.editData).copyWith(counterText: ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _resultField(value.resulttext, 'Nomor Sub Buku Besar')),
          ],
        ),
        const SizedBox(height: 16),
        _label('Nama Sub Buku Besar', required: true),
        _nameField(value),
        const SizedBox(height: 16),
        _label('Posting Type', required: true),
        DropdownButtonFormField<String>(
          value: value.postingType,
          isExpanded: true,
          decoration: _decoration('Pilih Posting Type'),
          items: const [
            DropdownMenuItem(value: 'I', child: Text('I - Interaktif')),
            DropdownMenuItem(value: 'N', child: Text('N - Non-Interaktif')),
          ],
          validator: (v) => v == null || v.isEmpty ? 'Wajib dipilih' : null,
          onChanged: value.pilihPostingType,
        ),
        const SizedBox(height: 16),
        _LabaRugiFlags(value: value),
      ],
    );
  }
}

class _LabaRugiFlags extends StatelessWidget {
  final GlNotifier value;

  const _LabaRugiFlags({required this.value});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Laba Rugi'),
        _labaRugiDot('BERJALAN', 'Berjalan'),
        _labaRugiDot('TAHUN_LALU', 'Tahun Lalu'),
      ],
    );
  }

  Widget _labaRugiDot(String key, String label) {
    final selected = value.labaRugi == key;
    return InkWell(
      onTap: () => value.pilihLabaRugi(key),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(width: 2, color: Colors.grey)),
            child: selected ? Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: colorPrimary)) : const SizedBox(),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

Widget _nameField(GlNotifier value) {
  return TextFormField(
    controller: value.namaSbb,
    validator: _required,
    decoration: _decoration('Nama SBB'),
  );
}

Widget _resultField(TextEditingController controller, String hint) {
  return TextFormField(
    controller: controller,
    readOnly: true,
    decoration: _decoration(hint, filled: true),
  );
}

String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Wajib diisi';
  return null;
}

Widget _label(String text, {bool required = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 12)),
        if (required) const SizedBox(width: 4),
        if (required) const Text('*', style: TextStyle(fontSize: 10, color: Colors.red)),
      ],
    ),
  );
}

InputDecoration _decoration(String hint, {bool filled = false}) {
  return InputDecoration(
    hintText: hint,
    filled: filled,
    fillColor: filled ? Colors.grey.shade200 : Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}
