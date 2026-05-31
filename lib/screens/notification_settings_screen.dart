import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/notification_helper.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final Box _box = Hive.box('settings');

  bool get _notifEnabled => _box.get('notifEnabled', defaultValue: false) as bool;
  bool get _dailyReminder => _box.get('notifDaily',   defaultValue: true)  as bool;
  bool get _weeklySummary => _box.get('notifWeekly',  defaultValue: true)  as bool;
  bool get _budgetAlert   => _box.get('notifBudget',  defaultValue: true)  as bool;
  bool get _loanAlert     => _box.get('notifLoan',    defaultValue: true)  as bool;
  bool get _goalAlert     => _box.get('notifGoal',    defaultValue: true)  as bool;
  int  get _reminderHour  => _box.get('notifHour',    defaultValue: 21)    as int;
  int  get _reminderMinute=> _box.get('notifMinute',  defaultValue: 0)     as int;

  // Weekly summary prefs
  int get _weeklyDay    => _box.get('notifWeeklyDay',    defaultValue: 6)  as int;
  int get _weeklyHour   => _box.get('notifWeeklyHour',   defaultValue: 9)  as int;
  int get _weeklyMinute => _box.get('notifWeeklyMinute', defaultValue: 0)  as int;

  Future<void> _toggleMaster(bool value) async {
    if (value) {
      final granted = await NotificationHelper.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Permission denied. Please enable notifications in phone settings.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      _box.put('notifEnabled', true);
      _applyAll();
    } else {
      _box.put('notifEnabled', false);
      await NotificationHelper.cancelAll();
    }
    setState(() {});
  }

  void _applyAll() {
    if (!_notifEnabled) return;

    if (_dailyReminder) {
      NotificationHelper.scheduleDailyReminder(
          hour: _reminderHour, minute: _reminderMinute);
    } else {
      NotificationHelper.cancelDailyReminder();
    }

    if (_weeklySummary) {
      NotificationHelper.scheduleWeeklySummary(
          weekday: _weeklyDay,
          hour: _weeklyHour,
          minute: _weeklyMinute);
    } else {
      NotificationHelper.cancelWeeklySummary();
    }
  }

  void _toggle(String key, bool value) {
    _box.put(key, value);
    setState(() {});
    _applyAll();
  }

  Future<void> _pickDailyTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked != null) {
      _box.put('notifHour', picked.hour);
      _box.put('notifMinute', picked.minute);
      setState(() {});
      if (_notifEnabled && _dailyReminder) {
        NotificationHelper.scheduleDailyReminder(
            hour: picked.hour, minute: picked.minute);
      }
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  String _weekdayName(int day) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[day];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Master toggle card ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _notifEnabled
                    ? [theme.colorScheme.primary,
                       theme.colorScheme.primary.withOpacity(0.75)]
                    : [const Color(0xFF78909C), const Color(0xFF546E7A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (_notifEnabled
                          ? theme.colorScheme.primary
                          : const Color(0xFF78909C))
                      .withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _notifEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: Colors.white, size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notifications',
                          style: TextStyle(color: Colors.white,
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(
                        _notifEnabled
                            ? 'Notifications are ON'
                            : 'Tap to enable notifications',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _notifEnabled,
                  onChanged: _toggleMaster,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withOpacity(0.4),
                ),
              ],
            ),
          ),

          if (!_notifEnabled) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enable notifications above to configure individual alerts.',
                      style: TextStyle(fontSize: 13,
                          color: Colors.orange.shade700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_notifEnabled) ...[
            const SizedBox(height: 24),

            // ── Daily Reminder ─────────────────────────────────────────
            _sectionHeader('Daily Reminder', theme),
            _notifTile(
              isDark: isDark, theme: theme,
              icon: Icons.alarm_rounded, color: const Color(0xFF4A90E2),
              title: 'Log Expense Reminder',
              subtitle: 'Reminds you daily to record your spending',
              value: _dailyReminder,
              onChanged: (v) => _toggle('notifDaily', v),
            ),
            if (_dailyReminder) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDailyTime,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.access_time_rounded,
                            color: Color(0xFF4A90E2), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reminder Time',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('Tap to change',
                                style: TextStyle(fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF4A90E2).withOpacity(0.3)),
                        ),
                        child: Text(
                          _formatTime(_reminderHour, _reminderMinute),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15,
                              color: Color(0xFF4A90E2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Weekly Summary ─────────────────────────────────────────
            _sectionHeader('Weekly Summary', theme),
            _notifTileWithArrow(
              isDark: isDark, theme: theme,
              icon: Icons.bar_chart_rounded, color: const Color(0xFF9C27B0),
              title: 'Weekly Spending Summary',
              subtitle:
                  '${_weekdayName(_weeklyDay)}s at ${_formatTime(_weeklyHour, _weeklyMinute)}',
              value: _weeklySummary,
              onChanged: (v) => _toggle('notifWeekly', v),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const WeeklySummarySettingsScreen()),
              ).then((_) {
                setState(() {});
                _applyAll();
              }),
            ),

            const SizedBox(height: 16),

            // ── Alerts ─────────────────────────────────────────────────
            _sectionHeader('Alerts', theme),
            _notifTile(
              isDark: isDark, theme: theme,
              icon: Icons.pie_chart_rounded, color: const Color(0xFFFF9800),
              title: 'Budget Warnings',
              subtitle: 'At 80% and 100% of category budget',
              value: _budgetAlert,
              onChanged: (v) => _toggle('notifBudget', v),
            ),
            const SizedBox(height: 8),
            _notifTile(
              isDark: isDark, theme: theme,
              icon: Icons.handshake_rounded, color: const Color(0xFFE57373),
              title: 'Loan Overdue',
              subtitle: 'When a loan passes its due date',
              value: _loanAlert,
              onChanged: (v) => _toggle('notifLoan', v),
            ),
            const SizedBox(height: 8),
            _notifTile(
              isDark: isDark, theme: theme,
              icon: Icons.flag_rounded, color: const Color(0xFF2ECC71),
              title: 'Goal Milestones',
              subtitle: 'At 50%, 75%, and 100% of savings goals',
              value: _goalAlert,
              onChanged: (v) => _toggle('notifGoal', v),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: theme.colorScheme.primary)),
    );
  }

  Widget _notifTile({
    required bool isDark, required ThemeData theme,
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required bool value, required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.45))),
        trailing: Switch.adaptive(value: value, onChanged: onChanged),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Tile with arrow — tappable to open sub-page
  Widget _notifTileWithArrow({
    required bool isDark, required ThemeData theme,
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required bool value, required ValueChanged<bool> onChanged,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(subtitle,
                style: TextStyle(fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.45))),
            trailing: Switch.adaptive(value: value, onChanged: onChanged),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          if (value) ...[
            Divider(
                height: 1,
                color: theme.colorScheme.onSurface.withOpacity(0.07),
                indent: 16, endIndent: 16),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              title: Text('Customize schedule',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: color, size: 20),
              onTap: onTap,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16))),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Weekly Summary Settings Page ──────────────────────────────────────────────

class WeeklySummarySettingsScreen extends StatefulWidget {
  const WeeklySummarySettingsScreen({super.key});

  @override
  State<WeeklySummarySettingsScreen> createState() =>
      _WeeklySummarySettingsScreenState();
}

class _WeeklySummarySettingsScreenState
    extends State<WeeklySummarySettingsScreen> {
  final Box _box = Hive.box('settings');

  int get _weeklyDay    => _box.get('notifWeeklyDay',    defaultValue: 6) as int;
  int get _weeklyHour   => _box.get('notifWeeklyHour',   defaultValue: 9) as int;
  int get _weeklyMinute => _box.get('notifWeeklyMinute', defaultValue: 0) as int;

  // 1=Mon ... 7=Sun
  static const _days = [
    {'label': 'Monday',    'value': 1},
    {'label': 'Tuesday',   'value': 2},
    {'label': 'Wednesday', 'value': 3},
    {'label': 'Thursday',  'value': 4},
    {'label': 'Friday',    'value': 5},
    {'label': 'Saturday',  'value': 6},
    {'label': 'Sunday',    'value': 7},
  ];

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _weeklyHour, minute: _weeklyMinute),
    );
    if (picked != null) {
      _box.put('notifWeeklyHour', picked.hour);
      _box.put('notifWeeklyMinute', picked.minute);
      setState(() {});
      _reschedule();
    }
  }

  void _pickDay(int day) {
    _box.put('notifWeeklyDay', day);
    setState(() {});
    _reschedule();
  }

  void _reschedule() {
    final enabled = _box.get('notifEnabled', defaultValue: false) as bool;
    final weekly  = _box.get('notifWeekly',  defaultValue: true)  as bool;
    if (enabled && weekly) {
      NotificationHelper.scheduleWeeklySummary(
          weekday: _weeklyDay,
          hour: _weeklyHour,
          minute: _weeklyMinute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const color = Color(0xFF9C27B0);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Weekly Summary Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Info card ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your weekly spending summary will be sent every '
                    '${_days.firstWhere((d) => d['value'] == _weeklyDay)['label']} '
                    'at ${_formatTime(_weeklyHour, _weeklyMinute)}.',
                    style: TextStyle(
                        fontSize: 13, color: color, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // ── Day picker ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text('DAY OF WEEK',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary)),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _days.map((day) {
              final val = day['value'] as int;
              final label = day['label'] as String;
              final isSelected = _weeklyDay == val;
              return GestureDetector(
                onTap: () => _pickDay(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : (isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: isSelected
                              ? color.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 8)
                    ],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ── Time picker ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text('TIME',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary)),
          ),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [BoxShadow(
                    color: color.withOpacity(0.1), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.access_time_rounded,
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notification Time',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Tap to change',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      _formatTime(_weeklyHour, _weeklyMinute),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
