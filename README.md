# Media Playlist Task

[▶️ Watch recording.mp4](./recording.mp4)

A Flutter application for browsing, viewing, and managing a playlist of videos, with support for offline downloads and queue management.

## Features

- 📺 **Video List**: Browse a paginated list of videos with thumbnails, titles, and authors.
- 🔍 **Video Details**: View detailed information and play videos in a dedicated screen.
- ⏯️ **Video Player**: Stream videos online or play downloaded videos offline.
- 💾 **Download Queue**: Add videos to a download queue and manage downloads.
- ✅ **Offline Support**: Watch downloaded videos without an internet connection.
- 💡 **Auto-Play**: Toggle auto-play for seamless video browsing.
- 💾 **Persistent Storage**: Downloaded videos and queue state are saved locally.
- 🗑️ **Remove Downloads**: Delete downloaded videos from the device.
- 🧩 **GetX State Management**: Efficient and reactive UI updates.
- 🎨 **Modern UI**: Clean, responsive, and user-friendly interface.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart 3.x
- Android Studio or Xcode (for mobile builds)
- Internet connection (for initial video list and streaming)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vijaybheda/media_playlist_task.git
   cd media_playlist_task
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Project Structure

```
lib/
  main.dart                  # App entry point
  video_list_screen.dart     # Main video list UI
  video_view_screen.dart     # Video details and player
  video_player_widget.dart   # Custom video player widget
  download_queue_screen.dart # Download queue management
  data/
    model/
      video_model.dart       # Video data model
    video_data_provider.dart # Loads video data from assets
    video_list_controller.dart # GetX controller for state
    services/
      storage/
        get_storage.dart     # Local storage using GetStorage
  assets/
    videos_data.json         # Video metadata
```

### How It Works

- **Video List:** Loads video data from a local JSON file and displays it in a paginated list.
- **Video Player:** Uses the `video_player` package to stream or play local files.
- **Download Queue:** Users can queue videos for download; progress and completion are managed via GetX.
- **Offline Viewing:** Downloaded videos are stored locally and can be played without internet.
- **State Management:** All UI and data state is managed using GetX for reactivity and simplicity.

### Dependencies

- [`get`](https://pub.dev/packages/get) - State management and navigation
- [`get_storage`](https://pub.dev/packages/get_storage) - Local storage
- [`video_player`](https://pub.dev/packages/video_player) - Video playback
- [`dio`](https://pub.dev/packages/dio) - HTTP client for downloads
- [`cached_network_image`](https://pub.dev/packages/cached_network_image) - Efficient image loading

### Customization

- **Add More Videos:** Edit `assets/videos_data.json` to add or update video entries.
- **Change UI Theme:** Modify `ThemeData` in `main.dart`.
- **Extend Functionality:** Add new features by creating additional screens or controllers.
