import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/services/file_scanner_service.dart';

void main() async {
  print('🚀 Starting File Scanner Performance Test...');

  // Initialize Flutter binding if needed
  WidgetsFlutterBinding.ensureInitialized();

  final scannerService = FileScannerService();

  // Test 1: Create a test directory with sample music files
  print('\n=== Test 1: Creating Test Environment ===');

  // Create a temporary test directory
  final tempDir = Directory.systemTemp.createTempSync('music_test_');
  print('Created test directory: ${tempDir.path}');

  try {
    // Create sample music files (we'll create empty files with music extensions)
    final musicExtensions = ['.mp3', '.wav', '.flac', '.m4a', '.aac'];
    final testFiles = <File>[];

    print('Creating test music files...');
    for (int i = 0; i < 50; i++) {
      final extension = musicExtensions[i % musicExtensions.length];
      final file = File('${tempDir.path}/test_song_$i$extension');
      await file.writeAsString('test audio content $i');
      testFiles.add(file);
    }
    print('✓ Created ${testFiles.length} test music files');

    // Test 2: Measure scanning performance
    print('\n=== Test 2: Performance Measurement ===');

    final stopwatch = Stopwatch()..start();
    final scannedMusic = <Music>[];

    print('Starting scan...');
    await scannerService.scanDirectory(
      tempDir,
      scannedMusic,
      onProgress: (current, total) {
        print('Progress: $current/$total files processed');
      },
    );

    stopwatch.stop();

    print('\n📊 Performance Results:');
    print('✓ Scanned ${scannedMusic.length} music files');
    print('✓ Total scanning time: ${stopwatch.elapsedMilliseconds}ms');
    print(
        '✓ Average time per file: ${stopwatch.elapsedMilliseconds / scannedMusic.length}ms');

    // Test 3: Verify metadata extraction
    print('\n=== Test 3: Metadata Verification ===');
    if (scannedMusic.isNotEmpty) {
      final firstMusic = scannedMusic.first;
      print('First music file metadata:');
      print('  Title: ${firstMusic.title}');
      print('  Artist: ${firstMusic.artist}');
      print('  Album: ${firstMusic.album}');
      print('  Duration: ${firstMusic.duration} seconds');
      print('  Path: ${firstMusic.filePath}');
    }

    // Test 4: Test with larger batch
    print('\n=== Test 4: Large Batch Test ===');

    // Create more test files for larger batch testing
    print('Creating additional test files...');
    for (int i = 50; i < 200; i++) {
      final extension = musicExtensions[i % musicExtensions.length];
      final file = File('${tempDir.path}/test_song_$i$extension');
      await file.writeAsString('test audio content $i');
    }
    print('✓ Created additional test files (total: 200)');

    final largeStopwatch = Stopwatch()..start();
    final largeScannedMusic = <Music>[];

    print('Starting large batch scan...');
    await scannerService.scanDirectory(
      tempDir,
      largeScannedMusic,
      onProgress: (current, total) {
        if (current % 50 == 0 || current == total) {
          print('Large batch progress: $current/$total files processed');
        }
      },
    );

    largeStopwatch.stop();

    print('\n📊 Large Batch Performance Results:');
    print('✓ Scanned ${largeScannedMusic.length} music files');
    print('✓ Total scanning time: ${largeStopwatch.elapsedMilliseconds}ms');
    print(
        '✓ Average time per file: ${largeStopwatch.elapsedMilliseconds / largeScannedMusic.length}ms');
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Cleanup
    print('\n=== Cleanup ===');
    try {
      await tempDir.delete(recursive: true);
      print('✓ Cleaned up test directory');
    } catch (e) {
      print('Warning: Could not clean up test directory: $e');
    }
  }

  print('\n✅ Performance test completed!');
}
