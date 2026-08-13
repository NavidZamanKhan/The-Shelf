import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing Library & Smart Import app settings and storage usage.
class AppSettingsService {
  static final AppSettingsService instance = AppSettingsService._internal();
  AppSettingsService._internal();

  static const String _keyInstantAutoFile = 'settings_auto_file_instant';
  static const String _keyHiddenShelves = 'settings_hidden_shelves';

  /// Whether instant auto-filing (skip confirmation modal) is enabled.
  Future<bool> getInstantAutoFile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyInstantAutoFile) ?? false;
  }

  Future<void> setInstantAutoFile(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInstantAutoFile, value);
  }

  /// Set of hidden shelf category names.
  Future<Set<String>> getHiddenShelves() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyHiddenShelves) ?? [];
    return list.toSet();
  }

  Future<void> setHiddenShelves(Set<String> hidden) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyHiddenShelves, hidden.toList());
  }

  /// Calculates total size of imported documents & local profile cache in bytes.
  Future<int> getStorageUsageBytes() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      int totalSize = 0;

      final importsDir = Directory('${docsDir.path}/imports');
      if (await importsDir.exists()) {
        await for (final file in importsDir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      final profileDir = Directory('${docsDir.path}/profile');
      if (await profileDir.exists()) {
        await for (final file in profileDir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage usage: $e');
      return 0;
    }
  }

  /// Formats byte count to human readable MB/KB string.
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Clears temporary cache directories.
  Future<void> clearLocalCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final list = tempDir.listSync();
        for (final entity in list) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error clearing temporary cache: $e');
    }
  }
}
