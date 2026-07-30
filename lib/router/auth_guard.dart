import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

/// Envuelve una pantalla protegida y redirige al login si no hay una sesion que sea valida.

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    if (!isAuthenticated) {
      return const LoginScreen();
    }
    return child;
  }
}
