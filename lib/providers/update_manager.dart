import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import './download.dart';
import './history.dart';
import './pending.dart';

final downloadUpdatesProvider = Provider<StreamSubscription<TaskUpdate>>((ref) {
  final subscription = FileDownloader().updates.listen((update) async {
    switch (update) {
      case TaskStatusUpdate():
        final task = update.task as DownloadTask;
        final record = await FileDownloader().database.recordForId(task.taskId);
        if (update.status == TaskStatus.complete) {
          ref.read(downloadManagerProvider.notifier).state = ref
              .read(downloadManagerProvider.notifier)
              .state
              .where((t) => t.taskId != task.taskId)
              .toList();
          ref
              .read(pendingDownloadsProvider.notifier)
              .removePendingTask(task.taskId);
          if (record != null) {
            ref.read(downloadHistoryProvider.notifier).addCompletedTask(record);
          }
        } else if (update.status == TaskStatus.enqueued) {
          ref.read(pendingDownloadsProvider.notifier).addPendingTask(task);
        }
        break;
      case TaskProgressUpdate():
        // Handle progress update if needed
        break;
    }
  });

  ref.onDispose(() => subscription.cancel());
  return subscription;
});
