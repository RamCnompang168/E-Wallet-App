import 'package:flutter/material.dart';

/// Shared NovaPay design tokens and color palette.
abstract final class AppColors {
  static const primaryDark = Color(0xFF0F2624);
  static const accentGreen = Color(0xFF38E54D);
  static const accentGreenLight = Color(0xFF4ADE80);
  static const surfaceLight = Color(0xFFF8FAFC);
  static const cardBackground = Colors.white;
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFF1F5F9);
  static const danger = Color(0xFFDC2626);

  // Semantic and backward-compatible aliases
  static const primary = primaryDark;
  static const blue = accentGreen;
  static const black = textPrimary;
  static const background = surfaceLight;
  static const text = textPrimary;
  static const surface = cardBackground;
  static const surfaceRaised = Color(0xFFF1F5F9);
  static const muted = textSecondary;
  static const emerald = accentGreen;
  static const yellow = accentGreen;
  static const amber = accentGreen;
  static const indigo = accentGreen;
  static const navy = primaryDark;
  static const light = surfaceLight;
}
