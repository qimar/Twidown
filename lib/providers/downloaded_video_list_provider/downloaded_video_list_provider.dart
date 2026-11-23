// downloaded_video_list_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:videodownloader/models/video_downloaded_model/video_downloaded_model.dart';
import 'package:videodownloader/service_locator.dart';
import 'package:videodownloader/services/object_box/object_box_service.dart';

class DownloadedVideoListProvider extends ChangeNotifier {
  List<VideoDownloadedModel> _downloadedVideos = [];
  List<VideoDownloadedModel> get downloadedVideos => _downloadedVideos;

  // Track videos that are pending deletion (for UNDO)
  final Set<VideoDownloadedModel> _pendingDelete = {};

  // Prevent full reload from overriding pending deletes
  bool _hasPendingUndo = false;

 void loadDownloadedVideos({bool forceRefresh = false}) {
  if (forceRefresh || !_hasPendingUndo) {
    final videos = getIt<ObjectBox>().getAllDownloadedVideos();
    debugPrint("📦 Loaded ${videos.length} videos from ObjectBox");
    _downloadedVideos = videos;
    _pendingDelete.clear();
    _hasPendingUndo = false;
  }
  debugPrint("📢 notifyListeners called, list size: ${_downloadedVideos.length}");
  notifyListeners();
}

  Future<void> deleteVideo(VideoDownloadedModel video, BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final box = getIt<ObjectBox>().store.box<VideoDownloadedModel>();

    // 1. Optimistic UI removal
    _downloadedVideos.remove(video);
    _pendingDelete.add(video);
    _hasPendingUndo = true;
    notifyListeners();

    // 2. Show Undo SnackBar
    scaffold.showSnackBar(
      SnackBar(
        content: const Text("Video deleted"),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "UNDO",
          textColor: Colors.white,
          onPressed: () {
            if (_pendingDelete.remove(video)) {
              _downloadedVideos.add(video);
              _hasPendingUndo = _pendingDelete.isNotEmpty;
              notifyListeners();
            }
          },
        ),
      ),
    );

    // 3. Auto commit delete after timeout
    await Future.delayed(const Duration(seconds: 4));

    if (_pendingDelete.contains(video)) {
      try {
        final file = File(video.videoPath);
        if (await file.exists()) await file.delete();

        box.remove(video.id);
        _pendingDelete.remove(video);
        _hasPendingUndo = _pendingDelete.isNotEmpty;

        debugPrint("Video permanently deleted: ${video.title}");
      } catch (e) {
        debugPrint("Delete failed: $e");
        // Revert on failure
        if (!_downloadedVideos.contains(video)) {
          _downloadedVideos.add(video);
        }
        _pendingDelete.remove(video);
        _hasPendingUndo = _pendingDelete.isNotEmpty;
        notifyListeners();

        scaffold.showSnackBar(const SnackBar(content: Text("Delete failed")));
      }
    }
  }

  void clearPendingOperations() {
    _pendingDelete.clear();
    _hasPendingUndo = false;
  }

   void onNewVideoDownloaded() {
  debugPrint("🔔 onNewVideoDownloaded called");
  loadDownloadedVideos(forceRefresh: true);
}
}