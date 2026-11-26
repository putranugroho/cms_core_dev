import 'package:flutter/services.dart';

/// Input persen 0–100 dengan maksimal dua angka desimal.
/// Koma otomatis dinormalisasi menjadi titik agar payload selalu konsisten.
class PercentageInputFormatter extends TextInputFormatter {
  const PercentageInputFormatter({this.maximum = 100, this.decimalRange = 2});

  final double maximum;
  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(',', '.');
    if (text.isEmpty) return newValue;
    final pattern = RegExp('^\\d{0,3}(\\.\\d{0,$decimalRange})?\$');
    if (!pattern.hasMatch(text)) return oldValue;
    final number = double.tryParse(text);
    if (number == null || number < 0 || number > maximum) return oldValue;
    return newValue.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

double? parsePercentage(String? raw) => double.tryParse((raw ?? '').trim().replaceAll(',', '.'));

String? validatePercentage(String? raw, {bool required = false, bool allowZero = true}) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return required ? 'Wajib diisi' : null;
  final value = parsePercentage(text);
  if (value == null) return 'Gunakan format angka, contoh: 12.5';
  if (value < 0 || value > 100) return 'Nilai harus antara 0 sampai 100';
  if (!allowZero && value == 0) return 'Nilai wajib lebih dari 0';
  return null;
}
