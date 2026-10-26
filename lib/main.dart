import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReelsCropperScreen(),
    ));

class ReelsCropperScreen extends StatefulWidget {
  const ReelsCropperScreen({super.key});

  @override
  State<ReelsCropperScreen> createState() => _ReelsCropperScreenState();
}

class _ReelsCropperScreenState extends State<ReelsCropperScreen> {
  File? _selectedFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;
  final GlobalKey _cropKey = GlobalKey();
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia(bool isVideo) async {
    final XFile? picked = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      _videoController?.dispose();
      _videoController = null;

      if (isVideo) {
        final controller = VideoPlayerController.file(File(picked.path));
        await controller.initialize();
        controller.setLooping(true);
        controller.play();
        setState(() {
          _selectedFile = File(picked.path);
          _isVideo = true;
          _videoController = controller;
        });
      } else {
        setState(() {
          _selectedFile = File(picked.path);
          _isVideo = false;
        });
      }
    }
  }

  Future<void> _saveMedia() async {
    if (_selectedFile == null) return;
    setState(() => _isSaving = true);

    try {
      if (_isVideo) {
        await Gal.putVideo(_selectedFile!.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video saved to Gallery! ðŸŽ¬'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        RenderRepaintBoundary boundary =
            _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file = await File(
                '${tempDir.path}/reel_${DateTime.now().millisecondsSinceEpoch}.png')
            .create();
        await file.writeAsBytes(pngBytes);

        await Gal.putImage(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved 9:16 Reel Photo to Gallery! ðŸŽ‰'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Reels Cropper (9:16)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _selectedFile == null
                    ? Container(
                        width: 250,
                        height: 250 * (16 / 9),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30, width: 2),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.video_library_outlined,
                                size: 55, color: Colors.white70),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white24,
                                  foregroundColor: Colors.white),
                              onPressed: () => _pickMedia(false),
                              icon: const Icon(Icons.image),
                              label: const Text('Select Photo'),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent,
                                  foregroundColor: Colors.black),
                              onPressed: () => _pickMedia(true),
                              icon: const Icon(Icons.videocam),
                              label: const Text('Select Video'),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: RepaintBoundary(
                          key: _cropKey,
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: Container(
                              color: Colors.black,
                              child: _isVideo
                                  ? (_videoController != null &&
                                          _videoController!.value.isInitialized
                                      ? FittedBox(
                                          fit: BoxFit.cover,
                                          clipBehavior: Clip.hardEdge,
                                          child: SizedBox(
                                            width: _videoController!
                                                .value.size.width,
                                            height: _videoController!
                                                .value.size.height,
                                            child: VideoPlayer(
                                                _videoController!),
                                          ),
                                        )
                                      : const Center(
                                          child: CircularProgressIndicator()))
                                  : InteractiveViewer(
                                      clipBehavior: Clip.hardEdge,
                                      boundaryMargin: const EdgeInsets.all(200),
                                      minScale: 0.2,
                                      maxScale: 5.0,
                                      child: Image.file(_selectedFile!,
                                          fit: BoxFit.contain),
                                    ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.grey[900],
                          builder: (ctx) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo,
                                    color: Colors.white),
                                title: const Text('Choose Photo',
                                    style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickMedia(false);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.video_collection,
                                    color: Colors.greenAccent),
                                title: const Text('Choose Video',
                                    style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickMedia(true);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.change_circle_outlined),
                      label: const Text('Change'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: (_selectedFile != null && !_isSaving)
                          ? _saveMedia
                          : null,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.check_circle),
                      label: Text(_isSaving ? 'Saving...' : 'Save 9:16',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
