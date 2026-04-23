import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

// All available tabs definition
class _TabDef {
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const _TabDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}

final List<_TabDef> _allTabs = [
  _TabDef(
    id: 'home',
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    screen: const DashboardScreen(),
  ),
  _TabDef(
    id: 'expenses',
    label: 'Expenses',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
    screen: const ExpensesScreen(),
  ),
  _TabDef(
    id: 'goals',
    label: 'Goals',
    icon: Icons.flag_outlined,
    activeIcon: Icons.flag_rounded,
    screen: const GoalsScreen(),
  ),
  _TabDef(
    id: 'stats',
    label: 'Stats',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    screen: const StatisticsScreen(),
  ),
  _TabDef(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    screen: const SettingsScreen(),
  ),
];

// Default order — right-hand friendly: Goals | Stats | Home(center) | Expenses | Settings
const List<String> _defaultTabOrder = [
  'home',
  'expenses',
  'goals',
  'stats',
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late List<String> _visibleTabIds;
  late int _currentIndex;
  int _previousIndex = 0;
  final Box _settingsBox = Hive.box('settings');

  @override
  void initState() {
    super.initState();
    _loadTabPrefs();
  }

  void _loadTabPrefs() {
    final saved = _settingsBox.get('visibleTabs') as List?;
    if (saved != null && saved.length >= 3) {
      _visibleTabIds = List<String>.from(saved);
    } else {
      _visibleTabIds = List<String>.from(_defaultTabOrder);
    }
    // Always ensure 'home' is present
    if (!_visibleTabIds.contains('home')) {
      _visibleTabIds.insert(_visibleTabIds.length ~/ 2, 'home');
    }
    _currentIndex = _visibleTabIds.indexOf('home');
    if (_currentIndex < 0) _currentIndex = 0;
    _previousIndex = _currentIndex;
  }

  void _saveTabPrefs() {
    _settingsBox.put('visibleTabs', _visibleTabIds);
  }

  List<_TabDef> get _visibleTabs =>
      _visibleTabIds.map((id) => _allTabs.firstWhere((t) => t.id == id)).toList();

  int get _centerIndex => _visibleTabs.indexWhere((t) => t.id == 'home');

  void _goTo(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  void _showMoreMenu() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hiddenTabs = _allTabs
        .where((t) => !_visibleTabIds.contains(t.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('More', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Settings always in More
            _MoreTile(
              icon: Icons.settings_rounded,
              label: 'Settings',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),

            if (hiddenTabs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(color: Colors.grey.withOpacity(0.15)),
              const SizedBox(height: 8),
              Text('Other Screens',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.4))),
              const SizedBox(height: 8),
              ...hiddenTabs.map((tab) => _MoreTile(
                icon: tab.activeIcon,
                label: tab.label,
                onTap: () {
                  Navigator.pop(ctx);
                  // Temporarily navigate by adding to visible list
                  setState(() {
                    if (!_visibleTabIds.contains(tab.id)) {
                      _visibleTabIds.add(tab.id);
                    }
                    _currentIndex = _visibleTabIds.indexOf(tab.id);
                    _previousIndex = _currentIndex;
                  });
                },
              )),
            ],

            const SizedBox(height: 8),
            Divider(color: Colors.grey.withOpacity(0.15)),
            const SizedBox(height: 8),

            // Customize tabs
            _MoreTile(
              icon: Icons.tune_rounded,
              label: 'Customize Tabs',
              onTap: () {
                Navigator.pop(ctx);
                _showTabCustomizer();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTabCustomizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TabCustomizerSheet(
        allTabs: _allTabs.where((t) => t.id != 'settings').toList(),
        visibleTabIds: List<String>.from(_visibleTabIds),
        onSave: (newIds) {
          setState(() {
            _visibleTabIds = newIds;
            final currentId = _visibleTabs.isNotEmpty &&
                    _currentIndex < _visibleTabs.length
                ? _visibleTabs[_currentIndex].id
                : 'home';
            final newIndex = newIds.indexOf(currentId);
            _currentIndex = newIndex >= 0 ? newIndex : newIds.indexOf('home');
            if (_currentIndex < 0) _currentIndex = 0;
            _previousIndex = _currentIndex;
          });
          _saveTabPrefs();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabs = _visibleTabs;
    final centerIdx = _centerIndex;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -400 && _currentIndex < tabs.length - 1) {
            _goTo(_currentIndex + 1);
          } else if (v > 400 && _currentIndex > 0) {
            _goTo(_currentIndex - 1);
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) {
            final goRight = _currentIndex >= _previousIndex;
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(goRight ? 0.06 : -0.06, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _currentIndex < tabs.length
                ? tabs[_currentIndex].screen
                : const DashboardScreen(),
          ),
        ),
      ),

      bottomNavigationBar: Container(
        // Bottom margin so nav bar floats above device edge
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ...List.generate(tabs.length, (i) {
                  final tab = tabs[i];
                  final isSelected = i == _currentIndex;
                  final isCenter = i == centerIdx;

                  if (isCenter) {
                    return _CenterButton(
                      icon: tab.activeIcon,
                      isSelected: isSelected,
                      onTap: () => _goTo(i),
                    );
                  }
                  return _NavButton(
                    icon: isSelected ? tab.activeIcon : tab.icon,
                    label: tab.label,
                    isSelected: isSelected,
                    onTap: () => _goTo(i),
                  );
                }),
                // Customize tabs button
                _CustomizeButton(onTap: _showMoreMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Center Home Button ────────────────────────────────────────────────────────

class _CenterButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary
                  .withOpacity(isSelected ? 0.5 : 0.3),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      )
          .animate(target: isSelected ? 1 : 0)
          .scale(
              begin: const Offset(0.93, 0.93),
              end: const Offset(1.0, 1.0),
              duration: 200.ms),
    );
  }
}

// ── Regular Nav Button ────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.38),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.38),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Customize Button ──────────────────────────────────────────────────────────

class _CustomizeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CustomizeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: theme.colorScheme.onSurface.withOpacity(0.38),
            ),
            const SizedBox(height: 3),
            Text(
              'More',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Customizer Sheet ──────────────────────────────────────────────────────

class _TabCustomizerSheet extends StatefulWidget {
  final List<_TabDef> allTabs;
  final List<String> visibleTabIds;
  final ValueChanged<List<String>> onSave;

  const _TabCustomizerSheet({
    required this.allTabs,
    required this.visibleTabIds,
    required this.onSave,
  });

  @override
  State<_TabCustomizerSheet> createState() => _TabCustomizerSheetState();
}

class _TabCustomizerSheetState extends State<_TabCustomizerSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.visibleTabIds);
  }

  void _toggle(String id) {
    if (id == 'home') return; // home is always visible
    setState(() {
      if (_selected.contains(id)) {
        if (_selected.length <= 3) return; // minimum 3 tabs
        _selected.remove(id);
      } else {
        if (_selected.length >= 5) return; // maximum 5 tabs
        // Insert before settings if present, else append
        final settingsIdx = _selected.indexOf('settings');
        if (settingsIdx >= 0) {
          _selected.insert(settingsIdx, id);
        } else {
          _selected.add(id);
        }
      }
    });
  }

  void _resetToDefault() {
    setState(() => _selected = List<String>.from(_defaultTabOrder));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Customize Tabs',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              TextButton(
                  onPressed: _resetToDefault,
                  child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Choose 3–5 tabs. Home is always visible.',
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),

          // Tab toggle list
          ...widget.allTabs.map((tab) {
            final isSelected = _selected.contains(tab.id);
            final isHome = tab.id == 'home';

            return GestureDetector(
              onTap: () => _toggle(tab.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.08)
                      : (isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.4)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? tab.activeIcon : tab.icon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        tab.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    if (isHome)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Always on',
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Tab count indicator
          Center(
            child: Text(
              '${_selected.length} / 5 tabs selected',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_selected);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── More Menu Tile ────────────────────────────────────────────────────────────

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.3)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
