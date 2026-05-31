import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Notification IDs ──────────────────────────────────────────────────────
  static const int _dailyReminderId   = 1;
  static const int _weeklySummaryId   = 2;
  static const int _loanOverdueBase   = 100;
  static const int _budgetWarn80Base  = 200;
  static const int _budgetWarn100Base = 300;
  static const int _goalMilestoneBase = 400;

  // ── Channels ──────────────────────────────────────────────────────────────
  static const _reminderChannel = AndroidNotificationChannel(
    'spendly_reminders', 'Daily Reminders',
    description: 'Daily expense logging reminders',
    importance: Importance.high,
  );
  static const _alertChannel = AndroidNotificationChannel(
    'spendly_alerts', 'Alerts',
    description: 'Budget, loan and goal alerts',
    importance: Importance.high,
  );
  static const _summaryChannel = AndroidNotificationChannel(
    'spendly_summary', 'Weekly Summary',
    description: 'Weekly spending summary',
    importance: Importance.defaultImportance,
  );

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    tz.initializeTimeZones();

    // ── Key fix: use Dart's built-in UTC offset — no external package needed
    // DateTime.now().timeZoneOffset gives the real device offset (e.g. +4:30)
    // We find the matching tz location by offset instead of by name.
    _setLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios));

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_reminderChannel);
    await androidPlugin?.createNotificationChannel(_alertChannel);
    await androidPlugin?.createNotificationChannel(_summaryChannel);
  }

  // ── Set local timezone using device UTC offset ────────────────────────────
  static void _setLocalTimezone() {
    final offsetSeconds = DateTime.now().timeZoneOffset.inSeconds;

    // Find a timezone in the database that matches the device's UTC offset
    // We iterate all locations and pick the first exact match
    for (final locationName in tz.timeZoneDatabase.locations.keys) {
      final location = tz.timeZoneDatabase.locations[locationName]!;
      final now = tz.TZDateTime.now(location);
      if (now.timeZoneOffset.inSeconds == offsetSeconds) {
        tz.setLocalLocation(location);
        return;
      }
    }

    // Fallback: build a fixed-offset location from the UTC offset directly
    // This always works even if no named zone matches exactly
    final utcNow = DateTime.now().toUtc();
    final localNow = DateTime.now();
    final diff = localNow.difference(utcNow);

    // Use UTC as base and adjust manually in scheduling methods
    tz.setLocalLocation(tz.UTC);
    _utcOffset = diff;
  }

  // Stores offset when no matching tz location found
  static Duration _utcOffset = Duration.zero;

  // ── Get correct "now" in local time ───────────────────────────────────────
  static tz.TZDateTime _localNow() {
    final location = tz.local;
    if (location == tz.UTC && _utcOffset != Duration.zero) {
      // Fallback: shift UTC time by device offset
      return tz.TZDateTime.now(tz.UTC).add(_utcOffset);
    }
    return tz.TZDateTime.now(location);
  }

  static tz.Location _localLocation() {
    return tz.local;
  }

  // ── Request permission ────────────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool granted = false;
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      granted = await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    return granted;
  }

  // ── Daily reminder ────────────────────────────────────────────────────────
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_dailyReminderId);

    final now = _localNow();
    var scheduled = tz.TZDateTime(
        _localLocation(), now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '💸 Time to log your expenses!',
      'Don\'t forget to record today\'s spending in Spendly.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannel.id, _reminderChannel.name,
          channelDescription: _reminderChannel.description,
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyReminder() async =>
      _plugin.cancel(_dailyReminderId);

  // ── Weekly summary ────────────────────────────────────────────────────────
  // weekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
  static Future<void> scheduleWeeklySummary({
    int weekday = 6,
    int hour    = 9,
    int minute  = 0,
  }) async {
    await _plugin.cancel(_weeklySummaryId);

    final now = _localNow();
    int daysUntil = (weekday - now.weekday + 7) % 7;
    if (daysUntil == 0 &&
        (now.hour > hour ||
            (now.hour == hour && now.minute >= minute))) {
      daysUntil = 7;
    }

    final scheduled = tz.TZDateTime(
      _localLocation(),
      now.year, now.month, now.day + daysUntil,
      hour, minute,
    );

    await _plugin.zonedSchedule(
      _weeklySummaryId,
      '📊 Your weekly spending summary is ready!',
      'Tap to see how you did this week in Spendly.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _summaryChannel.id, _summaryChannel.name,
          channelDescription: _summaryChannel.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: false, presentSound: false),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> cancelWeeklySummary() async =>
      _plugin.cancel(_weeklySummaryId);

  // ── Loan overdue alert ────────────────────────────────────────────────────
  static Future<void> showLoanOverdueAlert({
    required int index,
    required String personName,
    required String amount,
    required String type,
  }) async {
    final isLending = type == 'lending';
    await _plugin.show(
      _loanOverdueBase + index,
      isLending
          ? '⚠️ Loan Overdue — $personName owes you'
          : '⚠️ Loan Overdue — You owe $personName',
      '${isLending ? 'They owe you' : 'You owe'} $amount. Past due date.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannel.id, _alertChannel.name,
          channelDescription: _alertChannel.description,
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  // ── Budget warning ────────────────────────────────────────────────────────
  static Future<void> showBudgetWarning({
    required int index,
    required String categoryName,
    required String spent,
    required String limit,
    required bool isOver,
  }) async {
    await _plugin.show(
      isOver ? _budgetWarn100Base + index : _budgetWarn80Base + index,
      isOver
          ? '🚨 Over Budget — $categoryName'
          : '⚠️ Budget Alert — $categoryName',
      isOver
          ? 'Exceeded your $categoryName budget! Spent: $spent / $limit'
          : 'Used 80%+ of your $categoryName budget. Spent: $spent / $limit',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannel.id, _alertChannel.name,
          channelDescription: _alertChannel.description,
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  // ── Goal milestone ────────────────────────────────────────────────────────
  static Future<void> showGoalMilestone({
    required int index,
    required String goalName,
    required int percent,
  }) async {
    String title, body;
    if (percent >= 100) {
      title = '🎉 Goal Completed — $goalName!';
      body  = 'Amazing! You\'ve fully reached your "$goalName" savings goal!';
    } else if (percent >= 75) {
      title = '🔥 75% Done — $goalName';
      body  = 'You\'re $percent% of the way to "$goalName". Keep going!';
    } else {
      title = '👏 50% Done — $goalName';
      body  = 'Halfway there! You\'ve saved $percent% toward "$goalName".';
    }
    await _plugin.show(
      _goalMilestoneBase + index,
      title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannel.id, _alertChannel.name,
          channelDescription: _alertChannel.description,
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  // ── Cancel all ────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async => _plugin.cancelAll();
}
