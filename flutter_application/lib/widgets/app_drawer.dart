import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/providers.dart';

class AppDrawer extends StatelessWidget {
  final void Function(int index)? onNavigate;

  const AppDrawer({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isAdmin = auth.isAdmin;
        final isAuthenticated = auth.isAuthenticated;
        final username = auth.currentUser?['username'] ?? '';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.directions_run,
                        color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'SahaTakip v2.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isAuthenticated) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$username${isAdmin ? ' (Admin)' : ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
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

              // Admin-only items
              if (isAdmin) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'YÖNETİM',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
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

              const Divider(),

              // Auth actions
              if (isAuthenticated)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Çıkış Yap',
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await auth.logout();
                    if (context.mounted) {
                      onNavigate?.call(0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Başarıyla çıkış yapıldı'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                )
              else ...[
                _DrawerItem(
                  icon: Icons.login,
                  title: 'Giriş Yap',
                  index: 5,
                  onNavigate: onNavigate,
                ),
                _DrawerItem(
                  icon: Icons.person_add,
                  title: 'Kayıt Ol',
                  index: 6,
                  onNavigate: onNavigate,
                ),
              ],
            ],
          ),
        );
      },
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
        Navigator.of(context).pop();
        onNavigate?.call(index);
      },
    );
  }
}
