import 'package:flutter/material.dart';

/// The periods offered by [ListFilterBar].
///
/// 'custom' is deliberately absent — it needs a date picker rather than a
/// plain toggle, so the bar renders it as its own chip.
const kFilterPeriods = <({String key, String label})>[
  (key: 'all', label: 'All'),
  (key: 'today', label: 'Today'),
  (key: 'week', label: 'This Week'),
  (key: 'month', label: 'This Month'),
];

/// Sort orders shared by both lists.
///
/// Labels are short because they have to fit a chip in the bar; the icon
/// carries the direction.
const kSortOptions = <({String key, String label, IconData icon})>[
  (key: 'dateDesc', label: 'Newest', icon: Icons.arrow_downward_rounded),
  (key: 'dateAsc', label: 'Oldest', icon: Icons.arrow_upward_rounded),
  (
    key: 'amountDesc',
    label: 'Highest',
    icon: Icons.keyboard_double_arrow_up_rounded
  ),
  (
    key: 'amountAsc',
    label: 'Lowest',
    icon: Icons.keyboard_double_arrow_down_rounded
  ),
];

/// The date range a period key selects, or null for 'all' — no restriction.
///
/// Lives here rather than in either screen so Expenses and Income can never
/// disagree about what "This Week" means.
///
/// Ranges run to the end of their last day, not to the current instant. Both
/// expenses and income can be dated ahead (a scheduled bill, next week's pay),
/// and those entries belong to the month they fall in.
DateTimeRange? rangeForPeriod(String period, DateTime now) {
  switch (period) {
    case 'today':
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case 'week':
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6)),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case 'month':
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        // Day 0 of next month is the last day of this one.
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
    default:
      return null;
  }
}

/// One filter currently narrowing the list, rendered as a removable chip.
class ActiveFilter {
  final String label;
  final VoidCallback onRemove;
  final IconData? icon;
  final Color? color;

  const ActiveFilter({
    required this.label,
    required this.onRemove,
    this.icon,
    this.color,
  });
}

/// The filter header shared by the Expenses and Income tabs.
///
/// Everything that narrows the list is reachable from this one bar. Search,
/// period and sort sit inline because they get changed constantly; the
/// remaining filters need a list to pick from, so they stay behind the tune
/// button and report back as removable chips.
class ListFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;

  final String sortBy;
  final ValueChanged<String> onSortChanged;

  final String periodFilter;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onPickCustomRange;

  /// Shown on the custom chip once a range exists, so the dates appear in the
  /// chip that selected them instead of in a second chip underneath.
  final String? customRangeLabel;

  final VoidCallback onFilterTap;
  final bool hasActiveFilter;
  final List<ActiveFilter> activeFilters;

  const ListFilterBar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.sortBy,
    required this.onSortChanged,
    required this.periodFilter,
    required this.onPeriodChanged,
    required this.onPickCustomRange,
    required this.onFilterTap,
    required this.hasActiveFilter,
    this.customRangeLabel,
    this.activeFilters = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final sort = kSortOptions.firstWhere((s) => s.key == sortBy,
        orElse: () => kSortOptions.first);

    return Column(
      children: [
        // ── Search, sort and filter on one line ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 38, minHeight: 38),
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              splashRadius: 18,
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                            ),
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort was previously buried in the sheet, so the list could be
              // ordered by amount with nothing on screen saying so.
              PopupMenuButton<String>(
                onSelected: onSortChanged,
                tooltip: 'Sort',
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                itemBuilder: (_) => kSortOptions
                    .map((o) => PopupMenuItem<String>(
                          value: o.key,
                          height: 44,
                          child: Row(
                            children: [
                              Icon(o.icon,
                                  size: 17,
                                  color: o.key == sortBy
                                      ? primary
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.55)),
                              const SizedBox(width: 10),
                              Text(o.label,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: o.key == sortBy
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: o.key == sortBy ? primary : null,
                                  )),
                            ],
                          ),
                        ))
                    .toList(),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sort.icon, size: 15, color: primary),
                      const SizedBox(width: 5),
                      Text(sort.label,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // The dot marks filters that are set but not visible from here.
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: onFilterTap,
                    tooltip: 'More filters',
                    visualDensity: VisualDensity.compact,
                  ),
                  if (hasActiveFilter)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: primary, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // ── Period chips ─────────────────────────────────────────────
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final p in kFilterPeriods) ...[
                _PeriodChip(
                  label: p.label,
                  selected: periodFilter == p.key,
                  onTap: () => onPeriodChanged(p.key),
                ),
                const SizedBox(width: 8),
              ],
              // Once a range is picked the chip shows it, which is why there
              // is no second chip repeating the same dates below.
              _PeriodChip(
                label: periodFilter == 'custom' && customRangeLabel != null
                    ? customRangeLabel!
                    : 'Custom',
                icon: Icons.date_range_rounded,
                selected: periodFilter == 'custom',
                onTap: onPickCustomRange,
              ),
            ],
          ),
        ),

        // ── Whatever the sheet is currently filtering by ─────────────
        if (activeFilters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            // Left-aligned: the Column centres its children by default, which
            // left this row floating in the middle while the search box,
            // period chips and the list below it all start at the same margin.
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    activeFilters.map((f) => _ActiveChip(filter: f)).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected ? Colors.white : theme.colorScheme.primary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A filter set from the sheet, shown so it can be undone without reopening
/// the sheet to hunt for what is switched on.
class _ActiveChip extends StatelessWidget {
  final ActiveFilter filter;
  const _ActiveChip({required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = filter.color ?? theme.colorScheme.primary;
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: filter.onRemove,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filter.icon != null) ...[
                Icon(filter.icon, size: 13, color: color),
                const SizedBox(width: 5),
              ],
              // Long category and wallet names get cut rather than forcing
              // the chip past the screen edge.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  filter.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.close_rounded, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
