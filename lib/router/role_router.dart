import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../screens/placeholder/admin_webview_screen.dart';
import '../screens/placeholder/home_chofer_screen.dart';
import '../screens/placeholder/pos_vendedor_screen.dart';
import '../screens/placeholder/under_construction_screen.dart';
import '../screens/placeholder/unknown_role_screen.dart';

class RoleRouter {
  static Widget destinationFor(UserRole role) {
    switch (role) {
      case UserRole.chofer:
        return const HomeChoferScreen();
      case UserRole.vendedor:
        return const PosVendedorScreen();
      case UserRole.admin:
        return const AdminWebviewScreen();
      case UserRole.gerente:
      case UserRole.adminIt:
        return const UnderConstructionScreen();
      case UserRole.unknown:
        return const UnknownRoleScreen();
    }
  }

  static void goToRoleHome(BuildContext context, UserRole role) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destinationFor(role)),
      (route) => false,
    );
  }
}
