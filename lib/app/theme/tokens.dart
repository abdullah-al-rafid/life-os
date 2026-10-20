import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xFF080B14);
  static const surface = Color(0xFF101522);
  static const surfaceRaised = Color(0xFF171E2E);
  static const outline = Color(0xFF252E40);
  static const textPrimary = Color(0xFFF3F6FC);
  static const textSecondary = Color(0xFF9AA7BD);
  static const cyan = Color(0xFF62E6F5);
  static const purple = Color(0xFFAA8BFF);
  static const green = Color(0xFF78E0B1);
  static const warning = Color(0xFFFFC96B);
  static const error = Color(0xFFFF7D91);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadii {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const pill = 100.0;
}
