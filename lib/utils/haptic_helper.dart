import 'package:flutter/services.dart';

class HapticHelper {
  static bool enabled = true;

  static void light() {
    if (enabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void medium() {
    if (enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavy() {
    if (enabled) {
      HapticFeedback.heavyImpact();
    }
  }

  static void selection() {
    if (enabled) {
      HapticFeedback.selectionClick();
    }
  }

  static void vibrate() {
    if (enabled) {
      HapticFeedback.vibrate();
    }
  }
}
