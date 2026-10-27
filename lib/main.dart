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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(22),
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
                size: 50,
                color: Color(0xFF00FFA3),
              ),
            ),
            const SizedBox(height: 22),
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
              'Pro 9:16 Video Editor & Trimmer',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 32),
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
  bool _isBlurBackground = true;

  // Timeline, Trimming & Speed variables
  RangeValues _trimRange = const RangeValues(0, 1);
  Duration _videoTotalDuration = Duration.zero;
  double _currentSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0];

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
          _currentSpeed = 1.0;
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

    // Loop within trimmed boundary
    if (currentMs >= _trimRange.end) {
      _videoController!.seekTo(Duration(milliseconds: _trimRange.start.toInt()));
    } else if (currentMs < _trimRange.start) {
      _videoController!.seekTo(Duration(milliseconds: _trimRange.start.toInt()));
    }
    setState(() {});
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      _videoController!.value.isPlaying
          ? _videoController!.pause()
          : _videoController!.play();
    });
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _setPlaybackSpeed(double speed) {
    if (_videoController == null) return;
    setState(() {
      _currentSpeed = speed;
      _videoController!.setPlaybackSpeed(speed);
    });
  }

  String _formatDurationPrecise(double ms) {
    final duration = Duration(milliseconds: ms.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final millis = ((duration.inMilliseconds % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$millis';
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
    final currentPosMs =
        _videoController?.value.position.inMilliseconds.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Reels Cropper (9:16)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        centerTitle: true,
        actions: [
          if (_selectedFile != null) ...[
            IconButton(
              icon: Icon(
                _isBlurBackground ? Icons.blur_on : Icons.blur_off,
                color: _isBlurBackground ? const Color(0xFF00FFA3) : Colors.white38,
              ),
              tooltip: _isBlurBackground ? 'Blur Background ON' : 'Blur Background OFF',
              onPressed: () {
                setState(() {
                  _isBlurBackground = !_isBlurBackground;
                });
              },
            ),
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
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 1. BLURRED BACKGROUND LAYER
                                  if (_isBlurBackground && !_isFillMode) ...[
                                    Positioned.fill(
                                      child: _isVideo
                                          ? (_videoController != null &&
                                                  _videoController!.value.isInitialized
                                              ? FittedBox(
                                                  fit: BoxFit.cover,
                                                  clipBehavior: Clip.hardEdge,
                                                  child: SizedBox(
                                                    width: _videoController!.value.size.width,
                                                    height: _videoController!.value.size.height,
                                                    child: VideoPlayer(_videoController!),
                                                  ),
                                                )
                                              : Container(color: Colors.black))
                                          : Image.file(_selectedFile!, fit: BoxFit.cover),
                                    ),
                                    Positioned.fill(
                                      child: BackdropFilter(
                                        filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                                        child: Container(
                                          color: Colors.black.withOpacity(0.35),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // 2. FOREGROUND MEDIA PLAYER LAYER
                                  _isVideo
                                      ? (_videoController != null &&
                                              _videoController!.value.isInitialized
                                          ? GestureDetector(
                                              onTap: _togglePlayPause,
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
                                                        color: Colors.black54,
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // ADVANCED TIMELINE & SPEED CONTROLS PANEL
            if (_isVideo &&
                _videoController != null &&
                _videoController!.value.isInitialized &&
                totalMs > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    // Row 1: Play/Pause, Position, Speed Chips
                    Row(
                      children: [
                        InkWell(
                          onTap: _togglePlayPause,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00FFA3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDurationPrecise(currentPosMs),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Spacer(),

                        // Speed Chips (0.5x, 1x, 1.5x, 2x)
                        Row(
                          children: _speedOptions.map((speed) {
                            final isSelected = _currentSpeed == speed;
                            return Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: InkWell(
                                onTap: () => _setPlaybackSpeed(speed),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF00FFA3)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${speed}x',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 2: RangeSlider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5,
                        activeTrackColor: const Color(0xFF00FFA3),
                        inactiveTrackColor: Colors.white12,
                        rangeThumbShape:
                            const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                        thumbColor: const Color(
