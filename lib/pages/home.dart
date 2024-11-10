import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  final TextEditingController _urlController = TextEditingController();
  bool _isValidUrl = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_validateUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _validateUrl() {
    setState(() {
      _isValidUrl = Uri.tryParse(_urlController.text)?.hasAbsolutePath ?? false;
    });
  }

  void _startDownload() {
    if (!_isValidUrl) return;

    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      ref.read(pendingDownloadsProvider.notifier).addPendingTask(
            TaskStatusUpdate(
              DownloadTask(
                url: url,
                filename: url.split('/').last,
              ),
              TaskStatus.enqueued,
            ),
          );
      
      // Clear the input field after starting the download
      _urlController.clear();

      // Show a snackbar to confirm the download has started
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download started'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Navigate to pending downloads page
              DefaultTabController.of(context).animateTo(1);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox.expand(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primaryContainer,
                          ),
                          child: Icon(
                            Icons.bolt,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'QuickDownload',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fast and easy file downloads',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Enter URL',
                              hintText: 'https://example.com/file.pdf',
                              prefixIcon: const Icon(Icons.link),
                              suffixIcon: _urlController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _urlController.clear(),
                                    )
                                  : null,
                              errorText: _urlController.text.isNotEmpty && !_isValidUrl
                                  ? 'Please enter a valid URL'
                                  : null,
                            ),
                            onSubmitted: (_) => _startDownload(),
                            textInputAction: TextInputAction.go,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: FilledButton.icon(
                            onPressed: _isValidUrl ? _startDownload : null,
                            icon: const Icon(Icons.download),
                            label: const Text('Start Download'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}