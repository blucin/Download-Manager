import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'package:background_downloader/background_downloader.dart';

class Pending extends ConsumerWidget {
  const Pending({super.key});

  String _getStatusText(TaskUpdate update) {
    if (update is TaskStatusUpdate) {
      switch (update.status) {
        case TaskStatus.enqueued:
          return 'Waiting to start...';
        case TaskStatus.running:
          return 'Downloading...';
        case TaskStatus.failed:
          return 'Failed - Tap to retry';
        case TaskStatus.canceled:
          return 'Canceled';
        default:
          return update.status.toString();
      }
    }
    return 'Downloading...';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingTaskUpdates = ref.watch(pendingDownloadsProvider);

    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox.expand(
        child: pendingTaskUpdates.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download_done,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending downloads',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: pendingTaskUpdates.length,
                itemBuilder: (context, index) {
                  final update = pendingTaskUpdates.values.elementAt(index);
                  final progress = update is TaskProgressUpdate ? update.progress : 0.0;
                  final status = update is TaskStatusUpdate ? update.status : TaskStatus.running;
                  final bool isFailed = status == TaskStatus.failed;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: InkWell(
                      onTap: isFailed 
                        ? () => ref.read(pendingDownloadsProvider.notifier)
                            .retryDownload(update.task.taskId)
                        : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        update.task.filename,
                                        style: Theme.of(context).textTheme.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getStatusText(update),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isFailed 
                                            ? Theme.of(context).colorScheme.error
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    ref.read(pendingDownloadsProvider.notifier)
                                        .removePendingTask(update.task.taskId);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 8.0,
                                backgroundColor: isFailed 
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : null,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isFailed 
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              '${progress.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}