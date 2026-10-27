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

  RangeValues _trimRange = const RangeValues(0, 1);
  Duration _videoTotalDuration = Duration.zero;
  double _currentSpeed = 1.0;

  // Text Overlay Variables
  String _overlayText = '';
  Offset _textPosition = const Offset(20, 40);
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

  // Background Style Variables
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

  // Sticker / Emoji Variables
  String _selectedEmoji = '';
  Offset _emojiPosition = const Offset(140, 200);

  final List<String> _emojiList = [
    '🔥', '🚀', '💯', '✨', '💡', '🎬',
    '❤️', '👏', '⚡', '👀', '🎯', '⭐'
  ];

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
              'Select Background Style',
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
                'Text & Watermark',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                        hintText: 'Enter title or @name',
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0x7700FFA3)),
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
                        const Text('Size', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                    const Text('Color', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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

  Widget _buildSpeedChip(double speed) {
    final bool isSelected = _currentSpeed == speed;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: InkWell(
        onTap: () => _setPlaybackSpeed(speed),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00FFA3) : Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${speed}x',
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
    final double totalMs = _videoTotalDuration.inMilliseconds.toDouble();
    final double currentPosMs =
        _videoController?.value.position.inMilliseconds.toDouble() ?? 0.0;
    final Color selectedColor = _colorPalette[_colorIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Reels Cropper (9:16)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        centerTitle: true,
        actions: [
          if (_selectedFile != null) ...[
            // Emoji Sticker Button
            IconButton(
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: _selectedEmoji.isNotEmpty ? const Color(0xFF00FFA3) : Colors.white70,
              ),
              tooltip: 'Add Sticker',
              onPressed: _showEmojiSelector,
            ),
            // Background Theme Button
            IconButton(
              icon: const Icon(Icons.palette_outlined, color: Color(0xFF00FFA3)),
              tooltip: 'Background Styles',
              onPressed: _showBackgroundSelector,
            ),
            // Text Overlay Button
            IconButton(
              icon: Icon(
                Icons.text_fields_rounded,
                color: _overlayText.isNotEmpty ? const Color(0xFF00FFA3) : Colors.white70,
              ),
              tooltip: 'Add Text',
              onPressed: _showTextInputDialog,
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
                              decoration: _bgDecorations[_selectedBgIndex],
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
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

                                  // Draggable Custom Styled Text Layer
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: const Color(0xB3000000),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: selectedColor, width: 1.5),
                                          ),
                                          child: Text(
                                            _overlayText,
                                            style: TextStyle(
                                              color: selectedColor,
                                              fontSize: _textSize,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Draggable Sticker / Emoji Layer
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
                                            border: Border.all(
                                                color: Colors.white24, width: 1),
                                          ),
                                          child: Text(
                                            _selectedEmoji,
                                            style: const TextStyle(fontSize: 34),
                                          ),
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
            ),

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
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _buildSpeedChip(0.5),
                            _buildSpeedChip(1.0),
                            _buildSpeedChip(1.5),
                            _buildSpeedChip(2.0),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5,
                        activeTrackColor: const Color(0xFF00FFA3),
                        inactiveTrackColor: Colors.white12,
                        rangeThumbShape:
                            const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                        thumbColor: const Color(0xFF00FFA3),
                        overlayColor: const Color(0x3300FFA3),
                      ),
                      child: RangeSlider(
                        values: _trimRange,
                        min: 0.0,
                        max: totalMs,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _trimRange = values;
                          });
                          _videoController!.seekTo(
                              Duration(milliseconds: values.start.toInt()));
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Start: ${_formatDurationPrecise(_trimRange.start)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          'Trimmed: ${_formatDurationPrecise(_trimRange.end - _trimRange.start)}',
                          style: const TextStyle(
                              color: Color(0xFF00FFA3),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'End: ${_formatDurationPrecise(_trimRange.end)}',
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
