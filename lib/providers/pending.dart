import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';

class PendingDownloadsManager extends StateNotifier<List<DownloadTask>> {
  PendingDownloadsManager() : super([]);

  void addPendingTask(DownloadTask task) {
    state = [...state, task];
  }

  void removePendingTask(String taskId) {
    state = state.where((task) => task.taskId != taskId).toList();
  }
}

final pendingDownloadsProvider = StateNotifierProvider<PendingDownloadsManager, List<DownloadTask>>((ref) {
  return PendingDownloadsManager();
});
