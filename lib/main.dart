import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/expense_model.dart';
import 'models/category_model.dart';
import 'models/goal_model.dart';
import 'models/savings_model.dart';
import 'models/income_model.dart';
import 'models/loan_model.dart';
import 'providers/expense_provider.dart';
import 'providers/category_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/savings_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/income_provider.dart';
import 'providers/loan_provider.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(SavingsModelAdapter());
  Hive.registerAdapter(IncomeModelAdapter());
  Hive.registerAdapter(LoanModelAdapter());

  await Hive.openBox<ExpenseModel>('expenses');
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox<GoalModel>('goals');
  await Hive.openBox<SavingsModel>('savings');
  await Hive.openBox<IncomeModel>('income');
  await Hive.openBox<LoanModel>('loans');
  await Hive.openBox('settings');

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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
