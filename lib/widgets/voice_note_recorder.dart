import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../providers/order_provider.dart';
import '../theme/app_theme.dart';

/// Minimalistic, circular voice note recorder.
/// - Tap to record -> turns flashing red.
/// - Tap again to stop and save.
/// - Press and hold to record / release to stop also supported.
/// - Shows preview play/pause and delete icons when recorded.
class VoiceNoteRecorder extends StatefulWidget {
  const VoiceNoteRecorder({super.key});

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  AudioPlayer? _audioPlayer;

  bool _isRecording = false;
  bool _isLongPress = false;
  
  // Playback state
  bool _isPlaying = false;
  StreamSubscription? _compSub;

  // Red mic flash state
  bool _flashRed = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _compSub = _audioPlayer?.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _compSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    try {
      if (await _audioRecorder.hasPermission()) {
        String path = 'temp_voice_note.m4a';

        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          path = '${tempDir.path}/temp_voice_note.m4a';

          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }

        // Select best encoder for the current platform
        AudioEncoder encoder = AudioEncoder.aacLc;
        if (kIsWeb) {
          if (await _audioRecorder.isEncoderSupported(AudioEncoder.opus)) {
            encoder = AudioEncoder.opus;
          } else if (await _audioRecorder.isEncoderSupported(AudioEncoder.wav)) {
            encoder = AudioEncoder.wav;
          }
        }

        await _audioRecorder.start(
          RecordConfig(
            encoder: encoder,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 16000,
          ),
          path: path,
        );

        _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
          if (mounted) setState(() => _flashRed = !_flashRed);
        });

        setState(() {
          _isRecording = true;
          _flashRed = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('مطلوب إذن الوصول للميكروفون لتسجيل الصوت. يرجى تفعيله من إعدادات الهاتف/المتصفح.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Start recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء بدء التسجيل: $e'),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _flashTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        Uint8List bytes;
        if (kIsWeb) {
          final response = await http.get(Uri.parse(path));
          bytes = response.bodyBytes;
        } else {
          final file = File(path);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
          } else {
            return;
          }
        }
        final base64String = base64Encode(bytes);
        if (mounted) {
          Provider.of<OrderProvider>(context, listen: false)
              .setVoiceNoteBase64(base64String);
        }
      }
    } catch (e) {
      print('Stop recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء إيقاف التسجيل: $e'),
          ),
        );
      }
    }
  }

  Future<void> _playPause(String base64String) async {
    if (_isPlaying) {
      await _audioPlayer?.pause();
      setState(() => _isPlaying = false);
    } else {
      try {
        final bytes = base64Decode(base64String);
        await _audioPlayer?.stop();
        await _audioPlayer?.play(BytesSource(Uint8List.fromList(bytes)));
        setState(() => _isPlaying = true);
      } catch (e) {
        print('Playback error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final hasVoiceNote = provider.draftVoiceNoteBase64 != null;

    // ─── Recording State ───────────────────────────────
    if (_isRecording) {
      return GestureDetector(
        onTap: _stopRecording,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _flashRed ? AppTheme.error : AppTheme.error.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.error.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      );
    }

    // ─── Review State (Has Voice Note) ─────────────────
    if (hasVoiceNote) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: () => _playPause(provider.draftVoiceNoteBase64!),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.4)),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppTheme.accentAmber,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Delete Button
          GestureDetector(
            onTap: () {
              _audioPlayer?.stop();
              provider.setVoiceNoteBase64(null);
              setState(() => _isPlaying = false);
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.errorSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.error,
                size: 24,
              ),
            ),
          ),
        ],
      );
    }

    // ─── Default / Record State ───────────────────────
    return GestureDetector(
      onTap: () {
        if (_isRecording) {
          _stopRecording();
        } else {
          _startRecording();
        }
      },
      onLongPressStart: (_) {
        _isLongPress = true;
        _startRecording();
      },
      onLongPressEnd: (_) {
        if (_isLongPress) {
          _isLongPress = false;
          _stopRecording();
        }
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentAmber.withValues(alpha: 0.05),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          Icons.mic_none_rounded,
          color: AppTheme.accentAmber,
          size: 26,
        ),
      ),
    );
  }
}
