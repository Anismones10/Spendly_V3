import 'package:flutter/material.dart';
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
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
        padding: const EdgeInsets.all(16),
        children: [
          // ── Notifications ─────────────────────────────────────────────
          _SectionHeader('Notifications'),
          _SettingTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Reminders, alerts and summaries',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // ── Security ──────────────────────────────────────────────────
          _SectionHeader('Security'),
          const _SecuritySection(),
          const SizedBox(height: 16),

          // ── Appearance ────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          _SettingTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            trailing: Switch.adaptive(
              value: settings.isDarkMode,
              onChanged: (_) => settings.toggleDarkMode(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Sound ─────────────────────────────────────────────────────
          _SectionHeader('Sound'),
          _SettingTile(
            icon: Icons.volume_up_rounded,
            title: 'Sound Effects',
            trailing: Switch.adaptive(
              value: settings.soundEnabled,
              onChanged: (_) => settings.toggleSound(),
            ),
          ),
          _SettingTile(
            icon: Icons.vibration_rounded,
            title: 'Haptic Feedback',
            trailing: Switch.adaptive(
              value: settings.hapticEnabled,
              onChanged: (_) => settings.toggleHaptic(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Currency ──────────────────────────────────────────────────
          _SectionHeader('Currency'),
          _SettingTile(
            icon: Icons.currency_exchange_rounded,
            title: 'Currency',
            subtitle: settings.currency,
            onTap: () => _pickCurrency(context, settings),
          ),
          const SizedBox(height: 16),

          // ── Wallets ───────────────────────────────────────────────────
          _SectionHeader('Wallets'),
          _SettingTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Manage Wallets',
            subtitle: 'Cash, Card, Bank accounts',
            onTap: () => _manageWallets(context),
          ),
          _SettingTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Transfer Between Wallets',
            subtitle: 'Move money from one wallet to another',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransferScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // ── Budget ────────────────────────────────────────────────────
          _SectionHeader('Budget'),
          _SettingTile(
            icon: Icons.pie_chart_rounded,
            title: 'Category Budgets',
            subtitle: 'Set spending limits per category',
            onTap: () => _manageCategoryBudgets(context),
          ),
          const SizedBox(height: 16),

          // ── Categories ────────────────────────────────────────────────
          _SectionHeader('Categories'),
          _SettingTile(
            icon: Icons.category_rounded,
            title: 'Manage Categories',
            onTap: () => _manageCategories(context),
          ),
          const SizedBox(height: 16),

          // ── Data ──────────────────────────────────────────────────────
          _SectionHeader('Data'),
          _SettingTile(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Export PDF Report',
            subtitle: 'Full report with charts, pies & tables',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExportScreen()),
            ),
          ),
          _SettingTile(
            icon: Icons.download_rounded,
            title: 'Export Expenses (CSV)',
            subtitle: 'Save expenses as CSV',
            onTap: () async {
              final expenses   = context.read<ExpenseProvider>();
              final categories = context.read<CategoryProvider>();
              final catMap = {
                for (final c in categories.categories) c.id: c
              };
              await CsvHelper.exportExpenses(
                  expenses.allExpenses, catMap, settings.currencySymbol);
            },
          ),
          _SettingTile(
            icon: Icons.download_rounded,
            title: 'Export Income (CSV)',
            subtitle: 'Save income as CSV',
            onTap: () async {
              final income = context.read<IncomeProvider>();
              await CsvHelper.exportIncome(
                  income.allIncome, settings.currencySymbol);
            },
          ),
          _SettingTile(
            icon: Icons.download_rounded,
            title: 'Export Loans (CSV)',
            subtitle: 'Save lending & borrowing as CSV',
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
            onTap: () async {
              final expenses   = context.read<ExpenseProvider>();
              final categories = context.read<CategoryProvider>();
              final income     = context.read<IncomeProvider>();
              final loans      = context.read<LoanProvider>();
              final catMap = {
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
          _SettingTile(
            icon: Icons.delete_forever_rounded,
            title: 'Clear All Data',
            titleColor: Colors.red,
            onTap: () => _confirmClear(context),
          ),
          const SizedBox(height: 32),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader('About'),
          _SettingTile(
            icon: Icons.info_outline_rounded,
            title: 'About Spendly',
            subtitle: 'Version 1.1.0 · Made by Mones',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
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
            onPressed: () {
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
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ── Security Section ──────────────────────────────────────────────────────────

class _SecuritySection extends StatefulWidget {
  const _SecuritySection();

  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  final Box _box  = Hive.box('settings');
  final LocalAuthentication _auth = LocalAuthentication();

  bool get _lockEnabled => _box.get('lockEnabled',   defaultValue: false) as bool;
  bool get _bioEnabled  => _box.get('lockBiometric', defaultValue: true)  as bool;
  int  get _timeoutMins => _box.get('lockTimeout',   defaultValue: 30)    as int;

  static const _timeoutOptions = [0, 1, 5, 15, 30];
  static const _timeoutLabels  = ['Immediately', '1 min', '5 min', '15 min', '30 min'];

  Future<void> _toggleLock(bool value) async {
    if (value) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SetPinScreen()),
      );
      if (result == true) setState(() {});
    } else {
      // Must verify PIN before disabling
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => const SetPinScreen(isChanging: true)),
      );
      if (result == true) {
        _box.put('lockEnabled', false);
        _box.put('lockPin', '');
        setState(() {});
      }
    }
  }

  Future<void> _changePin() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => const SetPinScreen(isChanging: true)),
    );
    setState(() {});
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (value && !canCheck) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometrics not available on this device.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    } catch (_) {}
    _box.put('lockBiometric', value);
    setState(() {});
  }

  void _showTimeoutPicker() {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            const Text('Lock After',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('How long in background before locking',
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.45))),
            const SizedBox(height: 16),
            ...List.generate(_timeoutOptions.length, (i) {
              final isSelected = _timeoutMins == _timeoutOptions[i];
              return GestureDetector(
                onTap: () {
                  _box.put('lockTimeout', _timeoutOptions[i]);
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.08)
                        : (isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.35)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_timeoutLabels[i],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary : null,
                          )),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: theme.colorScheme.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _timeoutLabel() {
    final idx = _timeoutOptions.indexOf(_timeoutMins);
    return idx >= 0 ? _timeoutLabels[idx] : '$_timeoutMins min';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Master lock toggle ──────────────────────────────────────────
        _SettingTile(
          icon: Icons.lock_rounded,
          title: 'App Lock',
          subtitle: _lockEnabled
              ? 'PIN required to open Spendly'
              : 'Tap to enable PIN lock',
          trailing: Switch.adaptive(
            value: _lockEnabled,
            onChanged: _toggleLock,
          ),
        ),

        if (_lockEnabled) ...[
          // ── Change PIN ────────────────────────────────────────────────
          _SettingTile(
            icon: Icons.pin_rounded,
            title: 'Change PIN',
            subtitle: 'Update your current PIN',
            onTap: _changePin,
          ),

          // ── Biometric ─────────────────────────────────────────────────
          _SettingTile(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Unlock',
            subtitle: 'Use fingerprint or face to unlock',
            trailing: Switch.adaptive(
              value: _bioEnabled,
              onChanged: _toggleBiometric,
            ),
          ),

          // ── Timeout ───────────────────────────────────────────────────
          _SettingTile(
            icon: Icons.timer_rounded,
            title: 'Lock After',
            subtitle: _timeoutLabel() + ' of background',
            onTap: _showTimeoutPicker,
          ),
        ],
      ],
    );
  }
}

// ── Category Budgets Page ─────────────────────────────────────────────────────

class _CategoryBudgetsPage extends StatelessWidget {
  const _CategoryBudgetsPage();

  @override
  Widget build(BuildContext context) {
    final cats     = context.watch<CategoryProvider>().categories;
    final budgets  = context.watch<CategoryBudgetProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol   = settings.currencySymbol;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final theme    = Theme.of(context);
    final now      = DateTime.now();
    final catTotals = expenses.getCategoryTotals(now.year, now.month);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Category Budgets'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Set a monthly spending limit per category. Warned at 80% and 100%.',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          ...cats.map((cat) {
            final hasBudget  = budgets.hasBudget(cat.id);
            final limit      = budgets.getLimitFor(cat.id);
            final spent      = catTotals[cat.id] ?? 0;
            final catColor   = Color(cat.colorValue);
            final statusColor = hasBudget
                ? budgets.getStatusColor(cat.id, spent)
                : catColor;
            final pct = hasBudget && limit > 0
                ? (spent / limit).clamp(0.0, 1.0)
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(CategoryIcons.resolve(cat.icon),
                            color: catColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            if (hasBudget)
                              Text(
                                'Spent ${AppUtils.formatAmount(spent, symbol)} of ${AppUtils.formatAmount(limit, symbol)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.w500),
                              )
                            else
                              Text('No budget set',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4))),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _showBudgetSheet(context, cat, limit),
                        child: Text(hasBudget ? 'Edit' : 'Set',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary)),
                      ),
                      if (hasBudget)
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: Colors.red),
                          onPressed: () => budgets.removeBudget(cat.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  if (hasBudget) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(children: [
                        Container(
                            height: 6,
                            color: statusColor.withOpacity(0.12)),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showBudgetSheet(
      BuildContext context, dynamic cat, double currentLimit) {
    final ctrl = TextEditingController(
        text: currentLimit > 0 ? currentLimit.toStringAsFixed(2) : '');
    final settings = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Color(cat.colorValue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(CategoryIcons.resolve(cat.icon),
                      color: Color(cat.colorValue), size: 20),
                ),
                const SizedBox(width: 12),
                Text('Budget for ${cat.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Monthly limit',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  suffixText: settings.currencySymbol,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final limit = double.tryParse(ctrl.text);
                    if (limit != null && limit > 0) {
                      ctx.read<CategoryBudgetProvider>()
                          .setBudget(cat.id, limit);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Budget'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wallets Page ──────────────────────────────────────────────────────────────

class _WalletsPage extends StatelessWidget {
  const _WalletsPage();

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final wallets  = walletProvider.wallets;
    final settings = context.watch<SettingsProvider>();
    final symbol   = settings.currencySymbol;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final theme    = Theme.of(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Wallets'),
        actions: [
          if (wallets.length >= 2)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Transfer',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TransferScreen())),
            ),
        ],
      ),
      body: wallets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  Text('No wallets yet',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 16)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 16, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Balance',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(
                              AppUtils.formatAmount(
                                  walletProvider.totalBalance, symbol),
                              style: const TextStyle(
                                color: Colors.white, fontSize: 24,
                                fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      if (wallets.length >= 2)
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const TransferScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Transfer',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ...wallets.map((wallet) => _WalletTile(
                      wallet: wallet, symbol: symbol,
                      onEdit: () =>
                          _showWalletSheet(context, existing: wallet),
                      onDelete: wallets.length > 1
                          ? () => walletProvider.deleteWallet(wallet.id)
                          : null,
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWalletSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Wallet'),
      ),
    );
  }

  void _showWalletSheet(BuildContext context, {WalletModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletSheet(existing: existing),
    );
  }
}

class _WalletTile extends StatelessWidget {
  final WalletModel wallet;
  final String symbol;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _WalletTile({
    required this.wallet, required this.symbol,
    required this.onEdit, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = Color(wallet.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(WalletProvider.resolveIcon(wallet.type),
                color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text(wallet.type.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11, color: color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppUtils.formatAmount(wallet.balance, symbol),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15,
                      color: color)),
              Text('balance',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4))),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4)),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (onDelete != null) ...[
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletSheet extends StatefulWidget {
  final WalletModel? existing;
  const _WalletSheet({this.existing});

  @override
  State<_WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends State<_WalletSheet> {
  final _nameCtrl = TextEditingController();
  String _selectedType = 'cash';
  late Color _selectedColor;

  static const List<Color> _palette = [
    Color(0xFF4CAF50), Color(0xFF1E3A5F), Color(0xFF2196F3),
    Color(0xFF9C27B0), Color(0xFFE57373), Color(0xFFFF9800),
    Color(0xFF00BCD4), Color(0xFFFF6B6B), Color(0xFF4ECDC4),
    Color(0xFFFFBE76), Color(0xFF6C63FF), Color(0xFFE91E63),
  ];

  final List<Map<String, dynamic>> _types = [
    {'type': 'cash',    'label': 'Cash',    'icon': Icons.payments_rounded},
    {'type': 'card',    'label': 'Card',    'icon': Icons.credit_card_rounded},
    {'type': 'bank',    'label': 'Bank',    'icon': Icons.account_balance_rounded},
    {'type': 'savings', 'label': 'Savings', 'icon': Icons.savings_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text  = widget.existing!.name;
      _selectedType   = widget.existing!.type;
      _selectedColor  = Color(widget.existing!.colorValue);
    } else {
      _selectedColor = Color(WalletProvider.colorForType(_selectedType));
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final provider = context.read<WalletProvider>();
    final balance  = widget.existing?.balance ?? 0;
    final wallet   = WalletModel(
      id: widget.existing?.id ?? AppUtils.generateId(),
      name: name, type: _selectedType, balance: balance,
      colorValue: _selectedColor.value, icon: _selectedType,
    );
    if (widget.existing != null) {
      provider.updateWallet(wallet);
    } else {
      provider.addWallet(wallet);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              Text(widget.existing != null ? 'Edit Wallet' : 'New Wallet',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Wallet name',
                  prefixIcon: Icon(Icons.label_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: _types.map((t) {
                  final isSelected = _selectedType == t['type'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedType  = t['type'] as String;
                        _selectedColor = Color(
                            WalletProvider.colorForType(_selectedType));
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withOpacity(0.15)
                              : (isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _selectedColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(t['icon'] as IconData,
                                color: isSelected
                                    ? _selectedColor
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.35),
                                size: 20),
                            const SizedBox(height: 4),
                            Text(t['label'] as String,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? _selectedColor
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.4))),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Color',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _palette.map((color) {
                  final isSelected = _selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 10, spreadRadius: 2)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.existing != null
                      ? 'Save Changes' : 'Add Wallet'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Categories Page ───────────────────────────────────────────────────────────

class _CategoriesPage extends StatelessWidget {
  const _CategoriesPage();

  @override
  Widget build(BuildContext context) {
    final cats   = context.watch<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Categories'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: cats.categories.map((cat) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(cat.colorValue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CategoryIcons.resolve(cat.icon),
                    color: Color(cat.colorValue), size: 20),
              ),
              title: Text(cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: cat.isCustom
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red),
                      onPressed: () => cats.deleteCustomCategory(cat.id),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Default',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(cat.colorValue),
                              fontWeight: FontWeight.w600)),
                    ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategory(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddCategory(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedIconKey = 'star';
    Color  selectedColor   = const Color(0xFF1E3A5F);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Category',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Category name',
                        prefixIcon: Icon(Icons.label_rounded)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icon',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: CategoryIcons.pickerIcons.map((item) {
                      final key        = item['key'] as String;
                      final icon       = item['icon'] as IconData;
                      final isSelected = selectedIconKey == key;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedIconKey = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor.withOpacity(0.15)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.grey.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon,
                              color: isSelected
                                  ? selectedColor : Colors.grey,
                              size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      const Color(0xFF1E3A5F), const Color(0xFF4A90E2),
                      const Color(0xFF2ECC71), const Color(0xFFE57373),
                      const Color(0xFFFF9800), const Color(0xFF9C27B0),
                      const Color(0xFF00BCD4), const Color(0xFFFF6B6B),
                      const Color(0xFF4ECDC4), const Color(0xFFFFBE76),
                      const Color(0xFF96CEB4), const Color(0xFFE91E63),
                    ].map((color) {
                      final isSelected =
                          selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8, spreadRadius: 2)]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        ctx.read<CategoryProvider>().addCustomCategory(
                          CategoryModel(
                            id: AppUtils.generateId(),
                            name: name,
                            colorValue: selectedColor.value,
                            icon: selectedIconKey,
                            isCustom: true,
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add Category'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingTile({
    required this.icon, required this.title,
    this.subtitle, this.trailing, this.onTap, this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon,
            color: Theme.of(context).colorScheme.primary),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: titleColor)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded)
                : null),
        onTap: onTap,
      ),
    );
  }
}

// ── Currency Picker Sheet ─────────────────────────────────────────────────────

class _CurrencyPickerSheet extends StatefulWidget {
  final SettingsProvider settings;
  const _CurrencyPickerSheet({required this.settings});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const Map<String, List<String>> _regions = {
    'Americas': ['USD', 'CAD', 'AUD', 'BRL', 'MXN'],
    'Europe':   ['EUR', 'GBP', 'CHF', 'RUB', 'TRY', 'SEK', 'NOK'],
    'Middle East & Africa': ['AED', 'SAR', 'IRR', 'AFN', 'IQD', 'KWD', 'QAR'],
    'Asia': ['JPY', 'CNY', 'KRW', 'INR', 'PKR', 'BDT', 'THB', 'VND', 'SGD', 'HKD'],
  };

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme  = Theme.of(context);
    final allCurrencies = {
      for (final c in SettingsProvider.currencies) c['code']!: c['label']!
    };

    final isSearching = _query.isNotEmpty;
    final filtered = isSearching
        ? SettingsProvider.currencies
            .where((c) =>
                c['code']!.toLowerCase().contains(_query) ||
                c['label']!.toLowerCase().contains(_query))
            .toList()
        : <Map<String, String>>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: [
                  Center(child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2)),
                  )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Select Currency',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(widget.settings.currency,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _query = v.toLowerCase().trim()),
                    decoration: InputDecoration(
                      hintText: 'Search currency (e.g. USD, Euro, Yen...)',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: isSearching
                  ? filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text('No currency found',
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final code  = filtered[i]['code']!;
                            final label = filtered[i]['label']!;
                            return _CurrencyTile(
                              code: code, label: label,
                              isSelected: widget.settings.currency == code,
                              theme: theme, isDark: isDark,
                              onTap: () {
                                Navigator.pop(context);
                                widget.settings.setCurrency(code);
                              },
                            );
                          },
                        )
                  : ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: _regions.entries.map((region) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                              child: Text(region.key.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: theme.colorScheme.primary)),
                            ),
                            ...region.value.map((code) {
                              final label = allCurrencies[code] ?? code;
                              return _CurrencyTile(
                                code: code, label: label,
                                isSelected: widget.settings.currency == code,
                                theme: theme, isDark: isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.settings.setCurrency(code);
                                },
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
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
