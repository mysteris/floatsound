import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:just_audio/just_audio.dart';
import '../models/music.dart';

class FileScannerService {
  static final FileScannerService _instance = FileScannerService._internal();
  factory FileScannerService() => _instance;

  FileScannerService._internal();

  // Supported audio formats
  final List<String> _supportedFormats = [
    '.wav', '.flac', '.aiff', '.aif', '.mp3', '.m4a', '.ogg', '.opus',
    '.ape', '.dsf', '.dff' // Added HIFI formats
  ];

  // Scan directory for music files
  Future<List<Music>> scanDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw Exception('Directory does not exist');
    }

    final musicFiles = <Music>[];
    await _scanDirectoryRecursive(directory, musicFiles);

    return musicFiles;
  }

  // Recursively scan directory
  Future<void> _scanDirectoryRecursive(
      Directory directory, List<Music> musicFiles) async {
    final entities = directory.listSync(recursive: false, followLinks: false);

    for (final entity in entities) {
      if (entity is Directory) {
        await _scanDirectoryRecursive(entity, musicFiles);
      } else if (entity is File) {
        final fileExtension = path.extension(entity.path).toLowerCase();
        if (_supportedFormats.contains(fileExtension)) {
          final music = await _createMusicFromFile(entity);
          musicFiles.add(music);
        }
      }
    }
  }

  // Create Music object from file
  Future<Music> _createMusicFromFile(File file) async {
    final fileName = path.basenameWithoutExtension(file.path);
    final directory = file.parent;

    // Extract metadata (simplified for now)
    // In a real app, use audio_metadata package to extract proper metadata
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
  }

  // Extract metadata from audio file
  Future<Map<String, dynamic>> _extractMetadata(File file) async {
    try {
      final audioPlayer = AudioPlayer();
      await audioPlayer.setFilePath(file.path);

      // Get duration from just_audio
      final duration = audioPlayer.duration;

      // For now, just use the filename as title
      // In a real app, you might want to use a different approach
      // to extract more metadata
      final fileName = path.basenameWithoutExtension(file.path);

      await audioPlayer.dispose();

      return {
        'title': fileName,
        'artist': 'Unknown Artist',
        'album': 'Unknown Album',
        'duration': duration?.inSeconds ?? 0,
        'genre': '',
        'year': 0,
      };
    } catch (e) {
      // If metadata extraction fails, return default values
      return {
        'title': path.basenameWithoutExtension(file.path),
        'artist': 'Unknown Artist',
        'album': 'Unknown Album',
        'duration': 0,
        'genre': '',
        'year': 0,
      };
    }
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
}
