import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
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
      backgroundColor: const Color(0xFF0D0E12),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF00FFA3), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFA3).withOpacity(0.3),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.movie_creation_outlined,
                size: 48,
                color: Color(0xFF00FFA3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reels Cropper Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pro Video Studio & Reels Trimmer',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 22,
              height: 22,
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
  double _currentVolume = 1.0;

  double _aspectRatio = 9 / 16;
  String _aspectRatioLabel = '9:16';
  final List<String> _ratioNames = ['9:16 (Reel)', '1:1 (Square)', '4:5 (Post)', '16:9 (Landscape)'];
  final List<double> _ratioValues = [9 / 16, 1.0, 4 / 5, 16 / 9];

  RangeValues _trimRange = const RangeValues(0.0, 1.0);
  Duration _videoTotalDuration = Duration.zero;
  double _currentSpeed = 1.0;

  String _overlayText = '';
  Offset _textPosition = const Offset(20.0, 40.0);
  double _textSize = 20.0;
  int _colorIndex = 0;

  final List<Color> _colorPalette = [
    Colors.white,
    const Color(0xFF00FFA3),
    Colors.yellowAccent,
    Colors.cyanAccent,
    Colors.orangeAccent,
    Colors.redAccent,
  ];

  int _selectedBgIndex = 0;
  final List<Decoration> _bgDecorations = [
    const BoxDecoration(color: Colors.black),
    const BoxDecoration(color: Color(0xFF181A20)),
    const BoxDecoration(color: Colors.white),
    const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
      ),
    ),
    const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      ),
    ),
    const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
      ),
    ),
  ];

  String _selectedEmoji = '';
  Offset _emojiPosition = const Offset(140.0, 180.0);

  final List<String> _emojiList = ['🔥', '🚀', '💯', '✨', '💡', '🎬', '❤️', '👏', '⚡', '👀', '🎯', '⭐'];

  int _selectedFilterIndex = 0;
  final List<String> _filterNames = ['Normal', 'B&W', 'Vintage', 'Warm', 'Cool'];

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
          _currentVolume = 1.0;
          _currentSpeed = 1.0;
          _videoTotalDuration = controller.value.duration;
          _trimRange = RangeValues(0.0, totalMs > 0 ? totalMs : 1.0);
        });

        controller.setVolume(_currentVolume);
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

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
    });
  }

  void _seekRelative(int seconds) {
    if (_videoController == null) return;
    final target = _videoController!.value.position + Duration(seconds: seconds);
    _videoController!.seekTo(target);
  }

  void _setPlaybackSpeed(double speed) {
    if (_videoController == null) return;
    setState(() {
      _currentSpeed = speed;
      _videoController!.setPlaybackSpeed(speed);
    });
  }

  void _performSplit() {
    if (_videoController == null) return;
    final currentMs = _videoController!.value.position.inMilliseconds.toDouble();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2028),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Split Clip Options',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Playhead: ${_formatDurationPrecise(currentMs)}',
              style: const TextStyle(color: Color(0xFF00FFA3), fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Keep Left'),
                    onPressed: () {
                      setState(() {
                        _trimRange = RangeValues(_trimRange.start, currentMs);
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFA3),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Keep Right', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        _trimRange = RangeValues(currentMs, _trimRange.end);
                      });
                      _videoController?.seekTo(Duration(milliseconds: currentMs.toInt()));
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showVolumeDialog() {
    double tempVolume = _currentVolume;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2028),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Volume Level', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${(tempVolume * 100).toInt()}%', style: const TextStyle(color: Color(0xFF00FFA3), fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: tempVolume,
                min: 0.0,
                max: 1.5,
                activeColor: const Color(0xFF00FFA3),
                inactiveColor: Colors.white12,
                onChanged: (val) {
                  setSheetState(() => tempVolume = val);
                  setState(() {
                    _currentVolume = val;
                    _videoController?.setVolume(val);
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                    onPressed: () {
                      setSheetState(() => tempVolume = 0.0);
                      setState(() {
                        _currentVolume = 0.0;
                        _videoController?.setVolume(0.0);
                      });
                    },
                    child: const Text('Mute'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white),
                    onPressed: () {
                      setSheetState(() => tempVolume = 1.0);
                      setState(() {
                        _currentVolume = 1.0;
                        _videoController?.setVolume(1.0);
                      });
                    },
                    child: const Text('100%'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FFA3), foregroundColor: Colors.black),
                    onPressed: () {
                      setSheetState(() => tempVolume = 1.5);
                      setState(() {
                        _currentVolume = 1.5;
                        _videoController?.setVolume(1.5);
                      });
                    },
                    child: const Text('Boost 150%'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2028),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters & Grading', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_filterNames.length, (int index) {
                final bool isSelected = _selectedFilterIndex == index;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedFilterIndex = index);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00FFA3) : Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _filterNames[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showRatioSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2028),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Frame Aspect Ratio', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_ratioNames.length, (int index) {
                final bool isSelected = _aspectRatio == _ratioValues[index];
                final String label = _ratioNames[index].split(' ').first;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _aspectRatio = _ratioValues[index];
                      _aspectRatioLabel = label;
                    });
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00FFA3) : Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showEmojiSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2028),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overlay Stickers', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                if (_selectedEmoji.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedEmoji = '');
                      Navigator.pop(ctx);
                    },
                    child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _emojiList.length,
              itemBuilder: (context, index) {
                final emoji = _emojiList[index];
                return InkWell(
                  onTap: () {
                    setState(() => _selectedEmoji = emoji);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackgroundSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2028),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Canvas Background', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _bgDecorations.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedBgIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedBgIndex = index);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: _bgDecorations[index],
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00FFA3) : Colors.white24,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Color(0xFF00FFA3), size: 20) : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextInputDialog() {
    final textController = TextEditingController(text: _overlayText);
    double localSize = _textSize;
    int localColorIndex = _colorIndex;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2028),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Text / Title', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type text here...',
                        hintStyle: TextStyle(color: Colors.white38),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FFA3))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Size', style: TextStyle(color: Colors.white70)),
                        Text('${localSize.toInt()} pt', style: const TextStyle(color: Color(0xFF00FFA3), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: localSize,
                      min: 14.0,
                      max: 42.0,
                      activeColor: const Color(0xFF00FFA3),
                      inactiveColor: Colors.white12,
                      onChanged: (val) => setDialogState(() => localSize = val),
                    ),
                    const SizedBox(height: 10),
                    const Text('Color Palette', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_colorPalette.length, (int index) {
                        final bool isSelected = localColorIndex == index;
                        return GestureDetector(
                          onTap: () => setDialogState(() => localColorIndex = index),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _colorPalette[index],
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _overlayText = '');
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FFA3), foregroundColor: Colors.black),
                  onPressed: () {
                    setState(() {
                      _overlayText = textController.text.trim();
                      _textSize = localSize;
                      _colorIndex = localColorIndex;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSpeedSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2028),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Speed Ramp', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [0.5, 1.0, 1.5, 2.0].map((s) {
                final isSelected = _currentSpeed == s;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? const Color(0xFF00FFA3) : Colors.white12,
                    foregroundColor: isSelected ? Colors.black : Colors.white,
                  ),
                  onPressed: () {
                    _setPlaybackSpeed(s);
                    Navigator.pop(ctx);
                  },
                  child: Text('${s}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
              content: Text('Video saved to Gallery successfully! 🎬'),
              backgroundColor: Color(0xFF00C853),
            ),
          );
        }
      } else {
        RenderRepaintBoundary boundary = _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(pngBytes);

        await Gal.putImage(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved $_aspectRatioLabel Photo to Gallery! 🎉'),
              backgroundColor: const Color(0xFF00C853),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red),
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

  Widget _buildFilteredChild(Widget child) {
    if (_selectedFilterIndex == 1) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: child,
      );
    
