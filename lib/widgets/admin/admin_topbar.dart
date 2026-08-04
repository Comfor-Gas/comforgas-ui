import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class AdminTopbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;

  const AdminTopbar({super.key, this.onMenuTap});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!
        : (auth.user?.email ?? 'Admin');

    return Container(
      height: preferredSize.height,
      color: AppColors.steelBlue,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (onMenuTap != null)
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu, color: Colors.white),
            ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, color: Colors.white, size: 24),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthProvider>().logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
    );
  }
}
