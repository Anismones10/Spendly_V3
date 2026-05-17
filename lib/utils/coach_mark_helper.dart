import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class CoachMarkHelper {
  static const String _dashboardKey = 'coach_dashboard_shown';
  static const String _loansKey = 'coach_loans_shown';
  static const String _goalsKey = 'coach_goals_shown';
  static const String _statsKey = 'coach_stats_shown';

  static bool shouldShow(String key) {
    final box = Hive.box('settings');
    return !(box.get(key, defaultValue: false) as bool);
  }

  static void markShown(String key) {
    Hive.box('settings').put(key, true);
  }

  // ── Dashboard coach marks ─────────────────────────────────────────────────

  static void showDashboard(
    BuildContext context, {
    required GlobalKey walletCardKey,
    required GlobalKey moreButtonKey,
    required GlobalKey quickStatsKey,
    required GlobalKey fabKey,
  }) {
    if (!shouldShow(_dashboardKey)) return;

    TutorialCoachMark(
      targets: [
        _target(
          id: 'wallet_card',
          key: walletCardKey,
          title: 'Your Wallets 💳',
          body:
              'This card shows your total balance across all wallets.\nSwipe left or right to see Cash, Card, Bank individually.\nTap the 👁 icon to hide amounts.',
          align: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
        ),
        _target(
          id: 'more_button',
          key: moreButtonKey,
          title: '••• More Menu',
          body:
              'Tap here to open the More menu.\nYou can access Settings, Loans, Goals, Income, and customize which tabs appear in your bottom bar.',
          align: ContentAlign.bottom,
          shape: ShapeLightFocus.Circle,
        ),
        _target(
          id: 'quick_stats',
          key: quickStatsKey,
          title: 'Quick Stats 📊',
          body:
              'See how much you spent today and this week.\nTap Income to view and manage your monthly income.',
          align: ContentAlign.top,
          shape: ShapeLightFocus.RRect,
        ),
        _target(
          id: 'fab',
          key: fabKey,
          title: 'Add Expense ➕',
          body:
              'Tap here to record a new expense.\nYou can add multiple items at once — perfect for shopping trips!\nAlways pick a wallet so your balance stays accurate.',
          align: ContentAlign.top,
          shape: ShapeLightFocus.RRect,
        ),
      ],
      colorShadow: const Color(0xFF0F2440),
      opacityShadow: 0.92,
      paddingFocus: 10,
      onFinish: () => markShown(_dashboardKey),
      onSkip: () {
        markShown(_dashboardKey);
        return true;
      },
    ).show(context: context);
  }

  // ── Loans coach marks ─────────────────────────────────────────────────────

  static void showLoans(
    BuildContext context, {
    required GlobalKey lendingTabKey,
    required GlobalKey borrowingTabKey,
    required GlobalKey addButtonKey,
  }) {
    if (!shouldShow(_loansKey)) return;

    TutorialCoachMark(
      targets: [
        _target(
          id: 'lending_tab',
          key: lendingTabKey,
          title: 'Lending 🤝',
          body:
              'Money you gave to someone.\nThey owe you this amount back.\nThis does NOT come out of your wallet automatically — pick a wallet when adding.',
          align: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
        ),
        _target(
          id: 'borrowing_tab',
          key: borrowingTabKey,
          title: 'Borrowing 🤲',
          body:
              'Money someone gave you.\nYou owe them this amount.\nThis gets added to your wallet balance automatically.',
          align: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
        ),
        _target(
          id: 'add_loan',
          key: addButtonKey,
          title: 'Add a Loan ➕',
          body:
              'Record who you lent to or borrowed from.\nAlways pick a wallet so the dashboard card shows the correct remaining amount.',
          align: ContentAlign.top,
          shape: ShapeLightFocus.Circle,
        ),
      ],
      colorShadow: const Color(0xFF0F2440),
      opacityShadow: 0.92,
      paddingFocus: 10,
      onFinish: () => markShown(_loansKey),
      onSkip: () {
        markShown(_loansKey);
        return true;
      },
    ).show(context: context);
  }

  // ── Goals coach marks ─────────────────────────────────────────────────────

  static void showGoals(
    BuildContext context, {
    required GlobalKey addGoalKey,
    required GlobalKey goalCardKey,
  }) {
    if (!shouldShow(_goalsKey)) return;

    TutorialCoachMark(
      targets: [
        _target(
          id: 'goal_card',
          key: goalCardKey,
          title: 'Your Savings Goals 🎯',
          body:
              'Each card shows a goal you\'re saving toward.\nThe progress bar fills as you add savings.\nTap a goal to add money or see details.',
          align: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
        ),
        _target(
          id: 'add_goal',
          key: addGoalKey,
          title: 'Create a Goal ➕',
          body:
              'Tap here to create a new savings goal.\nGive it a name, a target amount, and an optional deadline.\nSpendly will track your progress automatically.',
          align: ContentAlign.top,
          shape: ShapeLightFocus.Circle,
        ),
      ],
      colorShadow: const Color(0xFF0F2440),
      opacityShadow: 0.92,
      paddingFocus: 10,
      onFinish: () => markShown(_goalsKey),
      onSkip: () {
        markShown(_goalsKey);
        return true;
      },
    ).show(context: context);
  }

  // ── Stats coach marks ─────────────────────────────────────────────────────

  static void showStats(
    BuildContext context, {
    required GlobalKey chartKey,
    required GlobalKey filterKey,
  }) {
    if (!shouldShow(_statsKey)) return;

    TutorialCoachMark(
      targets: [
        _target(
          id: 'filter',
          key: filterKey,
          title: 'Filter by time 📅',
          body:
              'Switch between week, month, and year views.\nThis changes all charts and numbers on this screen.',
          align: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
        ),
        _target(
          id: 'chart',
          key: chartKey,
          title: 'Spending breakdown 📊',
          body:
              'See exactly where your money goes each month.\nTap a category slice to see the exact amount spent.\nUse this to spot where you overspend.',
          align: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
        ),
      ],
      colorShadow: const Color(0xFF0F2440),
      opacityShadow: 0.92,
      paddingFocus: 10,
      onFinish: () => markShown(_statsKey),
      onSkip: () {
        markShown(_statsKey);
        return true;
      },
    ).show(context: context);
  }

  // ── Shared builder ────────────────────────────────────────────────────────

  static TargetFocus _target({
    required String id,
    required GlobalKey key,
    required String title,
    required String body,
    required ContentAlign align,
    required ShapeLightFocus shape,
  }) {
    return TargetFocus(
      identify: id,
      keyTarget: key,
      shape: shape,
      radius: 14,
      contents: [
        TargetContent(
          align: align,
          builder: (ctx, controller) => _CoachCard(
            title: title,
            body: body,
            onNext: controller.next,
            onSkip: controller.skip,
          ),
        ),
      ],
    );
  }
}

// ── Coach card UI ─────────────────────────────────────────────────────────────

class _CoachCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _CoachCard({
    required this.title,
    required this.body,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            GestureDetector(
              onTap: onSkip,
              child: Text(
                'Skip all',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onNext,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'Next  →',
                  style: TextStyle(
                    color: Color(0xFF0F2440),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
