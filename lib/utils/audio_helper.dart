import 'package:audioplayers/audioplayers.dart';

class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSuccess() async {
    try {
      // You can use a URL for testing if you don't have local assets yet
      await _player.play(UrlSource('https://www.soundjay.com/buttons/sounds/button-3.mp3'));
    } catch (e) {
      print('Audio error: $e');
    }
  }

  static Future<void> playNotification() async {
    try {
      await _player.play(UrlSource('https://www.soundjay.com/buttons/sounds/button-09.mp3'));
    } catch (e) {
      print('Audio error: $e');
    }
  }
}
