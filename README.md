# 💰 Spendly — Expense Tracker (Flutter)

A personal finance app for Android, built with Flutter, Dart, Hive, Provider, Firebase and Material Design 3.

Track your expenses, set a monthly budget, save toward goals, and manage loans. Your data works offline on your phone (Hive) and syncs to the cloud when you sign in with Google.

> **Status:** Android only for now. iOS is not published yet.

---

## ✨ Features

| Feature | Status |
| --- | --- |
| Add / edit / delete expenses | ✅ |
| Default and custom categories | ✅ |
| Monthly budget with gradient progress bar | ✅ |
| Built-in calculator (bottom sheet) | ✅ |
| Dark / light mode | ✅ |
| Currency selector (7 currencies) | ✅ |
| Calendar view with spending dots | ✅ |
| Savings jar with animated fill | ✅ |
| Savings goals with progress | ✅ |
| Loans | ✅ |
| Habit streak tracking 🔥 | ✅ |
| Smart insights (swipeable) | ✅ |
| Pie and bar charts | ✅ |
| Notifications (daily, budget, goal, loan, weekly) | ✅ |
| Google sign-in | ✅ |
| Cloud sync (settings, expenses, goals, loans) | ✅ |
| Local storage with Hive (works offline) | ✅ |
| CSV export | ✅ |
| Sound effects | ✅ |
| Month-end savings prompt | ✅ |
| Warning when you screenshot your finances | ✅ |
| Recurring expenses | ✅ |
| Search, sort and filter | ✅ |

---

## 🧰 Tech Stack

- **Flutter / Dart** for the app
- **Hive** for local storage
- **Provider** for state management
- **Firebase Authentication** (Google sign-in)
- **Cloud Firestore** for cloud sync
- **fl_chart**, **table_calendar**, **flutter_animate**, **google_fonts**, **audioplayers**, **share_plus**, **csv**, **intl**, **flutter_colorpicker**

See `pubspec.yaml` for the full list and versions.

---

## 📁 Project Structure

```
lib/
├── models/       # Data models (Hive)
├── providers/    # State management and app logic
├── screens/      # App screens
├── widgets/      # Reusable UI parts
└── utils/        # Helpers (theme, formatting, CSV, sounds)
```

---

## 🚀 Setup

### 1. Prerequisites

- Flutter 3.19+ with Dart 3.0+
- Android Studio or VS Code with the Flutter extension
- A Firebase project (free Spark plan is enough)

### 2. Install dependencies

```
flutter pub get
```

### 3. Connect your own Firebase project

The Firebase config files are **not** included in this repo (they are in `.gitignore`). To run the app you need your own:

1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Install the tools and run:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This creates `lib/firebase_options.dart` and `android/app/google-services.json`.
3. In Firebase Console → **Authentication**, turn on **Google** sign-in.
4. Add your app's **SHA-1** fingerprint in Project settings → Your apps → Android.
5. In **Firestore**, create a database and use these rules so each user can only access their own data:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null
                            && request.auth.uid == userId;
       }
     }
   }
   ```
6. Restrict your API key to your Android package name and SHA-1 in Google Cloud Console → APIs & Services → Credentials.

### 4. Add sound files

Place these in `assets/sounds/`:

- `chaching.mp3` plays when you add an expense
- `celebration.mp3` plays when a goal or savings is completed
- `warning.mp3` plays when the budget is low

Free sources: [freesound.org](https://freesound.org), [zapsplat.com](https://zapsplat.com)

Lottie animations are optional. Put JSON files in `assets/lottie/` (from [lottiefiles.com](https://lottiefiles.com)). The app uses emoji instead if they are missing.

### 5. Run the app

```
flutter run
```

---

## 🔒 Privacy and Security

- Each signed-in user can only read and write their own data in Firestore.
- Do not commit `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, signing keys (`.jks`, `key.properties`) or service account files.

---

## 📄 License

Copyright (c) 2026 Anis Mones. All rights reserved. See the [LICENSE](LICENSE) file.
