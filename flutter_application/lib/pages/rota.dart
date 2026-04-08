import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../services/providers.dart';
import '../widgets/app_layout.dart';

class Rota extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const Rota({super.key, this.onNavigate});

  @override
  State<Rota> createState() => _RotaState();
}

class _RotaState extends State<Rota> {
  final MapController _mapController = MapController();
  int selectedIndex = -1;
  final bool isAdmin = true;

  List<LatLng> _toLatLngList(List<Map<String, dynamic>> checkpoints) {
    final sorted = List<Map<String, dynamic>>.from(checkpoints)
      ..sort(
        (a, b) => ((a['order'] ?? 0) as num)
            .compareTo((b['order'] ?? 0) as num),
      );
    return sorted
        .map(
          (cp) => LatLng(
            (cp['latitude'] as num).toDouble(),
            (cp['longitude'] as num).toDouble(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Rotalar (KML/KMZ)',
      onNavigate: widget.onNavigate,
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, _) {
          if (courseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (courseProvider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Hata: ${courseProvider.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => courseProvider.loadCourses(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          final courses = courseProvider.courses;

          return LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Row(
                      children: [
                        // ===== COURSE LIST =====
                        SizedBox(
                          width: 360,
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.directions_walk,
                                        color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      'Rotalar (KML / KMZ)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Card(
                                  elevation: 2,
                                  margin: EdgeInsets.zero,
                                  child: courses.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('Henüz parkur yok.'),
                                              const SizedBox(height: 8),
                                              TextButton.icon(
                                                icon: const Icon(
                                                    Icons.upload_file),
                                                label: const Text(
                                                    'Dosya Yükle'),
                                                // Fixed: use onNavigate(4) instead of push
                                                onPressed: () =>
                                                    widget.onNavigate?.call(4),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: courses.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final course = courses[index];
                                            final isSelected =
                                                index == selectedIndex;

                                            return ListTile(
                                              selected: isSelected,
                                              selectedTileColor:
                                                  Colors.blue.shade50,
                                              leading: const Icon(
                                                Icons.location_on,
                                                color: Colors.red,
                                              ),
                                              title: Text(
                                                course['name']?.toString() ??
                                                    'Unknown',
                                              ),
                                              subtitle: Text(
                                                'ID: ${course['id']}',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              onTap: () async {
                                                setState(() {
                                                  selectedIndex = index;
                                                });
                                                await context
                                                    .read<CourseProvider>()
                                                    .loadCheckpoints(
                                                      course['id'] as int,
                                                    );

                                                final routePoints =
                                                    _toLatLngList(
                                                  context
                                                      .read<CourseProvider>()
                                                      .getCheckpoints(
                                                        course['id'] as int,
                                                      ),
                                                );

                                                if (routePoints.isNotEmpty &&
                                                    mounted) {
                                                  _mapController.move(
                                                    routePoints.first,
                                                    15,
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (isAdmin)
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.upload_file),
                                    label:
                                        const Text('Yeni Dosya Yükle (Admin)'),
                                    // Fixed: navigate via onNavigate instead of push
                                    onPressed: () =>
                                        widget.onNavigate?.call(4),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // ===== MAP PANEL =====
                        Expanded(
                          child: _MapPanel(
                            mapController: _mapController,
                            checkpoints: selectedIndex >= 0 &&
                                    selectedIndex < courses.length
                                ? courseProvider.getCheckpoints(
                                    courses[selectedIndex]['id'] as int,
                                  )
                                : const [],
                            toLatLngList: _toLatLngList,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({
    required this.mapController,
    required this.checkpoints,
    required this.toLatLngList,
  });

  final MapController mapController;
  final List<Map<String, dynamic>> checkpoints;
  final List<LatLng> Function(List<Map<String, dynamic>>) toLatLngList;

  @override
  Widget build(BuildContext context) {
    final selectedPoints = toLatLngList(checkpoints);

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: selectedPoints.isNotEmpty
                    ? selectedPoints.first
                    : const LatLng(41.0015, 39.7178),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.saha_takip',
                ),
                if (selectedPoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: selectedPoints,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (selectedPoints.isNotEmpty)
                  MarkerLayer(
                    markers: selectedPoints.asMap().entries.map((entry) {
                      return Marker(
                        point: entry.value,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.location_on,
                                color: Colors.red, size: 32),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        if (selectedPoints.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.yellow.shade200,
            width: double.infinity,
            child: const Text(
              'Lütfen sol taraftan görüntülenecek bir rota seçin.',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
