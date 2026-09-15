import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'models/user_role.dart';
import 'local/agenda_cache_service.dart';
import 'local/canje_offline_service.dart';
import 'local/cobro_offline_service.dart';
import 'local/comodato_offline_service.dart';
import 'local/offline_queue_service.dart';
import 'local/stock_camion_cache_service.dart';
import 'local/venta_social_local_service.dart';
import 'services/app_lock_controller.dart';
import 'services/canje_sync_manager.dart';
import 'services/cobro_sync_manager.dart';
import 'services/comodato_sync_manager.dart';
import 'services/sync_manager.dart';
import 'services/ubicacion_tracking_service.dart';
import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
import 'widgets/app_lock_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await OfflineQueueService.instance.init();
  await CobroOfflineService.instance.init();
  await ComodatoOfflineService.instance.init();
  await CanjeOfflineService.instance.init();
  await VentaSocialLocalService.instance.init();
  await AgendaCacheService.instance.init();
  await StockCamionCacheService.instance.init();
  runApp(const ComforGasApp());
}

class ComforGasApp extends StatelessWidget {
  const ComforGasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..restoreSession()),
        ChangeNotifierProvider(create: (_) => AppLockController()),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'Comfor Gas',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        builder: (context, child) => _AppShell(child: child!),
        home: const AuthGate(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  final Widget child;

  const _AppShell({required this.child});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  AuthProvider? _auth;
  AppLockController? _lock;
  AuthStatus? _previousStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final lock = context.read<AppLockController>();
    if (!identical(_auth, auth)) {
      _auth?.removeListener(_handleAuthChange);
      _lock?.removeListener(_handleLockChange);
      _auth = auth;
      _lock = lock;
      _previousStatus = auth.status;
      auth.addListener(_handleAuthChange);
      lock.addListener(_handleLockChange);
    }
  }

  void _handleAuthChange() {
    final auth = _auth;
    final lock = _lock;
    if (auth == null || lock == null) return;

    final previousStatus = _previousStatus;
    final status = auth.status;
    _previousStatus = status;

    if (status == AuthStatus.authenticated &&
        previousStatus != AuthStatus.authenticated) {
      lock.onSessionChanged(isAuthenticated: true, userEmail: auth.user?.email);
      SyncManager.instance.configurar(auth.apiClient);
      CobroSyncManager.instance.configurar(auth.apiClient);
      ComodatoSyncManager.instance.configurar(auth.apiClient);
      CanjeSyncManager.instance.configurar(auth.apiClient);
      if (auth.role == UserRole.chofer) {
        unawaited(UbicacionTrackingService.instance.iniciar(auth.apiClient));
      }
    } else if (previousStatus == AuthStatus.authenticated &&
        status == AuthStatus.unauthenticated) {
      lock.onSessionChanged(isAuthenticated: false);
      SyncManager.instance.detener();
      CobroSyncManager.instance.detener();
      ComodatoSyncManager.instance.detener();
      CanjeSyncManager.instance.detener();
      unawaited(UbicacionTrackingService.instance.detener());
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _handleLockChange() {
    final lock = _lock;
    final auth = _auth;
    if (lock == null || auth == null) return;

    if (lock.attemptsExhausted) {
      lock.resetAttempts();
      auth.logout();
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Superaste el máximo de intentos con huella/PIN. Ingresá con tu correo y contraseña.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_handleAuthChange);
    _lock?.removeListener(_handleLockChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockController>();

    return Stack(
      children: [
        widget.child,
        if (lock.isLocked)
          AppLockScreen(
            isAuthenticating: lock.isAuthenticating,
            remainingAttempts: lock.remainingAttempts,
            maxAttempts: AppLockController.maxAttempts,
            onRetry: lock.retry,
            onUseLoginInstead: () {
              context.read<AuthProvider>().logout();
            },
          ),
      ],
    );
  }
}
