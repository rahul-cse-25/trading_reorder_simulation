import 'package:intl/intl.dart';

class AppPriceFormatter {
  static final formatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static String format(double price) => formatter.format(price);
}
