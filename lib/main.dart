import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:gallery_saver/gallery_saver.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReelsCropperHome(),
    ));

class ReelsCropperHome extends StatefulWidget {
  const ReelsCropperHome({super.key});

  @override
  State<ReelsCropperHome> createState() => _ReelsCropperHomeState();
}

class _ReelsCropperHomeState extends State<ReelsCropperHome> {
  File? _videoFile;
  VideoPlayerController? _controller;
  bool _isProcessing = false;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      _controller?.dispose();
      _videoFile = File(picked.path);
      _controller = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
    }
  }

  Future<void> _cropAndExport() async {
    if (_videoFile == null) return;

    setState(() => _isProcessing = true);

    final outputPath = '${_videoFile!.parent.path}/reel_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final command = '-y -i "${_videoFile!.path}" -vf "scale=-2:1280,crop=720:1280" -preset ultrafast -c:a copy "$outputPath"';

    await FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      setState(() => _isProcessing = false);

      if (ReturnCode.isSuccess(returnCode)) {
        await GallerySaver.saveVideo(outputPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('à°°à±€à°²à± à°—à±à°¯à°¾à°²à°°à±€à°²à±‹ à°¸à±‡à°µà± à°…à°¯à±à°¯à°¿à°‚à°¦à°¿! ðŸŽ‰'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('à°Žà°°à±à°°à°°à± à°µà°šà±à°šà°¿à°‚à°¦à°¿! à°®à°³à±à°²à±€ à°ªà±à°°à°¯à°¤à±à°¨à°¿à°‚à°šà°‚à°¡à°¿.'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reels Cropper', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.greenAccent),
                  SizedBox(height: 16),
                  Text('à°µà±€à°¡à°¿à°¯à±‹ 9:16 à°²à±‹à°•à°¿ à°•à±à°°à°¾à°ªà± à°…à°µà±à°¤à±‹à°‚à°¦à°¿...', style: TextStyle(color: Colors.white)),
                ],
              )
            : _controller != null && _controller!.value.isInitialized
                ? Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: _cropAndExport,
                          icon: const Icon(Icons.crop),
                          label: const Text('9:16 à°°à±€à°²à±â€Œà°—à°¾ à°®à°¾à°°à±à°šà±', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library),
                    label: const Text('à°µà±€à°¡à°¿à°¯à±‹ à°¸à±†à°²à±†à°•à±à°Ÿà± à°šà±‡à°¸à±à°•à±‹à°‚à°¡à°¿'),
                  ),
      ),
    );
  }
}
