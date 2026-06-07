import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/expense_tile.dart';
import '../utils/app_utils.dart';

class CalendarScreen extends StatefulWidget {
  final bool embedded;
  const CalendarScreen({super.key, this.embedded = false});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime  _focusedDay  = DateTime.now();
  DateTime? _selectedDay;

  final Box _box = Hive.box('settings');

  // Threshold saved in Hive — 0 means "use monthly average"
  double get _threshold =>
      (_box.get('calendarThreshold', defaultValue: 0.0) as num).toDouble();

  void _setThreshold(double value) {
    _box.put('calendarThreshold', value);
    setState(() {});
  }

  // ── Dot color logic ────────────────────────────────────────────────────────
  Color _dotColor(double amount, double threshold) {
    if (amount <= threshold)          return const Color(0xFF2ECC71); // green
    if (amount <= threshold * 2)      return const Color(0xFFFF9800); // orange
    return const Color(0xFFE57373);                                   // red
  }

  // ── Threshold picker dialog ────────────────────────────────────────────────
  void _showThresholdPicker(BuildContext context, double avgDaily, String symbol) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final current = _threshold == 0 ? avgDaily : _threshold;
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Set Daily Threshold',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Spending at or below this amount = 🟢 green\n'
                'Up to 2× this amount = 🟠 orange\n'
                'Above 2× this amount = 🔴 red',
                style: TextStyle(
                  fontSize: 13, height: 1.7,
                  color: theme.colorScheme.onSurface.withOpacity(0.55)),
              ),
              const SizedBox(height: 20),

              // Auto suggestion
              if (avgDaily > 0)
                GestureDetector(
                  onTap: () {
                    ctrl.text = avgDaily.toStringAsFixed(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: theme.colorScheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Use monthly average: ${AppUtils.formatAmount(avgDaily, symbol)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Manual input
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'))
                ],
                decoration: InputDecoration(
                  labelText: 'Threshold amount',
                  prefixText: '$symbol ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                autofocus: true,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  // Reset to auto
                  OutlinedButton(
                    onPressed: () {
                      _setThreshold(0);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Use Auto'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final val = double.tryParse(ctrl.text);
                        if (val != null && val > 0) {
                          _setThreshold(val);
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol   = settings.currencySymbol;
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;

    final dailyTotals = expenses.getDailyTotals(
        _focusedDay.year, _focusedDay.month);
    final monthTotal = expenses.getTotalForMonth(
        _focusedDay.year, _focusedDay.month);

    // Effective threshold — use saved value or fall back to monthly average
    final daysInMonth =
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final avgDaily = monthTotal > 0 ? monthTotal / daysInMonth : 0.0;
    final effectiveThreshold = _threshold > 0 ? _threshold : avgDaily;

    final isCustom = _threshold > 0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: isDark
                  ? const Color(0xFF121212)
                  : const Color(0xFFF5F7FA),
              title: const Text('Calendar'),
            ),
      body: Column(
        children: [
          // ── Calendar ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay  = focused;
                });
                _showDayExpenses(context, selected, expenses, symbol);
              },
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
                leftChevronIcon: Icon(Icons.chevron_left_rounded,
                    color: theme.colorScheme.primary),
                rightChevronIcon: Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.primary),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (ctx, day, events) {
                  final total = dailyTotals[day.day] ?? 0.0;
                  if (total == 0 || effectiveThreshold == 0) {
                    return const SizedBox.shrink();
                  }
                  final color = _dotColor(total, effectiveThreshold);
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Legend + threshold button ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // 3 legend dots
                _LegendItem(
                    color: const Color(0xFF2ECC71),
                    label: '≤ threshold'),
                const SizedBox(width: 12),
                _LegendItem(
                    color: const Color(0xFFFF9800),
                    label: '≤ 2×'),
                const SizedBox(width: 12),
                _LegendItem(
                    color: const Color(0xFFE57373),
                    label: 'High'),
                const Spacer(),
                // Set threshold button
                GestureDetector(
                  onTap: () => _showThresholdPicker(
                      context, avgDaily, symbol),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCustom
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.onSurface
                              .withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: isCustom
                          ? Border.all(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 14,
                            color: isCustom
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          isCustom
                              ? AppUtils.formatAmount(
                                  _threshold, symbol)
                              : 'Auto',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCustom
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Month total ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppUtils.formatMonthYear(_focusedDay),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(
                  'Total: ${AppUtils.formatAmount(monthTotal, symbol)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDayExpenses(BuildContext context, DateTime day,
      ExpenseProvider expenses, String symbol) {
    final dayExpenses = expenses.getExpensesForDay(day);
    if (dayExpenses.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppUtils.formatDate(day),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                    ),
                    Text(
                      AppUtils.formatAmount(
                          dayExpenses.fold(
                              0.0, (s, e) => s + e.amount),
                          symbol),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color:
                            Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: dayExpenses.length,
                  itemBuilder: (ctx, i) => ExpenseTile(
                    expense: dayExpenses[i],
                    symbol: symbol,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6))),
      ],
    );
  }
}
