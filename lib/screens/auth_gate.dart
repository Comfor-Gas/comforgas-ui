import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../router/role_router.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthProvider? _auth;
  AuthStatus? _resolvedStatus;
  UserRole? _resolvedRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (!identical(_auth, auth)) {
      _auth?.removeListener(_handleChange);
      _auth = auth;
      auth.addListener(_handleChange);
      _handleChange(); 
    }
  }

  void _handleChange() {
    if (_resolvedStatus != null) return; 
    final auth = _auth;
    if (auth == null) return;
    if (auth.status == AuthStatus.unknown) return; 

    setState(() {
      _resolvedStatus = auth.status;
      _resolvedRole = auth.role;
    });
  }

  @override
  void dispose() {
    _auth?.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedStatus = _resolvedStatus;

    if (resolvedStatus == null) {
      return const _SplashScreen();
    }

    if (resolvedStatus == AuthStatus.authenticated) {
      return RoleRouter.destinationFor(_resolvedRole ?? UserRole.unknown);
    }

    return const LoginScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
    );
  }
}
