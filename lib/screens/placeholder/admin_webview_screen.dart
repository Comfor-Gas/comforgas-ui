import 'package:flutter/material.dart';

import 'role_placeholder_scaffold.dart';

class AdminWebviewScreen extends StatelessWidget {
  const AdminWebviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderScaffold(
      title: 'Panel Admin',
      description: 'Webview del panel administrativo',
      icon: Icons.admin_panel_settings_outlined,
    );
  }
}
