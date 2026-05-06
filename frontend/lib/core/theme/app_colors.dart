import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const indigo = Color(0xFF6366F1);
  static const indigoDark = Color(0xFF4F46E5);
  static const indigoLight = Color(0xFFA5B4FC);

  // Semantic
  static const success = Color(0xFF10B981);   // Easy
  static const warning = Color(0xFFF59E0B);   // Hard
  static const error = Color(0xFFEF4444);     // Again
  static const info = Color(0xFF3B82F6);      // Good

  // Dark surfaces
  static const darkBase = Color(0xFF0F172A);
  static const darkCard = Color(0xFF1E293B);
  static const darkCardElevated = Color(0xFF293548);
  static const darkBorder = Color(0xFF334155);

  // Light surfaces
  static const lightBase = Color(0xFFF8FAFC);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);

  // Text
  static const textPrimaryDark = Color(0xFFF1F5F9);
  static const textMutedDark = Color(0xFF94A3B8);
  static const textDimDark = Color(0xFF64748B);

  static const textPrimaryLight = Color(0xFF0F172A);
  static const textMutedLight = Color(0xFF475569);
  static const textDimLight = Color(0xFF94A3B8);

  // Review ratings
  static const ratingAgain = Color(0xFFEF4444);
  static const ratingHard = Color(0xFFF59E0B);
  static const ratingGood = Color(0xFF3B82F6);
  static const ratingEasy = Color(0xFF10B981);

  // Deck accent colors
  static const List<Color> deckAccents = [
    Color(0xFF6366F1), // indigo
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFFEF4444), // red
    Color(0xFF14B8A6), // teal
  ];
}
