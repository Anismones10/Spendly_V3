import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmotionCharacter extends StatelessWidget {
  final double percentage;
  const EmotionCharacter({super.key, required this.percentage});

  _EmotionData get _data {
    if (percentage >= 1.0) {
      return _EmotionData(
        icon: Icons.warning_rounded,
        color: const Color(0xFFE57373),
        title: 'Over Budget!',
        message: 'You have exceeded your budget. Time to pause spending.',
        bgGradient: [const Color(0xFFE57373), const Color(0xFFEF9A9A)],
      );
    }
    if (percentage >= 0.8) {
      return _EmotionData(
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFFF9800),
        title: 'Almost There',
        message: 'Only ${((1 - percentage) * 100).round()}% of your budget left. Spend wisely.',
        bgGradient: [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
      );
    }
    if (percentage >= 0.5) {
      return _EmotionData(
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF4A90E2),
        title: 'Halfway',
        message: 'You have used ${(percentage * 100).round()}% of your budget. Stay on track.',
        bgGradient: [const Color(0xFF4A90E2), const Color(0xFF64B5F6)],
      );
    }
    return _EmotionData(
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF2ECC71),
      title: 'On Track',
      message: 'Great job! You are well within your budget this month.',
      bgGradient: [const Color(0xFF2ECC71), const Color(0xFF66BB6A)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 12)
        ],
      ),
      child: Row(
        children: [
          // Icon in gradient circle
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: d.bgGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: d.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(d.icon, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Column(
                key: ValueKey(d.title),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: d.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    d.message,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionData {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final List<Color> bgGradient;

  const _EmotionData({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.bgGradient,
  });
}
