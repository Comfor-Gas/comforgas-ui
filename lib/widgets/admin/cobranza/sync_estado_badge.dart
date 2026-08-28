import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class SyncEstadoBadge extends StatelessWidget {
  final bool diferido;

  const SyncEstadoBadge({super.key, required this.diferido});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.badgeGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.badgeGreen.withOpacity(0.4)),
          ),
          child: const Text(
            'CONSISTENTE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: AppColors.badgeGreen,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          diferido ? 'Sync diferido' : 'Sync inmediato',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: diferido ? AppColors.badgeAmber : AppColors.graphiteGray,
          ),
        ),
      ],
    );
  }
}
