import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../widgets/app_layout.dart';
import '../services/api_service.dart';
import '../services/providers.dart';

class DosyaYukle extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const DosyaYukle({super.key, this.onNavigate});

  @override
  State<DosyaYukle> createState() => _DosyaYukleState();
}

class _DosyaYukleState extends State<DosyaYukle> {
  String fileName = "No file selected";
  String? filePath;
  Uint8List? fileBytes;
  bool _isUploading = false;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['kml', 'kmz'],
    );

    if (result != null) {
      setState(() {
        fileName = result.files.single.name;
        if (kIsWeb) {
          // On web, use bytes instead of path
          fileBytes = result.files.single.bytes;
          filePath = null;
        } else {
          // On mobile, use path
          filePath = result.files.single.path;
          fileBytes = null;
        }
      });
    }
  }

  Future<void> uploadFile() async {
    if (kIsWeb ? fileBytes == null : filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file first")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final token = context.read<AuthProvider>().token;
      late Map<String, dynamic> response;
      if (kIsWeb) {
        // Upload from bytes on web
        response = await ApiService.uploadKMLFromBytes(
          fileName,
          fileBytes!,
          token: token,
        );
      } else {
        // Upload from file path on mobile
        response = await ApiService.uploadKML(filePath!, token: token);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Course created: ${response['course_name']}\nCheckpoints: ${response['checkpoints_count']}",
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload courses after upload
        if (mounted) {
          context.read<CourseProvider>().loadCourses();
        }

        // Reset form
        setState(() {
          fileName = "No file selected";
          filePath = null;
          fileBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: "Dosya Yükle",
      onNavigate: widget.onNavigate,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_file, size: 60),
                  const SizedBox(height: 16),

                  const Text(
                    "KML / KMZ Dosyası Yükle",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isUploading ? null : pickFile,
                        child: const Text("Dosya Seç"),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Text(
                          fileName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _isUploading
                      ? const SizedBox(
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text("Yükle"),
                          onPressed: uploadFile,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
