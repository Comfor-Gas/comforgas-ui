import 'package:flutter/material.dart';

import 'role_placeholder_scaffold.dart';

class UnknownRoleScreen extends StatelessWidget {
  const UnknownRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderScaffold(
      title: 'Rol no reconocido',
      description: 'Tu usuario no tiene un rol válido asignado. Contacta al administrador.',
      icon: Icons.help_outline,
    );
  }
}
