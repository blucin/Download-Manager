import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<bool> {
  final SharedPreferences prefs;
  static const String _key = 'isDarkMode';

  ThemeNotifier(this.prefs) : super(prefs.getBool(_key) ?? false);

  void toggleTheme() {
    state = !state;
    prefs.setBool(_key, state);
  }
}
