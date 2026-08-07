import 'package:accounting_kantor_gl_useraccess/utils/button_custom.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:accounting_kantor_gl_useraccess/utils/informationdialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductDepositoPage extends StatefulWidget {
  const ProductDepositoPage({super.key});

  @override
  State<ProductDepositoPage> createState() => _ProductDepositoPageState();
}

class _ProductDepositoPageState extends State<ProductDepositoPage> {
  final _formKey = GlobalKey<FormState>();
  final _kantor = TextEditingController(text: '100');
  final _kodeProduk = TextEditingController(text: '01');
  final _jangkaWaktu = TextEditingController(text: '1');
  int _step = 0;

  final List<String> _steps = const [
    'Identitas Produk',
    'Penalti & Bunga',
    'Tabel Penalti',
    'Nominal & Pajak',
    'Setup SBB',
  ];

  @override
  void dispose() {
    _kantor.dispose();
    _kodeProduk.dispose();
    _jangkaWaktu.dispose();
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
      _kantor.text = '100';
      _kodeProduk.text = '01';
      _jangkaWaktu.text = '1';
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    informationDialog(
      context,
      'Informasi',
      'UI Setup Produk Deposito sudah disiapkan. Endpoint simpan belum tersedia, sehingga data belum dikirim ke backend.',
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
              title: 'Setup Produk Deposito',
              subtitle: 'Definisi produk deposito untuk pengembangan produk ke depan',
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
                                _ProductIdentity(kantor: _kantor, kodeProduk: _kodeProduk, jangkaWaktu: _jangkaWaktu),
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
          title: 'Identitas Produk Deposito',
          children: const [
            _DropdownField(label: 'Jenis Jangka Waktu', value: 'Bulan', items: ['Hari', 'Bulan']),
            _TextField(label: 'Singkatan Produk', initialValue: 'Dep. 1BLN'),
            _TextField(label: 'Nama Panjang Produk', initialValue: 'Deposito 1 Bulan'),
            _DropdownField(label: 'Pembayaran Bunga', value: 'B-Accrual Bank Bulanan', items: ['B-Accrual Bank Bulanan', 'Transfer', 'Tunai']),
            _DropdownField(label: 'Faktor Pembagi', value: 'A-365', items: ['A-365', 'B-360', 'Aktual']),
            _DropdownField(label: 'Pencadangan Bunga (Akrual)', value: 'P-Proportional', items: ['P-Proportional', 'N-Nominal Tetap']),
          ],
        );
      case 1:
        return _SectionCard(
          title: 'Penalti, Bunga, dan Perhitungan Penuh',
          children: const [
            _CheckField(label: 'Bunga berbunga (Roll Over)'),
            _CheckField(label: 'Pencairan Bebas kapan saja'),
            _CheckField(label: 'Pencairan dikenakan Penalti', initialValue: true),
            _DropdownField(label: 'Perhitungan penalti', value: 'Prosentase', items: ['Nominal Tetap', 'Prosentase']),
            _NumberField(label: 'Minimal penalti (Rp atau %)', initialValue: '2.00'),
            _DropdownField(label: 'Bunga Deposito P + I', value: 'Tiap Bulan', items: ['Tiap Bulan', 'Tiap Jatuh Tempo Deposito']),
          ],
        );
      case 2:
        return _SectionCard(
          title: 'Tabel Penalti Berdasarkan Jumlah Hari',
          children: const [
            _PenaltyTable(),
          ],
        );
      case 3:
        return _SectionCard(
          title: 'Nominal Deposito, Spread, dan Pajak',
          children: const [
            _MoneyField(label: 'Minimal Nominal Deposito', initialValue: '500000'),
            _MoneyField(label: 'Maksimal Nominal Deposito', initialValue: '1000000000000'),
            _NumberField(label: 'Maksimal Spread', initialValue: '2.00'),
            _MoneyField(label: 'Maksimal Deposito Tidak Kena Pajak', initialValue: '7500000'),
            _NumberField(label: 'Tax (%)', initialValue: '20.00'),
          ],
        );
      default:
        return _SectionCard(
          title: 'Setup No SBB Produk Deposito',
          children: const [
            _TextField(label: 'Deposito', initialValue: '0210501'),
            _TextField(label: 'Biaya Bunga', initialValue: '0520201'),
            _TextField(label: 'Titipan Pajak', initialValue: '0210101'),
            _TextField(label: 'Materai', initialValue: '0190501'),
            _TextField(label: 'Titipan Accu Bunga', initialValue: '0290102'),
            _TextField(label: 'Titipan Penc Pokok', initialValue: '0210304'),
            _TextField(label: 'Titipan Penc Bunga', initialValue: '0290101'),
            _TextField(label: 'Penalty', initialValue: '0440999'),
            _TextField(label: 'Tip Bunga J Tempo', initialValue: '0210305'),
            _TextField(label: 'SBB Subsidi Tax', initialValue: '0000000'),
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
            decoration: BoxDecoration(color: Colors.yellowAccent.shade400, borderRadius: BorderRadius.circular(6)),
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
            const Text('Step Setup Deposito', style: TextStyle(fontWeight: FontWeight.bold)),
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
  final TextEditingController kantor;
  final TextEditingController kodeProduk;
  final TextEditingController jangkaWaktu;

  const _ProductIdentity({required this.kantor, required this.kodeProduk, required this.jangkaWaktu});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.yellowAccent.shade400, borderRadius: BorderRadius.circular(8)),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(width: 120, child: _TextField(label: 'Kantor', controller: kantor, required: true, maxLength: 7)),
          SizedBox(width: 140, child: _TextField(label: 'Kode Produk', controller: kodeProduk, required: true, maxLength: 20)),
          SizedBox(width: 140, child: _TextField(label: 'Jangka Waktu', controller: jangkaWaktu, required: true, maxLength: 5, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          SizedBox(width: 100, child: ButtonPrimary(onTap: () {}, name: 'Cari')),
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
        Wrap(spacing: 16, runSpacing: 12, children: children.map((e) => SizedBox(width: e is _PenaltyTable ? 650 : 320, child: e)).toList()),
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

class _PenaltyTable extends StatelessWidget {
  const _PenaltyTable();

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [DataColumn(label: Text('< Jumlah Hari')), DataColumn(label: Text('Nominal / Prosentase'))],
      rows: const [
        DataRow(cells: [DataCell(Text('999')), DataCell(Text('2.50'))]),
        DataRow(cells: [DataCell(Text('')), DataCell(Text('0.00'))]),
        DataRow(cells: [DataCell(Text('')), DataCell(Text('0.00'))]),
        DataRow(cells: [DataCell(Text('')), DataCell(Text('0.00'))]),
        DataRow(cells: [DataCell(Text('')), DataCell(Text('0.00'))]),
      ],
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
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
