import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';
import '../screens/add_expense_screen.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final String symbol;

  const ExpenseTile(
      {super.key, required this.expense, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    final wallets = context.watch<WalletProvider>();
    final cat = categories.getById(expense.categoryId);
    final wallet = expense.walletId != null
        ? wallets.getById(expense.walletId!)
        : null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasNote =
        expense.note != null && expense.note!.trim().isNotEmpty;
    final hasTime =
        expense.timeHour != null && expense.timeMinute != null;
    final isRecurringInstance = expense.recurringParentId != null;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text(
                'Delete "${expense.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
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
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  AddExpenseScreen(existing: expense)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isRecurringInstance
                ? Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    width: 1)
                : null,
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
              // ── Category icon with wallet badge ──────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cat != null
                          ? Color(cat.colorValue).withOpacity(0.15)
                          : theme.colorScheme.primary
                              .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CategoryIcons.resolve(cat?.icon ?? ''),
                      color: cat != null
                          ? Color(cat.colorValue)
                          : const Color(0xFF4A90E2),
                      size: 22,
                    ),
                  ),
                  if (wallet != null)
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(wallet.colorValue),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          WalletProvider.resolveIcon(wallet.type),
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // ── Details ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row with icons
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRecurringInstance) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Auto-generated recurring',
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.repeat_rounded,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                        if (hasNote) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () =>
                                _showNote(context, isDark, theme),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.sticky_note_2_outlined,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Badges row
                    Row(
                      children: [
                        // Category name
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
                        // Wallet pill
                        if (wallet != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Color(wallet.colorValue)
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    WalletProvider.resolveIcon(
                                        wallet.type),
                                    size: 9,
                                    color:
                                        Color(wallet.colorValue)),
                                const SizedBox(width: 3),
                                Text(
                                  wallet.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(wallet.colorValue),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Recurring badge
                        if (expense.isRecurring) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(6),
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

                    // Date + Time row
                    Row(
                      children: [
                        Text(
                          AppUtils.formatDate(expense.date),
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4)),
                        ),
                        if (hasTime) ...[
                          Text(
                            '  ·  ',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.25)),
                          ),
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: theme.colorScheme.primary
                                .withOpacity(0.5),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            expense.formattedTime,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Amount ───────────────────────────────────────────────
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

  void _showNote(
      BuildContext context, bool isDark, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sticky_note_2_rounded,
                      color: theme.colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    expense.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close_rounded,
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.4)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.primary
                        .withOpacity(0.15)),
              ),
              child: Text(
                expense.note!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
