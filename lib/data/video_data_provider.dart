import 'dart:convert';
import 'package:flutter/services.dart';
import 'model/video_model.dart';

class VideoDataProvider {
  static Future<List<VideoModel>> getVideos({
    int page = 1,
    int pageSize = 5,
  }) async {
    final String jsonString = await rootBundle.loadString(
      'assets/videos_data.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    final List<VideoModel> allVideos = jsonList
        .map((e) => VideoModel.fromJson(e))
        .toList();

    final int start = (page - 1) * pageSize;
    final int end = (start + pageSize).clamp(0, allVideos.length);
    await Future.delayed(const Duration(milliseconds: 500));
    return allVideos.sublist(start, end);
  }
}
