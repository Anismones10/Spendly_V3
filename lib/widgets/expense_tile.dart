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
  final bool isSelecting;
  final double? overrideAmount; // used to show split group total

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.symbol,
    this.isSelecting = false,
    this.overrideAmount,
  });

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

    // Parse SPLIT_PART note
    // Format: SPLIT_PART|groupId|partIndex/total|walletId:amt|...|NOTE:note
    final isSplitPart = expense.note?.startsWith('SPLIT_PART|') == true;
    String? userNote;
    List<({String walletId, double amount})> splitWallets = [];
    int splitPart = 1;
    int splitTotal = 1;

    if (isSplitPart) {
      final parts = expense.note!.split('|');
      // parts[0]=SPLIT_PART, parts[1]=groupId, parts[2]=partIndex/total
      // parts[3..N]=walletId:amount, optional NOTE:note
      if (parts.length > 2) {
        final fraction = parts[2].split('/');
        splitPart = int.tryParse(fraction[0]) ?? 1;
        splitTotal = int.tryParse(fraction.length > 1 ? fraction[1] : '1') ?? 1;
      }
      for (int i = 3; i < parts.length; i++) {
        if (parts[i].startsWith('NOTE:')) {
          userNote = parts[i].substring(5);
        } else if (parts[i].contains(':')) {
          final kv = parts[i].split(':');
          final amt = double.tryParse(kv[1]) ?? 0;
          splitWallets.add((walletId: kv[0], amount: amt));
        }
      }
    } else {
      final hasNote = expense.note != null && expense.note!.trim().isNotEmpty;
      userNote = hasNote ? expense.note : null;
    }

    final hasNote = userNote != null && userNote.isNotEmpty;
    final hasTime = expense.timeHour != null && expense.timeMinute != null;
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
        onTap: isSelecting ? null : () => Navigator.push(
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
                        // Wallet pill(s) — show all split wallets or single wallet
                        if (isSplitPart && splitWallets.isNotEmpty) ...[
                          ...splitWallets.map((sw) {
                            final sw_wallet = wallets.getById(sw.walletId);
                            if (sw_wallet == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Color(sw_wallet.colorValue)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        WalletProvider.resolveIcon(sw_wallet.type),
                                        size: 9,
                                        color: Color(sw_wallet.colorValue)),
                                    const SizedBox(width: 3),
                                    Text(
                                      sw_wallet.name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(sw_wallet.colorValue),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ] else if (wallet != null) ...[
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
                AppUtils.formatAmount(
                  isSplitPart && splitWallets.isNotEmpty
                      ? splitWallets.fold(0.0, (s, e) => s + e.amount)
                      : expense.amount,
                  symbol,
                ),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecurringMenu(
      BuildContext context, bool isDark, ThemeData theme) {
    final provider = context.read<ExpenseProvider>();
    final childCount = provider.allExpenses
        .where((e) => e.recurringParentId == expense.id)
        .length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).padding.bottom + 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.repeat_rounded,
                      color: theme.colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${expense.recurringType ?? 'recurring'} · $childCount instance${childCount == 1 ? '' : 's'} generated',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Edit ──────────────────────────────────────────────────
            _RecurringOption(
              icon: Icons.edit_rounded,
              color: theme.colorScheme.primary,
              title: 'Edit this expense',
              subtitle: 'Change details for this entry only',
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(existing: expense)),
                );
              },
            ),
            const SizedBox(height: 10),

            // ── Stop recurring ────────────────────────────────────────
            _RecurringOption(
              icon: Icons.stop_circle_rounded,
              color: const Color(0xFFFF9800),
              title: 'Stop recurring',
              subtitle: 'Keep this expense but stop future auto-generation',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Stop Recurring?'),
                    content: Text(
                        '"${expense.name}" will no longer auto-generate new entries. Existing entries are kept.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800)),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Stop')),
                    ],
                  ),
                );
                if (confirm == true) {
                  final updated = ExpenseModel(
                    id: expense.id,
                    name: expense.name,
                    amount: expense.amount,
                    categoryId: expense.categoryId,
                    date: expense.date,
                    note: expense.note,
                    isRecurring: false,
                    recurringType: null,
                    walletId: expense.walletId,
                    timeHour: expense.timeHour,
                    timeMinute: expense.timeMinute,
                    recurringParentId: null,
                    recurringLastGenerated: expense.recurringLastGenerated,
                  );
                  provider.updateExpense(updated);
                }
              },
            ),
            const SizedBox(height: 10),

            // ── Delete this only ──────────────────────────────────────
            _RecurringOption(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFE57373),
              title: 'Delete this entry only',
              subtitle: 'Remove just this expense, keep recurring active',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete This Entry?'),
                    content: Text(
                        'Delete "${expense.name}"? The recurring schedule stays active.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  provider.deleteExpense(expense.id);
                }
              },
            ),
            const SizedBox(height: 10),

            // ── Delete all ────────────────────────────────────────────
            _RecurringOption(
              icon: Icons.delete_forever_rounded,
              color: const Color(0xFFB71C1C),
              title: 'Delete all recurring entries',
              subtitle: 'Remove this and all auto-generated entries',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete All?'),
                    content: Text(
                        'This will delete "${expense.name}" and all its auto-generated entries. This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete All')),
                    ],
                  ),
                );
                if (confirm == true) {
                  provider.deleteExpense(expense.id);
                }
              },
            ),
          ],
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
                () {
                  final n = expense.note ?? '';
                  if (n.startsWith('SPLIT_PART|')) {
                    final parts = n.split('|');
                    for (final p in parts) {
                      if (p.startsWith('NOTE:')) return p.substring(5);
                    }
                    return '';
                  }
                  return n;
                }(),
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


// ── Recurring option tile ─────────────────────────────────────────────────────

class _RecurringOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _RecurringOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color.withOpacity(0.4), size: 18),
          ],
        ),
      ),
    );
  }
}
