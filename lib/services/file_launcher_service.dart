import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:the_shelf/services/document_repository.dart';

/// Service for opening documents/PDFs using the OS's native viewer.
/// On iOS: Opens native QuickLook preview.
/// On Android: Launches native OS PDF viewer intent.
class FileLauncherService {
  static final FileLauncherService instance = FileLauncherService._internal();
  FileLauncherService._internal();

  /// Attempts to resolve a broken path by searching permanent app imports directory or current app container.
  Future<File?> _resolveHealedFile(String originalPath) async {
    final String fileName = p.basename(originalPath);
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final importsDir = Directory('${docsDir.path}/imports');

      if (await importsDir.exists()) {
        final List<FileSystemEntity> files = importsDir.listSync();
        for (final entity in files) {
          if (entity is File && p.basename(entity.path).endsWith(fileName)) {
            return entity;
          }
        }
      }

      final exactImportFile = File('${importsDir.path}/$fileName');
      if (await exactImportFile.exists()) {
        return exactImportFile;
      }
    } catch (e) {
      debugPrint('Error searching healed file: $e');
    }
    return null;
  }

  /// Opens local file at [filePath] using native OS default application.
  Future<void> openFile(BuildContext context, String filePath, {String? documentId}) async {
    final String trimmedPath = filePath.trim();
    if (trimmedPath.isEmpty) {
      _showSnackBar(context, 'No file path recorded for this document.', isError: true);
      return;
    }

    File targetFile = File(trimmedPath);
    if (!await targetFile.exists()) {
      // Attempt path healing from permanent application storage
      final File? healedFile = await _resolveHealedFile(trimmedPath);
      if (healedFile != null) {
        targetFile = healedFile;
        if (documentId != null) {
          try {
            await DocumentRepository.instance.updateDocumentFilePath(documentId, targetFile.path);
          } catch (_) {}
        }
      } else {
        if (context.mounted) {
          _showSnackBar(
            context,
            'File not found on device (cleared by OS temp cleanup). Tap + to re-import!',
            isError: true,
          );
        }
        return;
      }
    }

    try {
      final OpenResult result = await OpenFilex.open(targetFile.path);
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
