import 'package:accounting_kantor_gl_useraccess/utils/button_custom.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductTabunganPage extends StatefulWidget {
  const ProductTabunganPage({super.key});

  @override
  State<ProductTabunganPage> createState() => _ProductTabunganPageState();
}

class _ProductTabunganPageState extends State<ProductTabunganPage> {
  final _formKey = GlobalKey<FormState>();
  final _kodeProduk = TextEditingController(text: '01');
  final _keterangan = TextEditingController(text: 'Tabungan Angsa');
  int _step = 0;

  final List<String> _steps = const [
    'Perhitungan Bunga',
    'Saldo Progresif',
    'Setoran & Saldo',
    'Biaya',
    'SBB Produk',
    'Penutupan & Charge',
    'Pasif & Rekap',
    'Asuransi',
    'Penarikan Tunai',
    'Tabungan Berjangka',
  ];

  @override
  void dispose() {
    _kodeProduk.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step < _steps.length - 1) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _reset() {
    setState(() {
      _step = 0;
      _kodeProduk.text = '01';
      _keterangan.text = 'Tabungan Angsa';
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    informationDialog(
      context,
      'Informasi',
      'UI Setup Produk Tabungan sudah disiapkan. Endpoint simpan belum tersedia, sehingga data belum dikirim ke backend.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: 'Setup Produk Tabungan',
              subtitle: 'Definisi produk tabungan untuk pengembangan produk ke depan',
              mode: 'U',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 230, child: _StepNavigation(steps: _steps, current: _step, onTap: (i) => setState(() => _step = i))),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ProductIdentity(kodeController: _kodeProduk, keteranganController: _keterangan),
                                const SizedBox(height: 16),
                                Expanded(child: SingleChildScrollView(child: _buildStepContent())),
                                const SizedBox(height: 16),
                                _FormNavigation(
                                  current: _step,
                                  total: _steps.length,
                                  onBack: _back,
                                  onNext: _next,
                                  onReset: _reset,
                                  onSave: _save,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _SectionCard(
          title: 'Dasar Perhitungan Bunga & Pajak',
          children: [
            _DropdownField(label: 'Dasar Perhitungan Bunga', value: 'H-Saldo harian', items: const ['H-Saldo harian', 'Rata-rata saldo', 'Saldo akhir bulan']),
            _DropdownField(label: 'Metode Pembukuan Bunga', value: 'C-Cr Abis', items: const ['C-Cr Abis', 'Transfer otomatis', 'Kapitalisasi']),
            _DropdownField(label: 'Tgl Pembukuan ke rekening', value: '5-EOM Sore', items: const ['5-EOM Sore', 'EOM Pagi', 'Tanggal tertentu']),
            _NumberField(label: 'Periode - Dari'),
            _NumberField(label: 'Periode - Sampai'),
            _DropdownField(label: 'Faktor Pembagi', value: 'B-365', items: const ['B-365', 'A-360', 'Aktual']),
            _MoneyField(label: 'Maksimal Saldo Tidak Kena Pajak', initialValue: '7500000'),
            _NumberField(label: 'Rate Pajak (%)', initialValue: '20.00'),
            _TextField(label: 'Kode Pengurusan Buku', initialValue: '02'),
            _CheckField(label: 'Minus Saldo Minimum'),
            _CheckField(label: 'Hitung Bunga Dibulatkan'),
            _DropdownField(label: 'Saldo Hitung Pajak', value: 'Saldo Akhir', items: const ['Saldo Akhir', 'Saldo Rata-rata']),
            _DropdownField(label: 'Cara Hitung Pajak', value: 'Pajak dihitung harian', items: const ['Pajak dihitung harian', 'Pajak akhir bulan']),
          ],
        );
      case 1:
        return _SectionCard(
          title: 'Saldo Menggunakan Pola Progresif',
          children: [
            _CheckField(label: 'Saldo menggunakan pola progresif', initialValue: true),
            _RangeTable(titleLeft: 'Saldo Minimal', titleRight: 'Saldo Maksimal'),
          ],
        );
      case 2:
        return _SectionCard(
          title: 'Setoran, Saldo, dan Penalti',
          children: [
            _MoneyField(label: 'Minimal Setoran Pertama', initialValue: '50000'),
            _MoneyField(label: 'Minimal Setoran Berikutnya', initialValue: '50000'),
            _MoneyField(label: 'Saldo Minimum', initialValue: '50000'),
            _MoneyField(label: 'Maksimal Spread (%)', initialValue: '0'),
            _MoneyField(label: 'Max Penarikan Tunai 1 hari', initialValue: '999999999999'),
            _NumberField(label: 'Denda max penarikan (%)', initialValue: '0.000'),
            _NumberField(label: 'Kelipatan Setoran', initialValue: '0'),
            _TextField(label: 'File Setor'),
            _TextField(label: 'SBB Denda Max Penarikan', initialValue: '0000000'),
          ],
        );
      case 3:
        return _SectionCard(
          title: 'Biaya Administrasi & Penutupan',
          children: [
            _MoneyField(label: 'Biaya Administrasi Bulanan', initialValue: '5000'),
            _MoneyField(label: 'Biaya Penutupan', initialValue: '25000'),
            _MoneyField(label: 'Biaya Penggantian Buku', initialValue: '2500'),
            _MoneyField(label: 'Biaya Pencetakan Rekening Koran', initialValue: '0'),
            _MoneyField(label: 'Biaya Rekening Pasif', initialValue: '0'),
            _TextField(label: 'Tgl Proses', initialValue: '99'),
            _MoneyField(label: 'Jika minimal saldo', initialValue: '0'),
          ],
        );
      case 4:
        return _SectionCard(
          title: 'Setup No SBB Produk Tabungan',
          children: const [
            _TextField(label: 'SBB Tabungan', initialValue: '0210403'),
            _TextField(label: 'SBB Biaya Bunga', initialValue: '0520103'),
            _TextField(label: 'SBB Accrual Biaya Bunga', initialValue: '0000000'),
            _TextField(label: 'SBB Pend By Adm', initialValue: '0430201'),
            _TextField(label: 'SBB Pend Penutupan Tab', initialValue: '0440103'),
            _TextField(label: 'SBB Titipan Tax', initialValue: '0210203'),
            _TextField(label: 'SBB Pendapatan Fleks Pajak', initialValue: '0000000'),
            _TextField(label: 'SBB DD Tab', initialValue: '0000000'),
            _TextField(label: 'SBB Subsidi Tax', initialValue: '0000000'),
          ],
        );
      case 5:
        return _SectionCard(
          title: 'Otomatis Tutup, Charge, dan Fee Online',
          children: const [
            _CheckField(label: 'Saldo dibawah saldo minimum, otomatis TUTUP'),
            _TextField(label: 'Grace Periode Penutupan akhir dibawah Saldo Minimal'),
            _CheckField(label: 'Saldo NIHIL, otomatis TUTUP', initialValue: true),
            _TextField(label: 'Grace Periode Penutupan akhir dibawah Saldo Nihil'),
            _CheckField(label: 'Penutupan oleh Nasabah, Bunga Berjalan Dibayar', initialValue: true),
            _CheckField(label: 'Transaksi Antar Cabang melalui Front End dikenakan Charge'),
            _TextField(label: 'SBB Penampungan', initialValue: '0000000'),
            _TextField(label: 'SBB Fee Online', initialValue: '0000000'),
            _MoneyField(label: 'Fee Online'),
          ],
        );
      case 6:
        return _SectionCard(
          title: 'Pasif & Rekap Transaksi',
          children: const [
            _NumberField(label: 'Berapa lama (hari) tidak bertransaksi dianggap Pasif', initialValue: '180'),
            _DropdownField(label: 'Jika Pasif, apakah memerlukan otorisasi saat bertransaksi', value: 'Y-Ya', items: ['Y-Ya', 'T-Tidak']),
            _DropdownField(label: 'Trans yang tidak dicetak ke buku dilengkapi', value: '', items: ['', 'Ya', 'Tidak']),
            _DropdownField(label: 'Dasar Rekap Transaksi', value: '', items: ['', 'Harian', 'Bulanan']),
            _NumberField(label: 'Jumlah Hari / Transaksi'),
            _TextField(label: 'Kode Transaksi Rekap'),
          ],
        );
      case 7:
        return _SectionCard(
          title: 'Asuransi Tabungan',
          children: const [
            _CheckField(label: 'Tabungan diasuransikan'),
            _MoneyField(label: 'Premi Asuransi Per tahun (Rp)', initialValue: '0'),
            _TextField(label: 'SBB Biaya Asuransi', initialValue: '0000000'),
            _TextField(label: 'SBB Titipan Asuransi Tab', initialValue: '0000000'),
            _MoneyField(label: 'Min Saldo Perpanjangan Premi Otomatis (Rp)', initialValue: '0'),
          ],
        );
      case 8:
        return _SectionCard(
          title: 'Penarikan Tunai Dibatasi',
          children: const [
            _CheckField(label: 'Frekuensi Penarikan Tunai Dibatasi'),
            _TextField(label: 'Frek. Tarik Tunai'),
            _DropdownField(label: 'Jika Lebih', value: '', items: ['', 'Tolak', 'Denda']),
            _NumberField(label: 'Denda', initialValue: '0.000'),
            _TextField(label: 'SBB Denda', initialValue: '0000000'),
          ],
        );
      default:
        return _SectionCard(
          title: 'Tabungan Berjangka',
          children: const [
            _CheckField(label: 'Tabungan Berjangka'),
            _CheckField(label: 'JW dan setoran menggunakan table, jika tidak (Bln)'),
            _CheckField(label: 'Denda penarikan sebelum JT tempo'),
            _NumberField(label: 'Denda penarikan sebelum JT tempo', initialValue: '0.000'),
            _TextField(label: 'SBB Denda', initialValue: '0000000'),
            _CheckField(label: 'Jika sudah JT tempo dialihkan ke SBB'),
            _TextField(label: 'SBB Pengalihan JT', initialValue: '0000000'),
            _CheckField(label: 'Jika sudah JT tempo perhitungan bunga STOP'),
            _CheckField(label: 'Jika ditarik, status rekening TUTUP'),
          ],
        );
    }
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final String mode;

  const _Header({required this.title, required this.subtitle, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.greenAccent.shade400, borderRadius: BorderRadius.circular(6)),
            child: Text('Mode: $mode', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StepNavigation extends StatelessWidget {
  final List<String> steps;
  final int current;
  final ValueChanged<int> onTap;

  const _StepNavigation({required this.steps, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step Setup Tabungan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(steps.length, (i) {
              final selected = i == current;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: selected ? colorPrimary : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'Step ${i + 1}: ${steps[i]}',
                      style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ProductIdentity extends StatelessWidget {
  final TextEditingController kodeController;
  final TextEditingController keteranganController;

  const _ProductIdentity({required this.kodeController, required this.keteranganController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.greenAccent.shade400, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 130, child: _TextField(label: 'Kode Produk', controller: kodeController, required: true, maxLength: 20)),
          const SizedBox(width: 16),
          Expanded(child: _TextField(label: 'Keterangan', controller: keteranganController, required: true, maxLength: 200)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 12, children: children.map((e) => SizedBox(width: 310, child: e)).toList()),
      ],
    );
  }
}

class _FormNavigation extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const _FormNavigation({required this.current, required this.total, required this.onBack, required this.onNext, required this.onReset, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(onPressed: current == 0 ? null : onBack, child: const Text('Back')),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: current >= total - 1 ? null : onNext, child: const Text('Next')),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: onSave, style: ElevatedButton.styleFrom(backgroundColor: colorPrimary), child: const Text('Simpan', style: TextStyle(color: Colors.white))),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}

class _RangeTable extends StatelessWidget {
  final String titleLeft;
  final String titleRight;

  const _RangeTable({required this.titleLeft, required this.titleRight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 650,
      child: DataTable(
        columns: [DataColumn(label: Text(titleLeft)), DataColumn(label: Text(titleRight))],
        rows: const [
          DataRow(cells: [DataCell(Text('0.00')), DataCell(Text('49,999,999.00'))]),
          DataRow(cells: [DataCell(Text('50,000,000.00')), DataCell(Text('249,999,999.00'))]),
          DataRow(cells: [DataCell(Text('250,000,000.00')), DataCell(Text('499,999,999.00'))]),
          DataRow(cells: [DataCell(Text('500,000,000.00')), DataCell(Text('999,999,999.00'))]),
          DataRow(cells: [DataCell(Text('1,000,000,000.00')), DataCell(Text('999,999,999,999.00'))]),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final bool required;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const _TextField({required this.label, this.initialValue, this.controller, this.required = false, this.maxLength, this.inputFormatters});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: (value) {
        final text = (value ?? '').trim();
        if (required && text.isEmpty) return 'Wajib diisi';
        if (maxLength != null && text.length > maxLength!) return 'Maksimal $maxLength karakter';
        return null;
      },
      decoration: _decoration(label),
    );
  }
}

class _MoneyField extends _TextField {
  const _MoneyField({required super.label, super.initialValue}) : super(inputFormatters: const []);
}

class _NumberField extends _TextField {
  const _NumberField({required super.label, super.initialValue}) : super(inputFormatters: const []);
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;

  const _DropdownField({required this.label, required this.value, required this.items});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: _decoration(label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.isEmpty ? '-' : e))).toList(),
      onChanged: (_) {},
    );
  }
}

class _CheckField extends StatefulWidget {
  final String label;
  final bool initialValue;

  const _CheckField({required this.label, this.initialValue = false});

  @override
  State<_CheckField> createState() => _CheckFieldState();
}

class _CheckFieldState extends State<_CheckField> {
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(widget.label),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (v) => setState(() => value = v ?? false),
    );
  }
}

InputDecoration _decoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    counterText: '',
  );
}
