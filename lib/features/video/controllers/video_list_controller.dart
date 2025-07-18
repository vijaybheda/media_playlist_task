import 'package:get/get.dart';
import 'package:media_playlist_task/data/model/video_model.dart';
import 'package:media_playlist_task/data/services/storage/get_storage.dart';
import 'package:media_playlist_task/data/video_data_provider.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_playlist_task/features/video/controllers/video_player_controller.dart';

class VideoListController extends GetxController {
  final videos = <VideoModel>[].obs;
  final playingIndex = (-1).obs;
  final manualPaused = false.obs;
  final savedVideos = <String>{}.obs;
  final downloadQueue = <String>{}.obs;
  final downloadingVideos = <String>{}.obs;
  final downloadedVideos = <String>{}.obs;
  final videoFilePaths = <String, String>{}.obs;
  final downloadProgress = <String, double>{}.obs; // Track download progress

  final isLoading = false.obs;
  final isError = false.obs;
  final hasMore = true.obs;
  int _page = 1;
  final int _pageSize = 5;
  int _loadCount = 0;
  final int _maxLoads = 5;

  final autoPlayEnabled = true.obs;
  final storage = GetxStorage();

  @override
  void onInit() {
    super.onInit();
    loadVideos().then((_) {
      if (autoPlayEnabled.value && videos.isNotEmpty) {
        setPlayingIndex(0);
      }
    });
  }

  Future<void> loadVideos({bool refresh = false}) async {
    if (isLoading.value || !hasMore.value) return;
    isLoading.value = true;
    isError.value = false;
    try {
      if (refresh) {
        _page = 1;
        _loadCount = 0;
        videos.clear();
        hasMore.value = true;
      }
      if (_loadCount >= _maxLoads) {
        hasMore.value = false;
        return;
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
        _loadCount++;
        if (_loadCount >= _maxLoads) {
          hasMore.value = false;
        }
      }
    } catch (e) {
      if (videos.isEmpty) {
        isError.value = true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void setPlayingIndex(int index) {
    if (!autoPlayEnabled.value || manualPaused.value) return;
    if (playingIndex.value != index) {
      playingIndex.value = index;
      manualPaused.value = false;
      pauseAllExcept(index);
    }
  }

  void pausePlaying() {
    playingIndex.value = -1;
    manualPaused.value = false;
    pauseAllExcept(-1);
  }

  void manualPlay(int index) {
    playingIndex.value = index;
    manualPaused.value = false;
    pauseAllExcept(index);
  }

  void manualPause() {
    manualPaused.value = true;
    pauseAllExcept(-1);
  }

  void toggleAutoPlay() {
    autoPlayEnabled.value = !autoPlayEnabled.value;
    if (autoPlayEnabled.value) {
      manualPaused.value = false;
      if (videos.isNotEmpty)
        setPlayingIndex(playingIndex.value == -1 ? 0 : playingIndex.value);
    } else {
      pausePlaying();
    }
  }

  void pauseAllExcept(int exceptIndex) {
    for (var i = 0; i < videos.length; i++) {
      if (i != exceptIndex) {
        final tag = 'video_${videos[i].id}_$i';
        if (Get.isRegistered<VideoPlayerGetXController>(tag: tag)) {
          final ctrl = Get.find<VideoPlayerGetXController>(tag: tag);
          ctrl.updateShouldPlay(false);
        }
      } else if (i == exceptIndex) {
        final tag = 'video_${videos[i].id}_$i';
        if (Get.isRegistered<VideoPlayerGetXController>(tag: tag)) {
          final ctrl = Get.find<VideoPlayerGetXController>(tag: tag);
          ctrl.updateShouldPlay(true);
        }
      }
    }
  }

  void saveVideo(String videoId) {
    savedVideos.add(videoId);
    update();
  }

  void unsaveVideo(String videoId) {
    savedVideos.remove(videoId);
    update();
  }

  bool isSaved(String videoId) => savedVideos.contains(videoId);

  CancelToken? _downloadCancelToken;
  Map<String, CancelToken> _downloadTokens = {};

  Future<void> downloadVideo(String videoId, String url) async {
    if (isDownloaded(videoId) || isDownloading(videoId)) {
      return;
    }
    downloadQueue.add(videoId);
    downloadingVideos.add(videoId);
    downloadProgress[videoId] = 0.0; // Initialize progress

    // Create cancel token for this download
    final cancelToken = CancelToken();
    _downloadTokens[videoId] = cancelToken;

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/video_$videoId.mp4';

      await Dio().download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total) * 100;
            downloadProgress[videoId] = progress;
          }
        },
      );

      downloadedVideos.add(videoId);
      videoFilePaths[videoId] = filePath;
      downloadProgress.remove(videoId); // Clear progress after completion
      _downloadTokens.remove(videoId); // Clean up token
      Get.snackbar('Download Complete', 'Video downloaded and cached.');
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        Get.snackbar('Download Cancelled', 'Download was cancelled.');
      } else {
        Get.snackbar(
          'Download Failed',
          'Failed to download video: ${e.toString()}',
        );
      }
      downloadProgress.remove(videoId); // Clear progress on error
      _downloadTokens.remove(videoId); // Clean up token
    } finally {
      downloadingVideos.remove(videoId);
      downloadQueue.remove(videoId);
    }
  }

  void cancelDownload(String videoId) {
    final cancelToken = _downloadTokens[videoId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled by user');
    }
    downloadingVideos.remove(videoId);
    downloadQueue.remove(videoId);
    downloadProgress.remove(videoId);
    _downloadTokens.remove(videoId);
  }

  bool isDownloading(String videoId) => downloadingVideos.contains(videoId);
  bool isDownloaded(String videoId) => downloadedVideos.contains(videoId);

  double getDownloadProgress(String videoId) =>
      downloadProgress[videoId] ?? 0.0;

  String? getLocalFilePath(String videoId) {
    return videoFilePaths[videoId];
  }

  String getVideoTitle(String videoId) {
    return videos.firstWhereOrNull((v) => v.id == videoId)?.title ??
        'Unknown Video';
  }

  @override
  void onClose() {
    pauseAllExcept(-1);
    super.onClose();
  }
}
