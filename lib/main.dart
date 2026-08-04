import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const ComforGasApp());
}

class ComforGasApp extends StatelessWidget {
  const ComforGasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..restoreSession(),
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Comfor Gas',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        builder: (context, child) => _SessionWatcher(child: child!),
        home: const LoginScreen(),
      ),
    );
  }
}

class _SessionWatcher extends StatefulWidget {
  final Widget child;

  const _SessionWatcher({required this.child});

  @override
  State<_SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<_SessionWatcher> {
  AuthProvider? _auth;
  AuthStatus? _previousStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (!identical(_auth, auth)) {
      _auth?.removeListener(_handleAuthChange);
      _auth = auth;
      _previousStatus = auth.status;
      auth.addListener(_handleAuthChange);
    }
  }

  void _handleAuthChange() {
    final auth = _auth;
    if (auth == null) return;

    final wasAuthenticated = _previousStatus == AuthStatus.authenticated;
    _previousStatus = auth.status;

    if (wasAuthenticated && auth.status == AuthStatus.unauthenticated) {
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_handleAuthChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
