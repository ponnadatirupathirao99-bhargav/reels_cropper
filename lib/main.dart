import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

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
  File? _imageFile;
  final GlobalKey _cropKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveCroppedImage() async {
    if (_cropKey.currentContext == null) return;
    setState(() => _isSaving = true);

    try {
      RenderRepaintBoundary boundary =
          _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/reel_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('9:16 à°°à±€à°²à± à°«à±‹à°Ÿà±‹ à°—à±à°¯à°¾à°²à°°à±€à°²à±‹ à°¸à±‡à°µà± à°…à°¯à±à°¯à°¿à°‚à°¦à°¿! ðŸŽ‰'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('à°Žà°°à±à°°à°°à±: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Reels Cropper (9:16)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _imageFile == null
                    ? GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 250,
                          height: 250 * (16 / 9),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30, width: 2),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white10,
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 60, color: Colors.white70),
                              SizedBox(height: 12),
                              Text('à°«à±‹à°Ÿà±‹ à°¸à±†à°²à±†à°•à±à°Ÿà± à°šà±‡à°¸à±à°•à±‹à°‚à°¡à°¿', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            ],
                          ),
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
                              child: InteractiveViewer(
                                clipBehavior: Clip.hardEdge,
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
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
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('à°®à°¾à°°à±à°šà±'),
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
                      onPressed: (_imageFile != null && !_isSaving) ? _saveCroppedImage : null,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_circle),
                      label: Text(_isSaving ? 'à°¸à±‡à°µà± à°…à°µà±à°¤à±‹à°‚à°¦à°¿...' : '9:16 à°¸à±‡à°µà± à°šà±‡à°¯à°¿',
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
