import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/SecureStorageService.dart';

enum AppThemeMode { system, light, dark }

class ThemeCubit extends Cubit<AppThemeMode> {
  final SecureStorageService storage;
  ThemeCubit(this.storage) : super(AppThemeMode.system);

  static const String _key = 'theme';

  AppThemeMode _fromString(String? s) {
    switch (s) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  String _toString(AppThemeMode m) {
    switch (m) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  /// Call once at app start (in main) to load saved theme
  Future<void> hydrate() async {
    try {
      final saved = await storage.getString(_key);
      emit(_fromString(saved));
    } catch (e) {
      emit(AppThemeMode.system);
      // ignore or log
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    emit(mode);
    try {
      await storage.setString(_key, _toString(mode));
    } catch (_) {
      // ignore or log
    }
  }

  Future<void> setLightTheme() => setMode(AppThemeMode.light);
  Future<void> setDarkTheme() => setMode(AppThemeMode.dark);
  Future<void> setSystemTheme() => setMode(AppThemeMode.system);

  Future<void> clearForCurrentUser() => storage.delete(_key);
}
