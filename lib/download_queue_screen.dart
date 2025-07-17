import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/video_list_controller.dart';

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
                  ...controller.downloadQueue
                      .map(
                        (videoId) => ListTile(
                          title: Text('Video $videoId'),
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () {
                              controller.downloadQueue.remove(videoId);
                            },
                          ),
                        ),
                      )
                      .toList(),
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
                  ...controller.downloadingVideos
                      .map((videoId) => ListTile(title: Text('Video $videoId')))
                      .toList(),
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
                  ...controller.downloadedVideos
                      .map(
                        (videoId) => ListTile(
                          title: Text('Video $videoId'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
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
                      )
                      .toList(),
                ],
              ),
          ],
        );
      }),
    );
  }
}
