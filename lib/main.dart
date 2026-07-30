import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'router/role_router.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const ComforGasApp());
}

class ComforGasApp extends StatelessWidget {
  const ComforGasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Comfor Gas',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const _SplashScreen();
      case AuthStatus.authenticated:
        return RoleRouter.destinationFor(auth.role);
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
        return const LoginScreen();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
        ),
      ),
    );
  }
}
