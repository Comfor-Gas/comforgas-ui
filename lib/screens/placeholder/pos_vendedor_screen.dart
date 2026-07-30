import 'package:flutter/material.dart';

import 'role_placeholder_scaffold.dart';

class PosVendedorScreen extends StatelessWidget {
  const PosVendedorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderScaffold(
      title: 'POS Local',
      description: 'Ventas de Mostrador',
      icon: Icons.point_of_sale_outlined,
    );
  }
}
