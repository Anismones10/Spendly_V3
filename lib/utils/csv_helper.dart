import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../models/income_model.dart';
import '../models/loan_model.dart';

class CsvHelper {
  // ── Expenses ──────────────────────────────────────────────────────────────

  static Future<void> exportExpenses(
    List<ExpenseModel> expenses,
    Map<String, CategoryModel> categories,
    String currencySymbol,
  ) async {
    final rows = <List<dynamic>>[
      ['Date', 'Name', 'Category', 'Amount', 'Note', 'Recurring'],
      ...expenses.map((e) => [
        e.date.toIso8601String().split('T')[0],
        e.name,
        categories[e.categoryId]?.name ?? 'Uncategorized',
        e.amount,
        e.note ?? '',
        e.isRecurring ? (e.recurringType ?? 'Yes') : 'No',
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/expenses_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Expense Export');
  }

  // ── Income ────────────────────────────────────────────────────────────────

  static Future<void> exportIncome(
    List<IncomeModel> incomes,
    String currencySymbol,
  ) async {
    final rows = <List<dynamic>>[
      ['Date', 'Source', 'Amount', 'Note'],
      ...incomes.map((i) => [
        i.date.toIso8601String().split('T')[0],
        i.source,
        i.amount,
        i.note ?? '',
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/income_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Income Export');
  }

  // ── Loans ─────────────────────────────────────────────────────────────────

  static Future<void> exportLoans(
    List<LoanModel> loans,
    String currencySymbol,
  ) async {
    final rows = <List<dynamic>>[
      ['Date', 'Type', 'Person', 'Amount', 'Paid', 'Remaining', 'Due Date', 'Status', 'Note'],
      ...loans.map((l) => [
        l.date.toIso8601String().split('T')[0],
        l.type == 'lending' ? 'Lent Out' : 'Borrowed',
        l.personName,
        l.amount,
        l.paidAmount,
        l.amount - l.paidAmount,
        l.dueDate != null ? l.dueDate!.toIso8601String().split('T')[0] : '',
        l.status,
        l.note ?? '',
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/loans_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Loans Export');
  }

  // ── All in one ────────────────────────────────────────────────────────────

  static Future<void> exportAll(
    List<ExpenseModel> expenses,
    Map<String, CategoryModel> categories,
    List<IncomeModel> incomes,
    List<LoanModel> loans,
    String currencySymbol,
  ) async {
    final allRows = <List<dynamic>>[
      ['=== EXPENSES ==='],
      ['Date', 'Name', 'Category', 'Amount', 'Note', 'Recurring'],
      ...expenses.map((e) => [
        e.date.toIso8601String().split('T')[0],
        e.name,
        categories[e.categoryId]?.name ?? 'Uncategorized',
        e.amount,
        e.note ?? '',
        e.isRecurring ? (e.recurringType ?? 'Yes') : 'No',
      ]),
      [],
      ['=== INCOME ==='],
      ['Date', 'Source', 'Amount', 'Note'],
      ...incomes.map((i) => [
        i.date.toIso8601String().split('T')[0],
        i.source,
        i.amount,
        i.note ?? '',
      ]),
      [],
      ['=== LOANS ==='],
      ['Date', 'Type', 'Person', 'Amount', 'Paid', 'Remaining', 'Due Date', 'Status', 'Note'],
      ...loans.map((l) => [
        l.date.toIso8601String().split('T')[0],
        l.type == 'lending' ? 'Lent Out' : 'Borrowed',
        l.personName,
        l.amount,
        l.paidAmount,
        l.amount - l.paidAmount,
        l.dueDate != null ? l.dueDate!.toIso8601String().split('T')[0] : '',
        l.status,
        l.note ?? '',
      ]),
    ];

    final csv = const ListToCsvConverter().convert(allRows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/spendly_full_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Spendly Full Export');
  }
}
