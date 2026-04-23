import 'package:flutter/material.dart';

class InsightCard extends StatefulWidget {
  final List<String> insights;
  const InsightCard({super.key, required this.insights});

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            children: [
              Icon(Icons.lightbulb_rounded,
                  color: const Color(0xFFFFEB3B), size: 20),
              const SizedBox(width: 8),
              const Text('Smart Insights',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text(
                '${_current + 1}/${widget.insights.length}',
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: PageView.builder(
              itemCount: widget.insights.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.insights[i],
                  key: ValueKey(i),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.insights.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
