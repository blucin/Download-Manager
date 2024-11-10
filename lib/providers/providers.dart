import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_downloader/background_downloader.dart';
import 'dart:async';
import 'dart:convert';

// Models
class DownloadHistoryItem {
  final String taskId;
  final String url;
  final String filename;
  final DateTime timestamp;
  final String status;
  final String? filePath;

  DownloadHistoryItem({
    required this.taskId,
    required this.url,
    required this.filename,
    required this.timestamp,
    required this.status,
    this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'url': url,
        'filename': filename,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
        'filePath': filePath,
      };

  static DownloadHistoryItem fromJson(Map<String, dynamic> json) {
    return DownloadHistoryItem(
      taskId: json['taskId'],
      url: json['url'],
      filename: json['filename'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
      filePath: json['filePath'],
    );
  }
}

// Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

// Pending Downloads Provider
class PendingDownloadsNotifier extends StateNotifier<Map<String, TaskUpdate>> {
  PendingDownloadsNotifier() : super({});

  void addPendingTask(TaskUpdate update) async {
    state = {...state, update.task.taskId: update};
    // Start the download immediately after adding to pending
    await FileDownloader().enqueue(update.task);
  }

  Future<void> removePendingTask(String taskId) async {
    final task = state[taskId]?.task;
    if (task != null) {
      await FileDownloader().cancelTaskWithId(taskId);
    }
    state = {...state}..remove(taskId);
  }

  void updatePendingTask(TaskUpdate update) {
    if (state.containsKey(update.task.taskId)) {
      state = {...state, update.task.taskId: update};
    }
  }

  Future<void> retryDownload(String taskId) async {
    final existingTask = state[taskId]?.task;
    if (existingTask != null) {
      final newTask = DownloadTask(
        url: existingTask.url,
        filename: existingTask.filename,
      );

      await removePendingTask(taskId);

      addPendingTask(TaskStatusUpdate(
        newTask,
        TaskStatus.enqueued,
      ));
    }
  }
}

final pendingDownloadsProvider =
    StateNotifierProvider<PendingDownloadsNotifier, Map<String, TaskUpdate>>(
        (ref) {
  return PendingDownloadsNotifier();
});

// History Provider
class DownloadHistoryNotifier extends StateNotifier<List<DownloadHistoryItem>> {
  final SharedPreferences prefs;
  static const String _historyKey = 'download_history';

  DownloadHistoryNotifier(this.prefs) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      state = historyJson
          .map((item) => DownloadHistoryItem.fromJson(json.decode(item)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading history: $e');
      state = [];
    }
  }

  Future<void> addHistoryItem(TaskUpdate update, [String? filePath]) async {
    try {
      final item = DownloadHistoryItem(
        taskId: update.task.taskId,
        url: update.task.url,
        filename: update.task.filename,
        timestamp: DateTime.now(),
        status:
            update is TaskStatusUpdate ? update.status.toString() : 'unknown',
        filePath: filePath,
      );

      state = [item, ...state];

      final historyJson =
          state.map((item) => json.encode(item.toJson())).toList();
      await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      print('Error adding history item: $e');
    }
  }

  Future<void> clearHistory() async {
    state = [];
    await prefs.remove(_historyKey);
  }

  Future<void> removeHistoryItem(String taskId) async {
    state = state.where((item) => item.taskId != taskId).toList();

    final historyJson =
        state.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_historyKey, historyJson);
  }
}

final downloadHistoryProvider =
    StateNotifierProvider<DownloadHistoryNotifier, List<DownloadHistoryItem>>(
        (ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DownloadHistoryNotifier(prefs);
});

// Download Updates Provider
final downloadUpdatesProvider = Provider<Future<StreamSubscription<TaskUpdate>>>((ref) async {
  final subscription = FileDownloader().updates.listen((update) async {
    switch (update) {
      case TaskStatusUpdate():
        if (update.status == TaskStatus.enqueued ||
            update.status == TaskStatus.running) {
          ref.read(pendingDownloadsProvider.notifier).updatePendingTask(update);
        } else if (update.status == TaskStatus.complete ||
            update.status == TaskStatus.canceled ||
            update.status == TaskStatus.failed) {
          if (update.status == TaskStatus.complete) {
            final newFilePath = await FileDownloader().moveToSharedStorage(
              update.task as DownloadTask,
              SharedStorage.downloads
            );
            ref
                .read(downloadHistoryProvider.notifier)
                .addHistoryItem(update, newFilePath);
          }
          ref
              .read(pendingDownloadsProvider.notifier)
              .removePendingTask(update.task.taskId);
        }
        break;
      case TaskProgressUpdate():
        ref.read(pendingDownloadsProvider.notifier).updatePendingTask(update);
        break;
    }
  });

  ref.onDispose(() => subscription.cancel());
  return subscription;
});
