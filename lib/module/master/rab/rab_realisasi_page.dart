import 'package:flutter/material.dart';
import 'package:cms_core/utils/colors.dart';

/// Static, read-only illustration. No repository calls or transaction actions.
class RabRealisasiPage extends StatefulWidget {
  final bool marketing;
  const RabRealisasiPage({super.key, required this.marketing});
  @override
  State<RabRealisasiPage> createState() => _RabRealisasiState();
}

class _RabRealisasiState extends State<RabRealisasiPage> {
  final _horizontal = ScrollController();
  String _indicator = 'kredit';
  static const _ratios = <int>[0, 20, 50, 70, 90, 110, 120];
  int get _target => _indicator == 'tabungan' ? 100 : 1000000;
  String get _unit => _indicator == 'tabungan' ? 'rekening' : 'Rp';
  String get _title => widget.marketing ? 'Realisasi RAB Marketing' : 'Realisasi RAB Kantor';
  @override
  void dispose() { _horizontal.dispose(); super.dispose(); }

  String _number(int value) => value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  int _actual(int month) => _target * _ratios[month] ~/ 100;
  String _value(int row, int month) {
    if (month >= _ratios.length) return ''; // No illustrative data for Aug–Dec.
    switch (row) {
      case 0: return _number(_target);
      case 1: return _number(_actual(month));
      case 2: return '${(_actual(month) / _target * 100).toStringAsFixed(2).replaceAll('.', ',')}%';
      default: return _number(_actual(month) - _target);
    }
  }
  Widget _cell(String text, {bool heading = false, bool label = false, Color? color}) => Container(
    height: 48, alignment: label ? Alignment.centerLeft : Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: heading ? const Color(0xffeef2f7) : null,
    child: Text(text, maxLines: 1, style: TextStyle(fontWeight: heading || label ? FontWeight.w600 : FontWeight.normal, color: color)),
  );
  Widget _metadata(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [SizedBox(width: 130, child: Text(label)), const Text(':  '), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]),
  );
  @override
  Widget build(BuildContext context) => SafeArea(child: Scaffold(
    backgroundColor: const Color(0xfff5f7fa),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xfffff4d6), borderRadius: BorderRadius.circular(8)),
        child: const Text('DATA CONTOH • Tampilan hanya-baca. Realisasi belum terhubung ke API. Bulan 8–12 belum diisi pada contoh.')),
      const SizedBox(height: 20),
      Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _metadata(widget.marketing ? 'Kode AO' : 'Kode Kantor', widget.marketing ? 'AO-CONTOH-001' : '001'),
        _metadata(widget.marketing ? 'Nama AO' : 'Nama Kantor', widget.marketing ? 'AO Contoh' : 'Kantor Contoh'),
        if (widget.marketing) _metadata('Nama Kantor', 'Kantor Contoh'),
        _metadata('Tahun', '2026'),
        const SizedBox(height: 12),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: DropdownButtonFormField<String>(
          value: _indicator, isExpanded: true, decoration: const InputDecoration(labelText: 'Indikator', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'tabungan', child: Text('Jumlah Rekening Tabungan')),
            DropdownMenuItem(value: 'kredit', child: Text('Total Plafond Kredit')),
            DropdownMenuItem(value: 'deposito', child: Text('Total Nominal Deposito')),
          ], onChanged: (value) { if (value != null) setState(() => _indicator = value); },
        )),
        const SizedBox(height: 18),
        Text('Satuan: $_unit', style: TextStyle(color: colorPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Scrollbar(controller: _horizontal, thumbVisibility: true, child: SingleChildScrollView(
          controller: _horizontal, scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(width: 1580, child: Table(
            border: TableBorder.all(color: const Color(0xffcbd5e1)),
            columnWidths: const {0: FixedColumnWidth(164)},
            defaultColumnWidth: const FixedColumnWidth(118),
            children: [
              TableRow(children: [_cell('Bulan', heading: true, label: true), for (var m = 1; m <= 12; m++) _cell('$m', heading: true)]),
              for (var row = 0; row < 4; row++) TableRow(children: [
                _cell(const ['Target', 'Realisasi', 'Ratio (%)', 'Kurang / Lebih'][row], label: true),
                for (var month = 0; month < 12; month++) _cell(_value(row, month),
                  color: row == 3 && month < _ratios.length ? (_actual(month) < _target ? Colors.red.shade700 : Colors.green.shade700) : null),
              ]),
            ],
          )),
        )),
        const SizedBox(height: 8),
        const Text('Ratio = Realisasi ÷ Target × 100%. Kurang / Lebih = Realisasi − Target.', style: TextStyle(color: Colors.black54)),
      ])),
    ])),
  ));
}
