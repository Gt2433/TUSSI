import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

class ImageCropperDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageCropperDialog({super.key, required this.imageBytes});

  @override
  State<ImageCropperDialog> createState() => _ImageCropperDialogState();
}

class _ImageCropperDialogState extends State<ImageCropperDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _cropAndSave() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      // Small delay to ensure render tree is stabilized
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Failed to find render boundary");
      }

      // Capture with 3.0 pixel ratio for high quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("Failed to convert image to bytes");
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      if (mounted) {
        Navigator.of(context).pop(pngBytes);
      }
    } catch (e) {
      debugPrint("Error cropping image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error cropping image: $e"),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              context.tr('crop_photo'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Instructions
            Text(
              context.tr('crop_instructions'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            // Cropper Area
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // RepaintBoundary capturing the square content of InteractiveViewer
                      RepaintBoundary(
                        key: _boundaryKey,
                        child: Container(
                          color: Colors.black,
                          width: 280,
                          height: 280,
                          child: InteractiveViewer(
                            minScale: 1.0,
                            maxScale: 5.0,
                            child: Center(
                              child: Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.cover,
                                width: 280,
                                height: 280,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Cutout Overlay (Visual Guide)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: CircleCutoutPainter(),
                          ),
                        ),
                      ),
                      // Circle Border Highlight
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.accentAmber.withValues(alpha: 0.6),
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppTheme.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('cancel'),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _cropAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: AppTheme.surfaceDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.surfaceDark,
                            ),
                          )
                        : Text(
                            context.tr('save'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CircleCutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.65);

    // Draw outer rect path and subtract inner circle path
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2 - 1, // Slight inset to align with border
        ),
      );

    final path = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
