import 'package:flutter/services.dart';

/// [IntegerInputFormatter] restricts input to positive whole numbers only.
/// Perfect for trading quantities (e.g., you can't buy 1.5 shares in this sim).
class IntegerInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty string so user can clear the field
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only allow digits 0-9
    final regExp = RegExp(r'^[0-9]*$');
    if (!regExp.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Prevent leading zeros (e.g., "05" becomes "5")
    // unless the entire value is just "0"
    if (newValue.text.length > 1 && newValue.text.startsWith('0')) {
      final sanitized = newValue.text.replaceFirst(RegExp(r'^0+'), '');
      return newValue.copyWith(
        text: sanitized.isEmpty ? '0' : sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }

    return newValue;
  }
}
