import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Sound and haptic feedback service for driver interactions.
/// Plays pure, crisp audio effects through the device speaker.
class DriverSoundService {
  DriverSoundService._();

  static AudioPlayer? _player;

  static AudioPlayer get _audioPlayer {
    if (_player == null) {
      _player = AudioPlayer()
        ..setReleaseMode(ReleaseMode.stop)
        ..setPlayerMode(PlayerMode.lowLatency);
    }
    return _player!;
  }

  /// Plays crisp swipe sound once when a card is swiped away.
  static Future<void> playSwipeSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/swipe.wav'), volume: 0.9);
    } catch (_) {}
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Plays positive accept chime when accepting a dispatch.
  static Future<void> playAcceptSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/accept.wav'), volume: 1.0);
    } catch (_) {}
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Plays soft whoosh sound when passing a request.
  static Future<void> playPassSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/pass.wav'), volume: 0.9);
    } catch (_) {}
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
