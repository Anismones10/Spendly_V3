import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import '../utils/category_icons.dart';
import '../utils/sound_helper.dart';
import '../widgets/calculator_sheet.dart';

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
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String _recurringType = 'monthly';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _amountController.text = e.amount.toString();
      _noteController.text = e.note ?? '';
      _selectedCategoryId = e.categoryId;
      _selectedDate = e.date;
      _isRecurring = e.isRecurring;
      _recurringType = e.recurringType ?? 'monthly';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (widget.existing != null) {
      final e = widget.existing!;
      return _nameController.text != e.name ||
          _amountController.text != e.amount.toString() ||
          _noteController.text != (e.note ?? '') ||
          _selectedCategoryId != e.categoryId ||
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text('Discard Changes?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to go back? Your changes will be lost.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
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
      setState(() => _amountController.text = result.toStringAsFixed(2));
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

  Future<void> _save() async {
    if (_nameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final expense = ExpenseModel(
      id: widget.existing?.id ?? AppUtils.generateId(),
      name: _nameController.text.trim(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      isRecurring: _isRecurring,
      recurringType: _isRecurring ? _recurringType : null,
    );

    final provider = context.read<ExpenseProvider>();
    if (widget.existing != null) {
      provider.updateExpense(expense);
    } else {
      provider.addExpense(expense);
      await SoundHelper.playChaChing();

      // Check budget
      final settings = context.read<SettingsProvider>();
      final budget = settings.monthlyBudget;
      if (budget > 0) {
        final now = DateTime.now();
        final total = provider.getTotalForMonth(now.year, now.month);
        if (total / budget >= 0.8) {
          await SoundHelper.playWarning();
        }
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: Text(widget.existing != null ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
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

            // Amount field - tapping opens calculator
            _buildLabel('Amount *'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _openCalculator,
              child: AbsorbPointer(
                child: TextField(
                  controller: _amountController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Tap to enter amount',
                    prefixIcon: const Icon(Icons.calculate_rounded),
                    suffixText: context.read<SettingsProvider>().currencySymbol,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 50.ms, duration: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 20),

            // Category picker
            _buildLabel('Category *'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final cat = categories[i];
                  final isSelected = _selectedCategoryId == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(cat.colorValue).withOpacity(0.25)
                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Color(cat.colorValue)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CategoryIcons.resolve(cat.icon), color: Color(cat.colorValue), size: 24),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected
                                    ? Color(cat.colorValue)
                                    : theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),

            // Date picker
            _buildLabel('Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      AppUtils.formatDate(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 20),

            // Note field
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

            // Recurring toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat_rounded),
                      const SizedBox(width: 12),
                      const Text('Recurring Expense',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Switch.adaptive(
                        value: _isRecurring,
                        onChanged: (v) => setState(() => _isRecurring = v),
                      ),
                    ],
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: ['daily', 'weekly', 'monthly'].map((type) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _recurringType = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _recurringType == type
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                type[0].toUpperCase() + type.substring(1),
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
                ],
              ),
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(widget.existing != null ? 'Update Expense' : 'Add Expense'),
              ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }
}
