import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_event.dart';
import 'package:the_shelf/blocs/collection/collection_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/collection_model.dart';
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/collection_card.dart';

class CreateCollectionModal extends StatefulWidget {
  final CollectionModel? initialCollection;

  const CreateCollectionModal({
    super.key,
    this.initialCollection,
  });

  static Future<void> show(BuildContext context, {CollectionModel? initialCollection}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCollectionModal(initialCollection: initialCollection),
    );
  }

  @override
  State<CreateCollectionModal> createState() => _CreateCollectionModalState();
}

class _CreateCollectionModalState extends State<CreateCollectionModal> {
  late final TextEditingController _nameController;
  late String _selectedColorHex;
  late String _selectedIconName;
  String? _errorMessage;

  static const List<String> presetColors = [
    '#E06D53', // Terracotta
    '#4E8A79', // Sage Green
    '#5B6C9A', // Indigo
    '#8E5B9A', // Violet
    '#D99B26', // Amber
    '#2B8B9B', // Teal
    '#C85B7A', // Rose
    '#5A6B7C', // Slate
  ];

  static const List<String> presetIcons = [
    'bookmarkSimple',
    'folder',
    'star',
    'heart',
    'tag',
    'bookOpen',
    'lightning',
    'archive',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCollection?.name ?? '',
    );
    _selectedColorHex = widget.initialCollection?.colorHex ?? presetColors[0];
    _selectedIconName = widget.initialCollection?.iconName ?? presetIcons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Collection name cannot be empty';
      });
      return;
    }

    final collectionBloc = context.read<CollectionBloc>();
    if (widget.initialCollection == null) {
      // Check if at cap
      final state = collectionBloc.state;
      if (state is CollectionLoaded && state.isAtCap) {
        setState(() {
          _errorMessage = 'Maximum limit of 20 collections reached';
        });
        return;
      }
      collectionBloc.add(CreateCollection(
        name: name,
        colorHex: _selectedColorHex,
        iconName: _selectedIconName,
      ));
    } else {
      final updated = widget.initialCollection!.copyWith(
        name: name,
        colorHex: _selectedColorHex,
        iconName: _selectedIconName,
      );
      collectionBloc.add(UpdateCollection(updated));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;
    final isEditing = widget.initialCollection != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: activePalette.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: activePalette.cardBorder,
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: activePalette.secondaryText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Collection' : 'Create Collection',
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: activePalette.primaryText,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    PhosphorIcons.x,
                    color: activePalette.secondaryText,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name Input
            TextField(
              controller: _nameController,
              maxLength: 30,
              autofocus: true,
              style: TextStyle(
                fontSize: 16,
                color: activePalette.primaryText,
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Collection Name',
                hintText: 'e.g. Summer Reading, Work Docs',
                errorText: _errorMessage,
                labelStyle: TextStyle(color: activePalette.secondaryText),
                hintStyle: TextStyle(color: activePalette.secondaryText.withOpacity(0.5)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: activePalette.primaryAccent, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: activePalette.cardBorder),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color Selection Header
            Text(
              'Color Accent',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: activePalette.primaryText,
              ),
            ),
            const SizedBox(height: 10),

            // Color Palette Row
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presetColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final hex = presetColors[index];
                  final isSelected = hex.toUpperCase() == _selectedColorHex.toUpperCase();
                  final color = CollectionCard.parseHexColor(hex, activePalette.primaryAccent);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: activePalette.primaryText, width: 3)
                            : Border.all(color: Colors.transparent),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 20, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Icon Selection Header
            Text(
              'Icon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: activePalette.primaryText,
              ),
            ),
            const SizedBox(height: 10),

            // Icon Choices Row
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presetIcons.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final iconName = presetIcons[index];
                  final isSelected = iconName == _selectedIconName;
                  final iconData = CollectionCard.getCollectionIcon(iconName);
                  final activeColor = CollectionCard.parseHexColor(_selectedColorHex, activePalette.primaryAccent);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconName = iconName),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withOpacity(0.2)
                            : activePalette.subtleBadgeBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? activeColor : activePalette.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        iconData,
                        size: 22,
                        color: isSelected ? activeColor : activePalette.secondaryText,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Submit CTA Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CollectionCard.parseHexColor(_selectedColorHex, activePalette.primaryAccent),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Create Collection',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
