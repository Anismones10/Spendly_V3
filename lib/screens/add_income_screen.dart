import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/income_model.dart';
import '../providers/income_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/app_utils.dart';

const List<Map<String, dynamic>> _incomeSources = [
  {'key': 'salary',     'label': 'Salary',     'icon': Icons.work_rounded,           'color': 0xFF2ECC71},
  {'key': 'freelance',  'label': 'Freelance',  'icon': Icons.laptop_rounded,          'color': 0xFF4A90E2},
  {'key': 'gift',       'label': 'Gift',       'icon': Icons.card_giftcard_rounded,   'color': 0xFFE91E63},
  {'key': 'sale',       'label': 'Sale',       'icon': Icons.sell_rounded,            'color': 0xFFFF9800},
  {'key': 'investment', 'label': 'Investment', 'icon': Icons.trending_up_rounded,     'color': 0xFF9C27B0},
  {'key': 'bonus',      'label': 'Bonus',      'icon': Icons.stars_rounded,           'color': 0xFFF39C12},
  {'key': 'rental',     'label': 'Rental',     'icon': Icons.home_rounded,            'color': 0xFF26A69A},
  {'key': 'other',      'label': 'Other',      'icon': Icons.attach_money_rounded,    'color': 0xFF78909C},
];

IconData incomeSourceIcon(String key) {
  final found = _incomeSources.firstWhere(
    (s) => s['key'] == key,
    orElse: () => _incomeSources.last,
  );
  return found['icon'] as IconData;
}

Color incomeSourceColor(String key) {
  final found = _incomeSources.firstWhere(
    (s) => s['key'] == key,
    orElse: () => _incomeSources.last,
  );
  return Color(found['color'] as int);
}

String incomeSourceLabel(String key) {
  final found = _incomeSources.firstWhere(
    (s) => s['key'] == key,
    orElse: () => _incomeSources.last,
  );
  return found['label'] as String;
}

class AddIncomeScreen extends StatefulWidget {
  final IncomeModel? existing;
  const AddIncomeScreen({super.key, this.existing});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedSource = 'salary';
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _amountController.text = e.amount.toStringAsFixed(2);
      _noteController.text = e.note ?? '';
      _selectedSource = e.source;
      _selectedWalletId = e.walletId;
      _selectedDate = e.date;
      if (e.timeHour != null && e.timeMinute != null) {
        _selectedTime =
            TimeOfDay(hour: e.timeHour!, minute: e.timeMinute!);
      }
    } else {
      _selectedTime = TimeOfDay.now();
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
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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

  void _clearTime() => setState(() => _selectedTime = null);

  String _formatTime(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final min = m.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  void _save() {
    if (_nameController.text.isEmpty ||
        _amountController.text.isEmpty) {
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

    final income = IncomeModel(
      id: widget.existing?.id ?? AppUtils.generateId(),
      name: _nameController.text.trim(),
      amount: amount,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      source: _selectedSource,
      walletId: _selectedWalletId,
      timeHour: _selectedTime?.hour,
      timeMinute: _selectedTime?.minute,
    );

    final provider = context.read<IncomeProvider>();
    if (widget.existing != null) {
      provider.updateIncome(income);
    } else {
      provider.addIncome(income);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final wallets = context.watch<WalletProvider>().wallets;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF5F7FA),
        title: Text(widget.existing != null
            ? 'Edit Income'
            : 'Add Income'),
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
            // ── Income name ──────────────────────────────────────────
            _buildLabel('Income Name *'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Monthly Salary, Freelance Project',
                prefixIcon: Icon(Icons.label_rounded),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 20),

            // ── Amount ────────────────────────────────────────────────
            _buildLabel('Amount *'),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixIcon:
                    const Icon(Icons.attach_money_rounded),
                suffixText: symbol,
              ),
            )
                .animate()
                .fadeIn(delay: 50.ms, duration: 300.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 20),

            // ── Date & Time row ───────────────────────────────────────
            _buildLabel('Date & Time'),
            const SizedBox(height: 8),
            Row(
              children: [
                // Date
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
                // Time
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
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),

            // ── Add to Wallet ─────────────────────────────────────────
            _buildLabel('Add to Wallet'),
            const SizedBox(height: 4),
            Text(
              'Income will be added to the selected wallet balance',
              style: TextStyle(
                fontSize: 11,
                color:
                    theme.colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 10),
            if (wallets.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Add wallets in Settings → Wallets first.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // No wallet option
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedWalletId = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedWalletId == null
                            ? theme.colorScheme.primary
                                .withOpacity(0.1)
                            : (isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedWalletId == null
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.04),
                              blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.money_off_rounded,
                            color: _selectedWalletId == null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.4),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Just track (no wallet)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _selectedWalletId == null
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                Text(
                                  'Record income without affecting wallet balance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedWalletId == null)
                            Icon(Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                                size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...wallets.map((wallet) {
                    final isSelected = _selectedWalletId == wallet.id;
                    final walletColor = Color(wallet.colorValue);

                    return GestureDetector(
                      onTap: () => setState(
                          () => _selectedWalletId = wallet.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? walletColor.withOpacity(0.12)
                              : (isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? walletColor
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.04),
                                blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: walletColor.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Icon(
                                WalletProvider.resolveIcon(
                                    wallet.type),
                                color: walletColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallet.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isSelected
                                          ? walletColor
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    'Current balance: ${_formatBalance(wallet.balance, symbol)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? walletColor.withOpacity(0.7)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2ECC71)
                                      .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.arrow_downward_rounded,
                                        color: Color(0xFF2ECC71),
                                        size: 12),
                                    const SizedBox(width: 3),
                                    Text(
                                      _amountController.text.isNotEmpty
                                          ? '+${_amountController.text}'
                                          : 'Income',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2ECC71),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            const SizedBox(height: 20),

            // ── Source picker ─────────────────────────────────────────
            _buildLabel('Source *'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _incomeSources.map((source) {
                final key = source['key'] as String;
                final label = source['label'] as String;
                final icon = source['icon'] as IconData;
                final color = Color(source['color'] as int);
                final isSelected = _selectedSource == key;

                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedSource = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : (isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            color: isSelected
                                ? color
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.4),
                            size: 18),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? color
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 100.ms),
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
            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  widget.existing != null
                      ? 'Update Income'
                      : 'Add Income',
                ),
              ).animate().fadeIn(delay: 250.ms).scale(
                    begin: const Offset(0.95, 0.95),
                  ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatBalance(double amount, String symbol) {
    if (amount == 0) return 'Empty';
    return '$symbol${amount.toStringAsFixed(2)}';
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
}
