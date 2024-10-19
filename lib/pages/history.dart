import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class History extends ConsumerWidget {
  const History({super.key});

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MMM d, y HH:mm').format(dateTime);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'TaskStatus.complete':
        return Icons.check_circle;
      case 'TaskStatus.failed':
        return Icons.error;
      case 'TaskStatus.canceled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'TaskStatus.complete':
        return colorScheme.primary;
      case 'TaskStatus.failed':
        return colorScheme.error;
      case 'TaskStatus.canceled':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  Future<void> _openFile(BuildContext context, String? filePath) async {
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File path not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Request storage permissions
    if (await Permission.storage.request().isGranted ||
        await Permission.manageExternalStorage.request().isGranted) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access Downloads directory'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final fileName = filePath.split('/').last;
      final accessibleFilePath = '${downloadsDir.path}/$fileName';
      final file = File(accessibleFilePath);

      // log accessible file path
      print('Accessible file path: $accessibleFilePath');

      if (await file.exists()) {
        final result = await OpenFile.open(accessibleFilePath);
        if (result.type == ResultType.noAppToOpen) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot open this file type'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found in Downloads folder'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission denied'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyItems = ref.watch(downloadHistoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Card(
        shadowColor: Colors.transparent,
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Download History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                  if (historyItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(downloadHistoryProvider.notifier)
                            .clearHistory();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: historyItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No download history',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: historyItems.length,
                      itemBuilder: (context, index) {
                        final item = historyItems[index];

                        return Dismissible(
                          key: Key(item.taskId),
                          background: Container(
                            color: colorScheme.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Icon(
                              Icons.delete,
                              color: colorScheme.onError,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            ref
                                .read(downloadHistoryProvider.notifier)
                                .removeHistoryItem(item.taskId);
                          },
                          child: ListTile(
                            leading: Icon(
                              _getStatusIcon(item.status),
                              color: _getStatusColor(item.status, colorScheme),
                            ),
                            title: Text(
                              item.filename,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _formatDateTime(item.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: item.status == 'TaskStatus.complete'
                                ? IconButton(
                                    icon: const Icon(Icons.folder_open),
                                    onPressed: () =>
                                        _openFile(context, item.filePath),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
