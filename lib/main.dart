import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'models/expense_model.dart';
import 'models/category_model.dart';
import 'models/goal_model.dart';
import 'models/savings_model.dart';
import 'models/income_model.dart';
import 'models/loan_model.dart';
import 'models/wallet_model.dart';
import 'models/category_budget_model.dart';
import 'models/transfer_model.dart';
import 'providers/expense_provider.dart';
import 'providers/category_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/savings_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/income_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/category_budget_provider.dart';
import 'providers/transfer_provider.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/income_screen.dart';import 'utils/app_theme.dart';
import 'utils/notification_helper.dart';
import 'utils/widget_helper.dart';
import 'firebase_options.dart';
import 'app_state.dart';

// Global navigator key — needed for deep link navigation from widget
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(SavingsModelAdapter());
  Hive.registerAdapter(IncomeModelAdapter());
  Hive.registerAdapter(LoanModelAdapter());
  Hive.registerAdapter(WalletModelAdapter());
  Hive.registerAdapter(CategoryBudgetModelAdapter());
  Hive.registerAdapter(TransferModelAdapter());

  await Hive.openBox<ExpenseModel>('expenses');
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox<GoalModel>('goals');
  await Hive.openBox<SavingsModel>('savings');
  await Hive.openBox<IncomeModel>('income');
  await Hive.openBox<LoanModel>('loans');
  await Hive.openBox<WalletModel>('wallets');
  await Hive.openBox<CategoryBudgetModel>('category_budgets');
  await Hive.openBox<TransferModel>('transfers');
  await Hive.openBox('settings');

  await NotificationHelper.init();

  // ── Home widget init ───────────────────────────────────────────────────
  await HomeWidget.setAppGroupId('group.com.blazefang.spendly');
  await WidgetHelper.updateWidget(); // push initial data to widget

  final settingsBox  = Hive.box('settings');
  final notifEnabled =
  settingsBox.get('notifEnabled', defaultValue: false) as bool;
  if (notifEnabled) {
    final notifDaily  =
    settingsBox.get('notifDaily',  defaultValue: true) as bool;
    final notifWeekly =
    settingsBox.get('notifWeekly', defaultValue: true) as bool;
    final hour   = settingsBox.get('notifHour',   defaultValue: 21) as int;
    final minute = settingsBox.get('notifMinute', defaultValue: 0)  as int;

    if (notifDaily) {
      await NotificationHelper.scheduleDailyReminder(
          hour: hour, minute: minute);
    }
    if (notifWeekly) {
      final weeklyDay    =
      settingsBox.get('notifWeeklyDay',    defaultValue: 6) as int;
      final weeklyHour   =
      settingsBox.get('notifWeeklyHour',   defaultValue: 9) as int;
      final weeklyMinute =
      settingsBox.get('notifWeeklyMinute', defaultValue: 0) as int;
      await NotificationHelper.scheduleWeeklySummary(
        weekday: weeklyDay,
        hour:    weeklyHour,
        minute:  weeklyMinute,
      );
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CategoryBudgetProvider()),
        ChangeNotifierProvider(create: (_) => TransferProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  static const _widgetChannel = MethodChannel('com.blazefang.spendly/widget');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for widget button taps sent directly from MainActivity via MethodChannel
    _widgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final action = call.arguments as String?;
        if (action == 'add_expense') {
          _pushScreenWhenReady(() => const AddExpenseScreen());
        } else if (action == 'income') {
          _pushScreenWhenReady(() => const IncomeScreen());
        }
      }
    });
  }

  bool _widgetPushInFlight = false;

  void _pushScreenWhenReady(Widget Function() builder, [int attempts = 0]) {
    if (_widgetPushInFlight) return; // already pushed/pushing — ignore duplicates
    if (attempts > 50) return; // give up after ~10 seconds

    final state = navigatorKey.currentState;

    // SplashScreen does its own pushReplacement ~1.5s after creation. If we
    // push our screen before that happens, the splash's pushReplacement will
    // replace OUR route instead of itself, kicking the user back to home.
    // So wait until splash has signaled it's done navigating.
    if (state != null && splashNavigationDone) {
      _widgetPushInFlight = true;
      state.push(
        MaterialPageRoute(builder: (_) => builder()),
      ).then((_) {
        _widgetPushInFlight = false; // reset once user navigates back
      });
      return;
    }

    Future.delayed(
      const Duration(milliseconds: 200),
          () => _pushScreenWhenReady(builder, attempts + 1),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh widget data every time app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetHelper.updateWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // needed for deep link navigation
      theme:     AppTheme.light(settings.themeColor),
      darkTheme: AppTheme.dark(settings.themeColor),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}