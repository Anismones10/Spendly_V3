import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}
