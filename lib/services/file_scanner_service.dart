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
    '.dsf',  // DSD format
    '.dff',  // DSD format
    '.alac', // Apple Lossless
    '.wv',   // WavPack
    '.tak',  // TAK format
    '.tta',  // True Audio
    '.aac',
    '.mp4',
    '.m4v',
    '.3gp',
    '.3g2',
    '.mj2'
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
  }

  // Extract metadata from audio file using FFmpeg-kit
  Future<Map<String, dynamic>> _extractMetadata(File file) async {
    try {
      final mediaInfo = await FFprobeKit.getMediaInformation(file.path);
      final information = mediaInfo.getMediaInformation();
      
      if (information == null) {
        return _getDefaultMetadata(file);
      }

      // Extract duration
      final durationStr = information.getDuration();
      int duration = 0;
      if (durationStr != null) {
        duration = (double.parse(durationStr) * 1000).round();
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
          final date = tags['date'] ?? tags['DATE'] ?? tags['year'] ?? tags['YEAR'];
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
}