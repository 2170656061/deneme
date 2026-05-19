import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/ana_sayfa.dart';
import 'pages/harita.dart';
import 'pages/rota.dart';
import 'pages/y_panel.dart';
import 'pages/dosya_yukle.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'services/providers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CourseProvider()..loadCourses()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()..loadResults()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SahaTakip',
        home: _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isAdmin = auth.isAdmin;

        // When an admin logs in, load users list (needs auth token)
        if (isAdmin && auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userProvider = context.read<UserProvider>();
            if (userProvider.users.isEmpty && !userProvider.isLoading) {
              userProvider.loadUsers(token: auth.token);
            }
          });
        }

        // Build the visible bottom-nav destinations based on role
        // Indices map:
        //   0 → Ana Sayfa
        //   1 → Harita
        //   2 → Rotalar
        //   3 → Yönetim  (admin only)
        //   4 → Dosya    (admin only)
        //   5 → Login    (hidden page)
        //   6 → Register (hidden page)

        final destinations = <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),
          const NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Rotalar',
          ),
          if (isAdmin) ...[
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Yönetim',
            ),
            const NavigationDestination(
              icon: Icon(Icons.upload_file_outlined),
              selectedIcon: Icon(Icons.upload_file),
              label: 'Dosya',
            ),
          ],
        ];

        // Map the visible index back to the logical page index
        // For guests: visible[0,1,2] → logical[0,1,2]
        // For admins: visible[0,1,2,3,4] → logical[0,1,2,3,4]
        int visibleIndex = _currentIndex;
        if (!isAdmin && (_currentIndex == 3 || _currentIndex == 4)) {
          // If we were on an admin page and user logged out, snap back to home.
          // Login (5) and register (6) must remain reachable for guests.
          visibleIndex = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _currentIndex = 0);
          });
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              AnaSayfa(onNavigate: _navigateTo),
              Harita(onNavigate: _navigateTo),
              Rota(onNavigate: _navigateTo),
              // Admin-only pages: still in the stack so state is preserved,
              // but a guard widget blocks guests from seeing their content.
              _AdminGuard(
                isAdmin: isAdmin,
                onNavigate: _navigateTo,
                child: YonetimPaneli(onNavigate: _navigateTo),
              ),
              _AdminGuard(
                isAdmin: isAdmin,
                onNavigate: _navigateTo,
                child: DosyaYukle(onNavigate: _navigateTo),
              ),
              LoginPage(onNavigate: _navigateTo),
              RegisterPage(onNavigate: _navigateTo),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: visibleIndex.clamp(0, destinations.length - 1),
            onDestinationSelected: (i) {
              // For guests, visible indices 0-2 map directly to logical 0-2
              // For admins, visible 0-4 map directly to logical 0-4
              _navigateTo(i);
            },
            destinations: destinations,
          ),
        );
      },
    );
  }
}

/// Wraps an admin-only page. Guests see a "login required" message instead.
class _AdminGuard extends StatelessWidget {
  final bool isAdmin;
  final Widget child;
  final void Function(int index) onNavigate;

  const _AdminGuard({
    required this.isAdmin,
    required this.child,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (isAdmin) return child;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Bu sayfaya erişmek için\ngiriş yapmanız gerekiyor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Giriş Yap'),
            onPressed: () => onNavigate(5),
          ),
        ],
      ),
    );
  }
}
