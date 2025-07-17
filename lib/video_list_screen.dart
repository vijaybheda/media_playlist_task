import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_playlist_task/download_queue_screen.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'data/video_list_controller.dart';
import 'video_player_widget.dart';
import 'video_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoListScreen extends GetView<VideoListController> {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          Obx(
            () => IconButton(
              icon: Icon(
                controller.downloadQueue.isNotEmpty
                    ? Icons.download_done
                    : Icons.download,
              ),
              onPressed: () {
                Get.to(() => const DownloadQueueScreen());
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Get.to(() => SavedVideosScreen());
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
                      child: Text(
                        'End of list',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }
              final video = controller.videos[index];
              final isPlaying = controller.playingIndex.value == index;
              return VisibilityDetector(
                key: Key('video_$index'),
                onVisibilityChanged: (info) {
                  if (info.visibleFraction > 0.85) {
                    controller.setPlayingIndex(index);
                  } else if (controller.playingIndex.value == index) {
                    controller.pausePlaying();
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => VideoViewScreen(video: video));
                  },
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 220,
                          child: isPlaying
                              ? VideoPlayerWidget(
                                  key: ValueKey('player_$index'),
                                  url: video.videoUrl,
                                )
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _buildThumbnail(video.thumbnailUrl),
                                    Center(
                                      child: Icon(
                                        Icons.play_circle,
                                        size: 64,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        ListTile(
                          title: Text(video.title),
                          subtitle: Text('${video.duration} • ${video.author}'),
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
                                  onPressed: () {
                                    controller.isSaved(video.id)
                                        ? controller.unsaveVideo(video.id)
                                        : controller.saveVideo(video.id);
                                  },
                                ),
                              ),
                              Obx(
                                () => IconButton(
                                  icon: controller.isDownloading(video.id)
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          controller.isDownloaded(video.id)
                                              ? Icons.download_done
                                              : Icons.download,
                                        ),
                                  onPressed: () {
                                    if (!controller.isDownloaded(video.id)) {
                                      controller.downloadVideo(
                                        video.id,
                                        video.videoUrl,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  int getVisibleVideo() {
    return controller.playingIndex.value;
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
