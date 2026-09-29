import 'package:flutter/material.dart';

import '../../../core/responsive.dart';

class FlotaDialogoLayout {
  FlotaDialogoLayout._();

  static EdgeInsets inset(BuildContext context, {double vertical = 32}) {
    if (Responsive.isMobileContext(context)) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 20);
    }
    return EdgeInsets.symmetric(horizontal: 24, vertical: vertical);
  }

  static EdgeInsets contenido(BuildContext context, {double inferior = 22}) {
    if (Responsive.isMobileContext(context)) {
      return EdgeInsets.fromLTRB(16, 18, 16, inferior < 18 ? inferior : 18);
    }
    return EdgeInsets.fromLTRB(24, 22, 24, inferior);
  }

  static TextStyle titulo(BuildContext context, TextStyle base) {
    return base.copyWith(fontSize: Responsive.isMobileContext(context) ? 18 : 20);
  }
}

class FlotaAccionesDialogo extends StatelessWidget {
  final Widget secundaria;
  final Widget primaria;

  const FlotaAccionesDialogo({
    super.key,
    required this.secundaria,
    required this.primaria,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobileContext(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          primaria,
          const SizedBox(height: 10),
          secundaria,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: secundaria),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: primaria),
      ],
    );
  }
}
