import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/income_provider.dart';
import '../providers/loan_provider.dart';
import '../utils/csv_helper.dart';
import 'about_screen.dart';
import '../utils/category_icons.dart';
import '../models/category_model.dart';
import '../utils/app_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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

          _SectionHeader('Sound'),
          _SettingTile(
            icon: Icons.volume_up_rounded,
            title: 'Sound Effects',
            trailing: Switch.adaptive(
              value: settings.soundEnabled,
              onChanged: (_) => settings.toggleSound(),
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader('Budget & Currency'),
          _SettingTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Monthly Budget',
            subtitle: settings.monthlyBudget > 0
                ? '${settings.currencySymbol}${settings.monthlyBudget.toStringAsFixed(2)}'
                : 'Not set',
            onTap: () => _editBudget(context, settings),
          ),
          _SettingTile(
            icon: Icons.currency_exchange_rounded,
            title: 'Currency',
            subtitle: settings.currency,
            onTap: () => _pickCurrency(context, settings),
          ),
          const SizedBox(height: 16),

          _SectionHeader('Categories'),
          _SettingTile(
            icon: Icons.category_rounded,
            title: 'Manage Categories',
            onTap: () => _manageCategories(context),
          ),
          const SizedBox(height: 16),

          _SectionHeader('Data'),
          _SettingTile(
            icon: Icons.download_rounded,
            title: 'Export as CSV',
            onTap: () async {
              final expenses = context.read<ExpenseProvider>();
              final categories = context.read<CategoryProvider>();
              final catMap = {
                for (final c in categories.categories) c.id: c
              };
              await CsvHelper.exportExpenses(
                  expenses.allExpenses, catMap, settings.currencySymbol);
            },
          ),
          _SettingTile(
            icon: Icons.delete_forever_rounded,
            title: 'Clear All Data',
            titleColor: Colors.red,
            onTap: () => _confirmClear(context),
          ),
          const SizedBox(height: 32),

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
        ],
      ),
    );
  }

  void _editBudget(BuildContext context, SettingsProvider settings) {
    final ctrl = TextEditingController(
        text: settings.monthlyBudget > 0
            ? settings.monthlyBudget.toStringAsFixed(2)
            : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly Budget'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Enter budget amount'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) settings.setMonthlyBudget(val);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _pickCurrency(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final theme = Theme.of(ctx);

        final regions = {
          'Americas': ['USD', 'CAD', 'AUD', 'BRL', 'MXN'],
          'Europe': ['EUR', 'GBP', 'CHF', 'RUB', 'TRY', 'SEK', 'NOK'],
          'Middle East & Africa': ['AED', 'SAR', 'IRR', 'AFN', 'IQD', 'KWD', 'QAR'],
          'Asia': ['JPY', 'CNY', 'KRW', 'INR', 'PKR', 'BDT', 'THB', 'VND', 'SGD', 'HKD'],
        };

        final allCurrencies = {
          for (final c in SettingsProvider.currencies) c['code']!: c['label']!
        };

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
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
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
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
                              color:
                              theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              settings.currency,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (settings.currency != 'USD')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                              const Color(0xFFFF9800).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: Color(0xFFFF9800), size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Changing currency only updates the symbol. Amounts are not converted.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF9800),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: regions.entries.map((region) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.fromLTRB(4, 16, 4, 8),
                            child: Text(
                              region.key.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          ...region.value.map((code) {
                            final label = allCurrencies[code] ?? code;
                            final isSelected = settings.currency == code;
                            return GestureDetector(
                              onTap: () async {
                                Navigator.pop(ctx);
                                if (code == settings.currency) return;
                                final shouldChange =
                                await _showCurrencyWarning(
                                    context, settings.currency, code);
                                if (shouldChange == true) {
                                  settings.setCurrency(code);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      .withOpacity(0.08)
                                      : (isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.grey.shade50),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        .withOpacity(0.3)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded,
                                          color: theme.colorScheme.primary,
                                          size: 20),
                                  ],
                                ),
                              ),
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
      },
    );
  }

  Future<bool?> _showCurrencyWarning(
      BuildContext context, String fromCode, String toCode) {
    final fromLabel = SettingsProvider.currencies
        .firstWhere((c) => c['code'] == fromCode,
        orElse: () => {'label': fromCode})['label']!;
    final toLabel = SettingsProvider.currencies
        .firstWhere((c) => c['code'] == toCode,
        orElse: () => {'label': toCode})['label']!;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.currency_exchange_rounded,
                  color: Color(0xFFFF9800), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Change Currency?',
                  style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 14, height: 1.5, color: Colors.black87),
                children: [
                  const TextSpan(text: 'Switching from '),
                  TextSpan(
                    text: fromLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' to '),
                  TextSpan(
                    text: toLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.2)),
              ),
              child: const Text(
                'Your existing expenses will show the same numbers with the new currency symbol. Amounts will NOT be converted.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFFF9800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'To start fresh, go to Settings → Clear All Data after changing.',
              style:
              TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Change Anyway'),
          ),
        ],
      ),
    );
  }

  void _manageCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _CategoriesPage()),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete all expenses, savings, goals and settings. Are you sure?'),
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

// ------------- Section Header -------------

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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// ------------- Setting Tile -------------

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
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
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
        ),
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

// ------------- Categories Management Page -------------

class _CategoriesPage extends StatelessWidget {
  const _CategoriesPage();

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>();
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
    Color selectedColor = const Color(0xFF1E3A5F);

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
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
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
                    spacing: 8,
                    runSpacing: 8,
                    children: CategoryIcons.pickerIcons.map((item) {
                      final key = item['key'] as String;
                      final icon = item['icon'] as IconData;
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
                                  ? selectedColor
                                  : Colors.grey,
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
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      const Color(0xFF1E3A5F),
                      const Color(0xFF4A90E2),
                      const Color(0xFF2ECC71),
                      const Color(0xFFE57373),
                      const Color(0xFFFF9800),
                      const Color(0xFF9C27B0),
                      const Color(0xFF00BCD4),
                      const Color(0xFFFF6B6B),
                      const Color(0xFF4ECDC4),
                      const Color(0xFFFFBE76),
                      const Color(0xFF96CEB4),
                      const Color(0xFFE91E63),
                    ].map((color) {
                      final isSelected =
                          selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
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
                        ctx
                            .read<CategoryProvider>()
                            .addCustomCategory(
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
                ],           // closes children: [
              ),             // closes Column(
            ),               // closes SingleChildScrollView(
          ),                 // closes Container(
        ),                   // closes Padding(  ← return of StatefulBuilder
      ),                     // closes StatefulBuilder(  ← THIS was missing
    );                       // closes showModalBottomSheet(
  }
}