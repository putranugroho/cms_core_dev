import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter angka uang/Rupiah untuk input form.
/// Output: 1000000 -> 1.000.000.
class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter({this.allowDecimal = false});

  final bool allowDecimal;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;
    if (raw.isEmpty) return newValue;

    final normalized = raw.replaceAll('Rp', '').replaceAll(' ', '');
    String integerPart = normalized;
    String decimalPart = '';

    if (allowDecimal && normalized.contains(',')) {
      final parts = normalized.split(',');
      integerPart = parts.first;
      decimalPart = parts.length > 1 ? parts.sublist(1).join('').replaceAll(RegExp(r'[^0-9]'), '') : '';
    }

    final digits = integerPart.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final number = int.tryParse(digits) ?? 0;
    final formatted = NumberFormat.decimalPattern('id_ID').format(number);
    final result = allowDecimal && decimalPart.isNotEmpty ? '$formatted,$decimalPart' : formatted;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
      composing: TextRange.empty,
    );
  }
}

class RupiahInputFormatter extends CurrencyInputFormatter {
  RupiahInputFormatter() : super();
}

String cleanCurrencyInput(String value) {
  final raw = value.replaceAll('Rp', '').replaceAll(' ', '').trim();
  if (raw.contains(',')) {
    final parts = raw.split(',');
    final left = parts.first.replaceAll(RegExp(r'[^0-9]'), '');
    final right = parts.length > 1 ? parts.sublist(1).join('').replaceAll(RegExp(r'[^0-9]'), '') : '';
    return right.isEmpty ? left : '$left.$right';
  }
  return raw.replaceAll(RegExp(r'[^0-9]'), '');
}
