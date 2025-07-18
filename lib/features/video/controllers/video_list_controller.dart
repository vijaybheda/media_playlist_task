import 'package:get/get.dart';
import 'package:media_playlist_task/data/model/video_model.dart';
import 'package:media_playlist_task/data/video_data_provider.dart';
import 'package:media_playlist_task/data/services/storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VideoListController extends GetxController {
  /// List of all loaded videos
  final RxList<VideoModel> videos = <VideoModel>[].obs;

  /// Index of the currently playing video
  final RxInt playingIndex = (-1).obs;

  /// Whether manual pause is active
  final RxBool manualPaused = false.obs;

  /// Set of saved video IDs
  final RxSet<String> savedVideos = <String>{}.obs;

  /// Download management
  final RxSet<String> downloadQueue = <String>{}.obs;
  final RxSet<String> downloadingVideos = <String>{}.obs;
  final RxSet<String> downloadedVideos = <String>{}.obs;
  final RxMap<String, String> videoFilePaths = <String, String>{}.obs;
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;

  /// Playback position tracking for each video
  final RxMap<String, Duration> videoPositions = <String, Duration>{}.obs;

  /// UI state
  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool autoPlayEnabled = true.obs;

  /// Pagination and internal state
  int _page = 1;
  final int _pageSize = 5;
  int _loadCount = 0;
  final int _maxLoads = 5;

  /// Storage service
  final GetxStorage storage = GetxStorage();

  /// Download cancel tokens
  final Map<String, CancelToken> _downloadTokens = {};

  @override
  void onInit() {
    super.onInit();
    _restoreDownloadedVideos();
    loadVideos();
    // All other variables are initialized as usual (not restored from storage)
  }

  Future<void> _restoreDownloadedVideos() async {
    final dir = await getTemporaryDirectory();
    final files = dir.listSync();
    for (var file in files) {
      if (file is File &&
          file.path.endsWith('.mp4') &&
          file.path.contains('video_')) {
        final fileName = file.uri.pathSegments.last;
        final videoId = fileName.replaceAll(RegExp(r'video_|\.mp4'), '');
        downloadedVideos.add(videoId);
        videoFilePaths[videoId] = file.path;
      }
    }
  }

  /// Loads videos from the data provider, paginated
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
      // Get.snackbar('Error', 'Failed to load videos');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sets the currently playing video index
  void setPlayingIndex(int index) {
    if (!autoPlayEnabled.value || manualPaused.value) return;
    if (playingIndex.value != index) {
      playingIndex.value = index;
      manualPaused.value = false;
      pauseAllExcept(index);
    }
  }

  /// Pauses all videos
  void pausePlaying() {
    playingIndex.value = -1;
    manualPaused.value = false;
    pauseAllExcept(-1);
  }

  /// Manually play a video by index
  void manualPlay(int index) {
    playingIndex.value = index;
    manualPaused.value = false;
    pauseAllExcept(index);
  }

  /// Manually pause all videos
  void manualPause() {
    manualPaused.value = true;
    pauseAllExcept(-1);
  }

  /// Toggles auto-play
  void toggleAutoPlay() {
    autoPlayEnabled.value = !autoPlayEnabled.value;
    if (autoPlayEnabled.value) {
      manualPaused.value = false;
      if (videos.isNotEmpty) {
        setPlayingIndex(playingIndex.value == -1 ? 0 : playingIndex.value);
      }
    } else {
      pausePlaying();
    }
  }

  /// Pauses all except the given index
  void pauseAllExcept(int exceptIndex) {
    for (var i = 0; i < videos.length; i++) {
      final tag = 'video_${videos[i].id}_$i';
      if (Get.isRegistered(tag: tag)) {
        final ctrl = Get.find(tag: tag);
        ctrl.updateShouldPlay(i == exceptIndex);
      }
    }
  }

  /// Save a video by id
  void saveVideo(String videoId) {
    savedVideos.add(videoId);
  }

  /// Unsave a video by id
  void unsaveVideo(String videoId) {
    savedVideos.remove(videoId);
  }

  bool isSaved(String videoId) => savedVideos.contains(videoId);

  /// Download a video and track progress
  Future<void> downloadVideo(String videoId, String url) async {
    if (isDownloaded(videoId) || isDownloading(videoId)) return;
    downloadQueue.add(videoId);
    downloadingVideos.add(videoId);
    downloadProgress[videoId] = 0.0;

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
            downloadProgress[videoId] = (received / total) * 100;
          }
        },
      );

      downloadedVideos.add(videoId);
      videoFilePaths[videoId] = filePath;
      Get.snackbar('Download Complete', 'Video downloaded and cached.');
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        Get.snackbar('Download Cancelled', 'Download was cancelled.');
      } else {
        Get.snackbar('Download Failed', 'Failed to download video: $e');
      }
    } finally {
      downloadProgress.remove(videoId);
      downloadingVideos.remove(videoId);
      downloadQueue.remove(videoId);
      _downloadTokens.remove(videoId);
    }
  }

  /// Cancel a download by videoId
  void cancelDownload(String videoId) {
    _downloadTokens[videoId]?.cancel('Download cancelled by user');
    downloadingVideos.remove(videoId);
    downloadQueue.remove(videoId);
    downloadProgress.remove(videoId);
    _downloadTokens.remove(videoId);
  }

  bool isDownloading(String videoId) => downloadingVideos.contains(videoId);
  bool isDownloaded(String videoId) => downloadedVideos.contains(videoId);

  double getDownloadProgress(String videoId) =>
      downloadProgress[videoId] ?? 0.0;

  String? getLocalFilePath(String videoId) => videoFilePaths[videoId];

  /// Update the playback position for a video
  void updateVideoPosition(String videoId, Duration position) {
    videoPositions[videoId] = position;
  }

  /// Get the last known position for a video
  Duration getLastPosition(String videoId) =>
      videoPositions[videoId] ?? Duration.zero;

  /// Get the video title by id
  String getVideoTitle(String videoId) {
    return videos.firstWhereOrNull((v) => v.id == videoId)?.title ??
        'Unknown Video';
  }

  @override
  void onClose() {
    for (final token in _downloadTokens.values) {
      token.cancel('Controller disposed');
    }
    super.onClose();
  }

  void deleteVideo(String videoId) {
    final filePath = videoFilePaths[videoId];
    if (filePath != null) {
      final file = File(filePath);
      file.deleteSync();
    }
  }
}
