import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class IDRInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return TextEditingValue(); // Return empty if input is empty
    }

    // Remove all non-numeric characters
    String numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericString.isNotEmpty) {
      final double value = double.parse(numericString);
      final String formattedValue = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(value);
      
      return TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }

    return newValue; // Return unchanged if formatting fails
  }
}
