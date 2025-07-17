import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/model/video_model.dart';
import 'data/video_list_controller.dart';
import 'video_player_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoViewScreen extends StatelessWidget {
  final VideoModel video;
  const VideoViewScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final VideoListController controller = Get.find();
    final String? localPath = controller.getLocalFilePath(video.id);
    final bool isDownloaded =
        controller.isDownloaded(video.id) && localPath != null;
    return Scaffold(
      appBar: AppBar(title: Text(video.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: isDownloaded
                ? VideoPlayerWidget(filePath: localPath)
                : VideoPlayerWidget(url: video.videoUrl),
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
