import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';

class DownloadHistoryManager extends StateNotifier<List<TaskRecord>> {
  DownloadHistoryManager() : super([]);

  void addCompletedTask(TaskRecord record) {
    state = [...state, record];
  }

  void clearHistory() {
    state = [];
  }
}

final downloadHistoryProvider = StateNotifierProvider<DownloadHistoryManager, List<TaskRecord>>((ref) {
  return DownloadHistoryManager();
});
