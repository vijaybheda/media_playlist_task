import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:media_playlist_task/features/video/controllers/video_list_controller.dart';

class VideoPlayerGetXController extends GetxController {
  String? url;
  String? filePath;
  final RxBool shouldPlay = true.obs;
  final String videoId;
  final Duration initialPosition;

  VideoPlayerGetXController({
    this.url,
    this.filePath,
    bool shouldPlay = true,
    required this.videoId,
    this.initialPosition = Duration.zero,
  }) {
    this.shouldPlay.value = shouldPlay;
  }

  late final Rx<VideoPlayerController?> controller = Rx<VideoPlayerController?>(
    null,
  );
  final isInitialized = false.obs;
  final isPlaying = false.obs;
  final isError = false.obs;
  final errorMessage = ''.obs;
  final isFullScreen = false.obs;
  final showControls = true.obs;
  final volume = 1.0.obs;
  final isMuted = false.obs;
  final position = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
    ever(shouldPlay, (bool play) {
      if (play) {
        playVideo();
      } else {
        pauseVideo();
      }
    });
  }

  void _initializeController() async {
    try {
      isInitialized.value = false;
      isError.value = false;
      errorMessage.value = '';
      VideoPlayerController? ctrl;
      if (filePath != null) {
        final file = File(filePath!);
        if (!file.existsSync()) {
          isError.value = true;
          errorMessage.value = 'File not found';
          return;
        }
        ctrl = VideoPlayerController.file(file);
      } else if (url != null) {
        ctrl = VideoPlayerController.networkUrl(Uri.parse(url!));
      } else {
        isError.value = true;
        errorMessage.value = 'No video source';
        return;
      }
      await ctrl.initialize();
      await ctrl.setLooping(false); // No looping
      ctrl.setVolume(isMuted.value ? 0.0 : volume.value);
      if (initialPosition > Duration.zero) {
        await ctrl.seekTo(initialPosition);
      }
      controller.value = ctrl;
      isInitialized.value = true;
      if (shouldPlay.value) {
        playVideo();
      }
      ctrl.addListener(_onControllerUpdate);
    } catch (e) {
      isError.value = true;
      errorMessage.value = e.toString();
    }
  }

  void updateShouldPlay(bool play) {
    shouldPlay.value = play;
  }

  void updateSource({
    String? newFilePath,
    String? newUrl,
    Duration? newPosition,
  }) {
    if (newFilePath != filePath || newUrl != url) {
      filePath = newFilePath;
      url = newUrl;
      _disposeController();
      _initializeController();
    } else if (newPosition != null) {
      controller.value?.seekTo(newPosition);
    }
  }

  void _disposeController() {
    controller.value?.removeListener(_onControllerUpdate);
    controller.value?.dispose();
    controller.value = null;
    isInitialized.value = false;
  }

  void _onControllerUpdate() {
    final ctrl = controller.value;
    if (ctrl == null) return;
    isPlaying.value = ctrl.value.isPlaying;
    position.value = ctrl.value.position;
    // Update the global video position in VideoListController
    if (videoId.isNotEmpty) {
      final listController = Get.isRegistered<VideoListController>()
          ? Get.find<VideoListController>()
          : null;
      listController?.updateVideoPosition(videoId, ctrl.value.position);
    }
    if (ctrl.value.hasError) {
      isError.value = true;
      errorMessage.value = ctrl.value.errorDescription ?? 'Playback error';
    }
  }

  void playVideo() {
    final ctrl = controller.value;
    if (ctrl != null && isInitialized.value) {
      ctrl.play();
      isPlaying.value = true;
    }
  }

  void pauseVideo() {
    final ctrl = controller.value;
    if (ctrl != null && isInitialized.value) {
      ctrl.pause();
      isPlaying.value = false;
    }
  }

  void togglePlayPause() {
    isPlaying.value ? pauseVideo() : playVideo();
  }

  void setVolume(double v) {
    volume.value = v;
    if (!isMuted.value) {
      controller.value?.setVolume(v);
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (isMuted.value) {
      controller.value?.setVolume(0.0);
    } else {
      controller.value?.setVolume(volume.value);
    }
  }

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  void enterFullScreen() {
    isFullScreen.value = true;
  }

  void exitFullScreen() {
    isFullScreen.value = false;
  }

  @override
  void onClose() {
    _disposeController();
    super.onClose();
  }
}
