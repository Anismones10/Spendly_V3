// Unit tests for AppUtils — the pure helpers used across Spendly.
//
// Widget tests of MyApp are not included: main() initializes Firebase and
// opens ten Hive boxes before runApp, so pumping MyApp directly needs that
// setup mocked first. These cover the formatting and date logic instead,
// which is where a silent regression would actually be costly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/utils/app_utils.dart';

void main() {
  group('generateId', () {
    test('produces unique values across successive calls', () {
      final ids = <String>{};
      for (var i = 0; i < 200; i++) {
        ids.add(AppUtils.generateId());
      }
      expect(ids.length, 200, reason: 'IDs must not collide');
    });

    test('uses the <microsecond-epoch>_<counter> shape', () {
      expect(AppUtils.generateId(), matches(RegExp(r'^\d+_\d+$')));
    });

    test('counter advances so IDs in the same clock tick still differ', () {
      final first = AppUtils.generateId();
      final second = AppUtils.generateId();
      expect(first, isNot(second));
    });
  });

  group('formatAmount', () {
    test('always shows two decimal places', () {
      expect(AppUtils.formatAmount(5, r'$'), r'$5.00');
      expect(AppUtils.formatAmount(5.5, r'$'), r'$5.50');
    });

    test('groups thousands with commas', () {
      expect(AppUtils.formatAmount(1234567.89, r'$'), r'$1,234,567.89');
    });

    test('rounds to the nearest cent', () {
      expect(AppUtils.formatAmount(0.005, r'$'), r'$0.01');
    });

    test('handles zero and negative amounts', () {
      expect(AppUtils.formatAmount(0, r'$'), r'$0.00');
      expect(AppUtils.formatAmount(-42.5, r'$'), r'$-42.50');
    });

    test('respects a multi-character symbol', () {
      expect(AppUtils.formatAmount(99.9, 'TND '), 'TND 99.90');
    });
  });

  group('date formatting', () {
    final date = DateTime(2026, 3, 7);

    test('formatDate is MMM d, yyyy', () {
      expect(AppUtils.formatDate(date), 'Mar 7, 2026');
    });

    test('formatShortDate omits the year', () {
      expect(AppUtils.formatShortDate(date), 'Mar 7');
    });

    test('formatMonthYear spells the month out', () {
      expect(AppUtils.formatMonthYear(date), 'March 2026');
    });
  });

  group('isSameDay', () {
    test('is true when only the time differs', () {
      expect(
        AppUtils.isSameDay(
          DateTime(2026, 3, 7, 0, 0),
          DateTime(2026, 3, 7, 23, 59, 59),
        ),
        isTrue,
      );
    });

    test('is false across a midnight boundary', () {
      expect(
        AppUtils.isSameDay(DateTime(2026, 3, 7, 23, 59), DateTime(2026, 3, 8)),
        isFalse,
      );
    });

    test('does not match same day-of-month in another month or year', () {
      expect(AppUtils.isSameDay(DateTime(2026, 3, 7), DateTime(2026, 4, 7)),
          isFalse);
      expect(AppUtils.isSameDay(DateTime(2025, 3, 7), DateTime(2026, 3, 7)),
          isFalse);
    });
  });

  group('budgetColor', () {
    test('is green while under half the budget', () {
      expect(AppUtils.budgetColor(0), const Color(0xFF2ECC71));
      expect(AppUtils.budgetColor(0.49), const Color(0xFF2ECC71));
    });

    test('steps through amber and orange at the 50/75/90 thresholds', () {
      expect(AppUtils.budgetColor(0.5), const Color(0xFFF39C12));
      expect(AppUtils.budgetColor(0.74), const Color(0xFFF39C12));
      expect(AppUtils.budgetColor(0.75), const Color(0xFFE67E22));
      expect(AppUtils.budgetColor(0.89), const Color(0xFFE67E22));
    });

    test('is red at or past 90 percent, including overspend', () {
      expect(AppUtils.budgetColor(0.9), const Color(0xFFE57373));
      expect(AppUtils.budgetColor(1.5), const Color(0xFFE57373));
    });
  });
}
