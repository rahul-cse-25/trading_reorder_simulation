import 'package:intl/intl.dart';

class AppPriceFormatter {
  static final formatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static String format(double price) => formatter.format(price);

  static String formatCompact(double value) {
    final format = NumberFormat.compact(locale: 'en_IN');
    return '₹${format.format(value)}';
  }
}
