import 'package:flutter/material.dart';
import 'app_drawer.dart';

class AppLayout extends StatelessWidget {
  final String title;
  final Widget body;

  /// Optional callback forwarded to [AppDrawer] so drawer items can switch
  /// the [IndexedStack] page in main.dart without named routes.
  final void Function(int index)? onNavigate;

  const AppLayout({
    super.key,
    required this.title,
    required this.body,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: AppDrawer(onNavigate: onNavigate),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: body,
      ),
    );
  }
}
