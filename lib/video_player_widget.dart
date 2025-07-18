import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'features/video/controllers/video_player_controller.dart';
import 'features/video/controllers/video_list_controller.dart';
import 'dart:async';

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

class VideoPlayerWidget extends StatefulWidget {
  final String? url;
  final String? filePath;
  final String? thumbnailUrl;
  final bool shouldPlay;
  final String tag;
  final int index;

  const VideoPlayerWidget({
    super.key,
    this.url,
    this.filePath,
    this.thumbnailUrl,
    this.shouldPlay = true,
    required this.tag,
    required this.index,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver {
  late final VideoPlayerGetXController controller;
  Timer? _hideControlsTimer;

  void _showControlsTemporarily() {
    controller.showControls.value = true;
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(milliseconds: 1500), () {
      controller.showControls.value = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.put(
      VideoPlayerGetXController(
        url: widget.url,
        filePath: widget.filePath,
        shouldPlay: widget.shouldPlay,
        videoId: widget.tag,
        // assuming tag is unique per video
        initialPosition: Get.find<VideoListController>().getLastPosition(
          widget.tag,
        ),
      ),
      tag: widget.tag,
    );
    debugPrint('Controller created for tag: ${widget.tag}');
    controller.showControls.value = true;
    _showControlsTemporarily();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filePath != oldWidget.filePath || widget.url != oldWidget.url) {
      controller.updateSource(newFilePath: widget.filePath, newUrl: widget.url);
      debugPrint('Controller source updated for tag: ${widget.tag}');
    }
    if (widget.shouldPlay != oldWidget.shouldPlay) {
      controller.updateShouldPlay(widget.shouldPlay);
      debugPrint('Controller shouldPlay updated for tag: ${widget.shouldPlay}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    controller.pauseVideo();
    controller.onClose();
    Get.delete<VideoPlayerGetXController>(tag: widget.tag, force: true);
    debugPrint('Controller disposed for tag: ${widget.tag}');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      controller.pauseVideo();
    }
  }

  @override
  void deactivate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.pauseVideo();
    });
    super.deactivate();
  }

  void _onUserInteraction() {
    _showControlsTemporarily();
  }

  void _enterFullScreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenVideoPlayer(
          controller: controller,
          tag: widget.tag,
          onExit: _exitFullScreen,
        ),
      ),
    );
    // Restore portrait after exiting fullscreen
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _exitFullScreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isError = controller.isError.value;
      final isInitialized = controller.isInitialized.value;
      final isPlaying = controller.isPlaying.value;
      final isMuted = controller.isMuted.value;
      final position = controller.position.value;
      final ctrl = controller.controller.value;
      final duration = isInitialized && ctrl != null
          ? ctrl.value.duration
          : Duration.zero;
      final canSeek = isInitialized && ctrl != null && duration > Duration.zero;
      final showControls = controller.showControls.value;

      Widget background;
      if (isError) {
        background = Center(
          child: Text(
            controller.errorMessage.value,
            style: const TextStyle(color: Colors.red),
          ),
        );
      } else if (!isInitialized || ctrl == null) {
        background = AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: CachedNetworkImage(
              imageUrl: widget.thumbnailUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        background = AspectRatio(
          aspectRatio: ctrl.value.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VideoPlayer(ctrl),
          ),
        );
      }
      return GestureDetector(
        onTap: _onUserInteraction,
        onDoubleTap: _enterFullScreen,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            background,
            _ControlsOverlay(
              controller: controller,
              isFullscreen: false,
              onEnterFullScreen: _enterFullScreen,
              index: widget.index,
              tag: widget.tag,
            ),
          ],
        ),
      );
    });
  }
}

class _FullScreenVideoPlayer extends StatelessWidget {
  final VideoPlayerGetXController controller;
  final String tag;
  final VoidCallback onExit;
  const _FullScreenVideoPlayer({
    super.key,
    required this.controller,
    required this.tag,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(
          () => Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio:
                      controller.controller.value?.value.aspectRatio ?? 16 / 9,
                  child: VideoPlayer(controller.controller.value!),
                ),
              ),
              _ControlsOverlay(
                controller: controller,
                isFullscreen: true,
                onExitFullScreen: onExit,
                tag: tag,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final VideoPlayerGetXController controller;
  final bool isFullscreen;
  final VoidCallback? onExitFullScreen;
  final VoidCallback? onEnterFullScreen;
  final int? index;
  final String? tag;
  const _ControlsOverlay({
    super.key,
    required this.controller,
    this.isFullscreen = false,
    this.onExitFullScreen,
    this.onEnterFullScreen,
    this.index,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final isInitialized = controller.isInitialized.value;
    final isPlaying = controller.isPlaying.value;
    final isMuted = controller.isMuted.value;
    final position = controller.position.value;
    final ctrl = controller.controller.value;
    final duration = isInitialized && ctrl != null
        ? ctrl.value.duration
        : Duration.zero;
    final canSeek = isInitialized && ctrl != null && duration > Duration.zero;
    final showControls = controller.showControls.value;

    return Stack(
      children: [
        if (showControls) ...[
          // Center play/pause
          Align(
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () {
                  controller.showControls.value = true;
                  if (isInitialized && ctrl != null) {
                    controller.togglePlayPause();
                  } else {
                    // Manual play logic: set this video as playing
                    final listController =
                        Get.isRegistered<VideoListController>()
                        ? Get.find<VideoListController>()
                        : null;
                    if (listController != null && index != null) {
                      listController.manualPlay(index!);
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          // Mute/unmute and fullscreen/exit icons (top right, stacked vertically)
          Positioned(
            top: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isInitialized ? controller.toggleMute : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (isFullscreen && onExitFullScreen != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onExitFullScreen,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.fullscreen_exit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  )
                else if (!isFullscreen && onEnterFullScreen != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onEnterFullScreen,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        // Seekbar (always visible)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                        elevation: 2,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      activeTrackColor: Colors.deepPurple,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.deepPurple,
                      overlayColor: Colors.white,
                    ),
                    child: Slider(
                      value: canSeek
                          ? position.inMilliseconds
                                .clamp(0, duration.inMilliseconds)
                                .toDouble()
                          : 0.0,
                      min: 0.0,
                      max: canSeek ? duration.inMilliseconds.toDouble() : 1.0,
                      onChanged: canSeek
                          ? (value) {
                              controller.showControls.value = true;
                              controller.controller.value?.seekTo(
                                Duration(milliseconds: value.toInt()),
                              );
                            }
                          : null,
                      divisions: canSeek ? duration.inMilliseconds : 1,
                      label: _formatDuration(position),
                    ),
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
