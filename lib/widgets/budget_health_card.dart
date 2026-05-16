import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/category_budget_provider.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';

class BudgetHealthCard extends StatelessWidget {
  const BudgetHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    final budgets = context.watch<CategoryBudgetProvider>();
    final categories = context.watch<CategoryProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbol = settings.currencySymbol;
    final now = DateTime.now();

    // Only show categories that have a budget set
    final activeBudgets = budgets.all;
    if (activeBudgets.isEmpty) return const SizedBox.shrink();

    // Category totals for this month
    final catTotals = expenses.getCategoryTotals(now.year, now.month);

    // Check if any category is in warning or danger
    final hasAlert = activeBudgets.any((b) {
      final spent = catTotals[b.categoryId] ?? 0;
      return budgets.getStatus(b.categoryId, spent) != 'ok';
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
        border: hasAlert
            ? Border.all(
                color: const Color(0xFFFF9800).withOpacity(0.4),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hasAlert
                      ? const Color(0xFFFF9800).withOpacity(0.15)
                      : const Color(0xFF2ECC71).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasAlert
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: hasAlert
                      ? const Color(0xFFFF9800)
                      : const Color(0xFF2ECC71),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Budget Health',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${activeBudgets.length} categories',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Budget rows
          ...activeBudgets.asMap().entries.map((entry) {
            final budget = entry.value;
            final cat = categories.getById(budget.categoryId);
            if (cat == null) return const SizedBox.shrink();

            final spent = catTotals[budget.categoryId] ?? 0;
            final pct =
                budgets.getUsagePercent(budget.categoryId, spent).clamp(0.0, 1.0);
            final status = budgets.getStatus(budget.categoryId, spent);
            final statusColor =
                budgets.getStatusColor(budget.categoryId, spent);
            final catColor = Color(cat.colorValue);
            final remaining = budget.limitAmount - spent;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category row
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          CategoryIcons.resolve(cat.icon),
                          color: catColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              remaining >= 0
                                  ? '${AppUtils.formatAmount(remaining, symbol)} left'
                                  : '${AppUtils.formatAmount(remaining.abs(), symbol)} over!',
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Spent / Limit
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppUtils.formatAmount(spent, symbol),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            'of ${AppUtils.formatAmount(budget.limitAmount, symbol)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      if (status != 'ok')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status == 'danger' ? 'Over!' : '80%+',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      builder: (_, val, __) => Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: val,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: (entry.key * 60).ms).slideX(begin: 0.05),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
