import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/document_import/document_import_bloc.dart';
import 'package:the_shelf/blocs/document_import/document_import_event.dart';
import 'package:the_shelf/screens/classifier_debug_screen.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';

/// Reusable import bottom sheet modal widget.
class ImportBottomSheetModal extends StatelessWidget {
  const ImportBottomSheetModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return BlocProvider.value(
          value: context.read<DocumentImportBloc>(),
          child: const ImportBottomSheetModal(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: FutureBuilder<void>(
          future: ShelfClassifierService.instance.ensureInitialized(),
          builder: (context, snapshot) {
            final bool isReady = snapshot.connectionState == ConnectionState.done;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (!isReady)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading classifier model...'),
                      ],
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Import PDF / Document'),
                  subtitle: const Text('Add files from your device storage'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<DocumentImportBloc>().add(const PickAndExtractPdfEvent());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.center_focus_weak_outlined),
                  title: const Text('Scan Book or Document'),
                  subtitle: const Text('Use camera to scan physical pages'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: const Text('Add Web Article'),
                  subtitle: const Text('Save articles or URL documents'),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Classifier Verification Debugger'),
                  subtitle: const Text('Test on-device text classifier predictions'),
                  trailing: isReady
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                      : const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClassifierDebugScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
