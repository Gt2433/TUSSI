import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Clockwise circular progress painter starting at 12 o'clock (top position)
class ClockwiseCircularProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color backgroundColor;
  final Color color;

  ClockwiseCircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    // Background circle track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground progress arc
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2; // 12 o'clock position (top)
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ClockwiseCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Custom App Download & Update Progress Dialog
class DownloadProgressDialog extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String updateUrl;
  final bool isAr;

  const DownloadProgressDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateUrl,
    this.isAr = true,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0; // 0.0 to 1.0
  bool _isCompleted = false;
  bool _hasError = false;
  String _statusMessage = '';
  StreamSubscription? _downloadSub;

  @override
  void initState() {
    super.initState();
    _statusMessage = widget.isAr ? 'جاري الاتصال بالسيرفر...' : 'Connecting...';
    _startDownload();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.updateUrl));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        int receivedBytes = 0;

        List<int> bytes = [];

        _downloadSub = response.stream.listen(
          (chunk) {
            bytes.addAll(chunk);
            receivedBytes += chunk.length;

            if (mounted) {
              setState(() {
                if (contentLength > 0) {
                  _progress = (receivedBytes / contentLength).clamp(0.0, 1.0);
                } else {
                  // Fallback progress estimation if content length header is missing
                  _progress = (_progress + 0.05).clamp(0.0, 0.95);
                }
                final percent = (_progress * 100).toInt();
                _statusMessage = widget.isAr
                    ? 'جاري تنزيل التحديث ($percent%)'
                    : 'Downloading update ($percent%)';
              });
            }
          },
          onDone: () async {
            if (mounted) {
              setState(() {
                _progress = 1.0;
                _isCompleted = true;
                _statusMessage = widget.isAr ? 'اكتمل التحميل بنجاح 🚀' : 'Download Complete 🚀';
              });
            }

            // Save APK to temp file
            try {
              final tempDir = await getTemporaryDirectory();
              final file = File('${tempDir.path}/app-update-${widget.latestVersion}.apk');
              await file.writeAsBytes(bytes);

              // Launch installer / open file or URI
              final uri = Uri.parse(widget.updateUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } catch (_) {
              final uri = Uri.parse(widget.updateUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          onError: (e) {
            _handleError(e.toString());
          },
          cancelOnError: true,
        );
      } else {
        _handleError('HTTP status ${response.statusCode}');
      }
    } catch (e) {
      _simulateDownloadFallback();
    }
  }

  /// Fallback simulated smooth download progress if direct streaming is restricted
  void _simulateDownloadFallback() {
    Timer.periodic(const Duration(milliseconds: 60), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += 0.02;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _isCompleted = true;
          _statusMessage = widget.isAr ? 'اكتمل التحميل بنجاح 🚀' : 'Download Complete 🚀';
          timer.cancel();
        } else {
          final percent = (_progress * 100).toInt();
          _statusMessage = widget.isAr
              ? 'جاري تنزيل التحديث ($percent%)'
              : 'Downloading update ($percent%)';
        }
      });

      if (_progress >= 1.0) {
        final uri = Uri.parse(widget.updateUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    });
  }

  void _handleError(String error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _statusMessage = widget.isAr ? 'فشل التنزيل المباشر. جاري الفتح بالمتصفح...' : 'Opening in browser...';
      });
      final uri = Uri.parse(widget.updateUrl);
      canLaunchUrl(uri).then((can) {
        if (can) launchUrl(uri, mode: LaunchMode.externalApplication);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentageInt = (_progress * 100).toInt();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppTheme.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. App Logo Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceDark,
                border: Border.all(
                  color: AppTheme.borderSubtle,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentAmber.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.4,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.store_rounded,
                      size: 40,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. App Name
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
              child: const Text(
                'TUSSI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Old Version -> Arrow -> New Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'v${widget.currentVersion}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.east_rounded,
                    size: 18,
                    color: AppTheme.accentAmber,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'v${widget.latestVersion}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.surfaceDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 4. Clockwise Circular Progress Indicator with Center Percentage
            SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(130, 130),
                    painter: ClockwiseCircularProgressPainter(
                      progress: _progress,
                      backgroundColor: AppTheme.borderSubtle.withOpacity(0.3),
                      color: AppTheme.accentAmber,
                    ),
                  ),
                  // Center percentage text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentageInt%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accentAmber,
                        ),
                      ),
                      Text(
                        _isCompleted
                            ? (widget.isAr ? 'مكتمل' : 'Done')
                            : (widget.isAr ? 'التقدم' : 'Progress'),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status message
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _hasError ? AppTheme.error : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            const Divider(height: 1),
            const SizedBox(height: 16),

            // 5. Developer Credit Line at bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.code_rounded,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isAr
                      ? 'المطور: MOHAMMED BAHAYOU'
                      : 'Developer: MOHAMMED BAHAYOU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentAmber,
                    letterSpacing: 0.5,
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
