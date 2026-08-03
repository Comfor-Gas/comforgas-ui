import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.steelBlue,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.steelBlue,
  );

  static const TextStyle input = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.steelBlue,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.inputHint,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 0.8,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.graphiteGray,
  );

  static const TextStyle errorText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );

  static const TextStyle footer = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.footerText,
  );


  static const TextStyle panelTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.15,
  );

  static const TextStyle panelBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFFE3E9EF),
    height: 1.5,
  );

  static const TextStyle desktopTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.steelBlue,
  );

  static const TextStyle desktopSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.graphiteGray,
  );

  static const TextStyle footerLink = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.graphiteGray,
  );
}
