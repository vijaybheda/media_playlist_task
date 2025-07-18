import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'features/video/views/video_list_screen.dart';
import 'features/video/views/video_view_screen.dart';
import 'features/video/views/download_queue_screen.dart';
import 'features/video/bindings/video_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init('video_app');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Video List App',
      debugShowCheckedModeBanner: false,
      navigatorKey: Get.key,
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const VideoListScreen(),
          binding: VideoBinding(),
        ),
        GetPage(
          name: '/video',
          page: () => VideoViewScreen(video: Get.arguments),
          binding: VideoBinding(),
        ),
        GetPage(
          name: '/downloads',
          page: () => const DownloadQueueScreen(),
          binding: VideoBinding(),
        ),
      ],
      defaultTransition: Transition.native,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
