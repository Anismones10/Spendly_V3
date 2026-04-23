import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';
import '../screens/add_expense_screen.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final String symbol;

  const ExpenseTile({super.key, required this.expense, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    final cat = categories.getById(expense.categoryId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Expense'),
            content:
                Text('Delete "${expense.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<ExpenseProvider>().deleteExpense(expense.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddExpenseScreen(existing: expense)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat != null
                      ? Color(cat.colorValue).withOpacity(0.15)
                      : theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                    CategoryIcons.resolve(cat?.icon ?? ''),
                    color: cat != null ? Color(cat.colorValue) : const Color(0xFF4A90E2),
                    size: 22,
                  ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          cat?.name ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: cat != null
                                ? Color(cat.colorValue)
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (expense.isRecurring) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              expense.recurringType ?? 'recurring',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppUtils.formatDate(expense.date),
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                AppUtils.formatAmount(expense.amount, symbol),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
