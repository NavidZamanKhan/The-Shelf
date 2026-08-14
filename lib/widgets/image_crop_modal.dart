import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Bespoke full-screen image cropping and reframing modal for avatar & cover banner photos.
class ImageCropModal extends StatefulWidget {
  final String imagePath;
  final bool isBanner;

  const ImageCropModal({
    super.key,
    required this.imagePath,
    required this.isBanner,
  });

  /// Opens the cropping modal and returns the path to the cropped temporary image file.
  static Future<String?> show(
    BuildContext context, {
    required String imagePath,
    required bool isBanner,
  }) {
    return Navigator.of(context).push<String>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ImageCropModal(
              imagePath: imagePath,
              isBanner: isBanner,
            ),
          );
        },
      ),
    );
  }

  @override
  State<ImageCropModal> createState() => _ImageCropModalState();
}

class _ImageCropModalState extends State<ImageCropModal> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  int _quarterTurns = 0;
  bool _isProcessing = false;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02 && mounted) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _rotate() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _transformController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  void _reset() {
    setState(() {
      _quarterTurns = 0;
      _transformController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  Future<void> _applyCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Ensure layout is settled
      await Future.delayed(const Duration(milliseconds: 60));
      final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.of(context).pop(widget.imagePath);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) Navigator.of(context).pop(widget.imagePath);
        return;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final String filename = 'cropped_${widget.isBanner ? "banner" : "avatar"}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String croppedPath = '${tempDir.path}/$filename';
      final File croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(bytes, flush: true);

      if (mounted) {
        Navigator.of(context).pop(croppedPath);
      }
    } catch (e) {
      debugPrint('Error during image crop capture: $e');
      if (mounted) {
        Navigator.of(context).pop(widget.imagePath);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cropAspectRatio = widget.isBanner ? 2.4 : 1.0;
    final double viewportWidth = size.width - 48;
    final double viewportHeight = viewportWidth / cropAspectRatio;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E11),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(PhosphorIcons.x, color: Colors.white70, size: 24),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                  Text(
                    widget.isBanner ? 'Crop Cover Photo' : 'Crop Profile Photo',
                    style: const TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instruction subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Pinch to zoom and drag to reframe your ${widget.isBanner ? "cover" : "avatar"} photo.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ),

            const Spacer(),

            // Centered Cropping Viewport
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow & Shadow
                  Container(
                    width: viewportWidth,
                    height: viewportHeight,
                    decoration: BoxDecoration(
                      borderRadius: widget.isBanner
                          ? BorderRadius.circular(16)
                          : BorderRadius.circular(viewportWidth / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  // Repaint Boundary that captures the transformed image
                  ClipRRect(
                    borderRadius: widget.isBanner
                        ? BorderRadius.circular(16)
                        : BorderRadius.circular(viewportWidth / 2),
                    child: Container(
                      width: viewportWidth,
                      height: viewportHeight,
                      color: Colors.black,
                      child: RepaintBoundary(
                        key: _cropKey,
                        child: Container(
                          color: Colors.black,
                          child: InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 0.8,
                            maxScale: 5.0,
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            clipBehavior: Clip.hardEdge,
                            child: Center(
                              child: RotatedBox(
                                quarterTurns: _quarterTurns,
                                child: Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Grid Overlay & Corner Border Markers (Non-intrusive)
                  IgnorePointer(
                    child: Container(
                      width: viewportWidth,
                      height: viewportHeight,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 2.0,
                        ),
                        borderRadius: widget.isBanner
                            ? BorderRadius.circular(16)
                            : BorderRadius.circular(viewportWidth / 2),
                      ),
                      child: widget.isBanner
                          ? CustomPaint(
                              painter: _GridLinesPainter(),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Zoom & Tool Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Icon(PhosphorIcons.magnifyingGlassMinus, color: Colors.white60, size: 20),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: _currentScale.clamp(0.8, 5.0),
                        min: 0.8,
                        max: 5.0,
                        onChanged: (val) {
                          final currentTranslation = _transformController.value.getTranslation();
                          final newMatrix = Matrix4.identity()
                            ..setTranslation(currentTranslation)
                            ..scale(val, val, 1.0);
                          _transformController.value = newMatrix;
                        },
                      ),
                    ),
                  ),
                  const Icon(PhosphorIcons.magnifyingGlassPlus, color: Colors.white60, size: 20),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(PhosphorIcons.arrowClockwise, color: Colors.white, size: 22),
                    tooltip: 'Rotate 90°',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      padding: const EdgeInsets.all(10),
                    ),
                    onPressed: _rotate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bottom Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _applyCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.check, size: 20, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Apply & Use Photo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
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

/// Lightweight subtle rule-of-thirds grid lines painter for reframing guidance.
class _GridLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical third lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    // Horizontal third lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
