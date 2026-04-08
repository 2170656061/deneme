import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_layout.dart';
import '../services/providers.dart';

class AnaSayfa extends StatelessWidget {
  final void Function(int index)? onNavigate;
  const AnaSayfa({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return AppLayout(
          title: 'SahaTakip v2.0',
          onNavigate: onNavigate,
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (authProvider.isAuthenticated) ...[
                      // Show user info and logout when authenticated
                      Chip(
                        avatar: CircleAvatar(
                          backgroundColor: authProvider.isAdmin ? Colors.blue : Colors.grey,
                          child: Text(
                            (authProvider.currentUser?['username'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        label: Text(authProvider.currentUser?['username'] ?? ''),
                      ),
                      const SizedBox(width: 8),
                      if (authProvider.isAdmin)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Admin'),
                          onPressed: () => onNavigate?.call(3),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Çıkış'),
                        onPressed: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Başarıyla çıkış yapıldı'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    ] else ...[
                      // Show login button when not authenticated
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Giriş Yap'),
                        onPressed: () => onNavigate?.call(5),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Kayıt Ol'),
                        onPressed: () => onNavigate?.call(6),
                      ),
                    ],
                  ],
                ),
              ),
          const SizedBox(height: 16),
          const Text(
            "Ana Sayfa İçeriği",
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 24),

          // Karekod Tarama Kartı
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 80,
                        color: Colors.black54,
                      ),
                      SizedBox(height: 16),
                      Text("Request Camera Permissions"),
                      SizedBox(height: 6),
                      Text(
                        "Scan an Image File",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Karekod ve Son Konum Kartı
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                color: Colors.grey.shade100,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: const [
                      Text(
                        "Karekod Bekleniyor...",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 16),
                      Text("Son Bilinen Konum:"),
                      SizedBox(height: 6),
                      Text(
                        "40.943616 , 39.206912",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Baslat butonu
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    "CANLI TAKİBİ BAŞLAT",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    if (authProvider.isAuthenticated) {
                      // TODO: Start live tracking
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Canlı takip henüz uygulanmadı'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Lütfen önce giriş yapın'),
                          backgroundColor: Colors.red,
                          action: SnackBarAction(
                            label: 'Giriş Yap',
                            textColor: Colors.white,
                            onPressed: () => onNavigate?.call(5),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
