import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet_model.dart';
import '../widgets/expense_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/list_filter_bar.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final VoidCallback? onMoreTap;
  const ExpensesScreen({super.key, this.onMoreTap});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _searchController = TextEditingController();
  String _periodFilter = 'all';
  String? _walletFilter;

  // ── Selection mode ────────────────────────────────────────────────────────
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<ExpenseModel> all) {
    setState(() {
      _selectedIds.addAll(all.map((e) => e.id));
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelected(BuildContext context, ExpenseProvider expenses) async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Selected'),
        content: Text('Delete $count expense${count == 1 ? '' : 's'}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final id in _selectedIds.toList()) {
        expenses.deleteExpense(id);
      }
      _clearSelection();
    }
  }

  Future<void> _moveCategorySelected(BuildContext context) async {
    final categories = context.read<CategoryProvider>().categories;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedCat = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Move to Category',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: categories.map((cat) {
                  final color = Color(cat.colorValue);
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, cat.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Container(width: 36, height: 36,
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(CategoryIcons.resolve(cat.icon), color: color, size: 18)),
                        const SizedBox(width: 12),
                        Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedCat != null) {
      final provider = context.read<ExpenseProvider>();
      for (final id in _selectedIds.toList()) {
        final e = provider.allExpenses.firstWhere((x) => x.id == id, orElse: () => provider.allExpenses.first);
        provider.updateExpense(ExpenseModel(
          id: e.id, name: e.name, amount: e.amount,
          categoryId: selectedCat, date: e.date, note: e.note,
          isRecurring: e.isRecurring, recurringType: e.recurringType,
          walletId: e.walletId, timeHour: e.timeHour, timeMinute: e.timeMinute,
          recurringParentId: e.recurringParentId,
          recurringLastGenerated: e.recurringLastGenerated,
        ));
      }
      _clearSelection();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<DateTime, List<ExpenseModel>> _groupByDay(List<ExpenseModel> list) {
    final Map<DateTime, List<ExpenseModel>> grouped = {};
    for (final e in list) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      grouped.putIfAbsent(day, () => []).add(e);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String _formatDayHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    final month = DateFormat('MMMM').format(day);
    final d = day.day;
    String suffix;
    if (d >= 11 && d <= 13) {
      suffix = 'th';
    } else {
      switch (d % 10) {
        case 1: suffix = 'st'; break;
        case 2: suffix = 'nd'; break;
        case 3: suffix = 'rd'; break;
        default: suffix = 'th';
      }
    }
    return '$month $d$suffix';
  }

  /// Commits a period chosen in the filter sheet.
  ///
  /// A custom period arrives with the range the picker returned; the fixed ones
  /// derive theirs from the key, so the sheet never has to know the dates.
  void _applyPeriod(
      String period, DateTimeRange? range, ExpenseProvider expenses) {
    setState(() => _periodFilter = period);
    expenses.setDateRange(
        period == 'custom' ? range : rangeForPeriod(period, DateTime.now()));
  }

  List<ExpenseModel> _applyWalletFilter(List<ExpenseModel> list) {
    if (_walletFilter == null) return list;
    return list.where((e) => e.walletId == _walletFilter).toList();
  }

  void _showSortFilter(BuildContext context) {
    final expenses = context.read<ExpenseProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        walletFilter: _walletFilter,
        onWalletChanged: (id) => setState(() => _walletFilter = id),
        periodFilter: _periodFilter,
        customRange: _periodFilter == 'custom' ? expenses.dateRange : null,
        onPeriodChanged: (p, r) => _applyPeriod(p, r, expenses),
        onClearAll: () {
          expenses.clearFilters();
          _searchController.clear();
          setState(() {
            _periodFilter = 'all';
            _walletFilter = null;
          });
        },
      ),
    );
  }

  void _showSplitDetail(BuildContext context, ExpenseModel expense) {
    final walletProvider = context.read<WalletProvider>();
    final symbol = context.read<SettingsProvider>().currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Parse SPLIT_PART|groupId|partIndex/total|walletId:amt|...|NOTE:note
    final note = expense.note ?? '';
    final parts = note.split('|');
    String userNote = '';
    final splits = <Map<String, dynamic>>[];

    for (int i = 3; i < parts.length; i++) {
      if (parts[i].startsWith('NOTE:')) {
        userNote = parts[i].substring(5);
      } else if (parts[i].contains(':')) {
        final kv = parts[i].split(':');
        final wallet = walletProvider.getById(kv[0]);
        final amount = double.tryParse(kv[1]) ?? 0;
        splits.add({'wallet': wallet, 'walletId': kv[0], 'amount': amount});
      }
    }

    // Total = sum of all split parts
    final total = splits.fold(0.0, (s, e) => s + (e['amount'] as double));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.call_split_rounded,
                    color: Color(0xFF4A90E2), size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expense.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text(AppUtils.formatAmount(total, symbol),
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ]),
            ]),
            const SizedBox(height: 16),
            const Text('Split across wallets:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...splits.map((s) {
              final w = s['wallet'] as WalletModel?;
              final amount = s['amount'] as double;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.2)),
                ),
                child: Row(children: [
                  Icon(WalletProvider.resolveIcon(w?.type ?? ''),
                      color: const Color(0xFF4A90E2), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(w?.name ?? s['walletId'] as String,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Text(AppUtils.formatAmount(amount, symbol),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2ECC71))),
                ]),
              );
            }),
            if (userNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Note: $userNote',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tips / hints sheet ──────────────────────────────────────────────────
  void _showHints(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sections = <({
      String title,
      IconData icon,
      Color color,
      List<({IconData icon, String text})> tips,
    })>[
      (
        title: 'Managing expenses',
        icon: Icons.receipt_long_rounded,
        color: theme.colorScheme.primary,
        tips: [
          (icon: Icons.touch_app_rounded,
           text: 'Tap an expense to open and edit it.'),
          (icon: Icons.swipe_left_rounded,
           text: 'Swipe left on an expense to delete it.'),
        ],
      ),
      (
        title: 'Why an amount turns red',
        icon: Icons.arrow_upward_rounded,
        color: const Color(0xFFE57373),
        tips: [
          (icon: Icons.straighten_rounded,
           text: 'Every expense is measured against a daily limit. Both '
                 'colours mean the single expense went over it — not your '
                 'whole day.'),
          (icon: Icons.arrow_upward_rounded,
           text: 'Orange with an up arrow: above the limit, but not more '
                 'than double it.'),
          (icon: Icons.crop_square_rounded,
           text: 'Red: more than double the limit. Only red also outlines '
                 'the card, so the biggest ones stand out at a glance.'),
          (icon: Icons.calculate_rounded,
           text: 'On Auto the limit is this month\'s spending divided by its '
                 'days, so it moves as you spend.'),
          (icon: Icons.tune_rounded,
           text: 'Set your own limit from the Calendar tab to decide exactly '
                 'when an expense counts as high. The Calendar dots use the '
                 'same three colours.'),
        ],
      ),
      (
        title: 'Split expenses',
        icon: Icons.call_split_rounded,
        color: const Color(0xFF4A90E2),
        tips: [
          (icon: Icons.call_split_rounded,
           text: 'A blue split badge on the category icon means the expense '
                 'was paid from more than one wallet.'),
          (icon: Icons.touch_app_rounded,
           text: 'Tap that blue badge to see how much came from each wallet, '
                 'without opening the expense.'),
          (icon: Icons.functions_rounded,
           text: 'The amount shown on a split expense is the total of all '
                 'its parts.'),
        ],
      ),
      (
        title: 'Recurring expenses',
        icon: Icons.repeat_rounded,
        color: Colors.orange,
        tips: [
          (icon: Icons.repeat_rounded,
           text: 'An orange loop badge marks a recurring expense.'),
          (icon: Icons.tune_rounded,
           text: 'Use the loop button beside this one to manage all your '
                 'recurring expenses.'),
        ],
      ),
      (
        title: 'Selecting several at once',
        icon: Icons.checklist_rounded,
        color: Colors.teal,
        tips: [
          (icon: Icons.touch_app_rounded,
           text: 'Long-press an expense to start selecting. Then tap others '
                 'to add or remove them.'),
          (icon: Icons.done_all_rounded,
           text: 'Tap "All" in the top bar to select everything in view.'),
          (icon: Icons.visibility_rounded,
           text: 'While selecting, long-press an expense to view its details '
                 'without leaving selection mode.'),
          (icon: Icons.folder_rounded,
           text: 'Move the selected expenses to another category, or delete '
                 'them all, from the top bar.'),
        ],
      ),
      (
        title: 'Finding expenses',
        icon: Icons.search_rounded,
        color: Colors.purple,
        tips: [
          (icon: Icons.search_rounded,
           text: 'Search by name to filter the list as you type.'),
          (icon: Icons.swap_vert_rounded,
           text: 'The pill at the end of the search row sets the order — '
                 'newest, oldest, highest or lowest.'),
          (icon: Icons.tune_rounded,
           text: 'The tune button in the top bar holds the period, wallet and '
                 'category filters. A dot on it means one is active, and each '
                 'appears as a chip you can tap to remove.'),
          (icon: Icons.calendar_today_rounded,
           text: 'Periods cover Today, This Week, This Month, or a custom '
                 'range you pick yourself.'),
        ],
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15), blurRadius: 20)
            ],
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.help_outline_rounded,
                          color: theme.colorScheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tips',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.4)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: theme.colorScheme.onSurface.withOpacity(0.07)),
              // ── Sections ────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  itemCount: sections.length,
                  itemBuilder: (_, i) {
                    final s = sections[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(s.icon, size: 16, color: s.color),
                            const SizedBox(width: 8),
                            Text(
                              s.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: s.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...s.tips.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: s.color.withOpacity(0.10),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Icon(t.icon,
                                        size: 13, color: s.color),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.75),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (i != sections.length - 1) ...[
                          const SizedBox(height: 6),
                          Divider(
                              height: 1,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.07)),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecurringManager(BuildContext context, ExpenseProvider expenses) {
    final symbol = context.read<SettingsProvider>().currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final parents = expenses.recurringTemplates;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: parents.isEmpty ? 0.35 : 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(children: [
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
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Recurring Expenses',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text('${parents.length} active template${parents.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ]),
              ]),
              const SizedBox(height: 16),

              if (parents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(Icons.repeat_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Text('No recurring expenses yet',
                          style: TextStyle(
                              fontSize: 15,
                              color: theme.colorScheme.onSurface.withOpacity(0.4))),
                    ]),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    itemCount: parents.length,
                    itemBuilder: (_, i) {
                      final parent = parents[i];
                      final childCount = expenses.allExpenses
                          .where((e) => e.recurringParentId == parent.id)
                          .length;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + type badge
                            Row(children: [
                              Expanded(
                                child: Text(parent.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  parent.recurringType ?? 'recurring',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            // Amount + children count
                            Row(children: [
                              Text(
                                AppUtils.formatAmount(parent.amount, symbol),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.copy_rounded,
                                  size: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.4)),
                              const SizedBox(width: 4),
                              Text(
                                '$childCount instance${childCount == 1 ? '' : 's'} generated',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            // Action buttons
                            Row(children: [
                              // Edit
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => AddExpenseScreen(
                                              existing: parent)),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.edit_rounded,
                                            size: 14,
                                            color: theme.colorScheme.primary),
                                        const SizedBox(width: 5),
                                        Text('Edit',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Stop
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Stop Recurring?'),
                                        content: Text(
                                            '"${parent.name}" will stop auto-generating new entries. Existing entries are kept.'),
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
                                        id: parent.id,
                                        name: parent.name,
                                        amount: parent.amount,
                                        categoryId: parent.categoryId,
                                        date: parent.date,
                                        note: parent.note,
                                        isRecurring: false,
                                        recurringType: null,
                                        walletId: parent.walletId,
                                        timeHour: parent.timeHour,
                                        timeMinute: parent.timeMinute,
                                        recurringParentId: null,
                                        recurringLastGenerated:
                                        parent.recurringLastGenerated,
                                      );
                                      expenses.updateExpense(updated);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9800).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.stop_circle_rounded,
                                            size: 14, color: Color(0xFFFF9800)),
                                        SizedBox(width: 5),
                                        Text('Stop',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFFF9800))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete all
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Delete All?'),
                                        content: Text(
                                            'This will delete "${parent.name}" and all $childCount generated entries.'),
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
                                      expenses.deleteExpense(parent.id);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.delete_forever_rounded,
                                            size: 14, color: Colors.red),
                                        SizedBox(width: 5),
                                        Text('Delete',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Same daily threshold the Calendar uses for its day dots: the value
    // saved by the Calendar's picker, or this month's daily average when
    // it's left on Auto. Expenses above it get a coloured amount + arrow.
    final now = DateTime.now();
    final savedThreshold =
        (Hive.box('settings').get('calendarThreshold', defaultValue: 0.0)
                as num)
            .toDouble();
    final monthTotal = expenses.getTotalForMonth(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final highThreshold = savedThreshold > 0
        ? savedThreshold
        : (monthTotal > 0 ? monthTotal / daysInMonth : 0.0);

    final rawList = _applyWalletFilter(expenses.filteredExpenses);

    // For split expenses: show only part 1 (which represents the full split)
    // but show its total amount = sum of all parts in the group
    final splitGroupTotals = <String, double>{};
    for (final e in rawList) {
      if (e.note?.startsWith('SPLIT_PART|') == true) {
        final parts = e.note!.split('|');
        if (parts.length > 1) {
          final groupId = parts[1];
          splitGroupTotals[groupId] =
              (splitGroupTotals[groupId] ?? 0) + e.amount;
        }
      }
    }

    // Keep only part 1 of each split group for display.
    //
    // A wallet filter has already reduced each group to the single part that
    // wallet paid, so collapsing by part index would drop the whole expense
    // whenever that part happened to be 2nd or later. With the filter on, the
    // surviving part is exactly what should be listed.
    final seenGroups = <String>{};
    final list = rawList.where((e) {
      if (_walletFilter != null) return true;
      if (e.note?.startsWith('SPLIT_PART|') == true) {
        final parts = e.note!.split('|');
        if (parts.length > 2) {
          final groupId = parts[1];
          final partFraction = parts[2].split('/');
          final partIndex = int.tryParse(partFraction[0]) ?? 1;
          if (partIndex == 1) {
            seenGroups.add(groupId);
            return true; // show only part 1
          }
          return false; // hide parts 2+
        }
      }
      return true; // non-split expenses always shown
    }).toList();
    final grouped = _groupByDay(list);
    final days = grouped.keys.toList()
      ..sort((a, b) => expenses.sortBy == 'dateAsc'
          ? a.compareTo(b)   // oldest first
          : b.compareTo(a)); // newest first (default)
    final totalFiltered = list.fold(0.0, (s, e) {
      if (e.note?.startsWith('SPLIT_PART|') == true) {
        final parts = e.note!.split('|');
        if (parts.length > 1) {
          return s + (splitGroupTotals[parts[1]] ?? e.amount);
        }
      }
      return s + e.amount;
    });

    final hasActiveFilter = _periodFilter != 'all' ||
        expenses.filterCategory != null ||
        expenses.searchQuery.isNotEmpty ||
        _walletFilter != null;

    // Search is excluded: it is visible in its own box, so flagging it on the
    // filter button would mark a filter the user can already see.
    final hasSheetFilter = _periodFilter != 'all' ||
        expenses.filterCategory != null ||
        _walletFilter != null;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: _isSelecting
          ? AppBar(
        backgroundColor:
        isDark ? const Color(0xFF1E1E1E) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _clearSelection,
        ),
        title: Text('${_selectedIds.length} selected',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => _selectAll(list),
            child: const Text('All'),
          ),
          IconButton(
            icon: const Icon(Icons.folder_rounded),
            tooltip: 'Move Category',
            onPressed: () => _moveCategorySelected(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () => _deleteSelected(context, expenses),
          ),
        ],
      )
          : AppBar(
        backgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        // Tips and Recurring sit together on the left: both explain or manage
        // the list rather than change what it shows. 96 is exactly the two
        // buttons; the rest is the inset that keeps Tips off the screen edge
        // plus a little air before the title.
        leadingWidth: 108,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => _showHints(context),
              tooltip: 'Tips',
            ),
            IconButton(
              icon: const Icon(Icons.repeat_rounded),
              onPressed: () => _showRecurringManager(context, expenses),
              tooltip: 'Manage Recurring',
            ),
          ],
        ),
        title: const Text('Expenses'),
        actions: [
          // ── Filter button ──────────────────────────────────────────
          // Next to More rather than in the bar below: sort stays inline
          // because it is changed constantly, while these are set and left.
          // The dot marks filters that are on but not visible from here.
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => _showSortFilter(context),
                tooltip: 'Filters',
              ),
              if (hasSheetFilter)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          // ── More button ────────────────────────────────────────────
          if (widget.onMoreTap != null)
            GestureDetector(
              onTap: widget.onMoreTap,
              child: Container(
                // Matches the Income tab, and keeps the pill clear of the edge.
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.more_horiz_rounded,
                    color: theme.colorScheme.primary, size: 20),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter bar ────────────────────────────────────────────────────
          ListFilterBar(
            searchController: _searchController,
            searchHint: 'Search expenses...',
            onSearchChanged: expenses.setSearch,
            sortBy: expenses.sortBy,
            onSortChanged: expenses.setSortBy,
            activeFilters: [
              // Period leads: it is the filter that changes the totals most, so
              // it should be the first thing read back from the sheet.
              if (_periodFilter != 'all')
                ActiveFilter(
                  label: periodChipLabel(_periodFilter, expenses.dateRange),
                  icon: Icons.calendar_today_rounded,
                  onRemove: () => _applyPeriod('all', null, expenses),
                ),
              if (expenses.filterCategory != null)
                () {
                  final cat = context
                      .read<CategoryProvider>()
                      .getById(expenses.filterCategory!);
                  return ActiveFilter(
                    label: cat?.name ?? 'Category',
                    icon: cat != null ? CategoryIcons.resolve(cat.icon) : null,
                    color: cat != null ? Color(cat.colorValue) : null,
                    onRemove: () => expenses.setFilterCategory(null),
                  );
                }(),
              if (_walletFilter != null)
                () {
                  final w =
                      context.read<WalletProvider>().getById(_walletFilter!);
                  return ActiveFilter(
                    label: w?.name ?? 'Wallet',
                    icon: w != null
                        ? WalletProvider.resolveIcon(w.type)
                        : Icons.account_balance_wallet_rounded,
                    color: w != null ? Color(w.colorValue) : null,
                    onRemove: () => setState(() => _walletFilter = null),
                  );
                }(),
            ],
          ),

          // ── Summary bar ───────────────────────────────────────────────────
          if (hasActiveFilter && list.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${list.length} expense${list.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'Total: ${AppUtils.formatAmount(totalFiltered, symbol)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          // ── Expense list ──────────────────────────────────────────────────
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No Expenses Found',
              subtitle:
              'Add your first expense using the + button below.',
            )
                : expenses.sortBy.startsWith('amount')
                ? ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final expense = list[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i == 0)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 8, top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.sort_rounded,
                                size: 14,
                                color:
                                theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              expenses.sortBy == 'amountDesc'
                                  ? 'Highest first'
                                  : 'Lowest first',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Stack(
                      children: [
                        GestureDetector(
                          onLongPress: _isSelecting ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(existing: expense))) : () => _toggleSelection(expense.id),
                          onTap: _isSelecting
                              ? () => _toggleSelection(expense.id)
                              : (expense.note?.startsWith('SPLIT_PART|') == true)
                              ? () => _showSplitDetail(context, expense)
                              : null,
                          child: ExpenseTile(
                            expense: expense,
                            symbol: symbol,
                            isSelecting: _isSelecting,
                            threshold: highThreshold,
                            walletFilter: _walletFilter,
                            selected: _selectedIds.contains(expense.id),
                          ),
                        ),
                        if (_selectedIds.contains(expense.id))
                          Positioned(
                            top: 12, left: 12,
                            child: Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary
                                  .withOpacity(0.08),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: i == 0
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: (i * 30).ms)
                    .slideX(begin: 0.08);
              },
            )
                : ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: days.length,
              itemBuilder: (ctx, i) {
                final day = days[i];
                final dayExpenses = grouped[day]!;
                final dayTotal = dayExpenses.fold(0.0, (s, e) {
                  if (e.note?.startsWith('SPLIT_PART|') == true) {
                    final parts = e.note!.split('|');
                    if (parts.length > 1) {
                      return s + (splitGroupTotals[parts[1]] ?? e.amount);
                    }
                  }
                  return s + e.amount;
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      // The first header needs no space above it — the top gap
                      // separates one day from the previous one, and there is
                      // no previous day at the top of the list.
                      padding: EdgeInsets.only(
                          top: i == 0 ? 0 : 16, bottom: 8),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDayHeader(day),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color:
                              theme.colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Text(
                              AppUtils.formatAmount(
                                  dayTotal, symbol),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (i * 40).ms),
                    ...dayExpenses.asMap().entries.map((entry) {
                      final expense = entry.value;
                      final isSelected = _selectedIds.contains(expense.id);
                      return GestureDetector(
                        onLongPress: _isSelecting ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(existing: expense))) : () => _toggleSelection(expense.id),
                        onTap: _isSelecting ? () => _toggleSelection(expense.id) : null,
                        child: Stack(
                          children: [
                            ExpenseTile(
                              expense: expense,
                              symbol: symbol,
                              isSelecting: _isSelecting,
                              threshold: highThreshold,
                              walletFilter: _walletFilter,
                              selected: isSelected,
                              // The day header above already carries the
                              // date, so the tile only needs the time.
                              showDate: false,
                            ),
                            if (isSelected)
                              Positioned(
                                top: 12, left: 12,
                                child: Container(
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                          delay: ((i * 40) +
                              (entry.key * 25))
                              .ms)
                          .slideX(begin: 0.08);
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Filter Sheet ──────────────────────────────────────────────────────────────

/// Everything that narrows the list except search and sort — period, wallet
/// and category.
///
/// Search and sort stay inline in [ListFilterBar]: they are the two that get
/// changed constantly. Period moved into the sheet because four chips on their
/// own row crowded the header for a filter that is set once and left alone.
class _FilterSheet extends StatefulWidget {
  final String? walletFilter;
  final ValueChanged<String?> onWalletChanged;
  final String periodFilter;
  final DateTimeRange? customRange;

  /// Reports the period and, for 'custom', the range the picker returned.
  final void Function(String period, DateTimeRange? range) onPeriodChanged;
  final VoidCallback onClearAll;

  const _FilterSheet({
    required this.walletFilter,
    required this.onWalletChanged,
    required this.periodFilter,
    required this.customRange,
    required this.onPeriodChanged,
    required this.onClearAll,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  // Edited locally and committed on Apply, so dismissing the sheet leaves the
  // list exactly as it was. Period is held here too: mixing an instant-apply
  // period with deferred wallet and category would make Apply mean two things.
  late String? _category;
  late String? _wallet;
  late String _period;
  late DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _category = context.read<ExpenseProvider>().filterCategory;
    _wallet = widget.walletFilter;
    _period = widget.periodFilter;
    _customRange = widget.customRange;
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _period = 'custom';
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.read<CategoryProvider>();
    final wallets = context.read<WalletProvider>().wallets;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Expenses',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () {
                    widget.onClearAll();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Period ───────────────────────────────────────────────────────
            Text('Period',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            PeriodSelector(
              periodFilter: _period,
              onPeriodChanged: (p) => setState(() => _period = p),
              onPickCustomRange: _pickCustomRange,
              customRangeLabel: _customRange == null
                  ? null
                  : '${AppUtils.formatShortDate(_customRange!.start)} – '
                      '${AppUtils.formatShortDate(_customRange!.end)}',
            ),
            const SizedBox(height: 20),

            // ── Payment Method ───────────────────────────────────────────────
            if (wallets.isNotEmpty) ...[
              Text('Payment Method',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // All chip
                  GestureDetector(
                    onTap: () => setState(() => _wallet = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _wallet == null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _wallet == null
                              ? Colors.white
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  ...wallets.map((wallet) {
                    final isSelected = _wallet == wallet.id;
                    final color = Color(wallet.colorValue);
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _wallet = wallet.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.15)
                              : theme.colorScheme.primary
                              .withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              WalletProvider.resolveIcon(wallet.type),
                              size: 15,
                              color: isSelected
                                  ? color
                                  : theme.colorScheme.onSurface
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              wallet.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? color
                                    : theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ── Category ─────────────────────────────────────────────────────
            Text('Category',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _category = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _category == null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _category == null
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                ...categories.categories.map((cat) {
                  final isSelected = _category == cat.id;
                  final catColor = Color(cat.colorValue);
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _category = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? catColor.withOpacity(0.15)
                            : theme.colorScheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? catColor
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CategoryIcons.resolve(cat.icon),
                            size: 14,
                            color: isSelected
                                ? catColor
                                : theme.colorScheme.onSurface
                                .withOpacity(0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? catColor
                                  : theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context
                      .read<ExpenseProvider>()
                      .setFilterCategory(_category);
                  widget.onWalletChanged(_wallet);
                  widget.onPeriodChanged(_period, _customRange);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}