import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'admin_sidebar.dart';

class AdminBarraMovil extends StatelessWidget {
  final int indice;
  final VoidCallback onMenu;

  const AdminBarraMovil({super.key, required this.indice, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final item = indice >= 0 && indice < adminNavItems.length ? adminNavItems[indice] : null;
    return Material(
      color: SidebarPaleta.lienzo,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.25),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Menú',
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.orange, width: 1.6),
                ),
                child: Image.asset('assets/images/logomolecula.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMFOR GAS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (item != null)
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              if (item != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(item.icon, color: Colors.white.withOpacity(0.7), size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
