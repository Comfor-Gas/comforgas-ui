import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../core/responsive.dart';
import 'mobile/mobile_login_view.dart';
import 'desktop/desktop_login_view.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (Responsive.isDesktop(constraints)) {
            return const DesktopLoginView();
          }
          return const MobileLoginView();
        },
      ),
    );
  }
}