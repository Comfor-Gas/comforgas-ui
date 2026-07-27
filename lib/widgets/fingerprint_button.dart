import 'package:flutter/material.dart';

class FingerprintButton extends StatelessWidget {
  final VoidCallback? onTap;

  const FingerprintButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: const SizedBox(
        height: 120,
        width: 120,
        child: Image(
          image: AssetImage('assets/images/fingerprint.png'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
