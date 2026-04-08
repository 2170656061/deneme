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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CourseProvider()..loadCourses()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUsers()),
        ChangeNotifierProvider(create: (_) => ResultProvider()..loadResults()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SahaTakip',
        home: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              AnaSayfa(onNavigate: _navigateTo),
              Harita(onNavigate: _navigateTo),
              Rota(onNavigate: _navigateTo),
              YonetimPaneli(onNavigate: _navigateTo),
              DosyaYukle(onNavigate: _navigateTo),
              LoginPage(onNavigate: _navigateTo),
              RegisterPage(onNavigate: _navigateTo),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex > 4 ? 0 : _currentIndex,
            onDestinationSelected: _navigateTo,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Harita',
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined),
                selectedIcon: Icon(Icons.route),
                label: 'Rotalar',
              ),
              NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings),
                label: 'Yönetim',
              ),
              NavigationDestination(
                icon: Icon(Icons.upload_file_outlined),
                selectedIcon: Icon(Icons.upload_file),
                label: 'Dosya',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
