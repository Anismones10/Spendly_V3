import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/income_provider.dart';
import '../providers/category_provider.dart';
import 'income_screen.dart';
import '../widgets/insight_card.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/streak_badge.dart';
import '../utils/app_utils.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final savings = context.watch<SavingsProvider>();

    final income = context.watch<IncomeProvider>();
    final monthlyIncome = income.getTotalForMonth(now.year, now.month);
    final totalSpent = expenses.getTotalForMonth(now.year, now.month);
    final budget = settings.monthlyBudget;

    // Budget remaining = budget + income - spent
    // Income adds to the available budget
    final effectiveTotal = budget + monthlyIncome;
    final budgetRemaining = effectiveTotal - totalSpent;
    final percentage = effectiveTotal > 0
        ? (totalSpent / effectiveTotal).clamp(0.0, 1.0)
        : 0.0;

    // Income balance for the income/expense row
    final incomeBalance = monthlyIncome - totalSpent;
    final remaining = budgetRemaining;
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: Text(
                'Spendly',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            actions: [
              // Date display
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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
              StreakBadge(streak: settings.streak),
              const SizedBox(width: 12),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Income vs Expense quick row
                _buildIncomeExpenseRow(context, monthlyIncome, totalSpent, incomeBalance, symbol, isDark, theme)
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 400.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Main balance card
                _buildBalanceCard(context, totalSpent, budgetRemaining, effectiveTotal, monthlyIncome, symbol, isDark)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.2),


                const SizedBox(height: 16),

                // Quick stats row
                Row(
                  children: [
                    Expanded(
                      child: _QuickStatCard(
                        label: 'Today',
                        value: AppUtils.formatAmount(
                            expenses.getTotalForDay(now), symbol),
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
                        value: AppUtils.formatAmount(monthlyIncome, symbol),
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF2ECC71),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const IncomeScreen()),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Daily summary card
                const DailySummaryCard()
                    .animate()
                    .fadeIn(delay: 450.ms),

                const SizedBox(height: 16),

                // Insights
                InsightCard(insights: expenses.getInsights(
                  categoryNames: {
                    for (final cat in context.read<CategoryProvider>().categories)
                      cat.id: cat.name
                  },
                ))
                    .animate()
                    .fadeIn(delay: 500.ms),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 8,
      ).animate().scale(delay: 600.ms),
    );
  }

  Widget _buildIncomeExpenseRow(BuildContext context, double income,
      double expenses, double balance, String symbol, bool isDark, ThemeData theme) {
    final hasIncome = income > 0;
    final isPositive = balance >= 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IncomeScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            // Income
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.arrow_downward_rounded,
                      color: const Color(0xFF2ECC71), size: 18),
                  const SizedBox(height: 4),
                  Text(
                    AppUtils.formatAmount(income, symbol),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF2ECC71),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Income',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
            // Divider
            Container(width: 1, height: 40,
                color: theme.colorScheme.onSurface.withOpacity(0.1)),
            // Balance
            Expanded(
              child: Column(
                children: [
                  Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isPositive
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFE57373),
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasIncome
                        ? AppUtils.formatAmount(balance.abs(), symbol)
                        : '—',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isPositive
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFE57373),
                    ),
                  ),
                  Text(
                    hasIncome
                        ? (isPositive ? 'Saved' : 'Over')
                        : 'Add income',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            // Divider
            Container(width: 1, height: 40,
                color: theme.colorScheme.onSurface.withOpacity(0.1)),
            // Expenses
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.arrow_upward_rounded,
                      color: const Color(0xFFE57373), size: 18),
                  const SizedBox(height: 4),
                  Text(
                    AppUtils.formatAmount(expenses, symbol),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFFE57373),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Expenses',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double totalSpent, double remaining,
      double budget, double monthlyIncome, String symbol, bool isDark) {
    final theme = Theme.of(context);
    final pct = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = remaining < 0;

    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF16304F), Color(0xFF0F2440)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: 60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row — label + chip icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      budget > 0 && monthlyIncome > 0
                        ? 'Budget + Income'
                        : budget > 0 ? 'Monthly Budget' : 'Total Spent',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        // Chip icon like a bank card
                        Container(
                          width: 32,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.credit_card_rounded,
                              color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        if (budget > 0)
                          Text(
                            AppUtils.formatAmount(budget, symbol),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Remaining amount — big and bold
                Text(
                  budget > 0
                      ? AppUtils.formatAmount(remaining.abs(), symbol)
                      : AppUtils.formatAmount(totalSpent, symbol),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  budget > 0
                      ? (isOver ? 'over budget' : 'remaining')
                      : 'total spent',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),

                const Spacer(),

                // Progress bar + stats at bottom
                Column(
                  children: [
                    // Spent / Budget labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent ${AppUtils.formatAmount(totalSpent, symbol)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          budget > 0
                              ? '${(pct * 100).round()}% used'
                              : '',
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
                    // Budget progress bar
                    if (budget > 0)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isOver
                                      ? const Color(0xFFE57373)
                                      : pct > 0.75
                                          ? const Color(0xFFFF9800)
                                          : const Color(0xFF2ECC71),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
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
  }

  String _todayDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

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
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
