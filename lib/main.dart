import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ComforGasApp());
}

class ComforGasApp extends StatelessWidget {
  const ComforGasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comfor Gas',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
