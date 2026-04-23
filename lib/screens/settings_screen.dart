import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/goal_provider.dart';
import '../utils/csv_helper.dart';
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

          Center(
            child: Text(
              'Expense Tracker v1.0.0',
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Currency',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...SettingsProvider.currencies.map(
              (c) => ListTile(
                title: Text(c['label']!),
                trailing: settings.currency == c['code']
                    ? const Icon(Icons.check_rounded, color: Color(0xFF6C63FF))
                    : null,
                onTap: () {
                  settings.setCurrency(c['code']!);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
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
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ctx.read<ExpenseProvider>().clearAll();
              ctx.read<CategoryProvider>().clearAll();
              ctx.read<SavingsProvider>().clearAll();
              ctx.read<GoalProvider>().clearAll();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: titleColor),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
        onTap: onTap,
      ),
    );
  }
}

// ------------- Categories management page -------------

class _CategoriesPage extends StatelessWidget {
  const _CategoriesPage();

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Category',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Category name',
                      prefixIcon: Icon(Icons.label_rounded)),
                ),
                const SizedBox(height: 16),
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryIcons.pickerIcons.map((item) {
                    final key = item['key'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected = selectedIconKey == key;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIconKey = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor.withOpacity(0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? selectedColor : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon,
                            color: isSelected ? selectedColor : Colors.grey,
                            size: 24),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
