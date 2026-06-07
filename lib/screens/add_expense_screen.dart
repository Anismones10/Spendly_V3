import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/category_budget_provider.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';
import '../utils/sound_helper.dart';
import '../widgets/calculator_sheet.dart';
import '../utils/notification_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? existing;
  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isRecurring = false;
  String _recurringType = 'monthly';
  bool _reorderMode = false;

  // Multi-item support
  bool _useItems = false;
  final List<_ExpenseItem> _items = [];

  void _addItem() {
    setState(() => _items.add(_ExpenseItem()));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    _recalcTotal();
  }

  void _recalcTotal() {
    final total = _items.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item.amountCtrl.text) ?? 0);
    });
    setState(() => _amountController.text =
        total > 0 ? total.toStringAsFixed(2) : '');
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _amountController.text = e.amount.toString();
      _selectedCategoryId = e.categoryId;
      _selectedWalletId = e.walletId;
      _selectedDate = e.date;
      _isRecurring = e.isRecurring;
      _recurringType = e.recurringType ?? 'monthly';
      if (e.timeHour != null && e.timeMinute != null) {
        _selectedTime = TimeOfDay(hour: e.timeHour!, minute: e.timeMinute!);
      }

      // ── Restore multi-items from note if it was saved as bullet list ──────
      final note = e.note ?? '';
      final lines = note
          .split('\n')
          .where((l) => l.trim().startsWith('• '))
          .toList();

      if (lines.length >= 2) {
        // Note contains item list — restore them
        _useItems = true;
        for (final line in lines) {
          final withoutBullet = line.trim().substring(2); // remove "• "
          final lastColon = withoutBullet.lastIndexOf(': ');
          if (lastColon != -1) {
            final itemName   = withoutBullet.substring(0, lastColon).trim();
            final itemAmount = withoutBullet.substring(lastColon + 2).trim();
            final item = _ExpenseItem();
            item.nameCtrl.text   = itemName;
            item.amountCtrl.text = itemAmount;
            _items.add(item);
          }
        }
        // Remove item lines from note — keep any extra note text
        final extraNote = note
            .split('\n')
            .where((l) => !l.trim().startsWith('• '))
            .join('\n')
            .trim();
        _noteController.text = extraNote;
      } else {
        // Normal note — no items
        _noteController.text = note;
      }
    } else {
      // Default time to now
      final now = TimeOfDay.now();
      _selectedTime = now;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final wallets = context.read<WalletProvider>().wallets;
        if (wallets.isNotEmpty && _selectedWalletId == null) {
          setState(() => _selectedWalletId = wallets.first.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    for (final item in _items) {
      item.nameCtrl.dispose();
      item.amountCtrl.dispose();
    }
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (widget.existing != null) {
      final e = widget.existing!;
      return _nameController.text != e.name ||
          _amountController.text != e.amount.toString() ||
          _noteController.text != (e.note ?? '') ||
          _selectedCategoryId != e.categoryId ||
          _selectedWalletId != e.walletId ||
          _selectedDate != e.date ||
          _isRecurring != e.isRecurring;
    }
    return _nameController.text.isNotEmpty ||
        _amountController.text.isNotEmpty ||
        _noteController.text.isNotEmpty ||
        _selectedCategoryId != null;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Text('⚠️', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Discard Changes?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        ]),
        content: const Text(
          'You have unsaved changes. Are you sure you want to go back?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Editing')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openCalculator() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalculatorSheet(
        initial: double.tryParse(_amountController.text) ?? 0,
      ),
    );
    if (result != null) {
      setState(
          () => _amountController.text = result.toStringAsFixed(2));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _clearTime() {
    setState(() => _selectedTime = null);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final min = m.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  double _getWalletRemaining() {
    if (_selectedWalletId == null) return double.infinity;
    final wallets = context.read<WalletProvider>();
    final expenses = context.read<ExpenseProvider>();
    final wallet = wallets.getById(_selectedWalletId!);
    if (wallet == null) return double.infinity;
    final spent = expenses.getTotalForWallet(_selectedWalletId!);
    final currentAmount = widget.existing != null &&
            widget.existing!.walletId == _selectedWalletId
        ? widget.existing!.amount
        : 0.0;
    return wallet.balance - spent + currentAmount;
  }

  Future<void> _save() async {
    // Items mode validation
    if (_useItems && _items.isNotEmpty) {
      final validItems = _items
          .where((i) =>
              i.nameCtrl.text.trim().isNotEmpty &&
              (double.tryParse(i.amountCtrl.text) ?? 0) > 0)
          .toList();
      if (validItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please add at least one valid item.')),
        );
        return;
      }
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a category.')),
        );
        return;
      }
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = validItems.length == 1
            ? validItems.first.nameCtrl.text.trim()
            : 'Shopping (${validItems.length} items)';
      }
      final itemLines = validItems
          .map((i) =>
              '• ${i.nameCtrl.text.trim()}: ${i.amountCtrl.text}')
          .join('\n');
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = itemLines;
      }
    }

    if (_nameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill in all required fields.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount.')),
      );
      return;
    }

    // ── Wallet balance check ─────────────────────────────────────────────────
    if (_selectedWalletId != null) {
      final remaining    = _getWalletRemaining();
      if (amount > remaining) {
        final wallets      = context.read<WalletProvider>();
        final wallet       = wallets.getById(_selectedWalletId!);
        final symbol       = context.read<SettingsProvider>().currencySymbol;
        final canOverdraft = wallet?.allowOverdraft ?? false;

        if (canOverdraft) {
          // ── Soft warning — credit card mode ────────────────────────────
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card_rounded,
                      color: Color(0xFFFF9800), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Balance Warning',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17)),
                ),
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${wallet?.name ?? 'This wallet'} will go negative.',
                    style: const TextStyle(fontSize: 14, height: 1.5),
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
                    child: Column(
                      children: [
                        _BalanceRow(
                            label: 'Available',
                            value: AppUtils.formatAmount(
                                remaining < 0 ? 0 : remaining, symbol),
                            color: const Color(0xFF2ECC71)),
                        const SizedBox(height: 6),
                        _BalanceRow(
                            label: 'This expense',
                            value: AppUtils.formatAmount(amount, symbol),
                            color: const Color(0xFFFF9800)),
                        const Divider(height: 14),
                        _BalanceRow(
                            label: 'Shortfall',
                            value: AppUtils.formatAmount(
                                amount - (remaining < 0 ? 0 : remaining),
                                symbol),
                            color: const Color(0xFFE57373), bold: true),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800)),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Proceed Anyway'),
                ),
              ],
            ),
          );
          if (shouldProceed != true) return;

        } else {
          // ── Hard block — cannot proceed ────────────────────────────────
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE57373).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.block_rounded,
                      color: Color(0xFFE57373), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Insufficient Balance',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17)),
                ),
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${wallet?.name ?? 'This wallet'} doesn\'t have enough balance.',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFE57373).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _BalanceRow(
                            label: 'Available',
                            value: AppUtils.formatAmount(
                                remaining < 0 ? 0 : remaining, symbol),
                            color: const Color(0xFF2ECC71)),
                        const SizedBox(height: 6),
                        _BalanceRow(
                            label: 'This expense',
                            value: AppUtils.formatAmount(amount, symbol),
                            color: const Color(0xFFE57373)),
                        const Divider(height: 14),
                        _BalanceRow(
                            label: 'Shortfall',
                            value: AppUtils.formatAmount(
                                amount - (remaining < 0 ? 0 : remaining),
                                symbol),
                            color: const Color(0xFFE57373), bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enable overdraft in wallet settings to allow this.',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500),
                      ),
                    ),
                  ]),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          );
          return; // hard block
        }
      }
    }


    // Category budget overspend check
    if (_selectedCategoryId != null) {
      final budgets = context.read<CategoryBudgetProvider>();
      if (budgets.hasBudget(_selectedCategoryId!)) {
        final now = DateTime.now();
        final provider = context.read<ExpenseProvider>();
        final catTotals =
            provider.getCategoryTotals(now.year, now.month);
        final alreadySpent =
            catTotals[_selectedCategoryId!] ?? 0;
        final limit = budgets.getLimitFor(_selectedCategoryId!);
        final remaining = limit - alreadySpent;
        final symbol =
            context.read<SettingsProvider>().currencySymbol;
        final catName = context
                .read<CategoryProvider>()
                .getById(_selectedCategoryId!)
                ?.name ??
            '';

        if (amount > remaining) {
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pie_chart_rounded,
                      color: Color(0xFFFF9800), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Over Budget!',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17)),
                ),
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This expense exceeds your "$catName" budget.',
                    style:
                        const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFF9800).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFF9800)
                              .withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _BalanceRow(
                            label: 'Budget left',
                            value: AppUtils.formatAmount(
                                remaining < 0 ? 0 : remaining,
                                symbol),
                            color: const Color(0xFF2ECC71)),
                        const SizedBox(height: 6),
                        _BalanceRow(
                            label: 'This expense',
                            value: AppUtils.formatAmount(
                                amount, symbol),
                            color: const Color(0xFFFF9800)),
                        const Divider(height: 14),
                        _BalanceRow(
                            label: 'Over by',
                            value: AppUtils.formatAmount(
                                amount -
                                    (remaining < 0 ? 0 : remaining),
                                symbol),
                            color: const Color(0xFFE57373),
                            bold: true),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800)),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Proceed Anyway'),
                ),
              ],
            ),
          );
          if (shouldProceed != true) return;
        }
      }
    }

    final expense = ExpenseModel(
      id: widget.existing?.id ?? AppUtils.generateId(),
      name: _nameController.text.trim(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      isRecurring: _isRecurring,
      recurringType: _isRecurring ? _recurringType : null,
      walletId: _selectedWalletId,
      timeHour: _selectedTime?.hour,
      timeMinute: _selectedTime?.minute,
      // Preserve recurring metadata if editing
      recurringParentId: widget.existing?.recurringParentId,
      recurringLastGenerated: widget.existing?.recurringLastGenerated,
    );

    final provider = context.read<ExpenseProvider>();
    if (widget.existing != null) {
      // If editing a recurring parent → ask user what to update
      final isRecurringParent = expense.isRecurring &&
          expense.recurringParentId == null;

      if (isRecurringParent) {
        final updateAll = await _showRecurringUpdateDialog();
        if (updateAll == null) return; // user cancelled
        provider.updateRecurringExpense(expense, updateAll);
      } else {
        provider.updateExpense(expense);
      }
    } else {
      provider.addExpense(expense);
      await SoundHelper.playChaChing();

      if (mounted) {
      final budgets   = context.read<CategoryBudgetProvider>();
      final settings  = context.read<SettingsProvider>();
      final catNames  = context.read<CategoryProvider>();

      if (budgets.hasBudget(_selectedCategoryId!)) {
        final now2      = DateTime.now();
        final catTotals = provider.getCategoryTotals(now2.year, now2.month);
        final catSpent  = catTotals[_selectedCategoryId!] ?? 0;
        final status    = budgets.getStatus(_selectedCategoryId!, catSpent);
        final limit     = budgets.getLimitFor(_selectedCategoryId!);
        final catName   = catNames.getById(_selectedCategoryId!)?.name ?? '';
        final sym       = settings.currencySymbol;

        if (status == 'danger') {
          await SoundHelper.playWarning();

          // Fire 100% budget notification
          if (settings.notifEnabled && settings.notifBudget) {
            final catIndex = context
                .read<CategoryProvider>()
                .categories
                .indexWhere((c) => c.id == _selectedCategoryId);
            await NotificationHelper.showBudgetWarning(
              index: catIndex >= 0 ? catIndex : 0,
              categoryName: catName,
              spent: '$sym${catSpent.toStringAsFixed(2)}',
              limit: '$sym${limit.toStringAsFixed(2)}',
              isOver: true,
            );
          }
        } else if (status == 'warning') {
          // Fire 80% budget notification
          if (settings.notifEnabled && settings.notifBudget) {
            final catIndex = context
                .read<CategoryProvider>()
                .categories
                .indexWhere((c) => c.id == _selectedCategoryId);
            await NotificationHelper.showBudgetWarning(
              index: catIndex >= 0 ? catIndex : 0,
              categoryName: catName,
              spent: '$sym${catSpent.toStringAsFixed(2)}',
              limit: '$sym${limit.toStringAsFixed(2)}',
              isOver: false,
            );
          }
        }
      }
    }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;
    final wallets = context.watch<WalletProvider>().wallets;
    final budgets = context.watch<CategoryBudgetProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbol = context.read<SettingsProvider>().currencySymbol;
    final now = DateTime.now();
    final catTotals = expenses.getCategoryTotals(now.year, now.month);

    final walletRemaining = _getWalletRemaining();
    final enteredAmount =
        double.tryParse(_amountController.text) ?? 0;
    final isInsufficientBalance = _selectedWalletId != null &&
        enteredAmount > 0 &&
        enteredAmount > walletRemaining;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: isDark
              ? const Color(0xFF121212)
              : const Color(0xFFF5F7FA),
          title: Text(widget.existing != null
              ? 'Edit Expense'
              : 'Add Expense'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted)
                Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name ─────────────────────────────────────────────────
              _buildLabel('Expense Name *'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Coffee, Rent, Netflix',
                  prefixIcon: Icon(Icons.label_rounded),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 20),

              // ── Amount ────────────────────────────────────────────────
              _buildLabel('Amount *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _useItems ? null : _openCalculator,
                child: AbsorbPointer(
                  absorbing: !_useItems,
                  child: TextField(
                    controller: _amountController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: _useItems
                          ? 'Auto-calculated from items'
                          : 'Tap to enter amount',
                      prefixIcon:
                          const Icon(Icons.calculate_rounded),
                      suffixText: symbol,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 300.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 12),

              // ── Items toggle ──────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  setState(() {
                    _useItems = !_useItems;
                    if (_useItems && _items.isEmpty) _addItem();
                    if (!_useItems) {
                      _amountController.clear();
                      _items.clear();
                    }
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _useItems
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add multiple items (shopping list)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Items list ────────────────────────────────────────────
              if (_useItems) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      ...List.generate(_items.length, (i) {
                        final item = _items[i];
                        return Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: item.nameCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Item ${i + 1}',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10),
                                  ),
                                  style:
                                      const TextStyle(fontSize: 14),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () async {
                                    final result =
                                        await showModalBottomSheet<
                                            double>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor:
                                          Colors.transparent,
                                      builder: (_) => CalculatorSheet(
                                        initial: double.tryParse(
                                                item.amountCtrl
                                                    .text) ??
                                            0,
                                      ),
                                    );
                                    if (result != null) {
                                      setState(() => item.amountCtrl
                                          .text = result
                                          .toStringAsFixed(2));
                                      _recalcTotal();
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: TextField(
                                      controller: item.amountCtrl,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        suffixText: symbol,
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal: 8,
                                                vertical: 10),
                                      ),
                                      style: const TextStyle(
                                          fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                              if (_items.length > 1)
                                GestureDetector(
                                  onTap: () => _removeItem(i),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4),
                                    child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: theme
                                            .colorScheme.onSurface
                                            .withOpacity(0.3)),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Divider(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.1)),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12, 4, 12, 10),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6))),
                            Text(
                              '$symbol${_amountController.text.isEmpty ? '0.00' : _amountController.text}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _addItem,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withOpacity(0.06),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text('Add Item',
                                  style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Date & Time row ───────────────────────────────────────
              _buildLabel('Date & Time'),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Date picker
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: theme.colorScheme.primary,
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppUtils.formatDate(_selectedDate),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Time picker
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedTime != null
                            ? theme.colorScheme.primary
                                .withOpacity(0.1)
                            : (isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                        border: _selectedTime != null
                            ? Border.all(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.3),
                                width: 1.5)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded,
                              color: _selectedTime != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                              size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _selectedTime != null
                                ? _formatTime(_selectedTime!)
                                : 'Time',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedTime != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                            ),
                          ),
                          if (_selectedTime != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _clearTime,
                              child: Icon(Icons.close_rounded,
                                  size: 14,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.6)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 20),

              // ── Pay With ──────────────────────────────────────────────
              _buildLabel('Pay With'),
              const SizedBox(height: 8),
              if (wallets.isEmpty)
                _infoBox('Add wallets in Settings → Wallets.',
                    theme, isDark)
              else
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: wallets.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      final wallet = wallets[i];
                      final isSelected =
                          _selectedWalletId == wallet.id;
                      final walletColor =
                          Color(wallet.colorValue);
                      final spent =
                          expenses.getTotalForWallet(wallet.id);
                      final remaining = wallet.balance - spent;
                      final isLow = enteredAmount > 0 &&
                          enteredAmount > remaining;

                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedWalletId = wallet.id),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          width: 90,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isLow
                                    ? const Color(0xFFE57373)
                                        .withOpacity(0.15)
                                    : walletColor.withOpacity(0.15))
                                : (isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white),
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? (isLow
                                      ? const Color(0xFFE57373)
                                      : walletColor)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.05),
                                  blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                  WalletProvider.resolveIcon(
                                      wallet.type),
                                  color: isSelected
                                      ? (isLow
                                          ? const Color(0xFFE57373)
                                          : walletColor)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                  size: 20),
                              const SizedBox(height: 3),
                              Text(wallet.name,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? (isLow
                                              ? const Color(
                                                  0xFFE57373)
                                              : walletColor)
                                          : theme.colorScheme
                                              .onSurface
                                              .withOpacity(0.6)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (wallet.balance > 0)
                                Text(
                                  remaining < 0
                                      ? 'Empty'
                                      : AppUtils.formatAmount(
                                          remaining, symbol),
                                  style: TextStyle(
                                      fontSize: 8,
                                      color: remaining <= 0
                                          ? const Color(0xFFE57373)
                                          : theme.colorScheme
                                              .onSurface
                                              .withOpacity(0.35)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (isInsufficientBalance) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE57373).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE57373)
                            .withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE57373), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Not enough balance. Available: ${AppUtils.formatAmount(walletRemaining < 0 ? 0 : walletRemaining, symbol)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE57373),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 20),

              // ── Category ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _buildLabel('Category *')),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(
                          () => _reorderMode = !_reorderMode);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _reorderMode
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _reorderMode
                                ? Icons.check_rounded
                                : Icons.swap_vert_rounded,
                            size: 14,
                            color: _reorderMode
                                ? Colors.white
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _reorderMode ? 'Done' : 'Reorder',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _reorderMode
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_reorderMode)
                _buildReorderList(
                    categories, categoryProvider, theme, isDark)
              else
                SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      final isSelected =
                          _selectedCategoryId == cat.id;
                      final catColor = Color(cat.colorValue);
                      final spent = catTotals[cat.id] ?? 0;
                      final status = budgets.hasBudget(cat.id)
                          ? budgets.getStatus(cat.id, spent)
                          : 'ok';
                      final statusColor =
                          budgets.getStatusColor(cat.id, spent);

                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedCategoryId = cat.id),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          width: 72,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? catColor.withOpacity(0.25)
                                : (isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white),
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? catColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.05),
                                  blurRadius: 8),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                    CategoryIcons.resolve(cat.icon),
                                    color: catColor,
                                    size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? catColor
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (status != 'ok') ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1),
                                    decoration: BoxDecoration(
                                      color: statusColor
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status == 'danger'
                                          ? 'Over!'
                                          : '80%+',
                                      style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 100.ms),

              // Category budget warning
              if (_selectedCategoryId != null &&
                  budgets.hasBudget(_selectedCategoryId!) &&
                  !_reorderMode) ...[
                const SizedBox(height: 8),
                Builder(builder: (ctx) {
                  final spent =
                      catTotals[_selectedCategoryId!] ?? 0;
                  final status =
                      budgets.getStatus(_selectedCategoryId!, spent);
                  final statusColor = budgets
                      .getStatusColor(_selectedCategoryId!, spent);
                  final limit =
                      budgets.getLimitFor(_selectedCategoryId!);
                  final remaining = limit - spent;
                  if (status == 'ok') return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(
                          status == 'danger'
                              ? Icons.error_rounded
                              : Icons.warning_amber_rounded,
                          color: statusColor,
                          size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          status == 'danger'
                              ? 'Over budget! (${AppUtils.formatAmount(remaining.abs(), symbol)} over)'
                              : 'Almost at limit! Only ${AppUtils.formatAmount(remaining, symbol)} left.',
                          style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  );
                }),
              ],

              const SizedBox(height: 20),

              // ── Note ──────────────────────────────────────────────────
              _buildLabel('Note (Optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 20),

              // ── Recurring ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8)
                  ],
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.repeat_rounded,
                        color: _isRecurring
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withOpacity(0.5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recurring Expense',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                          if (_isRecurring)
                            Text(
                              'Automatically logged every $_recurringType',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isRecurring,
                      onChanged: (v) =>
                          setState(() => _isRecurring = v),
                    ),
                  ]),
                  if (_isRecurring) ...[
                    const SizedBox(height: 12),
                    // Info box explaining how it works
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14,
                              color: theme.colorScheme.primary
                                  .withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Spendly will automatically add this expense on each due date. Missed dates are caught up on next app open.',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary
                                    .withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['daily', 'weekly', 'monthly']
                          .map((type) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _recurringType = type),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: _recurringType == type
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary
                                        .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                type[0].toUpperCase() +
                                    type.substring(1),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _recurringType == type
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ]),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.existing != null
                      ? 'Update Expense'
                      : 'Add Expense'),
                ).animate().fadeIn(delay: 300.ms).scale(
                    begin: const Offset(0.95, 0.95)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a dialog asking whether to update only the template
  /// or also all already-generated instances.
  /// Returns true = update all, false = template only, null = cancelled.
  Future<bool?> _showRecurringUpdateDialog() async {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.repeat_rounded,
                  color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Update Recurring Expense',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: const Text(
          'This is a recurring template. How would you like to apply your changes?',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          // Template only
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Template only'),
          ),
          // Update all
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update all'),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderList(
    List categories,
    CategoryProvider categoryProvider,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 14,
                  color:
                      theme.colorScheme.primary.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                'Drag ☰ to reorder categories',
                style: TextStyle(
                    fontSize: 12,
                    color:
                        theme.colorScheme.primary.withOpacity(0.7)),
              ),
            ]),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.mediumImpact();
              categoryProvider.reorderCategories(
                  oldIndex, newIndex);
            },
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final catColor = Color(cat.colorValue);
              final isSelected = _selectedCategoryId == cat.id;

              return ListTile(
                key: ValueKey(cat.id),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 2),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(CategoryIcons.resolve(cat.icon),
                      color: catColor, size: 18),
                ),
                title: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected ? catColor : null,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: catColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(Icons.drag_handle_rounded,
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.3)),
                  ],
                ),
                onTap: () => setState(
                    () => _selectedCategoryId = cat.id),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  Widget _infoBox(String msg, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded,
            color: theme.colorScheme.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: const TextStyle(fontSize: 12))),
      ]),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ExpenseItem {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
}
