// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────
  static const primary = Color(0xFF25D366);
  static const primaryDark = Color(0xFF128C7E);
  static const primaryLight = Color(0xFFDCF8C6);

  // ── Background ─────────────────────────────────────────
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F2F5);

  // ── Text ───────────────────────────────────────────────
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFB4B2A9);
  static const textDisabled = Color(0xFFB4B2A9);

  // ── Border ─────────────────────────────────────────────
  static const border = Color(0xFFE0E0E0);
  static const borderFocus = primary;

  // ── Status ─────────────────────────────────────────────
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const success = primary;
  static const successLight = Color(0xFFDCF8C6);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);

  // ── Disabled ───────────────────────────────────────────
  static const disabled = Color(0xFFE5E4DC);
  static const disabledText = Color(0xFFB4B2A9);
}
