import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

/// Service for opening documents/PDFs using the OS's native viewer.
/// On iOS: Opens native QuickLook preview.
/// On Android: Launches native OS PDF viewer intent.
class FileLauncherService {
  static final FileLauncherService instance = FileLauncherService._internal();
  FileLauncherService._internal();

  /// Opens local file at [filePath] using native OS default application.
  Future<void> openFile(BuildContext context, String filePath) async {
    final String trimmedPath = filePath.trim();
    if (trimmedPath.isEmpty) {
      _showSnackBar(context, 'No file path recorded for this document.');
      return;
    }

    final File file = File(trimmedPath);
    if (!await file.exists()) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'File not found on device: "${file.path}"',
          isError: true,
        );
      }
      return;
    }

    try {
      final OpenResult result = await OpenFilex.open(trimmedPath);
      if (result.type != ResultType.done && context.mounted) {
        _showSnackBar(
          context,
          'Could not open document: ${result.message}',
          isError: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          'Error launching native viewer: $e',
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }
}
