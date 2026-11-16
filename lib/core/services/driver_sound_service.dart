import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sound and haptic feedback service for driver interactions.
/// Plays pure, crisp audio effects through the device speaker.
class DriverSoundService {
  DriverSoundService._();

  static AudioPlayer? _player;
  static AudioPlayer? _alertPlayer;
  static Timer? _vibrationTimer;
  static bool _isRinging = false;

  static bool get isRinging => _isRinging;

  static AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setPlayerMode(PlayerMode.lowLatency);
    return _player!;
  }

  static AudioPlayer get _ringingPlayer {
    _alertPlayer ??= AudioPlayer()
      ..setReleaseMode(ReleaseMode.loop)
      ..setPlayerMode(PlayerMode.lowLatency);
    return _alertPlayer!;
  }

  /// Starts the loud, repeating dispatch alert ringing sound + rhythmic haptic vibration
  /// when a new tow order is offered to the driver.
  static Future<void> startAlertRingtone() async {
    if (_isRinging) return;
    _isRinging = true;

    try {
      await _ringingPlayer.setReleaseMode(ReleaseMode.loop);
      await _ringingPlayer.setVolume(1.0);
      await _ringingPlayer.play(AssetSource('sounds/alert_ring.wav'));
    } catch (e) {
      debugPrint('[DriverSoundService] Alert audio play error: $e');
    }

    // Start rhythmic haptic vibration loop
    _vibrationTimer?.cancel();
    _triggerHapticPulse();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!_isRinging) {
        _vibrationTimer?.cancel();
        return;
      }
      _triggerHapticPulse();
    });
  }

  static void _triggerHapticPulse() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Immediately silences the alert ringing sound and stops haptic vibration.
  static Future<void> stopAlertRingtone() async {
    if (!_isRinging && _alertPlayer == null) return;
    _isRinging = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      await _alertPlayer?.stop();
    } catch (_) {}
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
    await stopAlertRingtone();
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
    await stopAlertRingtone();
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/pass.wav'), volume: 0.9);
    } catch (_) {}
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
