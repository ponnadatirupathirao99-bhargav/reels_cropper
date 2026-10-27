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
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00FFA3) : Colors.white24,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Color(0xFF00FFA3), size: 20)
                            : null,
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
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Text & Subtitle',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                        hintText: 'Enter title or subtitle',
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FFA3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Size',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${localSize.toInt()} pt',
                            style: const TextStyle(
                                color: Color(0xFF00FFA3), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: localSize,
                      min: 12.0,
                      max: 40.0,
                      activeColor: const Color(0xFF00FFA3),
                      inactiveColor: Colors.white12,
                      onChanged: (double val) {
                        setDialogState(() {
                          localSize = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text('Color',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_colorPalette.length, (int index) {
                        final bool isSelected = localColorIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              localColorIndex = index;
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _colorPalette[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.black)
                                : null,
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
                    setState(() {
                      _overlayText = '';
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFA3),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      _overlayText = textController.text.trim();
                      _textSize = localSize;
                      _colorIndex = localColorIndex;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Apply',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
              'Playback Speed',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
              content: Text('Video exported to Gallery! 🎬'),
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
                '${tempDir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png')
            .create();
        await file.writeAsBytes(pngBytes);

        await Gal.putImage(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved $_aspectRatioLabel Photo to Gallery! 🎉'),
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

  Widget _buildFilteredChild(Widget child) {
    if (_selectedFilterIndex == 1) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: child,
      );
    } else if (_selectedFilterIndex == 2) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFF8B5A2B),
          BlendMode.color,
        ),
        child: child,
      );
    } else if (_selectedFilterIndex == 3) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.orangeAccent,
          BlendMode.softLight,
        ),
        child: child,
      );
    } else if (_selectedFilterIndex == 4) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.cyanAccent,
          BlendMode.softLight,
        ),
        child: child,
      );
    }
    return child;
  }

  Widget _buildTimelineTrack({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: isActive ? const Color(0xFF00FFA3) : Colors.white60, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0x3300FFA3) : const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive ? const Color(0xFF00FFA3) : Colors.white12,
                    width: 1,
                  ),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF00FFA3) : Colors.white54,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalMs = _videoTotalDuration.inMilliseconds.toDouble();
    final double currentPosMs =
        _videoController?.value.position.inMilliseconds.toDouble() ?? 0.0;
    final Color selectedColor = _colorPalette[_colorIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (_selectedFile != null) {
              setState(() {
                _videoController?.dispose();
                _videoController = null;
                _selectedFile = null;
              });
            }
          },
        ),
        title: InkWell(
          onTap: _showRatioSelector,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.aspect_ratio, size: 16, color: Color(0xFF00FFA3)),
                const SizedBox(width: 6),
                Text(
                  _aspectRatioLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white70),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFillMode ? Icons.fit_screen : Icons.crop_free,
              color: const Color(0xFF00FFA3),
            ),
            tooltip: _isFillMode ? 'Fit Video' : 'Fill Screen',
            onPressed: () {
              setState(() {
                _isFillMode = !_isFillMode;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFA3),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (_selectedFile != null && !_isSaving) ? _saveMedia : null,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.file_upload_outlined, size: 18),
              label: Text(
                _isSaving ? '...' : 'Export',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Center Preview Canvas
            Expanded(
              flex: 4,
              child: Center(
                child: _selectedFile == null
                    ? Container(
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181818),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.video_library_outlined, size: 50, color: Colors.white54),
                            const SizedBox(height: 14),
                            const Text(
                              'Import video or photo to start editing',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                  ),
                                  onPressed: () => _pickMedia(false),
                                  icon: const Icon(Icons.image),
                                  label: const Text('Photo'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00FFA3),
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: () => _pickMedia(true),
                                  icon: const Icon(Icons.videocam),
                                  label: const Text('Video'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : RepaintBoundary(
                        key: _cropKey,
                        child: AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: Container(
                            decoration: _bgDecorations[_selectedBgIndex],
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _isVideo
                                    ? (_videoController != null && _videoController!.value.isInitialized
                                        ? GestureDetector(
                                            onTap: _togglePlayPause,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Center(
                                                  child: _buildFilteredChild(
                                                    FittedBox(
                                                      fit: _isFillMode ? BoxFit.cover : BoxFit.contain,
                                                      clipBehavior: Clip.hardEdge,
                                                      child: SizedBox(
                                                        width: _videoController!.value.size.width,
                                                        height: _videoController!.value.size.height,
                                                        child: VideoPlayer(_videoController!),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (!_videoController!.value.isPlaying)
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    padding: const EdgeInsets.all(12),
                                                    child: const Icon(
                                                      Icons.play_arrow,
                                                      size: 38,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          )
                                        : const Center(child: CircularProgressIndicator()))
                                    : InteractiveViewer(
                                        clipBehavior: Clip.hardEdge,
                                        boundaryMargin: const EdgeInsets.all(200),
                                        minScale: 0.2,
                                        maxScale: 5.0,
                                        child: _buildFilteredChild(
                                          Image.file(_selectedFile!, fit: BoxFit.contain),
                                        ),
                                      ),

                                if (_overlayText.isNotEmpty)
                                  Positioned(
                                    left: _textPosition.dx,
                                    top: _textPosition.dy,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        setState(() {
                                          _textPosition += details.delta;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: selectedColor, width: 1.5),
                                        ),
                                        child: Text(
                                          _overlayText,
                                          style: TextStyle(
                                            color: selectedColor,
                                            fontSize: _textSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                if (_selectedEmoji.isNotEmpty)
                                  Positioned(
                                    left: _emojiPosition.dx,
                                    top: _emojiPosition.dy,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        setState(() {
                                          _emojiPosition += details.delta;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black38,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white24, width: 1),
                                        ),
                                        child: Text(_selectedEmoji, style: const TextStyle(fontSize: 32)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // Timeline Header Bar (Playhead Time, Play/Pause, Undo/Redo)
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFF141414),
              child: Row(
                children: [
                  Text(
                    '${_formatDurationPrecise(currentPosMs)} / ${_formatDurationPrecise(totalMs)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.replay_5, color: Colors.white70, size: 20),
                    onPressed: () => _seekRelative(-5),
                  ),
                  InkWell(
                    onTap: _togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FFA3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (_videoController?.value.isPlaying ?? false) ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_5, color: Colors.white70, size: 20),
                    onPressed: () => _seekRelative(5),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white54, size: 18),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, color: Colors.white54, size: 18),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // CapCut Multi-Track Timeline Layers
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFF161616),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Track 1: Audio / Music Track
                          _buildTimelineTrack(
                            icon: Icons.music_note_rounded,
                            title: _currentVolume == 0.0
                                ? 'Audio Muted'
                                : 'Audio: ${(_currentVolume * 100).toInt()}% (Tap to adjust)',
                            isActive: _currentVolume > 0.0,
                            onTap: _showVolumeDialog,
                          ),

                          // Track 2: Subtitle / Text Track
                          _buildTimelineTrack(
                            icon: Icons.subtitles_rounded,
                            title: _overlayText.isEmpty ? 'Tap to add subtitle / text' : _overlayText,
                            isActive: _overlayText.isNotEmpty,
                            onTap: _showTextInputDialog,
                          ),

                          // Track 3: Sticker / Overlay Track
                          _buildTimelineTrack(
                            icon: Icons.layers_rounded,
                            title: _selectedEmoji.isEmpty
                                ? 'Tap to add sticker / overlay'
                                : 'Sticker: $_selectedEmoji',
                            isActive: _selectedEmoji.isNotEmpty,
                            onTap: _showEmojiSelector,
                          ),

                          // Track 4: Main Video Clip Track (Yellow Border)
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.videocam, color: Color(0xFFFFD54F), size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 6,
                                      activeTrackColor: const Color(0xFFFFD54F),
                                      inactiveTrackColor: Colors.white12,
                                      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                                      thumbColor: Colors.white,
                                      overlayColor: Colors.transparent,
                                    ),
                                    child: RangeSlider(
                                      values: _trimRange,
                                      min: 0.0,
                                      max: totalMs > 0 ? totalMs : 1.0,
                                      onChanged: (RangeValues values) {
                                        setState(() {
                                          _trimRange = values;
                                        });
                                        _videoController?.seekTo(
                                          Duration(milliseconds: values.start.toInt()),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Playhead Indicator Line
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 2,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // CapCut Bottom Action Bar
            Container(
              height: 64,
              color: const Color(0xFF121212),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildBottomActionButton(
                      icon: Icons.content_cut_rounded,
                      label: 'Split',
                      color: const Color(0xFF00FFA3),
                      onTap: _handleSplitAtCurrentPosition,
                    ),
                    _buildBottomActionButton(
                      icon: Icons.tune_rounded,
                      label: 'Trim',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ఎల్లో కలర్ వీడియో ట్రాక్ స్లైడర్‌ను లాగి ట్రిమ్ చేయండి.'),
                            backgroundColor: Colors.white24,
                          ),
                        );
                      },
                    ),
                    _buildBottomActionButton(
                      icon: Icons.speed_rounded,
                      label: '${_currentSpeed}x',
                      onTap: _showSpeedSelector,
                    ),
                    _buildBottomActionButton(
                      icon: Icons.volume_up_rounded,
                      label: 'Volume',
                      onTap: _showVolumeDialog,
                    ),
                    _buildBottomActionButton(
                      icon: Icons.auto_awesome,
                      label: 'Filters',
                      onTap: _showFilterSelector,
                    ),
                    _buildBottomActionButton(
                      icon: Icons.palette_outlined,
                      label: 'Canvas BG',
                      onTap: _showBackgroundSelector,
                    ),
                    _buildBottomActionButton(
                      icon: Icons.text_fields_rounded,
                      label: 'Text',
                      onTap: _showTextInputDialog,
                    ),
                    _buildBottomActionButton(
                      icon: Icons.emoji_emotions_outlined,
                      label: 'Stickers',
                      onTap: _showEmojiSelector,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
