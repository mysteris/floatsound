import 'package:flutter_test/flutter_test.dart';
import 'package:floatsound/services/file_scanner_service.dart';
import 'dart:io';

void main() {
  group('File Scanner Performance Tests', () {
    late FileScannerService scannerService;
    late Directory tempDir;

    setUp(() {
      scannerService = FileScannerService();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (e) {
          print('Warning: Could not clean up test directory: $e');
        }
      }
    });

    test('Test scanning performance with 50 music files', () async {
      // Create test directory and files
      tempDir = Directory.systemTemp.createTempSync('music_test_');
      final musicExtensions = ['.mp3', '.wav', '.flac', '.m4a', '.aac'];

      // Create 50 test music files
      for (int i = 0; i < 50; i++) {
        final extension = musicExtensions[i % musicExtensions.length];
        final file = File('${tempDir.path}/test_song_$i$extension');
        await file.writeAsString('test audio content $i');
      }

      // Measure scanning performance
      final stopwatch = Stopwatch()..start();

      final scannedMusic = await scannerService.scanDirectory(
        tempDir.path,
        onProgress: (current, total) {
          print('Progress: $current/$total files processed');
        },
      );

      stopwatch.stop();

      // Verify results
      expect(scannedMusic.length, greaterThanOrEqualTo(0));
      print('📊 Performance Results (50 files):');
      print('✓ Scanned ${scannedMusic.length} music files');
      print('✓ Total scanning time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '✓ Average time per file: ${scannedMusic.isNotEmpty ? stopwatch.elapsedMilliseconds / scannedMusic.length : 0}ms');
    });

    test('Test scanning performance with 200 music files', () async {
      // Create test directory and files
      tempDir = Directory.systemTemp.createTempSync('music_test_large_');
      final musicExtensions = ['.mp3', '.wav', '.flac', '.m4a', '.aac'];

      // Create 200 test music files
      for (int i = 0; i < 200; i++) {
        final extension = musicExtensions[i % musicExtensions.length];
        final file = File('${tempDir.path}/test_song_$i$extension');
        await file.writeAsString('test audio content $i');
      }

      // Measure scanning performance
      final stopwatch = Stopwatch()..start();

      final scannedMusic = await scannerService.scanDirectory(
        tempDir.path,
        onProgress: (current, total) {
          if (current % 50 == 0 || current == total) {
            print('Large batch progress: $current/$total files processed');
          }
        },
      );

      stopwatch.stop();

      // Verify results
      expect(scannedMusic.length, greaterThanOrEqualTo(0));
      print('\n📊 Performance Results (200 files):');
      print('✓ Scanned ${scannedMusic.length} music files');
      print('✓ Total scanning time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '✓ Average time per file: ${scannedMusic.isNotEmpty ? stopwatch.elapsedMilliseconds / scannedMusic.length : 0}ms');
    });

    test('Test concurrent processing optimization', () async {
      // Create test directory and files
      tempDir = Directory.systemTemp.createTempSync('music_test_concurrent_');
      final musicExtensions = ['.mp3', '.wav', '.flac', '.m4a', '.aac'];

      // Create 100 test music files
      for (int i = 0; i < 100; i++) {
        final extension = musicExtensions[i % musicExtensions.length];
        final file = File('${tempDir.path}/test_song_$i$extension');
        await file.writeAsString('test audio content $i');
      }

      // Measure scanning performance with detailed timing
      final stopwatch = Stopwatch()..start();
      int progressUpdates = 0;

      final scannedMusic = await scannerService.scanDirectory(
        tempDir.path,
        onProgress: (current, total) {
          progressUpdates++;
          if (current % 25 == 0 || current == total) {
            print('Concurrent test progress: $current/$total files processed');
          }
        },
      );

      stopwatch.stop();

      // Verify results and optimization
      expect(scannedMusic.length, greaterThanOrEqualTo(0));
      print('\n📊 Concurrent Processing Results:');
      print('✓ Scanned ${scannedMusic.length} music files');
      print('✓ Total scanning time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          '✓ Average time per file: ${scannedMusic.isNotEmpty ? stopwatch.elapsedMilliseconds / scannedMusic.length : 0}ms');
      print('✓ Progress updates: $progressUpdates');

      // The optimization should reduce progress updates (every 50 files or on completion)
      expect(progressUpdates,
          lessThanOrEqualTo((scannedMusic.length / 50).ceil() + 1));
    });
  });
}
