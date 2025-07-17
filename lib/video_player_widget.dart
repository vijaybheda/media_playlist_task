import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPlayerWidget extends StatefulWidget {
  final String? url;
  final String? filePath;
  const VideoPlayerWidget({super.key, this.url, this.filePath});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isFullScreen = false;
  double _volume = 1.0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.filePath != null) {
      final file = File(widget.filePath!);
      if (!file.existsSync()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _error = 'File not found';
          });
        });
        return;
      }
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
        });
    } else if (widget.url != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url!))
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
        });
    } else {
      throw Exception('Either url or filePath must be provided');
    }
    _controller.setLooping(true);
    _controller.addListener(_onVideoEnd);
  }

  String? _error;

  void _onVideoEnd() {
    if (_controller.value.position >= _controller.value.duration &&
        !_controller.value.isPlaying) {
      setState(() {
        _showControls = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: VideoPlayerWidget(
                    url: widget.url,
                    filePath: widget.filePath,
                  ),
                ),
              ),
            ),
          )
          .then((_) {
            setState(() {
              _isFullScreen = false;
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_controller.value.hasError) {
      return const Center(
        child: Text('Error loading video', style: TextStyle(color: Colors.red)),
      );
    }
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VideoPlayer(_controller),
            ),
          ),
          if (_showControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: _CustomControlsOverlay(
                controller: _controller,
                onFullScreen: _toggleFullScreen,
                volume: _volume,
                onVolumeChanged: (v) {
                  setState(() {
                    _volume = v;
                    _controller.setVolume(v);
                  });
                },
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              colors: VideoProgressColors(
                playedColor: Colors.deepPurple,
                bufferedColor: Colors.grey.shade400,
                backgroundColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onFullScreen;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  const _CustomControlsOverlay({
    required this.controller,
    required this.onFullScreen,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
            },
          ),
          Expanded(
            child: Slider(
              value: volume,
              min: 0.0,
              max: 1.0,
              onChanged: onVolumeChanged,
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
            onPressed: onFullScreen,
          ),
        ],
      ),
    );
  }
}
