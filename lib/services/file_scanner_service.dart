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

    // Quick directory existence check
    if (!await directory.exists()) {
      throw Exception('Directory does not exist: $directoryPath');
    }

    final musicFiles = <Music>[];

    try {
      await _scanDirectoryOptimized(directory, musicFiles,
          onProgress: onProgress);
    } catch (e) {
      // Fallback: try a simpler approach
      try {
        await _scanDirectorySimple(directory, musicFiles,
            onProgress: onProgress);
      } catch (fallbackError) {
        rethrow;
      }
    }

    return musicFiles;
  }

  // Optimized directory scanning with batch processing
  Future<void> _scanDirectoryOptimized(
      Directory directory, List<Music> musicFiles,
      {Function(int current, int total)? onProgress}) async {
    try {
      // Phase 1: Collect all audio files quickly
      final audioFiles = <File>[];
      await _collectAudioFiles(directory, audioFiles);

      if (audioFiles.isEmpty) {
        return;
      }

      // Phase 2: Process files with optimized metadata extraction
      await _processAudioFiles(audioFiles, musicFiles, onProgress);
    } catch (e) {
      rethrow;
    }
  }

  // Fast collection of audio files
  Future<void> _collectAudioFiles(
      Directory directory, List<File> audioFiles) async {
    try {
      await for (final entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final fileExtension = path.extension(entity.path).toLowerCase();

          if (_supportedFormats.contains(fileExtension)) {
            audioFiles.add(entity);
          }
        }
      }
    } catch (e) {
      // Fallback to sync method if async fails
      try {
        final entities =
            directory.listSync(recursive: true, followLinks: false);

        for (final entity in entities) {
          if (entity is File) {
            final fileExtension = path.extension(entity.path).toLowerCase();

            if (_supportedFormats.contains(fileExtension)) {
              audioFiles.add(entity);
            }
          }
        }
      } catch (syncError) {
        throw Exception('Failed to collect audio files: $syncError');
      }
    }
  }

  // Process audio files with concurrency
  Future<void> _processAudioFiles(List<File> audioFiles, List<Music> musicFiles,
      Function(int current, int total)? onProgress) async {
    final totalFiles = audioFiles.length;
    int processedFiles = 0;

    // Process files in batches of 5 for optimal concurrency
    const batchSize = 5;

    for (int i = 0; i < audioFiles.length; i += batchSize) {
      final end = (i + batchSize < audioFiles.length)
          ? i + batchSize
          : audioFiles.length;
      final batch = audioFiles.sublist(i, end);

      // Process batch concurrently
      final batchResults = await Future.wait(
        batch.map((file) => _createMusicFromFile(file)),
      );

      // Add results to main list
      musicFiles.addAll(batchResults);
      processedFiles += batch.length;

      // Update progress every 50 files to reduce UI updates
      if (processedFiles % 50 == 0 || processedFiles == totalFiles) {
        onProgress?.call(processedFiles, totalFiles);
      }
    }
  }

  // Simple fallback scanning method
  Future<void> _scanDirectorySimple(Directory directory, List<Music> musicFiles,
      {Function(int current, int total)? onProgress}) async {
    try {
      // Use the same optimized approach as main method
      await _scanDirectoryOptimized(directory, musicFiles,
          onProgress: onProgress);
    } catch (e) {
      rethrow;
    }
  }

  // Create Music object from file with optimized metadata extraction
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

  // Extract metadata from audio file using FFmpeg-kit with timeout
  Future<Map<String, dynamic>> _extractMetadata(File file) async {
    try {
      // Add timeout to prevent hanging on corrupted files
      final mediaInfo = await FFprobeKit.getMediaInformation(file.path)
          .timeout(const Duration(seconds: 5));
      final information = mediaInfo.getMediaInformation();

      if (information == null) {
        return _getDefaultMetadata(file);
      }

      // Extract duration
      final durationStr = information.getDuration();
      int duration = 0;
      if (durationStr != null) {
        try {
          duration = (double.parse(durationStr) * 1000).round();
        } catch (e) {
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

    return result;
  }
}
