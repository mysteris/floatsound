import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';

// Test script to verify FFprobeKit metadata extraction
void main() async {
  print('Testing FFprobeKit metadata extraction...\n');
  
  // Test with a sample audio file (you can modify this path)
  final testFile = 'test_audio.flac'; // Change to your test file
  
  if (!File(testFile).existsSync()) {
    print('Test file not found: $testFile');
    print('Please provide a valid audio file path to test.');
    return;
  }
  
  try {
    print('Extracting metadata from: $testFile');
    
    final mediaInfo = await FFprobeKit.getMediaInformation(testFile);
    final information = mediaInfo.getMediaInformation();
    
    if (information != null) {
      print('✓ Successfully extracted media information');
      
      // Basic info
      final duration = information.getDuration();
      final format = information.getFormat();
      final bitrate = information.getBitrate();
      
      print('  Duration: ${duration ?? "unknown"} seconds');
      print('  Format: ${format ?? "unknown"}');
      print('  Bitrate: ${bitrate ?? "unknown"}');
      
      // Extract metadata
      final allProps = information.getAllProperties();
      if (allProps != null) {
        print('\n  Metadata tags:');
        allProps.forEach((key, value) {
          if (key.toString().toLowerCase().contains('title') ||
              key.toString().toLowerCase().contains('artist') ||
              key.toString().toLowerCase().contains('album') ||
              key.toString().toLowerCase().contains('genre')) {
            print('    $key: $value');
          }
        });
      }
      
      // Stream information
      final streams = information.getStreams();
      if (streams.isNotEmpty) {
        print('\n  Streams:');
        for (final stream in streams) {
          print('    Type: ${stream.getType()}, Codec: ${stream.getCodec()}');
        }
      }
      
    } else {
      print('✗ Could not extract media information');
    }
    
  } catch (e) {
    print('✗ Error extracting metadata: $e');
  }
  
  print('\nMetadata extraction test completed!');
}