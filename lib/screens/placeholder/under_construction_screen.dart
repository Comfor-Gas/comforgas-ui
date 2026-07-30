import 'package:flutter/material.dart';
import 'role_placeholder_scaffold.dart';

class UnderConstructionScreen extends StatelessWidget {
  const UnderConstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderScaffold(
      title: 'En construcción',
      description:
          'Esta sección todavía está en construcción. Pronto vas a poder usarla.',
      icon: Icons.construction_outlined,
    );
  }
}
