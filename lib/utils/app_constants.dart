import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppConstants {
  // Padding
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  // Border radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // Auto-save debounce
  static const Duration autoSaveDebounce = Duration(milliseconds: 800);

  // Note color hex values (aligned with AppTheme)
  static const List<String> noteColorHexLight = [
    '#FFFDE7',
    '#E8F5E9',
    '#E3F2FD',
    '#FCE4EC',
    '#F3E5F5',
    '#E0F2F1',
    '#FFF3E0',
    '#F1F8E9',
  ];

  static const List<String> noteColorHexDark = [
    '#4A4000',
    '#1B3A20',
    '#0D2B4E',
    '#4A1A28',
    '#2D1B45',
    '#0A2E2A',
    '#3E2000',
    '#1A2E0A',
  ];

  // Pen colors for drawing
  static const List<Color> penColors = [
    Colors.black,
    Colors.white,
    Color(0xFFE53935), // Red
    Color(0xFF43A047), // Green
    Color(0xFF1E88E5), // Blue
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Color(0xFFFFB300), // Amber
    Color(0xFF6D4C41), // Brown
  ];
}

class DateFormatter {
  static String format(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEEE').format(date);
    if (date.year == now.year) return DateFormat('MMM d').format(date);
    return DateFormat('MMM d, y').format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }
}

extension StringExtension on String {
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}…';
  }
}

extension ColorExtension on Color {
  String toHex() =>
      '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  bool get isLight {
    final luminance = computeLuminance();
    return luminance > 0.5;
  }
}
