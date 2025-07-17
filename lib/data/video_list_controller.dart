import 'package:get/get.dart';
import 'package:media_playlist_task/video_list_screen.dart';
import 'model/video_model.dart';
import 'video_data_provider.dart';
import 'services/storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class VideoListController extends GetxController {
  final videos = <VideoModel>[].obs;
  final playingIndex = (-1).obs;
  final savedVideos = <String>{}.obs;
  final downloadQueue = <String>{}.obs;
  final downloadingVideos = <String>{}.obs;
  final downloadedVideos = <String>{}.obs;
  final videoFilePaths = <String, String>{}.obs;

  final isLoading = false.obs;
  final isError = false.obs;
  final hasMore = true.obs;
  int _page = 1;
  final int _pageSize = 5;

  final autoPlayEnabled = true.obs;
  final isAutoPlayPaused = false.obs;

  final storage = GetxStorage();

  @override
  void onInit() {
    super.onInit();
    _loadSavedVideos();
    _loadDownloadedVideos();
    _loadVideoFilePaths();
    loadVideos();
    _setupDownloadQueue();
  }

  void _setupDownloadQueue() {
    downloadQueue.addAll(downloadedVideos);
  }

  Future<void> loadVideos({bool refresh = false}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    isError.value = false;
    try {
      if (refresh) {
        _page = 1;
        videos.clear();
        hasMore.value = true;
      }
      final newVideos = await VideoDataProvider.getVideos(
        page: _page,
        pageSize: _pageSize,
      );
      if (newVideos.isEmpty) {
        hasMore.value = false;
      } else {
        videos.addAll(newVideos);
        _page++;
      }
    } catch (e) {
      isError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void setPlayingIndex(int index) {
    if (autoPlayEnabled.value && !isAutoPlayPaused.value) {
      playingIndex.value = index;
    }
  }

  void pausePlaying() {
    playingIndex.value = -1;
  }

  void toggleAutoPlay() {
    autoPlayEnabled.value = !autoPlayEnabled.value;
    if (autoPlayEnabled.value) {
      isAutoPlayPaused.value = false;
    }
  }

  void pauseAutoPlay() {
    isAutoPlayPaused.value = true;
  }

  void resumeAutoPlay() {
    isAutoPlayPaused.value = false;
    if (autoPlayEnabled.value) {
      final visibleVideo = Get.find<VideoListScreen>().getVisibleVideo();
      if (visibleVideo != null) {
        playingIndex.value = visibleVideo;
      }
    }
  }

  void saveVideo(String videoId) {
    savedVideos.add(videoId);
    storage.write('savedVideos', savedVideos.toList());
    update();
  }

  void unsaveVideo(String videoId) {
    savedVideos.remove(videoId);
    storage.write('savedVideos', savedVideos.toList());
    update();
  }

  bool isSaved(String videoId) => savedVideos.contains(videoId);

  void _loadSavedVideos() {
    final saved = storage.read<List>('savedVideos');
    if (saved != null) {
      savedVideos.addAll(saved.cast<String>());
    }
  }

  Future<void> downloadVideo(String videoId, String url) async {
    if (isDownloaded(videoId) || isDownloading(videoId)) {
      return;
    }

    if (downloadQueue.contains(videoId)) {
      Get.snackbar('Download Queue', 'Video is already in queue');
      return;
    }

    downloadQueue.add(videoId);

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/video_$videoId.mp4';

      await Dio().download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(1);
            Get.snackbar('Download Progress', '$progress%');
          }
        },
      );

      downloadedVideos.add(videoId);
      videoFilePaths[videoId] = filePath;
      storage.write('downloadedVideos', downloadedVideos.toList());
      storage.write('videoFilePaths', videoFilePaths);
      storage.write('videoFilePaths', videoFilePaths);
    } catch (e) {
      // handle error if needed
    } finally {
      downloadingVideos.remove(videoId);
    }
  }

  bool isDownloading(String videoId) => downloadingVideos.contains(videoId);
  bool isDownloaded(String videoId) => downloadedVideos.contains(videoId);

  void _loadDownloadedVideos() {
    final downloaded = storage.read<List>('downloadedVideos');
    if (downloaded != null) {
      downloadedVideos.addAll(downloaded.cast<String>());
    }
  }

  void _loadVideoFilePaths() {
    final paths = storage.read<Map>('videoFilePaths');
    if (paths != null) {
      videoFilePaths.addAll(Map<String, String>.from(paths));
    }
  }

  String? getLocalFilePath(String videoId) {
    return videoFilePaths[videoId];
  }

  void removeFromDownloadQueue(String videoId) {
    downloadQueue.remove(videoId);
    update();
  }

  void removeFromDownloadingVideos(String videoId) {
    downloadingVideos.remove(videoId);
    update();
  }
}
