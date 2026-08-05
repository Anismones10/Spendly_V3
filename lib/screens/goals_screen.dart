import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/goal_model.dart';
import '../providers/goal_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/empty_state.dart';

// Available goal icons
const List<Map<String, dynamic>> _goalIcons = [
  {'key': 'flag',      'icon': Icons.flag_rounded},
  {'key': 'laptop',    'icon': Icons.laptop_rounded},
  {'key': 'flight',    'icon': Icons.flight_rounded},
  {'key': 'home',      'icon': Icons.home_rounded},
  {'key': 'car',       'icon': Icons.directions_car_rounded},
  {'key': 'school',    'icon': Icons.school_rounded},
  {'key': 'phone',     'icon': Icons.smartphone_rounded},
  {'key': 'gift',      'icon': Icons.card_giftcard_rounded},
  {'key': 'health',    'icon': Icons.local_hospital_rounded},
  {'key': 'sport',     'icon': Icons.sports_soccer_rounded},
  {'key': 'music',     'icon': Icons.music_note_rounded},
  {'key': 'camera',    'icon': Icons.camera_alt_rounded},
  {'key': 'savings',   'icon': Icons.savings_rounded},
  {'key': 'beach',     'icon': Icons.beach_access_rounded},
  {'key': 'coffee',    'icon': Icons.coffee_rounded},
  {'key': 'star',      'icon': Icons.star_rounded},
];

IconData _resolveGoalIcon(String? key) {
  if (key == null) return Icons.flag_rounded;
  final found = _goalIcons.firstWhere(
    (e) => e['key'] == key,
    orElse: () => {'key': 'flag', 'icon': Icons.flag_rounded},
  );
  return found['icon'] as IconData;
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  void _selectAll(List<dynamic> all) {
    setState(() => _selectedIds.addAll(all.map((e) => e.id as String)));
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Selected'),
        content: Text('Delete $count goal${count == 1 ? '' : 's'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final provider = context.read<GoalProvider>();
      for (final id in _selectedIds.toList()) provider.deleteGoal(id);
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allGoals = [...goals.activeGoals, ...goals.completedGoals];

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: _isSelecting
          ? AppBar(
              backgroundColor:
                  isDark ? const Color(0xFF1E1E1E) : Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              actions: [
                TextButton(
                  onPressed: () => _selectAll(allGoals),
                  child: const Text('All'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _deleteSelected(context),
                ),
              ],
            )
          : AppBar(
              backgroundColor:
                  isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
              title: const Text('Goals'),
            ),
      body: goals.goals.isEmpty
          ? const EmptyState(
              icon: Icons.flag_rounded,
              title: 'No Goals Yet',
              subtitle: 'Set a savings goal and track your progress!',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                if (goals.activeGoals.isNotEmpty) ...[
                  _sectionLabel('Active Goals', theme),
                  ...goals.activeGoals.asMap().entries.map(
                        (e) {
                          final isSelected = _selectedIds.contains(e.value.id);
                          return GestureDetector(
                            onLongPress: () => _toggleSelection(e.value.id),
                            onTap: _isSelecting ? () => _toggleSelection(e.value.id) : null,
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(color: const Color(0xFFFF9800), width: 2)
                                        : null,
                                    color: isSelected
                                        ? const Color(0xFFFF9800).withOpacity(0.07)
                                        : Colors.transparent,
                                  ),
                                  child: _GoalCard(goal: e.value, symbol: symbol),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 12, left: 12,
                                    child: Container(
                                      width: 22, height: 22,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF9800),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (e.key * 60).ms)
                              .slideY(begin: 0.1);
                        },
                      ),
                ],
                if (goals.completedGoals.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _sectionLabel('Completed', theme),
                  ...goals.completedGoals.asMap().entries.map(
                        (e) {
                          final isSelected = _selectedIds.contains(e.value.id);
                          return GestureDetector(
                            onLongPress: () => _toggleSelection(e.value.id),
                            onTap: _isSelecting ? () => _toggleSelection(e.value.id) : null,
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(color: const Color(0xFFFF9800), width: 2)
                                        : null,
                                    color: isSelected
                                        ? const Color(0xFFFF9800).withOpacity(0.07)
                                        : Colors.transparent,
                                  ),
                                  child: _GoalCard(goal: e.value, symbol: symbol),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 12, left: 12,
                                    child: Container(
                                      width: 22, height: 22,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF9800),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (e.key * 60).ms);
                        },
                      ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _sectionLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  void _showGoalSheet(BuildContext context, {GoalModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalSheet(existing: existing),
    );
  }
}

// ── Goal Sheet (Add / Edit) ───────────────────────────────────────────────────

class _GoalSheet extends StatefulWidget {
  final GoalModel? existing;
  const _GoalSheet({this.existing});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  DateTime? _deadline;
  String _selectedIconKey = 'flag';

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _amountCtrl = TextEditingController(
        text: widget.existing != null
            ? widget.existing!.targetAmount.toStringAsFixed(2)
            : '');
    _deadline = widget.existing?.deadline;
    _selectedIconKey = widget.existing?.iconKey ?? 'flag';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (name.isEmpty || amount == null || amount <= 0) return;

    final provider = context.read<GoalProvider>();
    if (widget.existing != null) {
      provider.updateGoalDetails(
        id: widget.existing!.id,
        name: name,
        targetAmount: amount,
        deadline: _deadline,
        iconKey: _selectedIconKey,
      );
    } else {
      provider.addGoal(GoalModel(
        id: AppUtils.generateId(),
        name: name,
        targetAmount: amount,
        deadline: _deadline,
        iconKey: _selectedIconKey,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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

              Text(
                widget.existing != null ? 'Edit Goal' : 'New Savings Goal',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              // Name
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Goal name (e.g. New Laptop)',
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Target amount',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Icon picker
              const Text('Icon',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _goalIcons.map((item) {
                  final key = item['key'] as String;
                  final icon = item['icon'] as IconData;
                  final isSelected = _selectedIconKey == key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconKey = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.15)
                            : (isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade100),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Deadline
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _deadline ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        _deadline != null
                            ? AppUtils.formatDate(_deadline!)
                            : 'Set deadline (optional)',
                        style: TextStyle(
                          fontSize: 15,
                          color: _deadline != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      if (_deadline != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: Icon(Icons.close_rounded,
                              size: 18,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.existing != null
                      ? 'Save Changes'
                      : 'Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final String symbol;
  const _GoalCard({required this.goal, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = goal.progress.clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    Color progressColor;
    if (pct >= 100) {
      progressColor = const Color(0xFF2ECC71);
    } else if (pct >= 75) {
      progressColor = const Color(0xFF4A90E2);
    } else if (pct >= 50) {
      progressColor = theme.colorScheme.primary;
    } else {
      progressColor = theme.colorScheme.primary.withOpacity(0.7);
    }

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Goal',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content: Text(
                'Delete "${goal.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<GoalProvider>().deleteGoal(goal.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal "${goal.name}" deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () => _showOptions(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06), blurRadius: 12)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _resolveGoalIcon(goal.iconKey),
                      color: progressColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        if (goal.deadline != null)
                          Text(
                            'By ${AppUtils.formatDate(goal.deadline!)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5)),
                          ),
                      ],
                    ),
                  ),
                  // Status / actions
                  if (goal.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Done',
                          style: TextStyle(
                              color: Color(0xFF2ECC71),
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Add funds
                        IconButton(
                          icon: Icon(Icons.add_circle_rounded,
                              color: theme.colorScheme.primary),
                          onPressed: () => _showAddFunds(context),
                          tooltip: 'Add funds',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        // Edit
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                              size: 20),
                          onPressed: () => _showEdit(context),
                          tooltip: 'Edit goal',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppUtils.formatAmount(goal.savedAmount, symbol),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                        fontSize: 18),
                  ),
                  Text(
                    '${AppUtils.formatAmount(goal.targetAmount, symbol)} ($pct%)',
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (_, val, __) => LinearProgressIndicator(
                    value: val,
                    minHeight: 10,
                    backgroundColor: progressColor.withOpacity(0.12),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),

              if (!goal.isCompleted) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppUtils.formatAmount(goal.remaining, symbol)} remaining',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5)),
                    ),
                    Text(
                      'Swipe to delete',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.3)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    if (goal.isCompleted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle_rounded),
              title: const Text('Add Funds',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddFunds(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Goal',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showEdit(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Goal',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalSheet(existing: goal),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Goal',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${goal.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GoalProvider>().deleteGoal(goal.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddFunds(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add to "${goal.name}"',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Amount to add'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text);
              if (amount != null && amount > 0) {
                ctx.read<GoalProvider>().updateGoalSavings(goal.id, amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
