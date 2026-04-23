# 💰 Expense Tracker — Flutter App

A professional, fully functional expense tracker for Android & iOS built with Flutter, Dart, Hive, Provider, and Material Design 3.

---

## 📁 Project Structure

```
lib/
├── main.dart                      # Entry point + Hive init + MultiProvider
├── models/
│   ├── expense_model.dart         # Expense Hive model
│   ├── expense_model.g.dart       # Generated Hive adapter
│   ├── category_model.dart        # Category Hive model
│   ├── category_model.g.dart
│   ├── goal_model.dart            # Goal Hive model
│   ├── goal_model.g.dart
│   ├── savings_model.dart         # Savings Hive model
│   └── savings_model.g.dart
├── providers/
│   ├── expense_provider.dart      # Expense CRUD + filters + insights
│   ├── category_provider.dart     # Default + custom categories
│   ├── settings_provider.dart     # Dark mode, currency, budget, streak
│   ├── savings_provider.dart      # Savings jar
│   └── goal_provider.dart         # Savings goals
├── screens/
│   ├── main_shell.dart            # Bottom nav shell with animated transitions
│   ├── dashboard_screen.dart      # Home: balance card, budget bar, insights
│   ├── expenses_screen.dart       # List with search, sort, filter
│   ├── add_expense_screen.dart    # Add/Edit form with calculator
│   ├── calendar_screen.dart       # Monthly calendar with spending dots
│   ├── goals_screen.dart          # Savings goals with progress bars
│   ├── savings_screen.dart        # Savings jar screen
│   └── settings_screen.dart       # All app settings + category manager
├── widgets/
│   ├── budget_bar.dart            # Animated green→red gradient bar
│   ├── calculator_sheet.dart      # Bottom sheet calculator
│   ├── charts_widget.dart         # fl_chart pie + bar charts
│   ├── daily_summary_card.dart    # Today vs yesterday comparison
│   ├── emotion_character.dart     # Emoji character reacting to budget
│   ├── empty_state.dart           # Empty state illustrations
│   ├── expense_tile.dart          # Swipeable expense list item
│   ├── insight_card.dart          # Swipeable smart insights
│   ├── savings_jar_widget.dart    # Animated custom-painted savings jar
│   └── streak_badge.dart          # Flame streak badge
└── utils/
    ├── app_theme.dart             # Light & dark Material 3 themes
    ├── app_utils.dart             # Formatting helpers
    ├── csv_helper.dart            # CSV export via share_plus
    ├── month_end_dialog.dart      # Month-end savings prompt
    └── sound_helper.dart          # audioplayers wrapper
```

---

## 🚀 Setup Instructions

### 1. Prerequisites
- Flutter 3.19+ with Dart 3.0+
- Android Studio or VS Code with Flutter extension

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Add required assets

**Sounds** — Place these in `assets/sounds/`:
- `chaching.mp3` — plays when adding expense
- `celebration.mp3` — plays on goal completion / savings
- `warning.mp3` — plays when budget is low

Free sources: [freesound.org](https://freesound.org), [zapsplat.com](https://zapsplat.com)

**Lottie animations** — Place JSON files in `assets/lottie/`:
- Download from [lottiefiles.com](https://lottiefiles.com)
- Optional — the app works without them (uses emoji fallbacks)

### 4. Run the app
```bash
flutter run
```

---

## ✨ Features

| Feature | Status |
|---------|--------|
| Add / Edit / Delete expenses | ✅ |
| Category management (default + custom) | ✅ |
| Monthly budget with gradient progress bar | ✅ |
| Built-in calculator (bottom sheet) | ✅ |
| Dark / Light mode | ✅ |
| Currency selector (7 currencies) | ✅ |
| Hive local storage (fully offline) | ✅ |
| Provider state management | ✅ |
| Calendar view with spending dots | ✅ |
| Savings jar with animated fill | ✅ |
| Savings goals with progress | ✅ |
| Habit streak tracking 🔥 | ✅ |
| Smart insights (swipeable) | ✅ |
| fl_chart pie + bar charts | ✅ |
| CSV export | ✅ |
| Sound effects | ✅ |
| Month-end savings prompt | ✅ |
| Smooth animations throughout | ✅ |
| Empty states with messages | ✅ |
| Recurring expense support | ✅ |
| Search + sort + filter | ✅ |

---

## 📦 Key Packages

| Package | Purpose |
|---------|---------|
| `hive` + `hive_flutter` | Local database |
| `provider` | State management |
| `fl_chart` | Pie + bar charts |
| `table_calendar` | Monthly calendar |
| `audioplayers` | Sound effects |
| `google_fonts` | Poppins typography |
| `flutter_animate` | Smooth animations |
| `share_plus` | CSV export sharing |
| `csv` | CSV generation |
| `intl` | Date/number formatting |
| `flutter_colorpicker` | Custom category colors |

---

## 🔧 Notes

- The `.g.dart` files (Hive adapters) are pre-generated — no need to run `build_runner`.
- All data is stored locally using Hive — no internet connection required.
- Sound files must be added manually (see Setup step 3).
- The `ChartsWidget` can be added to the dashboard by importing and placing it in `dashboard_screen.dart`.
