import 'package:audioplayers/audioplayers.dart';

/// Service to handle simple sound effects in the application.
/// Uses the audioplayers package to load and play local assets.
class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  /// Play send sound when dispatching an order
  static Future<void> playSend() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('send.mp3'));
    } catch (e) {
      print('AudioService playSend Error: $e');
    }
  }

  /// Play receive sound when a new order arrives
  static Future<void> playReceive() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('receive.wav'));
    } catch (e) {
      print('AudioService playReceive Error: $e');
    }
  }
}
