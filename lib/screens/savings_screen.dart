import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/savings_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/savings_jar_widget.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savings = context.watch<SavingsProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Savings Jar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Jar visual
            SavingsJarWidget(totalSaved: savings.totalSaved)
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: 24),

            // Total card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Saved',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppUtils.formatAmount(savings.totalSaved, symbol),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Available for future use 🌟',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            if (savings.savings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.savings_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    Text(
                      'No savings yet',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'At month end, leftover budget moves here!',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 12),
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  const Text('Savings History',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              ...savings.savings.asMap().entries.map(
                    (e) => _SavingTile(
                      amount: e.value.amount,
                      date: e.value.date,
                      note: e.value.note,
                      symbol: symbol,
                    )
                        .animate()
                        .fadeIn(delay: (e.key * 60).ms)
                        .slideX(begin: 0.1),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavingTile extends StatelessWidget {
  final double amount;
  final DateTime date;
  final String note;
  final String symbol;

  const _SavingTile({
    required this.amount,
    required this.date,
    required this.note,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.savings_rounded, color: Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.isNotEmpty ? note : 'Month-end savings',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  AppUtils.formatDate(date),
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5)),
                ),
              ],
            ),
          ),
          Text(
            AppUtils.formatAmount(amount, symbol),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF4CAF50),
                fontSize: 16),
          ),
        ],
      ),
    );
  }
}
