import 'package:audioplayers/audioplayers.dart';

class AlertSoundActiviator {
  AlertSoundActiviator._();

  static final AlertSoundActiviator instance = AlertSoundActiviator._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playEmergencyAlert() async {
    await _player.play(AssetSource('sounds/emergency-alert.mp3'));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
