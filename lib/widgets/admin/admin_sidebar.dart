import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AdminNavItem {
  final IconData icon;
  final String label;

  const AdminNavItem({required this.icon, required this.label});
}

const List<AdminNavItem> adminNavItems = [
  AdminNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
  AdminNavItem(icon: Icons.event_note_outlined, label: 'Planificación'),
  AdminNavItem(icon: Icons.location_on_outlined, label: 'Seguimiento'),
  AdminNavItem(icon: Icons.groups_outlined, label: 'Clientes'),
  AdminNavItem(icon: Icons.alt_route_outlined, label: 'Rutas'),
  AdminNavItem(icon: Icons.settings_outlined, label: 'Configuración'),
];

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SidebarLogo(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: adminNavItems.length,
              itemBuilder: (context, index) {
                final item = adminNavItems[index];
                final selected = index == selectedIndex;
                return _SidebarTile(
                  item: item,
                  selected: selected,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logomolecula.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'COMFOR\nGAS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.sidebarActive
                : (_hover ? Colors.white.withOpacity(0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: selected ? Colors.white : Colors.white.withOpacity(0.75),
              ),
              const SizedBox(width: 14),
              Text(
                widget.item.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.4,
                  color: selected ? Colors.white : Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
