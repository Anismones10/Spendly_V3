import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dailyTotals = expenses.getDailyTotals(_focusedDay.year, _focusedDay.month);
    final monthTotal = expenses.getTotalForMonth(_focusedDay.year, _focusedDay.month);

    // Calculate average daily spending to determine red/green
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final avgDaily = monthTotal > 0 ? monthTotal / daysInMonth : 0.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: widget.embedded ? null : AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          // Calendar
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
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                _showDayExpenses(context, selected, expenses, symbol);
              },
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.3),
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
                  final total = dailyTotals[day.day] ?? 0;
                  if (total == 0) return const SizedBox.shrink();
                  final isHigh = total > avgDaily * 1.5;
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isHigh ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _LegendItem(color: Colors.green, label: 'Low/Normal spending'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.red, label: 'High spending'),
              ],
            ),
          ),

          // Month total
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppUtils.formatMonthYear(_focusedDay),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
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
                          fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    Text(
                      AppUtils.formatAmount(
                          dayExpenses.fold(0, (s, e) => s + e.amount), symbol),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
