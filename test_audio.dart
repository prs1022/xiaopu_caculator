import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(AudioTestApp());
}

class AudioTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: AudioTestScreen());
  }
}

class AudioTestScreen extends StatefulWidget {
  @override
  _AudioTestScreenState createState() => _AudioTestScreenState();
}

class _AudioTestScreenState extends State<AudioTestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _testAudio() async {
    try {
      print('开始测试音频播放...');
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
      print('音频播放成功！');
    } catch (e) {
      print('音频播放失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('音频测试')),
      body: Center(
        child: ElevatedButton(
          onPressed: _testAudio,
          child: Text('测试播放beep.mp3'),
        ),
      ),
    );
  }
}
