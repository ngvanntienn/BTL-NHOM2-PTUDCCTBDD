import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSuccess() async {
    try {
      // Dùng URL ổn định hơn hoặc xử lý lỗi nếu trình duyệt chặn tự động phát
      await _player.play(UrlSource('https://cdn.pixabay.com/audio/2022/03/15/audio_27387cc692.mp3'));
    } catch (e) {
      debugPrint('AudioHelper playSuccess error: $e');
    }
  }

  static Future<void> playNotification() async {
    try {
      await _player.play(UrlSource('https://cdn.pixabay.com/audio/2022/03/10/audio_c3507e15d8.mp3'));
    } catch (e) {
      debugPrint('AudioHelper playNotification error: $e');
    }
  }
}
