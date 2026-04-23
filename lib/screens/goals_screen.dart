import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/goal_model.dart';
import '../providers/goal_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/empty_state.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Goals'),
      ),
      body: goals.goals.isEmpty
          ? const EmptyState(
              icon: Icons.flag_rounded,
              title: 'No Goals Yet',
              subtitle: 'Set a savings goal and track your progress!',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                if (goals.activeGoals.isNotEmpty) ...[
                  _sectionLabel('Active Goals'),
                  ...goals.activeGoals.asMap().entries.map(
                        (e) => _GoalCard(goal: e.value, symbol: symbol)
                            .animate()
                            .fadeIn(delay: (e.key * 60).ms)
                            .slideY(begin: 0.1),
                      ),
                ],
                if (goals.completedGoals.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _sectionLabel('Completed'),
                  ...goals.completedGoals.map(
                    (g) => _GoalCard(goal: g, symbol: symbol),
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime? deadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Savings Goal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Goal name (e.g. New Laptop)',
                    prefixIcon: Icon(Icons.flag_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Target amount',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => deadline = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded),
                        const SizedBox(width: 12),
                        Text(deadline != null
                            ? AppUtils.formatDate(deadline!)
                            : 'Set deadline (optional)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final amount = double.tryParse(amountCtrl.text);
                      if (name.isEmpty || amount == null || amount <= 0) return;
                      ctx.read<GoalProvider>().addGoal(GoalModel(
                            id: AppUtils.generateId(),
                            name: name,
                            targetAmount: amount,
                            deadline: deadline,
                          ));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Create Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final String symbol;
  const _GoalCard({required this.goal, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = goal.progress.clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    Color progressColor;
    if (pct >= 100) {
      progressColor = const Color(0xFF4CAF50);
    } else if (pct >= 75) {
      progressColor = const Color(0xFF2196F3);
    } else {
      progressColor = theme.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  goal.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.flag_rounded,
                  color: progressColor,
                  size: 22,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (goal.deadline != null)
                      Text(
                        'By ${AppUtils.formatDate(goal.deadline!)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                  ],
                ),
              ),
              if (goal.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Completed',
                      style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded),
                  color: theme.colorScheme.primary,
                  onPressed: () => _showAddFunds(context),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppUtils.formatAmount(goal.savedAmount, symbol),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                    fontSize: 18),
              ),
              Text(
                '${AppUtils.formatAmount(goal.targetAmount, symbol)} ($pct%)',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: progressColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          if (!goal.isCompleted) ...[
            const SizedBox(height: 8),
            Text(
              '${AppUtils.formatAmount(goal.remaining, symbol)} remaining',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddFunds(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to "${goal.name}"'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Amount to add'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text);
              if (amount != null && amount > 0) {
                ctx.read<GoalProvider>().updateGoalSavings(goal.id, amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
