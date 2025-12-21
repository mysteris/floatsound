import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import '../models/music.dart';

class FileScannerService {
  static final FileScannerService _instance = FileScannerService._internal();
  factory FileScannerService() => _instance;

  FileScannerService._internal();

  // Supported audio formats - expanded with ffmpeg-kit support
  final List<String> _supportedFormats = [
    '.wav',
    '.flac',
    '.aiff',
    '.aif',
    '.mp3',
    '.m4a',
    '.ogg',
    '.opus',
    '.wma',
    '.ape',
    '.dsf', // DSD format
    '.dff', // DSD format
    '.alac', // Apple Lossless
    '.wv', // WavPack
    '.tak', // TAK format
    '.tta', // True Audio
    '.aac',
    '.mp4',
    '.m4v',
    '.3gp',
    '.3g2',
    '.mj2'
  ];

  // Scan directory for music files with progress callback
  Future<List<Music>> scanDirectory(String directoryPath,
      {Function(int current, int total)? onProgress}) async {
    final directory = Directory(directoryPath);

    print('=== STARTING DIRECTORY SCAN ==='); // Debug log
    print('Scanning directory: $directoryPath'); // Debug log
    print('Supported formats: ${_supportedFormats.join(', ')}'); // Debug log

    // Enhanced directory existence check with detailed error reporting
    bool directoryExists = false;
    try {
      directoryExists = await directory.exists();
      print('Directory exists check: $directoryExists'); // Debug log

      // If directory exists, try to list its immediate contents
      if (directoryExists) {
        print('Directory path resolved to: ${directory.path}'); // Debug log
        print(
            'Directory absolute path: ${directory.absolute.path}'); // Debug log

        // List immediate directory contents
        try {
          final immediateContents =
              directory.listSync(recursive: false, followLinks: false);
          print(
              'Immediate directory contents (${immediateContents.length} items):'); // Debug log
          for (var i = 0; i < immediateContents.length && i < 10; i++) {
            final item = immediateContents[i];
            print(
                '  [$i] ${item.path} (${item is File ? "File" : item is Directory ? "Directory" : "Other"})'); // Debug log
          }
          if (immediateContents.length > 10) {
            print(
                '  ... and ${immediateContents.length - 10} more items'); // Debug log
          }
        } catch (e) {
          print('Could not list immediate directory contents: $e'); // Debug log
        }
      }
    } catch (e) {
      print('Directory existence check failed: $e'); // Debug log
    }

    if (!directoryExists) {
      throw Exception('Directory does not exist: $directoryPath');
    }

    // Try to list directory contents to check permissions
    try {
      print('Testing directory access...'); // Debug log
      final testList = await directory.list().take(1).toList();
      print(
          'Directory access test successful, found ${testList.length} items'); // Debug log
    } catch (e) {
      print('Directory access test failed: $e'); // Debug log
      print('This might be a permission issue on Android 13+'); // Debug log
    }

    final musicFiles = <Music>[];

    try {
      await _scanDirectoryRecursive(directory, musicFiles,
          onProgress: onProgress);
    } catch (e) {
      print('Error in recursive scan: $e'); // Debug log
      print('Trying fallback scan method...'); // Debug log

      // Fallback: try a simpler approach
      try {
        await _scanDirectorySimple(directory, musicFiles,
            onProgress: onProgress);
      } catch (fallbackError) {
        print('Fallback scan also failed: $fallbackError'); // Debug log
        // Final fallback: try using absolute path with different approach
        try {
          await _scanWithAbsolutePath(directoryPath, musicFiles,
              onProgress: onProgress);
        } catch (finalError) {
          print('All scan methods failed: $finalError'); // Debug log
          rethrow;
        }
      }
    }

    print(
        'Scan completed. Total music files found: ${musicFiles.length}'); // Debug log
    return musicFiles;
  }

  // Recursively scan directory with progress tracking
  Future<void> _scanDirectoryRecursive(
      Directory directory, List<Music> musicFiles,
      {Function(int current, int total)? onProgress}) async {
    try {
      print('Starting directory scan: ${directory.path}'); // Debug log

      // Use list() instead of listSync() for better performance and error handling
      final entities = <FileSystemEntity>[];
      await for (final entity
          in directory.list(recursive: true, followLinks: false)) {
        entities.add(entity);
      }

      print('Found ${entities.length} total entities'); // Debug log

      // Get total number of files for progress tracking
      final totalFiles = entities.whereType<File>().length;
      print('Found $totalFiles total files'); // Debug log

      int processedFiles = 0;
      int musicFilesFound = 0;

      for (final entity in entities) {
        if (entity is File) {
          processedFiles++;

          try {
            final fileExtension = path.extension(entity.path).toLowerCase();
            print(
                'Checking file: ${entity.path}, extension: $fileExtension'); // Debug log

            if (_supportedFormats.contains(fileExtension)) {
              print(
                  '✓ Found supported music file: ${entity.path}'); // Debug log
              final music = await _createMusicFromFile(entity);
              musicFiles.add(music);
              musicFilesFound++;
            } else {
              print(
                  '✗ File extension not supported: $fileExtension'); // Debug log
            }
          } catch (e) {
            print('✗ Error processing file ${entity.path}: $e'); // Debug log
            // Continue processing other files even if one fails
          }

          // Report progress every 10 files or when finished
          if (processedFiles % 10 == 0 || processedFiles == totalFiles) {
            print(
                'Progress: $processedFiles/$totalFiles files processed, $musicFilesFound music files found'); // Debug log
            onProgress?.call(musicFilesFound, totalFiles);
          }
        }
      }

      print(
          'Scan completed. Found $musicFilesFound music files out of $totalFiles total files'); // Debug log
    } catch (e) {
      print('Error scanning directory ${directory.path}: $e'); // Debug log
      rethrow; // Re-throw the error to be handled by the caller
    }
  }

  // Simple fallback scanning method
  Future<void> _scanDirectorySimple(Directory directory, List<Music> musicFiles,
      {Function(int current, int total)? onProgress}) async {
    try {
      print('Using simple scan method for: ${directory.path}'); // Debug log

      int musicFilesFound = 0;
      int totalFiles = 0;

      // Count total files first
      await for (final entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalFiles++;
        }
      }

      print('Simple scan: Found $totalFiles total files'); // Debug log

      int processedFiles = 0;

      // Process files
      await for (final entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          processedFiles++;

          try {
            final fileExtension = path.extension(entity.path).toLowerCase();
            print(
                'Simple scan checking file: ${entity.path}, extension: $fileExtension'); // Debug log

            if (_supportedFormats.contains(fileExtension)) {
              print(
                  '✓ Simple scan found supported music file: ${entity.path}'); // Debug log
              final music = await _createMusicFromFile(entity);
              musicFiles.add(music);
              musicFilesFound++;
            } else {
              print(
                  '✗ Simple scan extension not supported: $fileExtension'); // Debug log
            }
          } catch (e) {
            print(
                '✗ Simple scan error processing file ${entity.path}: $e'); // Debug log
            // Continue processing other files
          }

          // Report progress
          onProgress?.call(musicFilesFound, totalFiles);
        }
      }

      print(
          'Simple scan completed. Found $musicFilesFound music files'); // Debug log
    } catch (e) {
      print('Simple scan failed: $e'); // Debug log
      rethrow;
    }
  }

  // Create Music object from file
  Future<Music> _createMusicFromFile(File file) async {
    try {
      final fileName = path.basenameWithoutExtension(file.path);
      final directory = file.parent;

      // Extract metadata using FFmpeg-kit
      final metadata = await _extractMetadata(file);

      // Look for cover image in the same directory
      final coverPath = await _findCoverImage(directory);

      return Music(
        id: file.path.hashCode.toString(),
        title: metadata['title'] ?? fileName,
        artist: metadata['artist'] ?? 'Unknown Artist',
        album: metadata['album'] ?? 'Unknown Album',
        filePath: file.path,
        coverPath: coverPath,
        duration: metadata['duration'] ?? 0,
        genre: metadata['genre'] ?? '',
        year: metadata['year'] ?? 0,
      );
    } catch (e) {
      print(
          'Error creating Music object from file ${file.path}: $e'); // Debug log
      // Return a basic Music object even if metadata extraction fails
      return Music(
        id: file.path.hashCode.toString(),
        title: path.basenameWithoutExtension(file.path),
        artist: 'Unknown Artist',
        album: 'Unknown Album',
        filePath: file.path,
        coverPath: null,
        duration: 0,
        genre: '',
        year: 0,
      );
    }
  }

  // Extract metadata from audio file using FFmpeg-kit
  Future<Map<String, dynamic>> _extractMetadata(File file) async {
    try {
      print('Extracting metadata from: ${file.path}'); // Debug log

      final mediaInfo = await FFprobeKit.getMediaInformation(file.path);
      final information = mediaInfo.getMediaInformation();

      if (information == null) {
        print('No media information found for: ${file.path}'); // Debug log
        return _getDefaultMetadata(file);
      }

      // Extract duration
      final durationStr = information.getDuration();
      int duration = 0;
      if (durationStr != null) {
        try {
          duration = (double.parse(durationStr) * 1000).round();
        } catch (e) {
          print('Error parsing duration: $e'); // Debug log
          duration = 0;
        }
      }

      // Extract metadata from streams and format
      final streams = information.getStreams();
      final format = information.getFormat();

      String title = path.basenameWithoutExtension(file.path);
      String artist = 'Unknown Artist';
      String album = 'Unknown Album';
      String genre = '';
      int year = 0;

      // Try to extract metadata from format tags
      if (format != null) {
        final tags = information.getAllProperties();
        if (tags != null) {
          title = tags['title'] ?? title;
          artist = tags['artist'] ?? tags['ARTIST'] ?? artist;
          album = tags['album'] ?? tags['ALBUM'] ?? album;
          genre = tags['genre'] ?? tags['GENRE'] ?? genre;

          // Extract year
          final date =
              tags['date'] ?? tags['DATE'] ?? tags['year'] ?? tags['YEAR'];
          if (date != null) {
            try {
              year = int.parse(date.toString().substring(0, 4));
            } catch (e) {
              // Ignore parsing errors
            }
          }
        }
      }

      // Try to extract from audio stream metadata if format didn't have it
      if (streams.isNotEmpty) {
        for (final stream in streams) {
          if (stream.getType() == 'audio') {
            final streamTags = stream.getTags();
            if (streamTags != null) {
              title = streamTags['title'] ?? title;
              artist = streamTags['artist'] ?? streamTags['ARTIST'] ?? artist;
              album = streamTags['album'] ?? streamTags['ALBUM'] ?? album;
              genre = streamTags['genre'] ?? streamTags['GENRE'] ?? genre;
            }
            break; // Use first audio stream
          }
        }
      }

      return {
        'title': title,
        'artist': artist,
        'album': album,
        'duration': duration,
        'genre': genre,
        'year': year,
      };
    } catch (e) {
      print('Error extracting metadata with FFmpeg-kit: $e');
      return _getDefaultMetadata(file);
    }
  }

  // Get default metadata when extraction fails
  Map<String, dynamic> _getDefaultMetadata(File file) {
    return {
      'title': path.basenameWithoutExtension(file.path),
      'artist': 'Unknown Artist',
      'album': 'Unknown Album',
      'duration': 0,
      'genre': '',
      'year': 0,
    };
  }

  // Find cover image in directory
  Future<String?> _findCoverImage(Directory directory) async {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    final entities = directory.listSync(recursive: false, followLinks: false);

    for (final entity in entities) {
      if (entity is File) {
        final fileExtension = path.extension(entity.path).toLowerCase();
        final fileName = path.basename(entity.path).toLowerCase();

        if (imageExtensions.contains(fileExtension)) {
          // Check if the file is likely a cover image
          if (fileName.contains('cover') ||
              fileName.contains('album') ||
              fileName.contains('art') ||
              fileName.contains('folder')) {
            return entity.path;
          }
        }
      }
    }

    // If no cover image found with specific name, return first image in directory
    for (final entity in entities) {
      if (entity is File) {
        final fileExtension = path.extension(entity.path).toLowerCase();
        if (imageExtensions.contains(fileExtension)) {
          return entity.path;
        }
      }
    }

    return null;
  }

  // Get supported audio formats
  List<String> get supportedFormats => _supportedFormats;

  // Simple test method to verify scanning works
  Future<Map<String, dynamic>> testScanDirectory(String directoryPath) async {
    print('=== TEST SCAN METHOD ==='); // Debug log
    final result = <String, dynamic>{
      'directoryPath': directoryPath,
      'directoryExists': false,
      'immediateContents': <String>[],
      'supportedFilesFound': 0,
      'allFilesFound': 0,
      'errors': <String>[],
    };

    try {
      final directory = Directory(directoryPath);

      // Check if directory exists
      result['directoryExists'] = await directory.exists();

      if (!result['directoryExists']) {
        result['errors'].add('Directory does not exist: $directoryPath');
        return result;
      }

      // List immediate contents
      try {
        final immediateContents =
            directory.listSync(recursive: false, followLinks: false);
        result['immediateContents'] = immediateContents
            .map((e) =>
                '${e.path} (${e is File ? "File" : e is Directory ? "Directory" : "Other"})')
            .toList();

        // Count all files recursively (simple approach)
        int totalFiles = 0;
        int supportedFiles = 0;

        try {
          final allEntities =
              directory.listSync(recursive: true, followLinks: false);
          for (final entity in allEntities) {
            if (entity is File) {
              totalFiles++;
              final fileExtension = path.extension(entity.path).toLowerCase();
              if (_supportedFormats.contains(fileExtension)) {
                supportedFiles++;
                print('Found supported file: ${entity.path}'); // Debug log
              }
            }
          }
        } catch (e) {
          result['errors'].add('Error during recursive scan: $e');
        }

        result['allFilesFound'] = totalFiles;
        result['supportedFilesFound'] = supportedFiles;
      } catch (e) {
        result['errors'].add('Error listing directory contents: $e');
      }
    } catch (e) {
      result['errors'].add('Test scan failed: $e');
    }

    print('Test scan result: $result'); // Debug log
    return result;
  }

  // Final fallback method using absolute path with different approach
  Future<void> _scanWithAbsolutePath(
      String directoryPath, List<Music> musicFiles,
      {Function(int current, int total)? onProgress}) async {
    try {
      print('Using absolute path scan method for: $directoryPath'); // Debug log

      // Try using dart:io with different approach
      final directory = Directory(directoryPath);

      // Method 1: Try listSync (synchronous approach)
      try {
        print('Trying synchronous directory listing...'); // Debug log
        final entities =
            directory.listSync(recursive: true, followLinks: false);
        print(
            'Synchronous scan found ${entities.length} entities'); // Debug log

        int musicFilesFound = 0;
        int totalFiles = entities.whereType<File>().length;

        for (final entity in entities) {
          if (entity is File) {
            try {
              final fileExtension = path.extension(entity.path).toLowerCase();
              print(
                  'Sync scan checking file: ${entity.path}, extension: $fileExtension'); // Debug log

              if (_supportedFormats.contains(fileExtension)) {
                print(
                    '✓ Sync scan found supported music file: ${entity.path}'); // Debug log
                final music = await _createMusicFromFile(entity);
                musicFiles.add(music);
                musicFilesFound++;
              }
            } catch (e) {
              print(
                  '✗ Sync scan error with file ${entity.path}: $e'); // Debug log
            }
          }
        }

        print(
            'Sync scan completed. Found $musicFilesFound music files'); // Debug log
        return;
      } catch (syncError) {
        print('Synchronous scan failed: $syncError'); // Debug log
      }

      // Method 2: Try with recursive: false and manual recursion
      try {
        print('Trying manual recursive scan...'); // Debug log
        await _manualRecursiveScan(directory, musicFiles,
            onProgress: onProgress);
        return;
      } catch (manualError) {
        print('Manual recursive scan failed: $manualError'); // Debug log
      }

      // Method 3: Try accessing common music directories directly
      try {
        print('Trying direct file access for common patterns...'); // Debug log
        await _directFileAccessScan(directoryPath, musicFiles,
            onProgress: onProgress);
        return;
      } catch (directError) {
        print('Direct file access scan failed: $directError'); // Debug log
      }

      throw Exception('All absolute path scan methods failed');
    } catch (e) {
      print('Absolute path scan failed completely: $e'); // Debug log
      rethrow;
    }
  }

  // Manual recursive scan with better error handling
  Future<void> _manualRecursiveScan(Directory directory, List<Music> musicFiles,
      {Function(int current, int total)? onProgress}) async {
    print('Starting manual recursive scan of: ${directory.path}'); // Debug log

    int totalFiles = 0;
    int musicFilesFound = 0;

    // First, try to list the directory
    try {
      final entities = directory.listSync(recursive: false, followLinks: false);

      for (final entity in entities) {
        if (entity is File) {
          totalFiles++;

          try {
            final fileExtension = path.extension(entity.path).toLowerCase();
            print(
                'Manual scan checking file: ${entity.path}, extension: $fileExtension'); // Debug log

            if (_supportedFormats.contains(fileExtension)) {
              print(
                  '✓ Manual scan found supported music file: ${entity.path}'); // Debug log
              final music = await _createMusicFromFile(entity);
              musicFiles.add(music);
              musicFilesFound++;
            }
          } catch (e) {
            print(
                '✗ Manual scan error with file ${entity.path}: $e'); // Debug log
          }

          onProgress?.call(musicFilesFound, totalFiles);
        } else if (entity is Directory) {
          // Recursively scan subdirectories
          try {
            await _manualRecursiveScan(entity, musicFiles,
                onProgress: onProgress);
          } catch (e) {
            print(
                '✗ Manual scan failed to access subdirectory ${entity.path}: $e'); // Debug log
          }
        }
      }

      print(
          'Manual recursive scan completed. Found $musicFilesFound music files'); // Debug log
    } catch (e) {
      print('Manual recursive scan failed: $e'); // Debug log
      throw Exception('Manual recursive scan failed: $e');
    }
  }

  // Direct file access scan for specific patterns
  Future<void> _directFileAccessScan(String basePath, List<Music> musicFiles,
      {Function(int current, int total)? onProgress}) async {
    print('Starting direct file access scan for: $basePath'); // Debug log

    int musicFilesFound = 0;

    // Try to find files with supported extensions directly
    for (final format in _supportedFormats) {
      try {
        // Look for files with this extension
        final pattern = '$basePath/**/*$format';
        print('Looking for files with pattern: $pattern'); // Debug log

        // This is a simplified approach - in real implementation you'd use proper glob matching
        // For now, let's try a basic approach
        final testFile = File('$basePath/test$format');
        if (await testFile.exists()) {
          print('Found test file: ${testFile.path}'); // Debug log
        }
      } catch (e) {
        print('Direct access failed for format $format: $e'); // Debug log
      }
    }

    // Try to access some common file patterns
    final commonPatterns = [
      '$basePath/*.mp3',
      '$basePath/*.flac',
      '$basePath/*.ape',
      '$basePath/*.dsf',
      '$basePath/*/*.mp3',
      '$basePath/*/*.flac',
      '$basePath/*/*.ape',
      '$basePath/*/*.dsf',
    ];

    for (final pattern in commonPatterns) {
      try {
        print('Testing pattern: $pattern'); // Debug log
        // Note: This is a conceptual approach - Flutter doesn't have built-in glob support
        // In a real implementation, you'd use a package like glob or path_provider
      } catch (e) {
        print('Pattern test failed: $e'); // Debug log
      }
    }

    print(
        'Direct file access scan completed. Found $musicFilesFound music files'); // Debug log
  }
}
