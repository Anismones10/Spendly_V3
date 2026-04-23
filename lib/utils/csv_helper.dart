import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class CsvHelper {
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
        categories[e.categoryId]?.name ?? e.categoryId,
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
}
