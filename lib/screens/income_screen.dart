import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/income_model.dart';
import '../providers/income_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/list_filter_bar.dart';
import 'add_income_screen.dart';

class IncomeScreen extends StatefulWidget {
  final VoidCallback? onMoreTap;
  const IncomeScreen({super.key, this.onMoreTap});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  final _searchController = TextEditingController();

  // Defaults to the current month because that is what this screen showed
  // before it had filters at all.
  String _periodFilter = 'month';
  String? _walletFilter;

  @override
  void initState() {
    super.initState();
    // The provider keeps filter state, so seed it to match the default chip.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<IncomeProvider>()
          .setDateRange(rangeForPeriod(_periodFilter, DateTime.now()));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Commits a period chosen in the filter sheet.
  ///
  /// A custom period arrives with the range the picker returned; the fixed ones
  /// derive theirs from the key, so the sheet never has to know the dates.
  void _applyPeriod(String period, DateTimeRange? range, IncomeProvider income) {
    setState(() => _periodFilter = period);
    income.setDateRange(
        period == 'custom' ? range : rangeForPeriod(period, DateTime.now()));
  }

  List<IncomeModel> _applyWalletFilter(List<IncomeModel> list) {
    if (_walletFilter == null) return list;
    return list.where((e) => e.walletId == _walletFilter).toList();
  }

  void _showSortFilter(BuildContext context) {
    final income = context.read<IncomeProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomeFilterSheet(
        walletFilter: _walletFilter,
        onWalletChanged: (id) => setState(() => _walletFilter = id),
        periodFilter: _periodFilter,
        customRange: _periodFilter == 'custom' ? income.dateRange : null,
        onPeriodChanged: (p, r) => _applyPeriod(p, r, income),
        onClearAll: () {
          income.clearFilters();
          _searchController.clear();
          setState(() {
            _periodFilter = 'all';
            _walletFilter = null;
          });
        },
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  void _selectAll(List<IncomeModel> all) {
    setState(() => _selectedIds.addAll(all.map((e) => e.id)));
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Selected'),
        content: Text('Delete $count income entr${count == 1 ? 'y' : 'ies'}?'),
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
      final provider = context.read<IncomeProvider>();
      for (final id in _selectedIds.toList()) provider.deleteIncome(id);
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final income = context.watch<IncomeProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    // The summary card always reports the current month, whatever the list is
    // filtered to — it is a month-to-date figure, not a view of the list.
    final monthlyIncome = income.getTotalForMonth(now.year, now.month);
    final monthlyExpenses = expenses.getTotalForMonth(now.year, now.month);
    final balance = monthlyIncome - monthlyExpenses;

    final incomeList = _applyWalletFilter(income.filteredIncome);
    final listTotal = incomeList.fold(0.0, (s, e) => s + e.amount);
    final hasActiveFilter = income.filterSource != null || _walletFilter != null;
    final isNarrowed = hasActiveFilter ||
        _periodFilter != 'all' ||
        income.searchQuery.isNotEmpty;

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
                  // Selects what is on screen, not every entry ever recorded.
                  onPressed: () => _selectAll(incomeList),
                  child: const Text('All'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _deleteSelected(context),
                ),
              ],
            )
          : AppBar(
              backgroundColor:
                  isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
              title: const Text('Income'),
              actions: [
                // ── Filter button ──────────────────────────────────────────
                // Beside More, matching the Expenses tab. The dot marks
                // filters that are on but not visible from here.
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune_rounded),
                      onPressed: () => _showSortFilter(context),
                      tooltip: 'Filters',
                    ),
                    if (hasActiveFilter || _periodFilter != 'all')
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
                if (widget.onMoreTap != null)
                  GestureDetector(
                    onTap: widget.onMoreTap,
                    child: Container(
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
            searchHint: 'Search income...',
            onSearchChanged: income.setSearch,
            sortBy: income.sortBy,
            onSortChanged: income.setSortBy,
            activeFilters: [
              // Period leads: it is the filter that changes the totals most, so
              // it should be the first thing read back from the sheet.
              if (_periodFilter != 'all')
                ActiveFilter(
                  label: periodChipLabel(_periodFilter, income.dateRange),
                  icon: Icons.calendar_today_rounded,
                  onRemove: () => _applyPeriod('all', null, income),
                ),
              if (income.filterSource != null)
                ActiveFilter(
                  // Sources are stored as keys, so show the readable label.
                  label: incomeSourceLabel(income.filterSource!),
                  icon: incomeSourceIcon(income.filterSource!),
                  color: incomeSourceColor(income.filterSource!),
                  onRemove: () => income.setFilterSource(null),
                ),
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
          const SizedBox(height: 8),

          Expanded(
            child: incomeList.isEmpty
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSummaryCard(context, symbol, monthlyIncome,
                            monthlyExpenses, balance, isDark, theme),
                      ),
                      Expanded(
                        child: EmptyState(
                          icon: Icons.account_balance_wallet_rounded,
                          title: isNarrowed
                              ? 'No Income Found'
                              : 'No Income Yet',
                          subtitle: isNarrowed
                              ? 'Nothing matches the current filters.'
                              : 'Add your first income source using the + '
                                  'button below.',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    children: [
                      // Summary card
                      _buildSummaryCard(context, symbol, monthlyIncome,
                          monthlyExpenses, balance, isDark, theme),
                      const SizedBox(height: 16),

                      // What the list is currently showing. Replaces the old
                      // month heading, which lied once a filter was applied.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${incomeList.length} '
                              'entr${incomeList.length == 1 ? 'y' : 'ies'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            Text(
                              'Total: ${AppUtils.formatAmount(listTotal, symbol)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2ECC71),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Income tiles
                      ...incomeList.asMap().entries.map(
                        (e) {
                          final isSelected =
                              _selectedIds.contains(e.value.id);
                          return GestureDetector(
                            onLongPress: _isSelecting
                                ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AddIncomeScreen(
                                            existing: e.value)))
                                : () => _toggleSelection(e.value.id),
                            onTap: _isSelecting
                                ? () => _toggleSelection(e.value.id)
                                : null,
                            child: Stack(
                              children: [
                                _IncomeTile(
                                    income: e.value,
                                    symbol: symbol,
                                    isSelecting: _isSelecting,
                                    selected: isSelected),
                                if (isSelected)
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2ECC71),
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
                              .fadeIn(delay: (e.key * 50).ms)
                              .slideX(begin: 0.08);
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
        ),
        backgroundColor: const Color(0xFF2ECC71),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Income',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String symbol,
    double income,
    double expenses,
    double balance,
    bool isDark,
    ThemeData theme,
  ) {
    final isPositive = balance >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
              : [const Color(0xFFE57373), const Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPositive
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFE57373))
                .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Names the month explicitly. The list below can be filtered to any
          // range, so without this the card looks like it belongs to whatever
          // the list is showing.
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 6),
              Text(
                AppUtils.formatMonthYear(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Income vs Expenses row
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Income',
                  value: AppUtils.formatAmount(income, symbol),
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Expenses',
                  value: AppUtils.formatAmount(expenses, symbol),
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),

          // Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : ''}${AppUtils.formatAmount(balance, symbol)} balance',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPositive
                ? 'Great! You\'re saving money this month'
                : 'Spending more than you earn this month',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

// ── Summary Item ──────────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Income Tile ───────────────────────────────────────────────────────────────

class _IncomeTile extends StatelessWidget {
  final IncomeModel income;
  final String symbol;
  final bool isSelecting;
  // Drawn by the card itself rather than by a wrapper, so the highlight lines
  // up with the card instead of also covering its bottom margin.
  final bool selected;

  const _IncomeTile({
    required this.income,
    required this.symbol,
    this.isSelecting = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = incomeSourceColor(income.source);
    final icon = incomeSourceIcon(income.source);
    final label = incomeSourceLabel(income.source);

    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Income',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content: Text('Delete "${income.name}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          context.read<IncomeProvider>().deleteIncome(income.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: isSelecting ? null : () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddIncomeScreen(existing: income)),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    const Color(0xFF2ECC71).withOpacity(0.07),
                    isDark ? const Color(0xFF1E1E1E) : Colors.white)
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(color: const Color(0xFF2ECC71), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      income.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppUtils.formatDate(income.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.4),
                          ),
                        ),
                        if (income.walletId != null) ...[
                          const SizedBox(width: 6),
                          Builder(builder: (ctx) {
                            final walletProvider = ctx.watch<WalletProvider>();
                            final w = walletProvider.getById(income.walletId!);
                            if (w == null) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Color(w.colorValue).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    WalletProvider.resolveIcon(w.type),
                                    size: 9,
                                    color: Color(w.colorValue),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    w.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(w.colorValue),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                    if (income.note != null && income.note!.isNotEmpty)
                      Text(
                        income.note!,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                '+${AppUtils.formatAmount(income.amount, symbol)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Income counterpart to the Expenses filter sheet.
///
/// Holds period, source and wallet. Search and sort stay in [ListFilterBar]
/// because those get changed far more often than these.
class _IncomeFilterSheet extends StatefulWidget {
  final String? walletFilter;
  final ValueChanged<String?> onWalletChanged;
  final String periodFilter;
  final DateTimeRange? customRange;

  /// Reports the period and, for 'custom', the range the picker returned.
  final void Function(String period, DateTimeRange? range) onPeriodChanged;
  final VoidCallback onClearAll;

  const _IncomeFilterSheet({
    required this.walletFilter,
    required this.onWalletChanged,
    required this.periodFilter,
    required this.customRange,
    required this.onPeriodChanged,
    required this.onClearAll,
  });

  @override
  State<_IncomeFilterSheet> createState() => _IncomeFilterSheetState();
}

class _IncomeFilterSheetState extends State<_IncomeFilterSheet> {
  // Edited locally and committed on Apply, so backing out of the sheet leaves
  // the list exactly as it was. Period is held here too: mixing an instant-apply
  // period with a deferred source and wallet would make Apply mean two things.
  late String? _source;
  late String? _wallet;
  late String _period;
  late DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _source = context.read<IncomeProvider>().filterSource;
    _wallet = widget.walletFilter;
    _period = widget.periodFilter;
    _customRange = widget.customRange;
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      // Income can be dated ahead, so the picker has to allow it.
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wallets = context.read<WalletProvider>().wallets;

    // Only the sources actually in use — offering the full list would mean
    // chips that can only ever return nothing.
    final sources = context.read<IncomeProvider>().allSources;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                Text('Filter Income',
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

            // ── Wallet ───────────────────────────────────────────────────────
            if (wallets.isNotEmpty) ...[
              Text('Wallet',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SheetChip(
                    label: 'All',
                    selected: _wallet == null,
                    onTap: () => setState(() => _wallet = null),
                  ),
                  ...wallets.map((wallet) => _SheetChip(
                        label: wallet.name,
                        icon: WalletProvider.resolveIcon(wallet.type),
                        accent: Color(wallet.colorValue),
                        selected: _wallet == wallet.id,
                        onTap: () => setState(() => _wallet = wallet.id),
                      )),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ── Source ───────────────────────────────────────────────────────
            if (sources.isNotEmpty) ...[
              Text('Source',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SheetChip(
                    label: 'All',
                    selected: _source == null,
                    onTap: () => setState(() => _source = null),
                  ),
                  ...sources.map((key) => _SheetChip(
                        label: incomeSourceLabel(key),
                        icon: incomeSourceIcon(key),
                        accent: incomeSourceColor(key),
                        selected: _source == key,
                        onTap: () => setState(() => _source = key),
                      )),
                ],
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<IncomeProvider>().setFilterSource(_source);
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

/// A selectable chip inside [_IncomeFilterSheet].
///
/// Matches the Expenses sheet: plain primary fill for the "All" chip, and a
/// tinted outline in the item's own colour for everything else.
class _SheetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// The item's own colour. Null falls back to the theme, which is what the
  /// "All" chip uses.
  final Color? accent;

  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (accent == null) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? primary : primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : primary,
            ),
          ),
        ),
      );
    }

    final color = accent!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.15)
              : primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected
                      ? color
                      : theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
