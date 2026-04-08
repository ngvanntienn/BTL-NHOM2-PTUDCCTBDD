import 'package:intl/intl.dart';

class MoneyUtils {
  MoneyUtils._();

  static double normalizeVnd(num value) {
    final double amount = value.toDouble();
    if (amount == 0) {
      return 0;
    }

    // Backward compatibility: old data sometimes stores amounts in "thousands".
    if (amount.abs() < 1000) {
      return amount * 1000;
    }

    return amount;
  }

  static String formatVnd(NumberFormat formatter, num value) {
    return formatter.format(normalizeVnd(value));
  }
}
