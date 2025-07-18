import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_playlist_task/data/model/video_model.dart';
import 'package:media_playlist_task/features/video/controllers/video_list_controller.dart';
import 'package:media_playlist_task/video_player_widget.dart';

class VideoViewScreen extends StatelessWidget {
  final VideoModel video;
  const VideoViewScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoListController>();

    final String? localPath = controller.getLocalFilePath(video.id);
    final bool isDownloaded =
        controller.isDownloaded(video.id) && localPath != null;
    // Pause all feed videos when entering detail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.pauseAllExcept(-1);
    });
    return WillPopScope(
      onWillPop: () async {
        // On back, resume feed auto-play if enabled
        if (controller.autoPlayEnabled.value && controller.videos.isNotEmpty) {
          controller.setPlayingIndex(0);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(video.title)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: isDownloaded
                  ? VideoPlayerWidget(
                      filePath: localPath,
                      thumbnailUrl: video.thumbnailUrl,
                      tag: 'video_detail_${video.id}',
                // todo
                index: 0,
                    )
                  : VideoPlayerWidget(
                      url: video.videoUrl,
                      thumbnailUrl: video.thumbnailUrl,
                      tag: 'video_detail_${video.id}',
                // todo:
                index: 0,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('${video.duration} • ${video.author}'),
                  const SizedBox(height: 8),
                  Text(video.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedVideosScreen extends StatelessWidget {
  const SavedVideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VideoListController controller = Get.find<VideoListController>();
    final saved = controller.videos
        .where((v) => controller.isSaved(v.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Videos')),
      body: ListView.builder(
        itemCount: saved.length,
        itemBuilder: (context, index) {
          final video = saved[index];
          return ListTile(
            leading: CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              width: 80,
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
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),
            title: Text(video.title),
            subtitle: Text(video.author),
          );
        },
      ),
    );
  }
}
