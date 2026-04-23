import 'package:flutter/material.dart';
import '../utils/app_utils.dart';

class BudgetBar extends StatelessWidget {
  final double percentage;
  const BudgetBar({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.budgetColor(percentage);
    final pct = (percentage * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budget Used',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, value, __) => Stack(
                children: [
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.8),
                            color,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: value > 0.1
                          ? Text(
                              '$pct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Legend(color: const Color(0xFF4CAF50), label: '0–50%'),
              _Legend(color: const Color(0xFFFFEB3B), label: '50–75%'),
              _Legend(color: const Color(0xFFFF9800), label: '75–90%'),
              _Legend(color: const Color(0xFFF44336), label: '90–100%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
