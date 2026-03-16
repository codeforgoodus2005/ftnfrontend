import 'package:flutter/material.dart';

/// Centralized button styling to keep the app's CTAs consistent.
class AppButtonStyles {
  static ButtonStyle loginPrimary() {
    return ElevatedButton.styleFrom(
      // "Deep yellow" rectangular login button style.
      backgroundColor: const Color(0xFFF2B705),
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0,
    );
  }
}
