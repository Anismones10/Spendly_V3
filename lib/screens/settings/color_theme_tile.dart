part of '../settings_screen.dart';

// ── Color Theme Tile ─────────────────────────────────────────────────────────

class _ColorThemeTile extends StatelessWidget {
  final SettingsProvider settings;
  const _ColorThemeTile({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final current = settings.themeColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: current.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_rounded,
                    color: current, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('App Color',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          // ── Color circles ────────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(AppColors.presets.length, (i) {
              final color     = AppColors.presets[i];
              final isSelected =
                  current.value == color.value;
              return GestureDetector(
                onTap: () => settings.setThemeColor(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width:  isSelected ? 36 : 30,
                  height: isSelected ? 36 : 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                        color: theme.colorScheme.onSurface,
                        width: 2.5)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final String code;
  final String label;
  final bool isSelected;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onTap;

  const _CurrencyTile({
    required this.code, required this.label, required this.isSelected,
    required this.theme, required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : theme.colorScheme.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(code,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.5))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary : null)),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
