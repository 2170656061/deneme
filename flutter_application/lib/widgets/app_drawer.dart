import 'package:flutter/material.dart';

/// A simple callback-based drawer so we don't rely on named routes.
/// Pass [onNavigate] with the page index to switch to.
class AppDrawer extends StatelessWidget {
  /// Called with the bottom-nav index when user taps a menu item.
  final void Function(int index)? onNavigate;

  const AppDrawer({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.directions_run, color: Colors.white, size: 36),
                SizedBox(height: 8),
                Text(
                  'SahaTakip v2.0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.home,
            title: 'Ana Sayfa',
            index: 0,
            onNavigate: onNavigate,
          ),
          _DrawerItem(
            icon: Icons.map,
            title: 'Harita',
            index: 1,
            onNavigate: onNavigate,
          ),
          _DrawerItem(
            icon: Icons.route,
            title: 'Rotalar',
            index: 2,
            onNavigate: onNavigate,
          ),
          _DrawerItem(
            icon: Icons.admin_panel_settings,
            title: 'Yönetim Paneli',
            index: 3,
            onNavigate: onNavigate,
          ),
          _DrawerItem(
            icon: Icons.upload_file,
            title: 'Dosya Yükle',
            index: 4,
            onNavigate: onNavigate,
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int index;
  final void Function(int)? onNavigate;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.index,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        onNavigate?.call(index);
      },
    );
  }
}
