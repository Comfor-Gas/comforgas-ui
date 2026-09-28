import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../theme/app_colors.dart';

class ChoferNavBar extends StatelessWidget {
  final int indice;
  final ValueChanged<int> onCambio;

  const ChoferNavBar({super.key, required this.indice, required this.onCambio});

  static const List<(IconData, String)> _items = [
    (Icons.home_outlined, 'Inicio'),
    (Icons.event_note_outlined, 'Agenda'),
    (Icons.propane_tank_outlined, 'Stock'),
    (Icons.assignment_turned_in_outlined, 'Rendición'),
    (Icons.person_outline, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.inputBorder)),
        boxShadow: [
          BoxShadow(
            color: AppColors.steelBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: GNav(
            selectedIndex: indice,
            onTabChange: onCambio,
            gap: 6,
            haptic: true,
            iconSize: 22,
            color: AppColors.graphiteGray,
            activeColor: AppColors.orange,
            tabBackgroundColor: AppColors.orange.withOpacity(0.12),
            rippleColor: AppColors.orange.withOpacity(0.10),
            hoverColor: AppColors.steelBlue.withOpacity(0.06),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.orange,
            ),
            tabs: [
              for (final item in _items) GButton(icon: item.$1, text: item.$2),
            ],
          ),
        ),
      ),
    );
  }
}
