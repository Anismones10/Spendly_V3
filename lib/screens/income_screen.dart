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

    final monthlyIncome = income.getTotalForMonth(now.year, now.month);
    final monthlyExpenses = expenses.getTotalForMonth(now.year, now.month);
    final balance = monthlyIncome - monthlyExpenses;
    final monthIncomeList = income.getIncomeForMonth(now.year, now.month);

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
                  onPressed: () => _selectAll(monthIncomeList),
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
      body: monthIncomeList.isEmpty
          ? Column(
              children: [
                _buildSummaryCard(
                    context, symbol, monthlyIncome, monthlyExpenses, balance, isDark, theme),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'No Income Yet',
                    subtitle:
                        'Add your first income source using the + button below.',
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Summary card
                _buildSummaryCard(
                    context, symbol, monthlyIncome, monthlyExpenses, balance, isDark, theme),
                const SizedBox(height: 20),

                // Month label
                Text(
                  AppUtils.formatMonthYear(now),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Income tiles
                ...monthIncomeList.asMap().entries.map(
                      (e) {
                        final isSelected = _selectedIds.contains(e.value.id);
                        return GestureDetector(
                          onLongPress: () => _toggleSelection(e.value.id),
                          onTap: _isSelecting ? () => _toggleSelection(e.value.id) : null,
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(color: const Color(0xFF2ECC71), width: 2)
                                      : null,
                                  color: isSelected
                                      ? const Color(0xFF2ECC71).withOpacity(0.07)
                                      : Colors.transparent,
                                ),
                                child: _IncomeTile(income: e.value, symbol: symbol),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 12, left: 12,
                                  child: Container(
                                    width: 22, height: 22,
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

  const _IncomeTile({required this.income, required this.symbol});

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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddIncomeScreen(existing: income)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
