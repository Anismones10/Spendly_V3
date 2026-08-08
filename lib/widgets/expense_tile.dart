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
  // Daily threshold from Calendar. Amounts above it are flagged.
  // Null or 0 means no flagging.
  final double? threshold;
  // Drawn by the card itself rather than by a wrapper, so the highlight
  // lines up with the card instead of also covering its bottom margin.
  final bool selected;
  // Off when a date header already sits above the tile, so the day isn't
  // printed twice on every card in the grouped list.
  final bool showDate;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.symbol,
    this.isSelecting = false,
    this.overrideAmount,
    this.threshold,
    this.selected = false,
    this.showDate = true,
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

    if (isSplitPart) {
      final parts = expense.note!.split('|');
      // parts[0]=SPLIT_PART, parts[1]=groupId, parts[2]=partIndex/total
      // parts[3..N]=walletId:amount, optional NOTE:note
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

    // Above the daily threshold. The amount and the card outline share one
    // colour so they can never disagree — the same bands the Calendar uses
    // for its day dots.
    final shownAmount = isSplitPart && splitWallets.isNotEmpty
        ? splitWallets.fold(0.0, (s, e) => s + e.amount)
        : expense.amount;
    final Color? highColor =
        threshold == null || threshold! <= 0 || shownAmount <= threshold!
            ? null
            : shownAmount <= threshold! * 2
                ? const Color(0xFFFF9800)
                : const Color(0xFFE57373);

    // Only the red band outlines the card. Outlining the orange one too put a
    // frame around most of the list, which stopped the flag meaning anything.
    final bool outlineHigh = highColor == const Color(0xFFE57373);

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    theme.colorScheme.primary.withOpacity(0.07), cardColor)
                : cardColor,
            borderRadius: BorderRadius.circular(16),
            // Selection wins over the high-spend outline, which wins over the
            // faint recurring one.
            border: selected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : outlineHigh
                    ? Border.all(color: highColor!, width: 1.5)
                    : isRecurringInstance
                        ? Border.all(
                            color:
                                theme.colorScheme.primary.withOpacity(0.15),
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
              // ── Category icon with split/recurring badge ─────────────
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
                  // No wallet badge here — the wallet pill next to the
                  // category name already names the wallet, and the badge
                  // repeated it as an unlabelled icon.
                  //
                  // Split and recurring are mutually exclusive, so one slot
                  // is enough. When it's a split, the badge doubles as the
                  // button that opens the per-wallet breakdown.
                  if (isSplitPart ||
                      expense.isRecurring ||
                      isRecurringInstance)
                    Positioned(
                      bottom: -4,
                      left: -4,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isSplitPart && splitWallets.isNotEmpty
                            ? () => _showSplitBreakdown(
                                context, isDark, theme, splitWallets)
                            : null,
                        // Padding grows the tap target inward over the avatar
                        // without moving the badge, which is anchored
                        // bottom-left. A bare 20x20 badge is too small to hit.
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, right: 10),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isSplitPart
                                  ? const Color(0xFF4A90E2)
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isSplitPart
                                  ? Icons.call_split_rounded
                                  : Icons.repeat_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
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
                            final swWallet = wallets.getById(sw.walletId);
                            if (swWallet == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Color(swWallet.colorValue)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        WalletProvider.resolveIcon(swWallet.type),
                                        size: 9,
                                        color: Color(swWallet.colorValue)),
                                    const SizedBox(width: 3),
                                    Text(
                                      swWallet.name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(swWallet.colorValue),
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
                        if (showDate)
                          Text(
                            AppUtils.formatDate(expense.date),
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4)),
                          ),
                        if (hasTime) ...[
                          if (showDate)
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
              if (highColor == null)
                Text(
                  AppUtils.formatAmount(shownAmount, symbol),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 14, color: highColor),
                    const SizedBox(width: 2),
                    Text(
                      AppUtils.formatAmount(shownAmount, symbol),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: highColor),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSplitBreakdown(
      BuildContext context,
      bool isDark,
      ThemeData theme,
      List<({String walletId, double amount})> splitWallets) {
    final wallets = context.read<WalletProvider>();
    final total = splitWallets.fold(0.0, (s, e) => s + e.amount);

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
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)
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
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.call_split_rounded,
                      color: Color(0xFF4A90E2), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Split across ${splitWallets.length} wallets',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...splitWallets.map((sw) {
              final w = wallets.getById(sw.walletId);
              final color =
                  w != null ? Color(w.colorValue) : theme.colorScheme.primary;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        w != null
                            ? WalletProvider.resolveIcon(w.type)
                            : Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w?.name ?? 'Deleted wallet',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppUtils.formatAmount(sw.amount, symbol),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppUtils.formatAmount(total, symbol),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
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
