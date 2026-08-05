import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  /// Monotonic counter appended to the timestamp. The system clock is not
  /// fine-grained enough on its own — several hundred calls can land in the
  /// same tick — so the counter is what actually guarantees uniqueness for
  /// IDs created in the same session.
  static int _idCounter = 0;

  static String generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  static String formatAmount(double amount, String symbol) {
    final formatter = NumberFormat('#,##0.00');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Color budgetColor(double percentage) {
    if (percentage < 0.5) return const Color(0xFF2ECC71);  // income green
    if (percentage < 0.75) return const Color(0xFFF39C12); // warm amber
    if (percentage < 0.9) return const Color(0xFFE67E22);  // orange
    return const Color(0xFFE57373);                         // soft expense red
  }
}
