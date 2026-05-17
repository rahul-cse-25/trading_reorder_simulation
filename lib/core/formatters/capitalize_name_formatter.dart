import 'package:flutter/services.dart';

/// [CapitalizeFirstLetterFormatter] ensures the first letter of a string is uppercase.
/// Useful for watchlist names, user names, etc.
class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Capitalize only the first character
    final String text =
        newValue.text[0].toUpperCase() + newValue.text.substring(1);

    return newValue.copyWith(
      text: text,
      selection: newValue.selection,
    );
  }
}
