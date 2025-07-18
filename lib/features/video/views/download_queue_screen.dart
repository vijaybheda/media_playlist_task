import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_playlist_task/features/video/controllers/video_list_controller.dart';

class DownloadQueueScreen extends StatelessWidget {
  const DownloadQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoListController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Download Queue')),
      body: Obx(() {
        if (controller.downloadQueue.isEmpty &&
            controller.downloadingVideos.isEmpty &&
            controller.downloadedVideos.isEmpty) {
          return const Center(child: Text('No downloads in queue'));
        }
        return ListView(
          children: [
            if (controller.downloadQueue.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Queued Downloads',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...controller.downloadQueue.map(
                    (videoId) => Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.schedule,
                          color: Colors.orange,
                        ),
                        title: Text(
                          controller.getVideoTitle(videoId),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Queued for download',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            controller.downloadQueue.remove(videoId);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (controller.downloadingVideos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Downloading',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...controller.downloadingVideos.map(
                    (videoId) => Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.getVideoTitle(videoId),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Obx(() {
                                      final progress = controller
                                          .getDownloadProgress(videoId);
                                      return Text(
                                        '${progress.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue,
                                        ),
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        controller.cancelDownload(videoId);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Obx(() {
                              final progress = controller.getDownloadProgress(
                                videoId,
                              );
                              return Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: progress / 100,
                                    backgroundColor: Colors.grey[300],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.blue,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Downloading...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '${progress.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (controller.downloadedVideos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Completed Downloads',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...controller.downloadedVideos.map(
                    (videoId) => Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text(
                          controller.getVideoTitle(videoId),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Download completed',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            controller.downloadedVideos.remove(videoId);
                            controller.videoFilePaths.remove(videoId);
                            controller.storage.write(
                              'downloadedVideos',
                              controller.downloadedVideos.toList(),
                            );
                            controller.storage.write(
                              'videoFilePaths',
                              controller.videoFilePaths,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      }),
    );
  }
}
