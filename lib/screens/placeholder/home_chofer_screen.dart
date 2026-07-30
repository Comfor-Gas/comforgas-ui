import 'package:flutter/material.dart';

import 'role_placeholder_scaffold.dart';

class HomeChoferScreen extends StatelessWidget {
  const HomeChoferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderScaffold(
      title: 'Home Chofer',
      description: 'Descarga de Hoja de Ruta',
      icon: Icons.local_shipping_outlined,
    );
  }
}
