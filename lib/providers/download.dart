import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';

class DownloadManager extends StateNotifier<List<DownloadTask>> {
  DownloadManager() : super([]);

  void addDownloadTask(String url) {
    final task = DownloadTask(
      url: url,
      filename: url.split('/').last,
    );
    state = [...state, task];
    _enqueueTask(task);
  }

  void _enqueueTask(DownloadTask task) async {
    final success = await FileDownloader().enqueue(task);
    if (!success) {
      // Handle enqueue failure
    }
  }

  void cancelTask(String taskId) async {
    await FileDownloader().cancelTaskWithId(taskId);
    state = state.where((task) => task.taskId != taskId).toList();
  }

  /* TODO
  void pauseTask(String taskId) async {
    await FileDownloader().pause(taskId);
  }

    TODO
  void resumeTask(String taskId) async {
    await FileDownloader().resume(taskId);
  }
  */
}

final downloadManagerProvider = StateNotifierProvider<DownloadManager, List<DownloadTask>>((ref) {
  return DownloadManager();
});