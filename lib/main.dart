import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import './pages/home.dart';
import './pages/history.dart';
import './pages/pending.dart';
import './pages/settings.dart';
import './providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Check for storage permission
  if (await Permission.storage.isGranted) {
    // Permission is already granted
  } else {
    // Request permission
    final status = await Permission.storage.request();
    if (status.isGranted) {
      // Permission granted
    } else {
      // Permission denied
    }
  } 

  FileDownloader().configureNotification(
    running: const TaskNotification('Downloading', 'file: {filename}'),
    progressBar: true
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NavigationBarApp(),
    ),
  );
}

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const NavigationExample(),
    );
  }
}

class NavigationExample extends ConsumerStatefulWidget {
  const NavigationExample({super.key});

  @override
  ConsumerState<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends ConsumerState<NavigationExample> {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Access the provider to ensure it is active
    ref.read(downloadUpdatesProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Pending',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: <Widget>[
        const Home(),
        const Pending(),
        const History(),
        const Settings(),
      ][currentPageIndex],
    );
  }
}
