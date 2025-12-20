import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';

// Test script to verify audio format support
void main() async {
  print('Testing audio format support with flutter_sound + ffmpeg-kit...\n');
  
  // Test supported formats
  final testFormats = [
    'test.flac',
    'test.ape', 
    'test.dsf',
    'test.alac',
    'test.wav',
    'test.mp3'
  ];
  
  for (final format in testFormats) {
    print('Testing format: $format');
    
    try {
      // Test with FFprobe first
      final mediaInfo = await FFprobeKit.getMediaInformation(format);
      final information = mediaInfo.getMediaInformation();
      
      if (information != null) {
        final duration = information.getDuration();
        final formatName = information.getFormat();
        print('  ✓ FFprobe: Duration: ${duration ?? "unknown"}s, Format: ${formatName ?? "unknown"}');
      } else {
        print('  ✗ FFprobe: Could not read file');
      }
      
      // Test with Flutter Sound
      final player = FlutterSoundPlayer();
      await player.openPlayer();
      
      if (File(format).existsSync()) {
        print('  ✓ File exists');
        // Note: We can't actually test playback without running the app
        print('  → Ready for playback test in app');
      } else {
        print('  ✗ File not found');
      }
      
      await player.closePlayer();
      
    } catch (e) {
      print('  ✗ Error: $e');
    }
    
    print('');
  }
  
  print('Format support test completed!');
}