import '../utils/price_formatter.dart';

/// [MoneyUtils] provides precise integer-based financial calculations.
///
/// RULE: Store ALL money as integers (paisa/paise).
/// ₹100.50 -> stored as 10050 (int)
///
/// This avoids the #1 technical trap in financial apps: floating-point precision bugs.
/// Example: 0.1 + 0.2 != 0.3 in double math, but 10 + 20 == 30 in integer math.
class MoneyUtils {
  /// Convert rupees (double) to paisa (int)
  /// Uses .round() to handle precision issues during conversion itself.
  static int toPaisa(double rupees) => (rupees * 100).round();

  /// Convert paisa (int) to rupees (double) for display calculations
  static double toRupees(int paisa) => paisa / 100;

  /// Formats paisa directly into a localized currency string
  static String format(int paisa) => AppPriceFormatter.format(toRupees(paisa));

  /// Formats paisa directly into a localized compact currency string (K, M, B)
  static String formatCompact(int paisa) => AppPriceFormatter.formatCompact(toRupees(paisa));

  /// Calculates percentage change using integer math to maintain precision.
  /// Result is in basis points (1/100th of a percent).
  /// To get 2.5%, this returns 250.
  static int calculatePercentChange(int current, int previous) {
    if (previous == 0) return 0;
    // (diff * 10000) / previous gives precision to 2 decimal places in integer space
    return ((current - previous) * 10000) ~/ previous;
  }
}
