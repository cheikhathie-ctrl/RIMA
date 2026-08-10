import 'package:flutter/material.dart';
import 'colors.dart';

class RimaTextStyles {
  static const heading = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: RimaColors.textPrimary,
  );

  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: RimaColors.textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 16,
    color: RimaColors.textSecondary,
  );

  static const body = TextStyle(
    fontSize: 15,
    color: RimaColors.textPrimary,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}