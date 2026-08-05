import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/income_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/category_budget_provider.dart';
import '../providers/transfer_provider.dart';
import '../models/wallet_model.dart';
import '../utils/csv_helper.dart';
import '../screens/transfer_screen.dart';
import '../screens/export_screen.dart';
import '../screens/set_pin_screen.dart';
import 'about_screen.dart';
import 'notification_settings_screen.dart';
import '../utils/category_icons.dart';
import '../models/category_model.dart';
import '../utils/app_utils.dart';
import '../utils/app_theme.dart';
import '../utils/pin_helper.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'login_screen.dart' as login_nav;

// ── Widgets for this screen live in part files under settings/ ───────────────
part 'settings/security_section.dart';
part 'settings/category_budgets_page.dart';
part 'settings/wallets_page.dart';
part 'settings/categories_page.dart';
part 'settings/settings_widgets.dart';
part 'settings/currency_picker_sheet.dart';
part 'settings/smooth_switch.dart';
part 'settings/color_theme_tile.dart';
part 'settings/mini_key.dart';
part 'settings/sync_tile.dart';
part 'settings/account_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use read so toggling switches does NOT rebuild the whole screen
    final settings = context.read<SettingsProvider>();
    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [

          // ── General ───────────────────────────────────────────────────
          _ExpandableSection(
            icon: Icons.tune_rounded,
            title: 'General',
            color: const Color(0xFF5C6BC0),
            initiallyExpanded: false,
            children: [
              _SettingTile(
                icon: Icons.dark_mode_rounded,
                subtitleColor: const Color(0xFF5C6BC0),
                iconColor: const Color(0xFF5C6BC0),
                title: 'Dark Mode',
                trailing: _SmoothSwitch(hiveKey: 'darkMode', defaultValue: false, onToggle: () => settings.toggleDarkMode()),
              ),
              _SettingTile(
                icon: Icons.volume_up_rounded,
                subtitleColor: const Color(0xFF7E57C2),
                iconColor: const Color(0xFF7E57C2),
                title: 'Sound Effects',
                trailing: _SmoothSwitch(hiveKey: 'soundEnabled', defaultValue: true, onToggle: () => settings.toggleSound()),
              ),
              _SettingTile(
                icon: Icons.vibration_rounded,
                subtitleColor: const Color(0xFF26C6DA),
                iconColor: const Color(0xFF26C6DA),
                title: 'Haptic Feedback',
                trailing: _SmoothSwitch(hiveKey: 'hapticEnabled', defaultValue: true, onToggle: () => settings.toggleHaptic()),
              ),
              Consumer<SettingsProvider>(
                builder: (ctx, s, _) => _SettingTile(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Currency',
                  subtitle: s.currency,
                  subtitleColor: const Color(0xFF43A047),
                  iconColor: const Color(0xFF43A047),
                  onTap: () => _pickCurrency(ctx, s),
                ),
              ),
              // ── Color theme picker ─────────────────────────────────────
              Consumer<SettingsProvider>(
                builder: (_, s, __) => _ColorThemeTile(settings: s),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Notifications ─────────────────────────────────────────────
          _ExpandableSection(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            color: const Color(0xFFEF6C00),
            children: [
              _SettingTile(
                icon: Icons.notifications_active_rounded,
                title: 'Notification Settings',
                subtitle: 'Reminders, budget alerts & weekly summary',
                subtitleColor: const Color(0xFFEF6C00),
                iconColor: const Color(0xFFEF6C00),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen())),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Security ──────────────────────────────────────────────────
          _ExpandableSection(
            icon: Icons.security_rounded,
            title: 'Security',
            color: const Color(0xFF26A69A),
            children: const [_SecuritySection()],
          ),
          const SizedBox(height: 10),

          // ── Wallets & Budget ──────────────────────────────────────────
          _ExpandableSection(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Wallets & Budget',
            color: const Color(0xFF42A5F5),
            children: [
              _SettingTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Manage Wallets',
                subtitle: 'Cash, Card, Bank accounts',
                subtitleColor: const Color(0xFF42A5F5),
                iconColor: const Color(0xFF42A5F5),
                onTap: () => _manageWallets(context),
              ),
              _SettingTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Transfer Between Wallets',
                subtitle: 'Move money from one wallet to another',
                subtitleColor: const Color(0xFF7E57C2),
                iconColor: const Color(0xFF7E57C2),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TransferScreen())),
              ),
              _SettingTile(
                icon: Icons.pie_chart_rounded,
                title: 'Category Budgets',
                subtitle: 'Set spending limits per category',
                subtitleColor: const Color(0xFFEF6C00),
                iconColor: const Color(0xFFEF6C00),
                onTap: () => _manageCategoryBudgets(context),
              ),
              _SettingTile(
                icon: Icons.category_rounded,
                title: 'Manage Categories',
                onTap: () => _manageCategories(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Export ────────────────────────────────────────────────────
          _ExpandableSection(
            icon: Icons.ios_share_rounded,
            title: 'Export',
            color: const Color(0xFF66BB6A),
            children: [
              _SettingTile(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Export PDF Report',
                subtitle: 'Full report with charts, pies & tables',
                subtitleColor: const Color(0xFFE53935),
                iconColor: const Color(0xFFE53935),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExportScreen())),
              ),
              _SettingTile(
                icon: Icons.receipt_long_rounded,
                title: 'Export Expenses (CSV)',
                subtitle: 'Save expenses as spreadsheet',
                subtitleColor: const Color(0xFF42A5F5),
                iconColor: const Color(0xFF42A5F5),
                onTap: () async {
                  final expenses   = context.read<ExpenseProvider>();
                  final categories = context.read<CategoryProvider>();
                  final Map<String, CategoryModel> catMap = {
                    for (final c in categories.categories) c.id: c
                  };
                  await CsvHelper.exportExpenses(
                      expenses.allExpenses, catMap, settings.currencySymbol);
                },
              ),
              _SettingTile(
                icon: Icons.trending_up_rounded,
                title: 'Export Income (CSV)',
                subtitle: 'Save income as spreadsheet',
                subtitleColor: const Color(0xFF66BB6A),
                iconColor: const Color(0xFF66BB6A),
                onTap: () async {
                  final income = context.read<IncomeProvider>();
                  await CsvHelper.exportIncome(
                      income.allIncome, settings.currencySymbol);
                },
              ),
              _SettingTile(
                icon: Icons.handshake_rounded,
                title: 'Export Loans (CSV)',
                subtitle: 'Save lending & borrowing as spreadsheet',
                subtitleColor: const Color(0xFFEF6C00),
                iconColor: const Color(0xFFEF6C00),
                onTap: () async {
                  final loans = context.read<LoanProvider>();
                  await CsvHelper.exportLoans(
                      loans.allLoans, settings.currencySymbol);
                },
              ),
              _SettingTile(
                icon: Icons.download_for_offline_rounded,
                title: 'Export All Data (CSV)',
                subtitle: 'Expenses + Income + Loans in one file',
                subtitleColor: const Color(0xFF7E57C2),
                iconColor: const Color(0xFF7E57C2),
                onTap: () async {
                  final expenses   = context.read<ExpenseProvider>();
                  final categories = context.read<CategoryProvider>();
                  final income     = context.read<IncomeProvider>();
                  final loans      = context.read<LoanProvider>();
                  final Map<String, CategoryModel> catMap = {
                    for (final c in categories.categories) c.id: c
                  };
                  await CsvHelper.exportAll(
                    expenses.allExpenses,
                    catMap,
                    income.allIncome,
                    loans.allLoans,
                    settings.currencySymbol,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Data ──────────────────────────────────────────────────────
          _ExpandableSection(
            icon: Icons.storage_rounded,
            title: 'Data',
            color: const Color(0xFFEF5350),
            children: [
              const _SyncTile(),
              _SettingTile(
                icon: Icons.delete_forever_rounded,
                title: 'Clear All Data',
                subtitle: 'Permanently delete everything',
                titleColor: Colors.red,
                subtitleColor: const Color(0xFFEF5350),
                iconColor: const Color(0xFFEF5350),
                onTap: () => _confirmClear(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Account ───────────────────────────────────────────────────
          _ExpandableSection(
            icon: Icons.manage_accounts_rounded,
            title: 'Account',
            color: const Color(0xFF26A69A),
            children: [
              const _AccountTile(
                icon: Icons.switch_account_rounded,
                title: 'Switch Account',
                subtitle: 'Sign out and log in with a different account',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── About ─────────────────────────────────────────────────────
          _ExpandableSection(
            icon: Icons.info_outline_rounded,
            title: 'About',
            color: const Color(0xFF78909C),
            children: [
              _SettingTile(
                icon: Icons.info_outline_rounded,
                title: 'About Spendly',
                subtitle: 'Version 1.1.0 · Made by Mones',
                subtitleColor: const Color(0xFF78909C),
                iconColor: const Color(0xFF78909C),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AboutScreen())),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              'Spendly v1.1.0',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.3)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _manageCategoryBudgets(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const _CategoryBudgetsPage()));

  void _manageWallets(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const _WalletsPage()));

  void _pickCurrency(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyPickerSheet(settings: settings),
    );
  }

  void _manageCategories(BuildContext context) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const _CategoriesPage()));

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete all data including wallets, budgets, transfers and settings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              ctx.read<ExpenseProvider>().clearAll();
              ctx.read<CategoryProvider>().clearAll();
              ctx.read<SavingsProvider>().clearAll();
              ctx.read<GoalProvider>().clearAll();
              ctx.read<IncomeProvider>().clearAll();
              ctx.read<LoanProvider>().clearAll();
              ctx.read<WalletProvider>().clearAll();
              ctx.read<CategoryBudgetProvider>().clearAll();
              ctx.read<TransferProvider>().clearAll();
              ctx.read<SettingsProvider>().clearAllData();
              // Also clear Firestore so it doesn't restore on next login
              SyncService.clearCloudData();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
