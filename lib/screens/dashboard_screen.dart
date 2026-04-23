import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/savings_provider.dart';
import '../widgets/budget_bar.dart';
import '../widgets/insight_card.dart';
import '../widgets/emotion_character.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/streak_badge.dart';
import '../utils/app_utils.dart';
import 'add_expense_screen.dart';
import 'savings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final savings = context.watch<SavingsProvider>();

    final totalSpent = expenses.getTotalForMonth(now.year, now.month);
    final budget = settings.monthlyBudget;
    final remaining = budget - totalSpent;
    final percentage = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
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
                'How MUCH?',
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
                // Emotion Character
                EmotionCharacter(percentage: percentage)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2),

                const SizedBox(height: 16),

                // Main balance card
                _buildBalanceCard(context, totalSpent, remaining, budget, symbol, isDark)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.2),

                const SizedBox(height: 16),

                // Budget bar
                BudgetBar(percentage: percentage)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),

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
                        label: 'Saved',
                        value: AppUtils.formatAmount(savings.totalSaved, symbol),
                        icon: Icons.savings_rounded,
                        color: const Color(0xFF4CAF50),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SavingsScreen()),
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
                InsightCard(insights: expenses.getInsights())
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

  Widget _buildBalanceCard(BuildContext context, double totalSpent, double remaining,
      double budget, String symbol, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Budget',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                budget > 0
                    ? AppUtils.formatAmount(budget, symbol)
                    : 'Not set',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppUtils.formatAmount(totalSpent, symbol),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Spent',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${AppUtils.formatAmount(remaining.abs(), symbol)} ${remaining >= 0 ? 'remaining' : 'over budget'}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
