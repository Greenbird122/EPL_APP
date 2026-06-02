import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAppearance { light, dark }

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('app_theme_mode');
    state = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setAppearance(AppAppearance appearance) async {
    state = appearance == AppAppearance.dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'app_theme_mode',
      appearance == AppAppearance.dark ? 'dark' : 'light',
    );
  }

  AppAppearance get appearance =>
      state == ThemeMode.dark ? AppAppearance.dark : AppAppearance.light;
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

final appAppearanceProvider = Provider<AppAppearance>((ref) {
  final mode = ref.watch(themeModeProvider);
  return mode == ThemeMode.dark ? AppAppearance.dark : AppAppearance.light;
});
