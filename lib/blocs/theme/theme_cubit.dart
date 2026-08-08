import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_shelf/theme/app_color_palette.dart';

class ThemeCubit extends Cubit<AppColorPalette> {
  static const String _prefKey = 'theme_palette_id';

  ThemeCubit() : super(AppColorPalette.terracotta);

  /// Reads persisted palette ID from SharedPreferences on boot
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefKey);
      if (savedId != null) {
        emit(AppColorPalette.fromId(savedId));
      }
    } catch (_) {
      // Fallback to initial state if storage error occurs
    }
  }

  /// Sets active palette and persists choice to SharedPreferences
  Future<void> setPalette(String paletteId) async {
    final newPalette = AppColorPalette.fromId(paletteId);
    emit(newPalette);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, paletteId);
    } catch (_) {
      // Persistence error handled gracefully
    }
  }
}
