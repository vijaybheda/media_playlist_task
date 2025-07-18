import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'features/video/controllers/video_player_controller.dart';

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

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoPlayerGetXController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      VideoPlayerGetXController(
        url: widget.url,
        filePath: widget.filePath,
        shouldPlay: widget.shouldPlay,
      ),
      tag: widget.tag,
    );
    debugPrint('Controller created for tag: ${widget.tag}');
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
      debugPrint(
        'Controller shouldPlay updated for tag: ${widget.tag} to ${widget.shouldPlay}',
      );
    }
  }

  @override
  void dispose() {
    controller.pauseVideo();
    controller.onClose();
    Get.delete<VideoPlayerGetXController>(tag: widget.tag, force: true);
    debugPrint('Controller disposed for tag: ${widget.tag}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isError.value) {
        return Center(
          child: Text(
            controller.errorMessage.value,
            style: const TextStyle(color: Colors.red),
          ),
        );
      }
      if (!controller.isInitialized.value) {
        if (widget.thumbnailUrl != null) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Hero(
              tag: 'thumbnail_${widget.tag}',
              child: CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!,
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
          return const Center(child: CircularProgressIndicator());
        }
      }
      final ctrl = controller.controller.value!;
      bool isPlaying = controller.isPlaying.value;
      return GestureDetector(
        onTap: controller.toggleControls,
        onDoubleTap: () => _goFullScreen(context),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AspectRatio(
              aspectRatio: ctrl.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Hero(
                  tag: 'video_player_${widget.tag}',
                  child: VideoPlayer(ctrl),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Hero(
                tag: 'progress_bar_${widget.tag}',
                child: VideoProgressIndicator(
                  ctrl,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  colors: VideoProgressColors(
                    playedColor: Colors.deepPurple,
                    bufferedColor: Colors.grey.shade400,
                    backgroundColor: Colors.black26,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Hero(
                    tag: 'volume_button_${widget.tag}',
                    child: IconButton(
                      icon: Icon(
                        controller.isMuted.value
                            ? Icons.volume_off
                            : Icons.volume_up,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: controller.toggleMute,
                    ),
                  ),
                  Hero(
                    tag: 'play_button_${widget.tag}',
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: controller.togglePlayPause,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _goFullScreen(BuildContext context) {
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrientationBuilder(
          builder: (context, orientation) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Center(
                  child: Obx(() {
                    final ctrl = controller.controller.value;
                    if (ctrl == null || !controller.isInitialized.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return GestureDetector(
                      onTap: controller.toggleControls,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Video player takes full screen
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: ctrl.value.aspectRatio * 100,
                                height: 100,
                                child: Hero(
                                  tag: 'video_player_${widget.tag}',
                                  child: VideoPlayer(ctrl),
                                ),
                              ),
                            ),
                          ),

                          // Top controls bar
                          if (controller.showControls.value)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black87,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Back button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        // Restore original orientation
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                          DeviceOrientation.portraitDown,
                                          DeviceOrientation.landscapeLeft,
                                          DeviceOrientation.landscapeRight,
                                        ]);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    // Title or video info
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Video Player',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Fullscreen toggle
                                    IconButton(
                                      icon: const Icon(
                                        Icons.fullscreen_exit,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        // Restore original orientation
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                          DeviceOrientation.portraitDown,
                                          DeviceOrientation.landscapeLeft,
                                          DeviceOrientation.landscapeRight,
                                        ]);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Center play/pause button
                          if (controller.showControls.value)
                            Center(
                              child: Hero(
                                tag: 'play_button_${widget.tag}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      controller.isPlaying.value
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                    onPressed: controller.togglePlayPause,
                                  ),
                                ),
                              ),
                            ),

                          // Bottom controls bar
                          // if (controller.showControls.value)
                          //   Positioned(
                          //     bottom: 0,
                          //     left: 0,
                          //     right: 0,
                          //     child: Container(
                          //       padding: const EdgeInsets.symmetric(
                          //         horizontal: 20,
                          //         vertical: 15,
                          //       ),
                          //       decoration: BoxDecoration(
                          //         gradient: LinearGradient(
                          //           begin: Alignment.bottomCenter,
                          //           end: Alignment.topCenter,
                          //           colors: [
                          //             Colors.black87,
                          //             Colors.transparent,
                          //           ],
                          //         ),
                          //       ),
                          //       child: Column(
                          //         children: [
                          //           // Progress bar
                          //           Hero(
                          //             tag: 'progress_bar_${widget.tag}',
                          //             child: VideoProgressIndicator(
                          //               ctrl,
                          //               allowScrubbing: true,
                          //               padding: const EdgeInsets.symmetric(
                          //                 vertical: 8,
                          //                 horizontal: 0,
                          //               ),
                          //               colors: VideoProgressColors(
                          //                 playedColor: Colors.deepPurple,
                          //                 bufferedColor: Colors.grey.shade400,
                          //                 backgroundColor: Colors.black54,
                          //               ),
                          //             ),
                          //           ),
                          //           const SizedBox(height: 10),
                          //           // Bottom row controls
                          //           Row(
                          //             mainAxisAlignment:
                          //                 MainAxisAlignment.spaceBetween,
                          //             children: [
                          //               // Play/Pause button
                          //               Hero(
                          //                 tag:
                          //                     'play_button_small_${widget.tag}',
                          //                 child: IconButton(
                          //                   icon: Icon(
                          //                     controller.isPlaying.value
                          //                         ? Icons.pause
                          //                         : Icons.play_arrow,
                          //                     color: Colors.white,
                          //                     size: 28,
                          //                   ),
                          //                   onPressed:
                          //                       controller.togglePlayPause,
                          //                 ),
                          //               ),
                          //               // Volume control
                          //               Row(
                          //                 children: [
                          //                   Hero(
                          //                     tag:
                          //                         'volume_button_${widget.tag}',
                          //                     child: IconButton(
                          //                       icon: Icon(
                          //                         controller.isMuted.value
                          //                             ? Icons.volume_off
                          //                             : Icons.volume_up,
                          //                         color: Colors.white,
                          //                         size: 24,
                          //                       ),
                          //                       onPressed:
                          //                           controller.toggleMute,
                          //                     ),
                          //                   ),
                          //                   if (!controller.isMuted.value)
                          //                     SizedBox(
                          //                       width: 80,
                          //                       child: Slider(
                          //                         value:
                          //                             controller.volume.value,
                          //                         min: 0.0,
                          //                         max: 1.0,
                          //                         onChanged:
                          //                             controller.setVolume,
                          //                         activeColor: Colors.white,
                          //                         inactiveColor: Colors.white24,
                          //                       ),
                          //                     ),
                          //                 ],
                          //               ),
                          //               // Time display
                          //               Hero(
                          //                 tag: 'time_display_${widget.tag}',
                          //                 child: Container(
                          //                   padding: const EdgeInsets.symmetric(
                          //                     horizontal: 8,
                          //                     vertical: 4,
                          //                   ),
                          //                   decoration: BoxDecoration(
                          //                     color: Colors.black54,
                          //                     borderRadius:
                          //                         BorderRadius.circular(4),
                          //                   ),
                          //                   child: Obx(() {
                          //                     final ctrl =
                          //                         controller.controller.value;
                          //                     if (ctrl == null)
                          //                       return const SizedBox.shrink();
                          //                     return Text(
                          //                       '${_formatDuration(controller.position.value)} / ${_formatDuration(ctrl.value.duration)}',
                          //                       style: const TextStyle(
                          //                         color: Colors.white,
                          //                         fontSize: 12,
                          //                       ),
                          //                     );
                          //                   }),
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
