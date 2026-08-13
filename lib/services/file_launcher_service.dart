import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:the_shelf/services/cloud_library_service.dart';
import 'package:the_shelf/services/document_repository.dart';

/// Service for opening documents/PDFs using the OS's native viewer.
/// On iOS: Opens native QuickLook preview.
/// On Android: Launches native OS PDF viewer intent.
class FileLauncherService {
  static final FileLauncherService instance = FileLauncherService._internal();
  FileLauncherService._internal();

  /// Attempts to resolve a broken path by searching permanent app imports directory or current app container.
  Future<File?> _resolveHealedFile(String originalPath, {String? title}) async {
    final String trimmed = originalPath.trim();
    if (trimmed.isNotEmpty) {
      final direct = File(trimmed);
      if (await direct.exists()) return direct;
    }

    final String fileName = trimmed.isNotEmpty ? p.basename(trimmed) : '';
    final String rawBase = fileName.isNotEmpty ? p.basenameWithoutExtension(fileName) : '';
    final String cleanTitle = (title ?? '').trim().toLowerCase();

    try {
      final docsDir = await getApplicationDocumentsDirectory();

      // 1. Check in Documents root
      if (fileName.isNotEmpty) {
        final inDocs = File('${docsDir.path}/$fileName');
        if (await inDocs.exists()) return inDocs;
      }

      // 2. Check in Documents/imports
      final importsDir = Directory('${docsDir.path}/imports');
      if (fileName.isNotEmpty) {
        final exactImportFile = File('${importsDir.path}/$fileName');
        if (await exactImportFile.exists()) return exactImportFile;
      }

      // 3. Search inside importsDir
      if (await importsDir.exists()) {
        final List<FileSystemEntity> files = importsDir.listSync();
        for (final entity in files) {
          if (entity is File) {
            final base = p.basename(entity.path).toLowerCase();
            if (fileName.isNotEmpty && (base == fileName.toLowerCase() || base.endsWith(fileName.toLowerCase()) || base.endsWith('_$fileName'.toLowerCase()))) {
              return entity;
            }
            if (rawBase.isNotEmpty && base.contains(rawBase.toLowerCase())) {
              return entity;
            }
            if (cleanTitle.isNotEmpty && base.contains(cleanTitle)) {
              return entity;
            }
          }
        }
      }

      // 4. Search inside docsDir root
      final List<FileSystemEntity> docFiles = docsDir.listSync();
      for (final entity in docFiles) {
        if (entity is File) {
          final base = p.basename(entity.path).toLowerCase();
          if (fileName.isNotEmpty && (base == fileName.toLowerCase() || base.endsWith(fileName.toLowerCase()))) {
            return entity;
          }
          if (cleanTitle.isNotEmpty && base.contains(cleanTitle)) {
            return entity;
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching healed file: $e');
    }
    return null;
  }

  /// Opens local file at [filePath] using native OS default application.
  Future<void> openFile(BuildContext context, String filePath, {String? documentId, String? title}) async {
    final String trimmedPath = filePath.trim();

    // 1. Attempt local file check and on-device path healing first!
    File? targetFile;
    if (trimmedPath.isNotEmpty) {
      final directFile = File(trimmedPath);
      if (await directFile.exists()) {
        targetFile = directFile;
      }
    }

    targetFile ??= await _resolveHealedFile(trimmedPath, title: title);

    if (targetFile != null && await targetFile.exists()) {
      if (documentId != null && targetFile.path != trimmedPath) {
        try {
          await DocumentRepository.instance.updateDocumentFilePath(documentId, targetFile.path);
        } catch (_) {}
      }
    } else {
      // 2. Only if genuine local file is missing, attempt cloud fallback
      if (context.mounted) {
        _showSnackBar(context, 'Downloading document from cloud...', isError: false);
      }
      final downloadedFile = await CloudLibraryService.instance.downloadDocumentFile(
        docId: documentId ?? p.basenameWithoutExtension(trimmedPath),
        originalFileName: trimmedPath.isNotEmpty ? p.basename(trimmedPath) : '$title.pdf',
      );

      if (downloadedFile != null && await downloadedFile.exists()) {
        targetFile = downloadedFile;
        if (documentId != null) {
          try {
            await DocumentRepository.instance.updateDocumentFilePath(documentId, targetFile.path);
          } catch (_) {}
        }
      } else {
        if (context.mounted) {
          _showSnackBar(
            context,
            'File not found locally or in cloud. Tap + to re-import!',
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
