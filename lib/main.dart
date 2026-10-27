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
              ),
              child: const Icon(
                Icons.movie_creation_outlined,
                size: 50,
                color: Color(0xFF00FFA3),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Reels Cropper Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Multi-Track Video Studio & Trimmer',
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
  double _currentVolume = 1.0;

  // Aspect Ratio Settings
  double _aspectRatio = 9 / 16;
  String _aspectRatioLabel = '9:16';
  final List<String> _ratioNames = [
    '9:16 (Reel)',
    '1:1 (Square)',
    '4:5 (Post)',
    '16:9 (Landscape)'
  ];
  final List<double> _ratioValues = [9 / 16, 1.0, 4 / 5, 16 / 9];

  // Timeline & Speed
  RangeValues _trimRange = const RangeValues(0.0, 1.0);
  Duration _videoTotalDuration = Duration.zero;
  double _currentSpeed = 1.0;

  // Text Overlay Variables
  String _overlayText = '';
  Offset _textPosition = const Offset(20.0, 40.0);
  double _textSize = 18.0;
  int _colorIndex = 0;

  final List<Color> _colorPalette = [
    Colors.white,
    const Color(0xFF00FFA3),
    Colors.yellowAccent,
    Colors.cyanAccent,
    Colors.orangeAccent,
    Colors.redAccent,
  ];

  // Background Styles
  int _selectedBgIndex = 0;
  final List<Decoration> _bgDecorations = [
    const BoxDecoration(color: Colors.black),
    const BoxDecoration(color: Color(0xFF1E1E1E)),
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
    const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      ),
    ),
  ];

  // Sticker Variables
  String _selectedEmoji = '';
  Offset _emojiPosition = const Offset(140.0, 180.0);

  final List<String> _emojiList = [
    '🔥', '🚀', '💯', '✨', '💡', '🎬',
    '❤️', '👏', '⚡', '👀', '🎯', '⭐'
  ];

  // Color Filter Options
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
      _videoController!.value.isPlaying
          ? _videoController!.pause()
          : _videoController!.play();
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

  void _handleTimelineScrub(DragUpdateDetails details) {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    final double totalMs = _videoTotalDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) return;

    // Sensible scrubbing ratio: 1 horizontal pixel = 45 milliseconds
    final double deltaMs = -details.delta.dx * 45;
    final double currentMs = _videoController!.value.position.inMilliseconds.toDouble();
    final double targetMs = (currentMs + deltaMs).clamp(_trimRange.start, _trimRange.end);

    _videoController!.seekTo(Duration(milliseconds: targetMs.toInt()));
    setState(() {});
  }

  void _handleSplitAtCurrentPosition() {
    if (_videoController == null) return;
    final double currentMs = _videoController!.value.position.inMilliseconds.toDouble();

    if (currentMs <= _trimRange.start || currentMs >= _trimRange.end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ప్లేహెడ్‌ను ట్రిమ్ పరిధి మధ్యలో ఉంచి స్ప్లిట్ చేయండి.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.content_cut_rounded, color: Color(0xFF00FFA3)),
                const SizedBox(width: 8),
                Text(
                  'Split at ${_formatDurationPrecise(currentMs)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'ఏ భాగాన్ని ఉంచాలనుకుంటున్నారో ఎంచుకోండి:',
              style: TextStyle(color: Colors.white54, fontSize: 13),
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
                    onPressed: () {
                      setState(() {
                        _trimRange = RangeValues(_trimRange.start, currentMs);
                      });
                      _videoController!.seekTo(Duration(milliseconds: _trimRange.start.toInt()));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('మొదటి భాగం ఉంచబడింది (Keep Left) ✂️'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Keep Left'),
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
                    onPressed: () {
                      setState(() {
                        _trimRange = RangeValues(currentMs, _trimRange.end);
                      });
                      _videoController!.seekTo(Duration(milliseconds: currentMs.toInt()));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('తర్వాతి భాగం ఉంచబడింది (Keep Right) ✂️'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Keep Right', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showVolumeDialog() {
    double tempVolume = _currentVolume;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                  const Text(
                    'Audio Volume',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(tempVolume * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF00FFA3),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    tempVolume == 0.0 ? Icons.volume_off : Icons.volume_down,
                    color: Colors.white70,
                  ),
                  Expanded(
                    child: Slider(
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
                  ),
                  const Icon(Icons.volume_up, color: Color(0xFF00FFA3)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    onPressed: () {
                      setSheetState(() => tempVolume = 0.0);
                      setState(() {
                        _currentVolume = 0.0;
                        _videoController?.setVolume(0.0);
                      });
                    },
                    child: const Text('Mute (0%)'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                    ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFA3),
                      foregroundColor: Colors.black,
                    ),
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
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Video Filter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_filterNames.length, (int index) {
                final bool isSelected = _selectedFilterIndex == index;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFilterIndex = index;
                    });
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00FFA3) : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Screen Ratio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00FFA3) : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
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

  void _showEmojiSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose Emoji Sticker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Canvas Background',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _bgDecorations.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedBgIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBgIndex = index;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: _bgDecorations[index],
                      child: Container(
                        decoration
