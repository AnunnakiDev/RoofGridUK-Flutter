import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/auth/models/user_model.dart';
import 'package:roofgrid_uk/app/auth/providers/auth_provider.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          userAsync.when(
            data: (user) => _buildUserHeader(context, user),
            loading: () => _buildLoadingHeader(context),
            error: (_, __) => _buildErrorHeader(context),
          ),

          // Main Navigation
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'MAIN NAVIGATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            title: 'Home',
            route: '/home',
          ),
          _buildNavItem(
            context,
            icon: Icons.calculate_outlined,
            title: 'Calculators',
            route: '/calculator',
          ),
          userAsync.when(
            data: (user) {
              if (user != null && user.isAdmin) {
                return _buildNavItem(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin Dashboard',
                  route: '/admin',
                );
              } else {
                return const SizedBox.shrink();
              }
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(),

          // Support Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'SUPPORT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          _buildNavItem(
            context,
            icon: Icons.help_outline,
            title: 'FAQs',
            route: '/support/faq',
          ),
          _buildNavItem(
            context,
            icon: Icons.email_outlined,
            title: 'Contact Us',
            route: '/support/contact',
          ),
          _buildNavItem(
            context,
            icon: Icons.description_outlined,
            title: 'Legal Information',
            route: '/support/legal',
          ),

          const Divider(),

          // Account Section
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              await ref.read(authServiceProvider).signOut();
              // Router will handle redirect
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, UserModel? user) {
    return UserAccountsDrawerHeader(
      accountName: Text(user?.displayName ?? 'User'),
      accountEmail: Text(user?.email ?? ''),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          _getInitials(user?.displayName ?? 'U'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildLoadingHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: const Center(
        child: Text(
          'Error loading profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final isSelected = currentLocation.startsWith(route);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: isSelected
            ? TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (currentLocation != route) {
          context.go(route);
        }
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
