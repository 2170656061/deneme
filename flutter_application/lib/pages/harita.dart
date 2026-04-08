import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/app_layout.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class Harita extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const Harita({super.key, this.onNavigate});

  @override
  State<Harita> createState() => _HaritaState();
}

class _HaritaState extends State<Harita> {
  Uint8List? pickedBytes;
  String? pickedFilePath;
  String fileName = 'Dosya seçilmedi.';

  final TransformationController _tc = TransformationController();
  int? _draggingIndex;
  Offset? _lastScenePoint;
  List<Offset> dots = [];

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
      pickedFilePath = kIsWeb ? null : result.files.single.path;
      dots.clear();
      _tc.value = Matrix4.identity(); // reset zoom/pan on new image
    });
  }

  void _deleteAllDots() => setState(() => dots.clear());

  void _deleteLastDot() {
    if (dots.isNotEmpty) setState(() => dots.removeLast());
  }

  @override
  Widget build(BuildContext context) {
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
                      // LEFT: user selector
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
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              hint: const Text('-- Kullanıcı Seçiniz --'),
                              items: const [],
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Bir kullanıcı seçerek rotasını izleyebilirsiniz.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // RIGHT: map upload + dot controls
                      Expanded(
                        flex: 3,
                        child: Column(
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
                                // Fixed: separate "last" and "all" delete buttons
                                IconButton(
                                  icon: const Icon(Icons.undo,
                                      color: Colors.orange),
                                  tooltip: 'Son noktayı sil',
                                  onPressed:
                                      dots.isEmpty ? null : _deleteLastDot,
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed:
                                      dots.isEmpty ? null : _deleteAllDots,
                                  child: const Text('Tüm Noktaları Sil'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 16, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Yönetici Modu: Haritaya tıklayarak nokta ekleyin, '
                                    'noktaları sürükleyerek taşıyın. '
                                    'Toplam: ${dots.length} nokta',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map, size: 64, color: Colors.black26),
                              SizedBox(height: 12),
                              Text(
                                'Harita yüklenmedi',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black45),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '"Browse" ile bir görsel seçin',
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
                            onTapDown: (details) {
                              // Convert tap position to scene (image) coordinates
                              final scenePoint =
                                  _tc.toScene(details.localPosition);
                              setState(() => dots.add(scenePoint));
                            },
                            child: Stack(
                              children: [
                                // Map image
                                Image.memory(
                                  pickedBytes!,
                                  fit: BoxFit.contain,
                                ),

                                // Dots overlay
                                ...dots.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final offset = entry.value;

                                  return Positioned(
                                    left: offset.dx - 15,
                                    top: offset.dy - 15,
                                    child: GestureDetector(
                                      onPanStart: (d) {
                                        _draggingIndex = index;
                                        _lastScenePoint =
                                            _tc.toScene(d.localPosition);
                                      },
                                      onPanUpdate: (d) {
                                        if (_draggingIndex != index) return;
                                        final now =
                                            _tc.toScene(d.localPosition);
                                        final last = _lastScenePoint ?? now;
                                        final delta = now - last;
                                        setState(() {
                                          dots[index] = dots[index] + delta;
                                          _lastScenePoint = now;
                                        });
                                      },
                                      onPanEnd: (_) {
                                        _draggingIndex = null;
                                        _lastScenePoint = null;
                                      },
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
  }
}
