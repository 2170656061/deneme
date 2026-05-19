import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/providers.dart';
import '../widgets/app_layout.dart';
import 'dart:typed_data';

class Harita extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const Harita({super.key, this.onNavigate});

  @override
  State<Harita> createState() => _HaritaState();
}

class _HaritaState extends State<Harita> {
  Uint8List? pickedBytes;
  String fileName = 'Dosya seçilmedi.';

  final TransformationController _tc = TransformationController();
  int? _draggingIndex;
  Offset? _lastScenePoint;
  List<Offset> dots = [];

  // Selected user for tracking view
  Map<String, dynamic>? _selectedUser;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;

    setState(() {
      fileName = result.files.single.name;
      pickedBytes = result.files.single.bytes;
      dots.clear();
      _tc.value = Matrix4.identity();
    });
  }

  void _deleteAllDots() => setState(() => dots.clear());

  void _deleteLastDot() {
    if (dots.isNotEmpty) setState(() => dots.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, auth, userProvider, _) {
        final isAdmin = auth.isAdmin;

        return AppLayout(
          title: 'Harita Durumu',
          onNavigate: widget.onNavigate,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== TOP TOOLBAR =====
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT: user selector — only for admins
                          if (isAdmin) ...[
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kimin Haritası?',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<Map<String, dynamic>>(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    hint: const Text('-- Kullanıcı Seçiniz --'),
                                    value: _selectedUser,
                                    items: userProvider.users.map((u) {
                                      return DropdownMenuItem<Map<String, dynamic>>(
                                        value: u,
                                        child: Text(
                                          u['username']?.toString() ?? 'Unknown',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedUser = value);
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedUser != null
                                        ? 'Seçili: ${_selectedUser!['username']} (${_selectedUser!['role']})'
                                        : 'Bir kullanıcı seçerek rotasını izleyebilirsiniz.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],

                          // RIGHT: map upload + dot controls (admin only)
                          if (isAdmin)
                            Expanded(
                              flex: 3,
                              child: _buildAdminMapControls(),
                            )
                          else
                            // Guest: read-only notice
                            Expanded(
                              child: _buildGuestNotice(context),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== MAP AREA =====
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: pickedBytes == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.map,
                                      size: 64, color: Colors.black26),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Harita yüklenmedi',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black45),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isAdmin)
                                    const Text(
                                      '"Browse" ile bir görsel seçin',
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  else
                                    const Text(
                                      'Admin bir harita yüklemedi',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                ],
                              ),
                            )
                          : InteractiveViewer(
                              transformationController: _tc,
                              boundaryMargin: const EdgeInsets.all(100),
                              minScale: 0.5,
                              maxScale: 8,
                              child: GestureDetector(
                                onTapDown: isAdmin
                                    ? (details) {
                                        final scenePoint =
                                            _tc.toScene(details.localPosition);
                                        setState(() => dots.add(scenePoint));
                                      }
                                    : null, // guests cannot add dots
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      pickedBytes!,
                                      fit: BoxFit.contain,
                                    ),
                                    ...dots.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final offset = entry.value;

                                      return Positioned(
                                        left: offset.dx - 15,
                                        top: offset.dy - 15,
                                        child: GestureDetector(
                                          onPanStart: isAdmin
                                              ? (d) {
                                                  _draggingIndex = index;
                                                  _lastScenePoint =
                                                      _tc.toScene(d.localPosition);
                                                }
                                              : null,
                                          onPanUpdate: isAdmin
                                              ? (d) {
                                                  if (_draggingIndex != index) return;
                                                  final now =
                                                      _tc.toScene(d.localPosition);
                                                  final last =
                                                      _lastScenePoint ?? now;
                                                  final delta = now - last;
                                                  setState(() {
                                                    dots[index] =
                                                        dots[index] + delta;
                                                    _lastScenePoint = now;
                                                  });
                                                }
                                              : null,
                                          onPanEnd: isAdmin
                                              ? (_) {
                                                  _draggingIndex = null;
                                                  _lastScenePoint = null;
                                                }
                                              : null,
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminMapControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Harita Yükle (Admin)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text('Browse'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.orange),
              tooltip: 'Son noktayı sil',
              onPressed: dots.isEmpty ? null : _deleteLastDot,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: dots.isEmpty ? null : _deleteAllDots,
              child: const Text('Tüm Noktaları Sil'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.redAccent),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Yönetici Modu: Haritaya tıklayarak nokta ekleyin, '
                'noktaları sürükleyerek taşıyın. '
                'Toplam: ${dots.length} nokta',
                style: const TextStyle(fontSize: 13, color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestNotice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Görüntüleme Modu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Haritayı görüntüleyebilir ve yakınlaştırabilirsiniz. '
          'Nokta eklemek için admin girişi gereklidir.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Giriş Yap'),
          onPressed: () => widget.onNavigate?.call(5),
        ),
      ],
    );
  }
}
