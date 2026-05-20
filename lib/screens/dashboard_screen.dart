import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/income_provider.dart';
import '../providers/category_provider.dart';
import '../providers/category_budget_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet_model.dart';
import 'income_screen.dart';
import 'global_search_screen.dart';
import '../widgets/insight_card.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/streak_badge.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';
import '../utils/coach_mark_helper.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onMoreTap;
  const DashboardScreen({super.key, this.onMoreTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _cardController = PageController();
  int _currentCard = 0;
  bool _hideBalance = false;

  final GlobalKey _walletCardKey = GlobalKey();
  final GlobalKey _moreButtonKey = GlobalKey();
  final GlobalKey _quickStatsKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _hideBalance =
        box.get('hideBalance', defaultValue: false) as bool;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoachMarkHelper.showDashboard(
        context,
        walletCardKey: _walletCardKey,
        moreButtonKey: _moreButtonKey,
        quickStatsKey: _quickStatsKey,
        fabKey: _fabKey,
      );
    });
  }

  void _toggleHideBalance() {
    final newValue = !_hideBalance;
    setState(() => _hideBalance = newValue);
    Hive.box('settings').put('hideBalance', newValue);
  }

  void _openSearch() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GlobalSearchScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenses = context.watch<ExpenseProvider>();
    final SettingsProvider settings =
        context.watch<SettingsProvider>();
    final income = context.watch<IncomeProvider>();
    final loans = context.watch<LoanProvider>();
    final wallets = context.watch<WalletProvider>();

    final monthlyIncome =
        income.getTotalForMonth(now.year, now.month);
    final totalSpent =
        expenses.getTotalForMonth(now.year, now.month);
    final double budget = settings.monthlyBudget;
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allExpenses = expenses.allExpenses;
    final netLoan =
        loans.totalBorrowing - loans.totalLending;
    final totalAllSpent =
        expenses.getTotalForMonth(now.year, now.month);

    double spentForWallet(String walletId) {
      final filtered =
          allExpenses.where((e) => e.walletId == walletId);
      if (filtered.isEmpty) return 0;
      return filtered.fold(0.0, (sum, e) => sum + e.amount);
    }

    final allCards = <_CardData>[
      _CardData(
        title: 'All Wallets',
        totalBalance: wallets.totalBalance,
        spent: totalAllSpent,
        borrowed: loans.totalBorrowing,
        lentOut: loans.totalLending,
        netLoan: netLoan,
        isAllWallets: true,
      ),
      ...wallets.wallets.map((w) => _CardData(
            title: w.name,
            totalBalance: w.balance,
            spent: spentForWallet(w.id),
            borrowed: 0,
            lentOut: 0,
            netLoan: 0,
            isAllWallets: false,
            walletType: w.type,
            colorValue: w.colorValue,
          )),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 60,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF121212)
                : const Color(0xFFF5F7FA),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 12),
              title: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                ).createShader(bounds),
                child: Text(
                  'Spendly',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: theme.colorScheme.primary
                            .withOpacity(0.6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // 1 ── Date chip
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary
                          .withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  _todayDate(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              // 2 ── Search icon
              GestureDetector(
                onTap: _openSearch,
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),

              // 3 ── More button (same size as search icon)
              if (widget.onMoreTap != null)
                GestureDetector(
                  onTap: widget.onMoreTap,
                  child: Container(
                    key: _moreButtonKey,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              StreakBadge(streak: settings.streak),
              const SizedBox(width: 12),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Swipeable Wallet Cards ────────────────────────────
                SizedBox(
                  key: _walletCardKey,
                  height: 310,
                  child: PageView.builder(
                    controller: _cardController,
                    itemCount: allCards.length,
                    onPageChanged: (i) =>
                        setState(() => _currentCard = i),
                    itemBuilder: (ctx, i) {
                      final card = allCards[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: _WalletCard(
                          card: card,
                          symbol: symbol,
                          hideBalance: _hideBalance,
                          onToggleHide: _toggleHideBalance,
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

                // ── Dots + arrows ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_currentCard > 0) {
                                _cardController.previousPage(
                                    duration: const Duration(
                                        milliseconds: 300),
                                    curve: Curves.easeInOut);
                              }
                            },
                            child: Icon(
                                Icons.chevron_left_rounded,
                                size: 22,
                                color: _currentCard > 0
                                    ? theme.colorScheme.onSurface
                                        .withOpacity(0.5)
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.15)),
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(allCards.length, (i) {
                            final isSelected = i == _currentCard;
                            return AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              width: isSelected ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (_currentCard <
                                  allCards.length - 1) {
                                _cardController.nextPage(
                                    duration: const Duration(
                                        milliseconds: 300),
                                    curve: Curves.easeInOut);
                              }
                            },
                            child: Icon(
                                Icons.chevron_right_rounded,
                                size: 22,
                                color:
                                    _currentCard < allCards.length - 1
                                        ? theme.colorScheme.onSurface
                                            .withOpacity(0.5)
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.15)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Swipe to see wallets',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Quick Stats Row ───────────────────────────────────
                Padding(
                  key: _quickStatsKey,
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickStatCard(
                          label: 'Today',
                          value: AppUtils.formatAmount(
                              expenses.getTotalForDay(now),
                              symbol),
                          icon: Icons.today_rounded,
                          color: const Color(0xFF6C63FF),
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickStatCard(
                          label: 'This Week',
                          value: AppUtils.formatAmount(
                              expenses.getTotalForWeek(), symbol),
                          icon: Icons.date_range_rounded,
                          color: const Color(0xFF03DAC6),
                        ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickStatCard(
                          label: 'Income',
                          value: AppUtils.formatAmount(
                              monthlyIncome, symbol),
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF2ECC71),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const IncomeScreen()),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Daily Summary ─────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF)
                              .withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const DailySummaryCard(),
                  ).animate().fadeIn(delay: 450.ms),
                ),

                const SizedBox(height: 16),

                // ── Budget Health ─────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: _BudgetHealthCard(
                    expenses: expenses,
                    settings: settings,
                    symbol: symbol,
                    isDark: isDark,
                    theme: theme,
                    now: now,
                  ).animate().fadeIn(delay: 480.ms),
                ),

                const SizedBox(height: 16),

                // ── Insights ──────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: InsightCard(
                    insights: expenses.getInsights(
                      categoryNames: {
                        for (final cat in context
                            .read<CategoryProvider>()
                            .categories)
                          cat.id: cat.name
                      },
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ),
              ]),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        key: _fabKey,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 8,
      ).animate().scale(delay: 600.ms),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// ── Card Data ─────────────────────────────────────────────────────────────────

class _CardData {
  final String title;
  final double totalBalance;
  final double spent;
  final double borrowed;
  final double lentOut;
  final double netLoan;
  final bool isAllWallets;
  final String? walletType;
  final int? colorValue;

  double get remaining => totalBalance - spent;

  const _CardData({
    required this.title,
    required this.totalBalance,
    required this.spent,
    required this.borrowed,
    required this.lentOut,
    required this.netLoan,
    required this.isAllWallets,
    this.walletType,
    this.colorValue,
  });
}

// ── Wallet Card ───────────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final _CardData card;
  final String symbol;
  final bool hideBalance;
  final VoidCallback onToggleHide;

  const _WalletCard({
    required this.card,
    required this.symbol,
    required this.hideBalance,
    required this.onToggleHide,
  });

  String _fmt(double amount) =>
      hideBalance ? '••••••' : AppUtils.formatAmount(amount, symbol);

  @override
  Widget build(BuildContext context) {
    final pct = card.totalBalance > 0
        ? (card.spent / card.totalBalance).clamp(0.0, 1.0)
        : 0.0;
    final isOver =
        card.spent > card.totalBalance && card.totalBalance > 0;

    final Color cardColor = card.isAllWallets
        ? const Color(0xFF1E3A5F)
        : Color(card.colorValue ?? 0xFF1E3A5F);
    final Color cardColorDark = card.isAllWallets
        ? const Color(0xFF0F2440)
        : HSLColor.fromColor(Color(card.colorValue ?? 0xFF1E3A5F))
            .withLightness(
                (HSLColor.fromColor(
                            Color(card.colorValue ?? 0xFF1E3A5F))
                        .lightness -
                    0.15)
                    .clamp(0.0, 1.0))
            .toColor();

    IconData walletIcon =
        Icons.account_balance_wallet_rounded;
    if (card.walletType != null) {
      walletIcon = WalletProvider.resolveIcon(card.walletType!);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                cardColor.withOpacity(0.75),
                cardColorDark.withOpacity(0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            card.title,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onToggleHide,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              hideBalance
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white.withOpacity(0.85),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.9),
                            borderRadius:
                                BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.amber.withOpacity(0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(walletIcon,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _fmt(card.totalBalance),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _fmt(card.remaining),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'remaining',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (card.isAllWallets &&
                        (card.borrowed > 0 ||
                            card.lentOut > 0)) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Text(
                          'Net  ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _fmt(card.remaining -
                              card.borrowed +
                              card.lentOut),
                          style: TextStyle(
                            color: const Color(0xFF4A90E2),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF4A90E2)
                                    .withOpacity(0.7),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ],
                    const Spacer(),
                    if (card.isAllWallets) ...[
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '+ Borrowed',
                            style: TextStyle(
                              color: card.borrowed > 0
                                  ? const Color(0xFF2ECC71)
                                      .withOpacity(0.9)
                                  : Colors.white.withOpacity(0.25),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _fmt(card.borrowed),
                            style: TextStyle(
                              color: card.borrowed > 0
                                  ? const Color(0xFF2ECC71)
                                  : Colors.white.withOpacity(0.25),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              shadows: card.borrowed > 0
                                  ? [
                                      Shadow(
                                        color: const Color(0xFF2ECC71)
                                            .withOpacity(0.6),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '- Lent out',
                            style: TextStyle(
                              color: card.lentOut > 0
                                  ? const Color(0xFFE57373)
                                      .withOpacity(0.9)
                                  : Colors.white.withOpacity(0.25),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _fmt(card.lentOut),
                            style: TextStyle(
                              color: card.lentOut > 0
                                  ? const Color(0xFFE57373)
                                  : Colors.white.withOpacity(0.25),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              shadows: card.lentOut > 0
                                  ? [
                                      Shadow(
                                        color: const Color(0xFFE57373)
                                            .withOpacity(0.6),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent ${_fmt(card.spent)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                        if (card.totalBalance > 0)
                          Text(
                            '${(pct * 100).round()}% used',
                            style: TextStyle(
                              color: isOver
                                  ? const Color(0xFFE57373)
                                  : const Color(0xFF2ECC71),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: isOver
                                  ? const Color(0xFFE57373)
                                  : pct > 0.75
                                      ? const Color(0xFFFF9800)
                                      : const Color(0xFF2ECC71),
                              borderRadius:
                                  BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: (isOver
                                          ? const Color(0xFFE57373)
                                          : const Color(0xFF2ECC71))
                                      .withOpacity(0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Budget Health Card ────────────────────────────────────────────────────────

class _BudgetHealthCard extends StatelessWidget {
  final ExpenseProvider expenses;
  final SettingsProvider settings;
  final String symbol;
  final bool isDark;
  final ThemeData theme;
  final DateTime now;

  const _BudgetHealthCard({
    required this.expenses,
    required this.settings,
    required this.symbol,
    required this.isDark,
    required this.theme,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>();
    final budgets = context.watch<CategoryBudgetProvider>();
    final catTotals =
        expenses.getCategoryTotals(now.year, now.month);

    final allBudgetedCats = cats.categories
        .where((c) => budgets.hasBudget(c.id))
        .toList();

    if (allBudgetedCats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFF9800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.monitor_heart_rounded,
                    color: Color(0xFFFF9800), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Budget Health',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
              Text(
                '${allBudgetedCats.length} categor${allBudgetedCats.length == 1 ? 'y' : 'ies'}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface
                      .withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...allBudgetedCats.map((cat) {
            final spent = catTotals[cat.id] ?? 0;
            final limit = budgets.getLimitFor(cat.id);
            final remaining = limit - spent;
            final pct = (spent / limit).clamp(0.0, 1.0);
            final isOver = spent > limit;
            final catColor = Color(cat.colorValue);

            Color barColor;
            if (isOver) {
              barColor = const Color(0xFFE57373);
            } else if (pct >= 0.8) {
              barColor = const Color(0xFFFF9800);
            } else {
              barColor = catColor;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        CategoryIcons.resolve(cat.icon),
                        color: catColor,
                        size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                              isOver
                                  ? '${AppUtils.formatAmount(remaining.abs(), symbol)} over'
                                  : '${AppUtils.formatAmount(remaining, symbol)} left',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOver
                                    ? const Color(0xFFE57373)
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor:
                                barColor.withOpacity(0.12),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    barColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${AppUtils.formatAmount(spent, symbol)} of ${AppUtils.formatAmount(limit, symbol)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4),
                              ),
                            ),
                            Text(
                              '${(pct * 100).round()}% used',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: barColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Quick Stat Card ───────────────────────────────────────────────────────────

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: color.withOpacity(0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
