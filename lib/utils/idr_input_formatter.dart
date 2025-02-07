import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class IDRInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove any non-digit characters
    String cleanedText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanedText.isEmpty) {
      return TextEditingValue.empty;
    }

    // Format as currency
    String formattedText = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(int.parse(cleanedText));

    // Set the selection position
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
