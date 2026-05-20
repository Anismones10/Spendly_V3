import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/loan_model.dart';
import '../models/goal_model.dart';
import '../models/wallet_model.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';
import '../screens/add_expense_screen.dart';
import '../screens/add_income_screen.dart';

// ── Result types ──────────────────────────────────────────────────────────────

enum SearchResultType { expense, income, loan, goal, wallet }

class SearchResult {
  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final String? amount;
  final String? badge;
  final Color color;
  final IconData icon;
  final dynamic raw; // original model

  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    this.amount,
    this.badge,
    required this.color,
    required this.icon,
    required this.raw,
  });
}

// ── Main screen ───────────────────────────────────────────────────────────────

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  // Filter toggles
  bool _showExpenses = true;
  bool _showIncome = true;
  bool _showLoans = true;
  bool _showGoals = true;
  bool _showWallets = true;

  @override
  void initState() {
    super.initState();
    // Auto-focus on open
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
    _controller.addListener(() {
      setState(() => _query = _controller.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Build result list from all providers ──────────────────────────────────

  List<SearchResult> _buildResults(BuildContext context) {
    if (_query.isEmpty) return [];

    final symbol =
        context.read<SettingsProvider>().currencySymbol;
    final categories = context.read<CategoryProvider>();
    final results = <SearchResult>[];

    // ── Expenses ────────────────────────────────────────────────────────────
    if (_showExpenses) {
      final expenses = context.read<ExpenseProvider>().allExpenses;
      for (final e in expenses) {
        final cat = categories.getById(e.categoryId);
        final catName = cat?.name ?? '';
        if (_matches([e.name, catName, e.note ?? ''])) {
          results.add(SearchResult(
            type: SearchResultType.expense,
            id: e.id,
            title: e.name,
            subtitle:
                '$catName  ·  ${AppUtils.formatDate(e.date)}${e.formattedTime.isNotEmpty ? '  ·  ${e.formattedTime}' : ''}',
            amount:
                '-${AppUtils.formatAmount(e.amount, symbol)}',
            badge: e.isRecurring
                ? e.recurringType
                : e.recurringParentId != null
                    ? 'auto'
                    : null,
            color: cat != null
                ? Color(cat.colorValue)
                : const Color(0xFFE57373),
            icon: CategoryIcons.resolve(cat?.icon ?? ''),
            raw: e,
          ));
        }
      }
    }

    // ── Income ──────────────────────────────────────────────────────────────
    if (_showIncome) {
      final incomes =
          context.read<IncomeProvider>().allIncome;
      for (final i in incomes) {
        if (_matches([i.name, i.source, i.note ?? ''])) {
          results.add(SearchResult(
            type: SearchResultType.income,
            id: i.id,
            title: i.name,
            subtitle:
                '${i.source}  ·  ${AppUtils.formatDate(i.date)}${i.formattedTime.isNotEmpty ? '  ·  ${i.formattedTime}' : ''}',
            amount:
                '+${AppUtils.formatAmount(i.amount, symbol)}',
            badge: null,
            color: const Color(0xFF2ECC71),
            icon: Icons.account_balance_wallet_rounded,
            raw: i,
          ));
        }
      }
    }

    // ── Loans ────────────────────────────────────────────────────────────────
    if (_showLoans) {
      final loans = context.read<LoanProvider>().allLoans;
      for (final l in loans) {
        if (_matches([l.personName, l.type, l.note ?? ''])) {
          results.add(SearchResult(
            type: SearchResultType.loan,
            id: l.id,
            title: l.personName,
            subtitle:
                '${l.type == 'lending' ? 'Lent out' : 'Borrowed'}  ·  ${AppUtils.formatDate(l.date)}  ·  ${l.status}',
            amount: AppUtils.formatAmount(l.remaining, symbol),
            badge: l.isOverdue ? 'overdue' : null,
            color: l.type == 'lending'
                ? const Color(0xFF2ECC71)
                : const Color(0xFFE57373),
            icon: Icons.handshake_rounded,
            raw: l,
          ));
        }
      }
    }

    // ── Goals ────────────────────────────────────────────────────────────────
    if (_showGoals) {
      final goals = context.read<GoalProvider>().goals;
      for (final g in goals) {
        if (_matches([g.name])) {
          results.add(SearchResult(
            type: SearchResultType.goal,
            id: g.id,
            title: g.name,
            subtitle:
                '${(g.progress * 100).round()}% complete  ·  ${AppUtils.formatAmount(g.savedAmount, symbol)} saved',
            amount: AppUtils.formatAmount(g.targetAmount, symbol),
            badge: g.isCompleted ? 'done' : null,
            color: const Color(0xFF4A90E2),
            icon: Icons.flag_rounded,
            raw: g,
          ));
        }
      }
    }

    // ── Wallets ──────────────────────────────────────────────────────────────
    if (_showWallets) {
      final wallets =
          context.read<WalletProvider>().wallets;
      for (final w in wallets) {
        if (_matches([w.name, w.type])) {
          results.add(SearchResult(
            type: SearchResultType.wallet,
            id: w.id,
            title: w.name,
            subtitle:
                '${w.type.toUpperCase()}  ·  Balance: ${AppUtils.formatAmount(w.balance, symbol)}',
            amount: AppUtils.formatAmount(w.balance, symbol),
            badge: null,
            color: Color(w.colorValue),
            icon: WalletProvider.resolveIcon(w.type),
            raw: w,
          ));
        }
      }
    }

    // Sort: expenses/income by date desc, others by title
    results.sort((a, b) {
      DateTime? dateA = _dateOf(a);
      DateTime? dateB = _dateOf(b);
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      }
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      return a.title.compareTo(b.title);
    });

    return results;
  }

  DateTime? _dateOf(SearchResult r) {
    if (r.raw is ExpenseModel) return (r.raw as ExpenseModel).date;
    if (r.raw is IncomeModel) return (r.raw as IncomeModel).date;
    if (r.raw is LoanModel) return (r.raw as LoanModel).date;
    return null;
  }

  bool _matches(List<String> fields) {
    return fields.any(
        (f) => f.toLowerCase().contains(_query));
  }

  // ── Tap handler ───────────────────────────────────────────────────────────

  void _onTap(SearchResult result) {
    switch (result.type) {
      case SearchResultType.expense:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddExpenseScreen(existing: result.raw as ExpenseModel),
          ),
        );
        break;
      case SearchResultType.income:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddIncomeScreen(existing: result.raw as IncomeModel),
          ),
        );
        break;
      case SearchResultType.loan:
      case SearchResultType.goal:
      case SearchResultType.wallet:
        // Show a detail bottom sheet for these
        _showDetailSheet(result);
        break;
    }
  }

  void _showDetailSheet(SearchResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final symbol =
        context.read<SettingsProvider>().currencySymbol;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
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

            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: result.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(result.icon,
                      color: result.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18)),
                      Text(result.subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5))),
                    ],
                  ),
                ),
                if (result.amount != null)
                  Text(result.amount!,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: result.color)),
              ],
            ),

            const SizedBox(height: 20),

            // Type-specific detail rows
            if (result.type == SearchResultType.loan)
              _LoanDetail(loan: result.raw as LoanModel, symbol: symbol),
            if (result.type == SearchResultType.goal)
              _GoalDetail(goal: result.raw as GoalModel, symbol: symbol),
            if (result.type == SearchResultType.wallet)
              _WalletDetail(wallet: result.raw as WalletModel, symbol: symbol),
          ],
        ),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final results = _buildResults(context);

    // Group results by type
    final grouped = <SearchResultType, List<SearchResult>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search expenses, income, loans...',
            hintStyle: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.4)),
            border: InputBorder.none,
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _controller.clear();
                      _focusNode.requestFocus();
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
        ),
      ),

      body: Column(
        children: [
          // ── Filter chips ──────────────────────────────────────────────
          _FilterBar(
            showExpenses: _showExpenses,
            showIncome: _showIncome,
            showLoans: _showLoans,
            showGoals: _showGoals,
            showWallets: _showWallets,
            onToggle: (type) {
              setState(() {
                switch (type) {
                  case SearchResultType.expense:
                    _showExpenses = !_showExpenses;
                    break;
                  case SearchResultType.income:
                    _showIncome = !_showIncome;
                    break;
                  case SearchResultType.loan:
                    _showLoans = !_showLoans;
                    break;
                  case SearchResultType.goal:
                    _showGoals = !_showGoals;
                    break;
                  case SearchResultType.wallet:
                    _showWallets = !_showWallets;
                    break;
                }
              });
            },
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: _query.isEmpty
                ? _EmptyQuery()
                : results.isEmpty
                    ? _NoResults(query: _query)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            16, 8, 16, 32),
                        children: [
                          // Summary chip
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${results.length} result${results.length == 1 ? '' : 's'} for "$_query"',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Grouped sections
                          ...grouped.entries.map((entry) {
                            final typeLabel =
                                _typeLabel(entry.key);
                            final typeColor =
                                _typeColor(entry.key, theme);
                            final typeIcon =
                                _typeIcon(entry.key);

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Section header
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8, bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: typeColor
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                        ),
                                        child: Icon(typeIcon,
                                            size: 14,
                                            color: typeColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        typeLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: typeColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: typeColor
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10),
                                        ),
                                        child: Text(
                                          '${entry.value.length}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: typeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Result tiles
                                ...entry.value
                                    .asMap()
                                    .entries
                                    .map((e) {
                                  return _ResultTile(
                                    result: e.value,
                                    query: _query,
                                    onTap: () =>
                                        _onTap(e.value),
                                    isDark: isDark,
                                    theme: theme,
                                  )
                                      .animate()
                                      .fadeIn(
                                          delay: (e.key * 30).ms,
                                          duration: 250.ms)
                                      .slideX(begin: 0.06);
                                }),

                                const SizedBox(height: 8),
                              ],
                            );
                          }),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(SearchResultType t) {
    switch (t) {
      case SearchResultType.expense:
        return 'Expenses';
      case SearchResultType.income:
        return 'Income';
      case SearchResultType.loan:
        return 'Loans';
      case SearchResultType.goal:
        return 'Goals';
      case SearchResultType.wallet:
        return 'Wallets';
    }
  }

  Color _typeColor(SearchResultType t, ThemeData theme) {
    switch (t) {
      case SearchResultType.expense:
        return const Color(0xFFE57373);
      case SearchResultType.income:
        return const Color(0xFF2ECC71);
      case SearchResultType.loan:
        return const Color(0xFF4A90E2);
      case SearchResultType.goal:
        return const Color(0xFFFF9800);
      case SearchResultType.wallet:
        return theme.colorScheme.primary;
    }
  }

  IconData _typeIcon(SearchResultType t) {
    switch (t) {
      case SearchResultType.expense:
        return Icons.receipt_long_rounded;
      case SearchResultType.income:
        return Icons.account_balance_wallet_rounded;
      case SearchResultType.loan:
        return Icons.handshake_rounded;
      case SearchResultType.goal:
        return Icons.flag_rounded;
      case SearchResultType.wallet:
        return Icons.wallet_rounded;
    }
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final bool showExpenses;
  final bool showIncome;
  final bool showLoans;
  final bool showGoals;
  final bool showWallets;
  final ValueChanged<SearchResultType> onToggle;

  const _FilterBar({
    required this.showExpenses,
    required this.showIncome,
    required this.showLoans,
    required this.showGoals,
    required this.showWallets,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = [
      (SearchResultType.expense, 'Expenses',
          Icons.receipt_long_rounded, showExpenses),
      (SearchResultType.income, 'Income',
          Icons.account_balance_wallet_rounded, showIncome),
      (SearchResultType.loan, 'Loans',
          Icons.handshake_rounded, showLoans),
      (SearchResultType.goal, 'Goals',
          Icons.flag_rounded, showGoals),
      (SearchResultType.wallet, 'Wallets',
          Icons.wallet_rounded, showWallets),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (type, label, icon, active) = chips[i];
          return GestureDetector(
            onTap: () => onToggle(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: active
                          ? Colors.white
                          : theme.colorScheme.primary
                              .withOpacity(0.6)),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Result tile ───────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  final String query;
  final VoidCallback onTap;
  final bool isDark;
  final ThemeData theme;

  const _ResultTile({
    required this.result,
    required this.query,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: result.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(result.icon, color: result.color, size: 20),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Highlighted title
                  _HighlightedText(
                    text: result.title,
                    query: query,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    highlightColor: result.color,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.45)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _badgeColor(result.badge!)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        result.badge!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _badgeColor(result.badge!),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Amount + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (result.amount != null)
                  Text(
                    result.amount!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: result.type == SearchResultType.income
                          ? const Color(0xFF2ECC71)
                          : result.type == SearchResultType.expense
                              ? theme.colorScheme.onSurface
                              : result.color,
                    ),
                  ),
                const SizedBox(height: 2),
                Icon(Icons.chevron_right_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface
                        .withOpacity(0.25)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case 'overdue':
        return const Color(0xFFE57373);
      case 'done':
        return const Color(0xFF2ECC71);
      case 'auto':
        return const Color(0xFF4A90E2);
      default:
        return const Color(0xFFFF9800);
    }
  }
}

// ── Highlighted text ──────────────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final Color highlightColor;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());

    if (idx == -1) return Text(text, style: style);

    return Text.rich(
      TextSpan(
        children: [
          if (idx > 0)
            TextSpan(
                text: text.substring(0, idx),
                style: style),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: style.copyWith(
              color: highlightColor,
              backgroundColor: highlightColor.withOpacity(0.12),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(
                text: text.substring(idx + query.length),
                style: style),
        ],
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyQuery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tips = [
      (Icons.receipt_long_rounded, 'Expenses',
          'Search by name, category, or note'),
      (Icons.account_balance_wallet_rounded, 'Income',
          'Search by name or source'),
      (Icons.handshake_rounded, 'Loans',
          'Search by person name'),
      (Icons.flag_rounded, 'Goals', 'Search by goal name'),
      (Icons.wallet_rounded, 'Wallets',
          'Search by wallet name or type'),
    ];

    return ListView(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_rounded,
                    size: 34,
                    color: theme.colorScheme.primary
                        .withOpacity(0.5)),
              ),
              const SizedBox(height: 14),
              Text(
                'Search everything',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type to search across all your data',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'WHAT YOU CAN SEARCH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...tips.map((tip) {
          final (icon, label, desc) = tip;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: theme.colorScheme.primary
                        .withOpacity(0.6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(desc,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.45))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different spelling or check your filters above.',
              style: TextStyle(
                  fontSize: 13,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.45),
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail sheets ─────────────────────────────────────────────────────────────

class _LoanDetail extends StatelessWidget {
  final LoanModel loan;
  final String symbol;
  const _LoanDetail({required this.loan, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _Row('Type',
            loan.type == 'lending' ? 'Lent out' : 'Borrowed',
            theme),
        _Row('Total amount',
            AppUtils.formatAmount(loan.amount, symbol), theme),
        _Row('Paid',
            AppUtils.formatAmount(loan.paidAmount, symbol), theme),
        _Row('Remaining',
            AppUtils.formatAmount(loan.remaining, symbol), theme),
        _Row('Status', loan.status.toUpperCase(), theme),
        if (loan.dueDate != null)
          _Row('Due date', AppUtils.formatDate(loan.dueDate!), theme),
        if (loan.note != null && loan.note!.isNotEmpty)
          _Row('Note', loan.note!, theme),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: loan.progress,
            minHeight: 8,
            backgroundColor: const Color(0xFF4A90E2).withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4A90E2)),
          ),
        ),
        const SizedBox(height: 6),
        Text('${(loan.progress * 100).round()}% repaid',
            style: TextStyle(
                fontSize: 11,
                color:
                    theme.colorScheme.onSurface.withOpacity(0.4))),
      ],
    );
  }
}

class _GoalDetail extends StatelessWidget {
  final GoalModel goal;
  final String symbol;
  const _GoalDetail({required this.goal, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _Row('Target',
            AppUtils.formatAmount(goal.targetAmount, symbol),
            theme),
        _Row('Saved',
            AppUtils.formatAmount(goal.savedAmount, symbol), theme),
        _Row('Remaining',
            AppUtils.formatAmount(goal.remaining, symbol), theme),
        if (goal.deadline != null)
          _Row(
              'Deadline', AppUtils.formatDate(goal.deadline!), theme),
        _Row('Status', goal.isCompleted ? 'Completed ✓' : 'In progress',
            theme),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: goal.progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor:
                const Color(0xFFFF9800).withOpacity(0.12),
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFFFF9800)),
          ),
        ),
        const SizedBox(height: 6),
        Text('${(goal.progress * 100).round()}% complete',
            style: TextStyle(
                fontSize: 11,
                color:
                    theme.colorScheme.onSurface.withOpacity(0.4))),
      ],
    );
  }
}

class _WalletDetail extends StatelessWidget {
  final WalletModel wallet;
  final String symbol;
  const _WalletDetail(
      {required this.wallet, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _Row('Type', wallet.type.toUpperCase(), theme),
        _Row('Balance',
            AppUtils.formatAmount(wallet.balance, symbol), theme),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  const _Row(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.5))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
