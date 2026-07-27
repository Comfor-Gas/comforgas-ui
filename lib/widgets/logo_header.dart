import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Image(
          image: AssetImage('assets/images/logo_comfor_gas.png'),
          height: 200,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
