import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/currency_formatted.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:cms_core/utils/percentage_input_formatter.dart';
import 'package:cms_core/repository/new_menu_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PajakAgregatPage extends StatefulWidget {
  const PajakAgregatPage({super.key});

  @override
  State<PajakAgregatPage> createState() => _PajakAgregatPageState();
}

class _PajakAgregatPageState extends State<PajakAgregatPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominal = TextEditingController();
  final _rate = TextEditingController();
  bool _loading = true;
  String? _statusData;
  String? _updatedBy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final active = await NewMenuRepository.pajakAgregatActive();
      if (active != null) {
        _fill(active);
        final detail = await NewMenuRepository.pajakAgregatDetail();
        if (detail.isNotEmpty) _fill(detail);
      }
    } catch (e) {
      if (mounted) informationDialog(context, 'Warning', e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(Map<String, dynamic> data) {
    _nominal.text = _formatNominal(data['nominal']);
    _rate.text = _formatPercentage(data['rate']);
    _statusData = data['status_data']?.toString();
    _updatedBy = (data['updated_by'] ?? data['created_by'])?.toString();
  }

  @override
  void dispose() {
    _nominal.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final nominal = double.parse(cleanCurrencyInput(_nominal.text));
    final rate = double.parse(_rate.text.trim().replaceAll(',', '.'));
    DialogCustom().showLoading(context);
    try {
      final saved = await NewMenuRepository.pajakAgregatUpsert(nominal: nominal, rate: rate);
      if (mounted) Navigator.pop(context);
      _fill(saved);
      if (mounted) setState(() {});
      if (mounted) informationDialog(context, 'Informasi', 'Pajak Agregat berhasil disimpan.');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) informationDialog(context, 'Warning', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 760,
              child: Card(
                elevation: 0,
                color: const Color(0xFFFBF6FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _loading
                          ? const [Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))]
                          : [
                        const Text('Setup Pajak Agregat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nominal,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          validator: (value) {
                            final number = double.tryParse(cleanCurrencyInput(value ?? ''));
                            return number == null || number <= 0 ? 'Nominal wajib lebih dari 0' : null;
                          },
                          decoration: _decoration('Nominal Agregat yang Dikenakan Pajak *'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _rate,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: const [PercentageInputFormatter()],
                          validator: (value) => validatePercentage(value, required: true),
                          decoration: _decoration('Rate Pajak (%) *'),
                        ),
                        if ((_statusData ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text('Status: $_statusData${(_updatedBy ?? '').isEmpty ? '' : ' • Terakhir oleh: $_updatedBy'}',
                                style: const TextStyle(color: Colors.black54)),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, minimumSize: const Size(140, 52)),
                          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatNominal(dynamic value) {
  final number = double.tryParse(value?.toString() ?? '') ?? 0;
  if (number <= 0) return '';
  final digits = number.round().toString();
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
}

String _formatPercentage(dynamic value) {
  final number = double.tryParse(value?.toString() ?? '');
  if (number == null) return '';
  return number == number.roundToDouble() ? number.toStringAsFixed(0) : number.toString();
}

InputDecoration _decoration(String label) {
  return InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)));
}
