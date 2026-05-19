import 'package:flutter/material.dart';
import '../widgets/app_layout.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/providers.dart';
import '../services/api_service.dart';

class YonetimPaneli extends StatelessWidget {
  final void Function(int index)? onNavigate;
  const YonetimPaneli({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Yönetim Paneli',
      onNavigate: onNavigate,
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: '📊 Genel Bakış', icon: Icon(Icons.dashboard)),
                Tab(text: '🏃 Parkurlar', icon: Icon(Icons.route)),
                Tab(text: '📍 Kontrol Noktaları', icon: Icon(Icons.location_on)),
                Tab(text: '🏁 Sonuçlar', icon: Icon(Icons.emoji_events)),
                Tab(text: '👥 Kullanıcılar', icon: Icon(Icons.people)),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _DashboardTab(),
                  _CoursesTab(),
                  _CheckpointsTab(),
                  _ResultsTab(),
                  _UsersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ DASHBOARD TAB ============
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real stats from providers
          Consumer3<CourseProvider, UserProvider, ResultProvider>(
            builder: (context, courses, users, results, _) {
              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Parkurlar',
                      value: '${courses.courses.length}',
                      icon: Icons.route,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Toplam Kullanıcı',
                      value: '${users.users.length}',
                      icon: Icons.people,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Toplam Sonuç',
                      value: '${results.results.length}',
                      icon: Icons.check_circle,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Adminler',
                      value: '${users.users.where((u) => u['role'] == 'admin').length}',
                      icon: Icons.admin_panel_settings,
                      color: Colors.red,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Map Preview
          const Text(
            'Harita Önizleme',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(39.607900, 41.009379),
                  initialZoom: 10,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.saha_takip',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============ COURSES TAB ============
class _CoursesTab extends StatelessWidget {
  const _CoursesTab();

  Future<void> _showCreateCourseDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final distCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Parkur Ekle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Parkur Adı *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ad gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: distCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mesafe (km)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              try {
                final token = context.read<AuthProvider>().token;
                await ApiService.createCourse(
                  nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  distanceKm: distCtrl.text.trim().isEmpty
                      ? null
                      : double.tryParse(distCtrl.text.trim()),
                  token: token,
                );
                if (context.mounted) {
                  context.read<CourseProvider>().loadCourses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Parkur eklendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(BuildContext context, int courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Parkuru Sil'),
        content: const Text('Bu parkuru silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final token = context.read<AuthProvider>().token;
        await ApiService.deleteCourse(courseId, token: token);
        if (context.mounted) {
          context.read<CourseProvider>().loadCourses();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Parkur silindi.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Parkur Yönetimi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateCourseDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Parkur'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<CourseProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(child: Text('Hata: ${provider.error}'));
                }
                if (provider.courses.isEmpty) {
                  return const Center(
                    child: Text('Henüz parkur yok. Yeni parkur ekleyin.'),
                  );
                }
                return Card(
                  child: ListView.separated(
                    itemCount: provider.courses.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final course = provider.courses[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.route),
                        ),
                        title: Text(course['name']?.toString() ?? 'Unknown'),
                        subtitle: Text(
                          'ID: ${course['id']} • ${course['distance_km'] != null ? '${course['distance_km']} km' : 'Mesafe belirtilmemiş'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Sil',
                              onPressed: () =>
                                  _deleteCourse(context, course['id'] as int),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============ CHECKPOINTS TAB ============
class _CheckpointsTab extends StatelessWidget {
  const _CheckpointsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<CourseProvider>(
        builder: (context, courseProvider, _) {
          final courses = courseProvider.courses;

          if (courses.isEmpty) {
            return const Center(
              child: Text('Önce bir parkur oluşturun.'),
            );
          }

          return _CheckpointBody(courses: courses, courseProvider: courseProvider);
        },
      ),
    );
  }
}

class _CheckpointBody extends StatefulWidget {
  final List<Map<String, dynamic>> courses;
  final CourseProvider courseProvider;

  const _CheckpointBody({
    required this.courses,
    required this.courseProvider,
  });

  @override
  State<_CheckpointBody> createState() => _CheckpointBodyState();
}

class _CheckpointBodyState extends State<_CheckpointBody> {
  int? _selectedCourseId;

  Future<void> _showAddCheckpointDialog(BuildContext context, int courseId) async {
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final currentCheckpoints = widget.courseProvider.getCheckpoints(courseId);
    final nextOrder = currentCheckpoints.length + 1;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kontrol Noktası Ekle (#$nextOrder)'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: latCtrl,
                decoration: const InputDecoration(
                  labelText: 'Enlem (Latitude) *',
                  border: OutlineInputBorder(),
                  hintText: 'örn: 41.0082',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enlem gerekli';
                  if (double.tryParse(v.trim()) == null) return 'Geçerli bir sayı girin';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Boylam (Longitude) *',
                  border: OutlineInputBorder(),
                  hintText: 'örn: 28.9784',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Boylam gerekli';
                  if (double.tryParse(v.trim()) == null) return 'Geçerli bir sayı girin';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              try {
                final token = context.read<AuthProvider>().token;
                await ApiService.createCheckpoint(
                  courseId,
                  nextOrder,
                  double.parse(latCtrl.text.trim()),
                  double.parse(lonCtrl.text.trim()),
                  token: token,
                );
                if (context.mounted) {
                  // Force reload checkpoints for this course
                  widget.courseProvider.forceReloadCheckpoints(courseId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kontrol noktası eklendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course selector
        Row(
          children: [
            const Text(
              'Parkur Seç:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedCourseId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                hint: const Text('-- Parkur Seçiniz --'),
                items: widget.courses
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(c['name']?.toString() ?? 'Unknown'),
                      ),
                    )
                    .toList(),
                onChanged: (id) async {
                  setState(() => _selectedCourseId = id);
                  if (id != null) {
                    await widget.courseProvider.loadCheckpoints(id);
                    setState(() {});
                  }
                },
              ),
            ),
            if (_selectedCourseId != null) ...[
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    _showAddCheckpointDialog(context, _selectedCourseId!),
                icon: const Icon(Icons.add_location),
                label: const Text('Yeni Nokta'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _selectedCourseId == null
              ? const Center(child: Text('Bir parkur seçin.'))
              : Builder(
                  builder: (context) {
                    final checkpoints =
                        widget.courseProvider.getCheckpoints(_selectedCourseId!);
                    if (checkpoints.isEmpty) {
                      return const Center(
                        child: Text('Bu parkurda henüz kontrol noktası yok.'),
                      );
                    }
                    return Card(
                      child: ListView.separated(
                        itemCount: checkpoints.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cp = checkpoints[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red,
                              child: Text(
                                '${cp['order'] ?? index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              'Nokta #${cp['order'] ?? index + 1}',
                            ),
                            subtitle: Text(
                              'Lat: ${cp['latitude']?.toStringAsFixed(6)} '
                              '  Lon: ${cp['longitude']?.toStringAsFixed(6)}',
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============ RESULTS TAB ============
class _ResultsTab extends StatelessWidget {
  const _ResultsTab();

  String _formatDuration(double totalSeconds) {
    final h = (totalSeconds ~/ 3600);
    final m = ((totalSeconds % 3600) ~/ 60);
    final s = (totalSeconds % 60).toInt();
    if (h > 0) return '${h}s ${m}dk ${s}sn';
    if (m > 0) return '${m}dk ${s}sn';
    return '${s}sn';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Yarış Sonuçları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Yenile',
                onPressed: () =>
                    context.read<ResultProvider>().loadResults(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<ResultProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(child: Text('Hata: ${provider.error}'));
                }
                if (provider.results.isEmpty) {
                  return const Center(child: Text('Henüz sonuç yok.'));
                }
                return Card(
                  child: ListView.separated(
                    itemCount: provider.results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = provider.results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Kullanıcı ID: ${result['user_id']}  •  Parkur ID: ${result['course_id']}',
                        ),
                        subtitle: Text(
                          'Süre: ${_formatDuration((result['total_time_seconds'] as num).toDouble())}',
                        ),
                        trailing: Text(
                          result['completed_at']?.toString().substring(0, 10) ??
                              '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============ USERS TAB ============
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  Future<void> _showCreateUserDialog(BuildContext context) async {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'runner';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yeni Kullanıcı Ekle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Kullanıcı adı gerekli' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'E-posta *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
                    if (!v.contains('@')) return 'Geçerli e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Şifre *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Şifre gerekli';
                    if (v.length < 6) return 'Şifre en az 6 karakter olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'runner', child: Text('Koşucu')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedRole = val ?? 'runner');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();
                try {
                  final token = context.read<AuthProvider>().token;
                  await context.read<UserProvider>().createUser(
                        usernameCtrl.text.trim(),
                        emailCtrl.text.trim(),
                        passwordCtrl.text,
                        selectedRole,
                        token: token,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kullanıcı eklendi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kullanıcı Yönetimi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateUserDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Yeni Kullanıcı'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(child: Text('Hata: ${provider.error}'));
                }
                if (provider.users.isEmpty) {
                  return const Center(
                    child: Text('Henüz kullanıcı yok. Yeni kullanıcı ekleyin.'),
                  );
                }
                return Card(
                  child: ListView.separated(
                    itemCount: provider.users.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = provider.users[index];
                      final isAdmin = user['role'] == 'admin';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isAdmin ? Colors.blue : Colors.grey.shade400,
                          child: Text(
                            (user['username']?.toString() ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['username']?.toString() ?? 'Unknown'),
                        subtitle: Text(user['email']?.toString() ?? ''),
                        trailing: Chip(
                          label: Text(isAdmin ? 'Admin' : 'Koşucu'),
                          backgroundColor: isAdmin
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
