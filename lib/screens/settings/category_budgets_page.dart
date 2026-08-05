part of '../settings_screen.dart';

// ── Category Budgets Page ─────────────────────────────────────────────────────

class _CategoryBudgetsPage extends StatelessWidget {
  const _CategoryBudgetsPage();

  @override
  Widget build(BuildContext context) {
    final cats     = context.watch<CategoryProvider>().categories;
    final budgets  = context.watch<CategoryBudgetProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol   = settings.currencySymbol;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final theme    = Theme.of(context);
    final now      = DateTime.now();
    final catTotals = expenses.getCategoryTotals(now.year, now.month);

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Category Budgets'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Set a monthly spending limit per category. Warned at 80% and 100%.',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          // ── Monthly reset indicator ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF2ECC71).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded,
                    color: Color(0xFF2ECC71), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tracking ${AppUtils.formatMonthYear(now)} · Resets automatically on the 1st of each month',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2ECC71),
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          ...cats.map((cat) {
            final hasBudget  = budgets.hasBudget(cat.id);
            final limit      = budgets.getLimitFor(cat.id);
            final spent      = catTotals[cat.id] ?? 0;
            final catColor   = Color(cat.colorValue);
            final statusColor = hasBudget
                ? budgets.getStatusColor(cat.id, spent)
                : catColor;
            final pct = hasBudget && limit > 0
                ? (spent / limit).clamp(0.0, 1.0)
                : 0.0;

            return Container(
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(CategoryIcons.resolve(cat.icon),
                            color: catColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            if (hasBudget)
                              Text(
                                'Spent ${AppUtils.formatAmount(spent, symbol)} of ${AppUtils.formatAmount(limit, symbol)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.w500),
                              )
                            else
                              Text('No budget set',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4))),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _showBudgetSheet(context, cat, limit),
                        child: Text(hasBudget ? 'Edit' : 'Set',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary)),
                      ),
                      if (hasBudget)
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: Colors.red),
                          onPressed: () => budgets.removeBudget(cat.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  if (hasBudget) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(children: [
                        Container(
                            height: 6,
                            color: statusColor.withOpacity(0.12)),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showBudgetSheet(
      BuildContext context, dynamic cat, double currentLimit) {
    final ctrl = TextEditingController(
        text: currentLimit > 0 ? currentLimit.toStringAsFixed(2) : '');
    final settings = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Color(cat.colorValue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(CategoryIcons.resolve(cat.icon),
                      color: Color(cat.colorValue), size: 20),
                ),
                const SizedBox(width: 12),
                Text('Budget for ${cat.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Monthly limit',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  suffixText: settings.currencySymbol,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final limit = double.tryParse(ctrl.text);
                    if (limit != null && limit > 0) {
                      ctx.read<CategoryBudgetProvider>()
                          .setBudget(cat.id, limit);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Budget'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
