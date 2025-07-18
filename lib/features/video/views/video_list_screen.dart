import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_playlist_task/features/video/controllers/video_list_controller.dart';
import 'package:media_playlist_task/video_player_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final Map<int, double> _visibilityFractions = {};
  final double _visibilityThreshold = 0.85;

  void handleVisibilityChanged(
    int index,
    double visibleFraction,
    VideoListController controller,
  ) {
    _visibilityFractions[index] = visibleFraction;
    // Find the most visible video above threshold
    int? mostVisibleIndex;
    double maxVisible = _visibilityThreshold;
    _visibilityFractions.forEach((i, fraction) {
      if (fraction > maxVisible) {
        maxVisible = fraction;
        mostVisibleIndex = i;
      }
    });
    if (mostVisibleIndex != null) {
      controller.setPlayingIndex(mostVisibleIndex!);
    } else {
      controller.pausePlaying();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoListController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video List'),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.autoPlayEnabled.value
                    ? Icons.play_circle
                    : Icons.pause_circle,
              ),
              tooltip: controller.autoPlayEnabled.value
                  ? 'Auto-Play On'
                  : 'Auto-Play Off',
              onPressed: controller.toggleAutoPlay,
            ),
          ),

          /// download queue videos screen
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Get.toNamed('/downloads');
            },
          ),

        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.videos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.isError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load videos.'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => controller.loadVideos(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (controller.hasMore.value &&
                !controller.isLoading.value &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent * 0.7) {
              controller.loadVideos();
            }
            return false;
          },
          child: ListView.builder(
            itemCount: controller.videos.length + 1,
            itemBuilder: (context, index) {
              return VideoItemWidget(
                index,
                handleVisibilityChanged: handleVisibilityChanged,
              );
            },
          ),
        );
      }),
    );
  }
}

Widget _buildThumbnail(String url) {
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
    errorWidget: (context, url, error) => Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
      ),
    ),
  );
}

class VideoItemWidget extends StatefulWidget {
  final int index;
  final Function(
    int index,
    double visibleFraction,
    VideoListController controller,
  )?
  handleVisibilityChanged;

  const VideoItemWidget(
    this.index, {
    super.key,
    required this.handleVisibilityChanged,
  });

  @override
  State<VideoItemWidget> createState() => _VideoItemWidgetState();
}

class _VideoItemWidgetState extends State<VideoItemWidget> {
  int get index => widget.index;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoListController>();
    if (index == controller.videos.length) {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (!controller.hasMore.value) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('End of list', style: TextStyle(color: Colors.grey)),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }
    final video = controller.videos[index];
    return VisibilityDetector(
      key: Key('video_$index'),
      onVisibilityChanged: (info) {
        widget.handleVisibilityChanged?.call(
          index,
          info.visibleFraction,
          controller,
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8),
        child: InkWell(
          onTap: () {
            Get.toNamed('/video', arguments: video);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 220,
                child: Obx(() {
                  final isPlaying = controller.playingIndex.value == index;
                  final isDownloaded = controller.isDownloaded(video.id);
                  final localPath = controller.getLocalFilePath(video.id);
                  final tag = 'video_${video.id}_$index';
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      isPlaying
                          ? (() {
                              if (isDownloaded && localPath != null) {
                                return VideoPlayerWidget(
                                  key: ValueKey('player_${video.id}_file'),
                                  filePath: localPath,
                                  thumbnailUrl: video.thumbnailUrl,
                                  shouldPlay: isPlaying,
                                  tag: tag,
                                  index: index,
                                );
                              } else {
                                return VideoPlayerWidget(
                                  key: ValueKey('player_${video.id}_url'),
                                  url: video.videoUrl,
                                  thumbnailUrl: video.thumbnailUrl,
                                  shouldPlay: isPlaying,
                                  tag: tag,
                                  index: index,
                                );
                              }
                            })()
                          : _buildThumbnail(video.thumbnailUrl),

                      // TODO: mute unmute
                      // IconButton(
                      //   icon: Icon(
                      //     controller.isMuted.value ? Icons.volume_off : Icons.volume_up,
                      //     color: Colors.white,
                      //     size: 24,
                      //   ),
                      //   onPressed: controller.toggleMute,
                      // ),
                      // Manual play/pause overlay
                      // if (isPlaying)
                      //   Positioned(
                      //     right: 12,
                      //     bottom: 12,
                      //     child: Obx(
                      //       () => IconButton(
                      //         icon: Icon(
                      //           controller.manualPaused.value
                      //               ? Icons.play_arrow
                      //               : Icons.pause,
                      //           color: Colors.white,
                      //           size: 32,
                      //         ),
                      //         onPressed: () {
                      //           if (controller.manualPaused.value) {
                      //             controller.manualPlay(index);
                      //           } else {
                      //             controller.manualPause();
                      //           }
                      //         },
                      //       ),
                      //     ),
                      //   )
                      // else
                      //   Positioned(
                      //     right: 12,
                      //     bottom: 12,
                      //     child: IconButton(
                      //       icon: const Icon(
                      //         Icons.play_arrow,
                      //         color: Colors.white,
                      //         size: 32,
                      //       ),
                      //       onPressed: () {
                      //         controller.manualPlay(index);
                      //       },
                      //     ),
                      //   ),
                    ],
                  );
                }),
              ),
              ListTile(
                title: Text(video.title),
                subtitle: Text('${video.duration} 2 ${video.author}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(
                      () => IconButton(
                        icon: Icon(
                          controller.isSaved(video.id)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                        tooltip: controller.isSaved(video.id)
                            ? 'Unsave'
                            : 'Save',
                        onPressed: () {
                          controller.isSaved(video.id)
                              ? controller.unsaveVideo(video.id)
                              : controller.saveVideo(video.id);
                        },
                      ),
                    ),
                    Obx(() {
                      if (controller.isDownloaded(video.id)) {
                        return const Tooltip(
                          message: 'Downloaded',
                          child: Icon(Icons.download_done),
                        );
                      } else if (controller.isDownloading(video.id)) {
                        final progress = controller.getDownloadProgress(
                          video.id,
                        );
                        return Tooltip(
                          message:
                              'Downloading ${progress.toStringAsFixed(1)}%',
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress / 100,
                                  strokeWidth: 2,
                                  backgroundColor: Colors.grey[300],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                ),
                                Text(
                                  '${progress.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: 'Download',
                          onPressed: () {
                            controller.downloadVideo(video.id, video.videoUrl);
                          },
                        );
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
