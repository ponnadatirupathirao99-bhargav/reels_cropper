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
      home: SplashScreen(),
    ));

// Custom Dark Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReelsCropperScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF00FFA3), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFA3).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.crop_portrait_rounded,
                size: 55,
                color: Color(0xFF00FFA3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reels Cropper',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Convert to 9:16 Vertical HD',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF00FFA3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  bool _isFillMode = false;
  bool _isMuted = false;

  // Trimming variables
  RangeValues _trimRange = const RangeValues(0, 1);
  Duration _videoTotalDuration = Duration.zero;

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
        controller.setLooping(false);

        final totalMs = controller.value.duration.inMilliseconds.toDouble();
        setState(() {
          _selectedFile = File(picked.path);
          _isVideo = true;
          _videoController = controller;
          _isMuted = false;
          _videoTotalDuration = controller.value.duration;
          _trimRange = RangeValues(0.0, totalMs > 0 ? totalMs : 1.0);
        });

        controller.addListener(_videoListener);
        controller.play();
      } else {
        setState(() {
          _selectedFile = File(picked.path);
          _isVideo = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    final currentMs = _videoController!.value.position.inMilliseconds.toDouble();

    if (currentMs >= _trimRange.end) {
      _videoController!.seekTo(Duration(milliseconds: _trimRange.start.toInt()));
    } else if (currentMs < _trimRange.start) {
      _videoController!.seekTo(Duration(milliseconds: _trimRange.start.toInt()));
    }
    setState(() {});
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  String _formatDurationMs(double ms) {
    final duration = Duration(milliseconds: ms.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
              content: Text('Video saved to Gallery! 🎬'),
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
              content: Text('Saved 9:16 Reel Photo to Gallery! 🎉'),
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
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _videoTotalDuration.inMilliseconds.toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Reels Cropper (9:16)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        centerTitle: true,
        actions: [
          if (_isVideo && _videoController != null) ...[
            IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: _isMuted ? Colors.redAccent : const Color(0xFF00FFA3),
              ),
              tooltip: _isMuted ? 'Unmute' : 'Mute',
              onPressed: _toggleMute,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: const Color(0xFF00FFA3),
                ),
                icon: Icon(_isFillMode ? Icons.fit_screen : Icons.crop_free),
                label: Text(_isFillMode ? 'Fit Video' : 'Fill Screen'),
                onPressed: () {
                  setState(() {
                    _isFillMode = !_isFillMode;
                  });
                },
              ),
            ),
          ],
        ],
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
                                  backgroundColor: const Color(0xFF00FFA3),
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
                                      ? GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _videoController!.value.isPlaying
                                                  ? _videoController!.pause()
                                                  : _videoController!.play();
                                            });
                                          },
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Center(
                                                child: FittedBox(
                                                  fit: _isFillMode
                                                      ? BoxFit.cover
                                                      : BoxFit.contain,
                                                  clipBehavior: Clip.hardEdge,
                                                  child: SizedBox(
                                                    width: _videoController!
                                                        .value.size.width,
                                                    height: _videoController!
                                                        .value.size.height,
                                                    child: VideoPlayer(
                                                        _videoController!),
                                                  ),
                                                ),
                                              ),
                                              if (!_videoController!
                                                  .value.isPlaying)
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black45,
                                                    borderRadius:
                                                        BorderRadius.circular(30),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  child: const Icon(
                                                    Icons.play_arrow,
                                                    size: 40,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                            ],
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
            if (_isVideo &&
                _videoController != null &&
                _videoController!.value.isInitialized &&
                totalMs > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Start: ${_formatDurationMs(_trimRange.start)}',
                            style: const TextStyle(
                                color: Color(0xFF00FFA3),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text('Selected: ${_formatDurationMs(_trimRange.end - _trimRange.start)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text('End: ${_formatDurationMs(_trimRange.end)}',
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        rangeThumbShape:
                            const RoundRangeSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: RangeSlider(
                        values: _trimRange,
                        min: 0.0,
                        max: totalMs,
                        activeColor: const Color(0xFF00FFA3),
                        inactiveColor: Colors.white24,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _trimRange = values;
                          });
                          _videoController!.seekTo(
                              Duration(milliseconds: values.start.toInt()));
                        },
                      ),
                    ),
                  ],
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
                                    color: Color(0xFF00FFA3)),
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
                        backgroundColor: const Color(0xFF00FFA3),
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
