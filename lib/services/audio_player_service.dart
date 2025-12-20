import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import '../models/music.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _initializePlayer();
  }

  // Initialize method for compatibility
  Future<void> init() async {
    await _initializePlayer();
  }

  // Flutter Sound player
  FlutterSoundPlayer? _player;
  
  // Player state
  List<Music> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // Timer for position updates
  Timer? _positionTimer;
  
  // ValueNotifier to notify listeners when current music changes
  final ValueNotifier<Music?> _currentMusicNotifier = ValueNotifier<Music?>(null);
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> _durationNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);

  // Getters for notifiers
  ValueNotifier<Music?> get currentMusicNotifier => _currentMusicNotifier;
  ValueNotifier<Duration> get positionNotifier => _positionNotifier;
  ValueNotifier<Duration> get durationNotifier => _durationNotifier;
  ValueNotifier<bool> get isPlayingNotifier => _isPlayingNotifier;

  // Getters for current state
  Music? get currentMusic => _currentMusicNotifier.value;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  List<Music> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;

  // Initialize the player
  Future<void> _initializePlayer() async {
    try {
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();
      print('Flutter Sound player initialized successfully');
    } catch (e) {
      print('Error initializing Flutter Sound player: $e');
    }
  }

  // Play audio file
  Future<void> play() async {
    if (_player == null) {
      await _initializePlayer();
    }

    if (_playlist.isEmpty) return;
    
    final currentMusic = _playlist[_currentIndex];
    final inputPath = currentMusic.filePath;

    try {
      // Stop any current playback
      await stop();

      // Check if file exists
      if (!File(inputPath).existsSync()) {
        print('Audio file not found: $inputPath');
        return;
      }

      // Get media information for duration
      final mediaInfo = await FFprobeKit.getMediaInformation(inputPath);
      final information = mediaInfo.getMediaInformation();
      if (information != null) {
        final durationStr = information.getDuration();
        if (durationStr != null) {
          _totalDuration = Duration(milliseconds: (double.parse(durationStr) * 1000).round());
          _durationNotifier.value = _totalDuration;
        }
      }

      // Start playback with Flutter Sound
      await _player!.startPlayer(
        fromURI: inputPath,
        codec: Codec.defaultCodec,
        whenFinished: () {
          print('Playback completed for: ${currentMusic.title}');
          _isPlaying = false;
          _isPaused = false;
          _isPlayingNotifier.value = false;
          _stopPositionTimer();
          
          // Auto-play next track if available
          if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
            next();
          }
        },
      );

      // Update state
      _isPlaying = true;
      _isPaused = false;
      _isPlayingNotifier.value = true;
      _currentPosition = Duration.zero;
      _positionNotifier.value = _currentPosition;
      
      // Start position timer
      _startPositionTimer();
      
      print('Started playing: ${currentMusic.title}');
      
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying = false;
      _isPaused = false;
      _isPlayingNotifier.value = false;
    }
  }

  // Pause playback
  Future<void> pause() async {
    if (_player == null || !_isPlaying || _isPaused) return;

    try {
      await _player!.pausePlayer();
      _isPaused = true;
      _isPlayingNotifier.value = false;
      _stopPositionTimer();
      print('Paused playback');
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  // Resume playback
  Future<void> resume() async {
    if (_player == null || !_isPlaying || !_isPaused) return;

    try {
      await _player!.resumePlayer();
      _isPaused = false;
      _isPlayingNotifier.value = true;
      _startPositionTimer();
      print('Resumed playback');
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying && !_isPaused) {
      await pause();
    } else if (_isPlaying && _isPaused) {
      await resume();
    } else {
      await play();
    }
  }

  // Stop playback
  Future<void> stop() async {
    if (_player == null) return;

    try {
      if (_player!.isPlaying) {
        await _player!.stopPlayer();
      }
      _isPlaying = false;
      _isPaused = false;
      _isPlayingNotifier.value = false;
      _stopPositionTimer();
      _currentPosition = Duration.zero;
      _positionNotifier.value = _currentPosition;
      print('Stopped playback');
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    if (_player == null || !_isPlaying) return;

    try {
      await _player!.seekToPlayer(position);
      _currentPosition = position;
      _positionNotifier.value = _currentPosition;
      print('Seeked to: $position');
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  // Set playlist and play from index
  Future<void> setPlaylist(List<Music> playlist, {int startIndex = 0}) async {
    _playlist = List.from(playlist);
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    _currentMusicNotifier.value = _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
    
    if (_playlist.isNotEmpty) {
      await play();
    }
  }

  // Play next track
  Future<void> next() async {
    if (_playlist.isEmpty) return;
    
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    _currentMusicNotifier.value = _playlist[_currentIndex];
    await play();
  }

  // Play previous track
  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _currentMusicNotifier.value = _playlist[_currentIndex];
    await play();
  }

  // Add track to playlist
  void addToPlaylist(Music music) {
    _playlist.add(music);
    if (_playlist.length == 1 && !_isPlaying) {
      _currentMusicNotifier.value = music;
      play();
    }
  }

  // Remove track from playlist
  void removeFromPlaylist(Music music) {
    final index = _playlist.indexOf(music);
    if (index != -1) {
      _playlist.removeAt(index);
      if (_currentIndex >= index && _currentIndex > 0) {
        _currentIndex--;
      }
      if (_currentIndex < _playlist.length) {
        _currentMusicNotifier.value = _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
      } else if (_playlist.isNotEmpty) {
        _currentIndex = 0;
        _currentMusicNotifier.value = _playlist[0];
      } else {
        _currentMusicNotifier.value = null;
        stop();
      }
    }
  }

  // Start position timer
  void _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_player != null && _isPlaying && !_isPaused) {
        try {
          // Flutter Sound doesn't provide real-time position updates during playback
          // We'll estimate position based on elapsed time since last update
          _currentPosition = _currentPosition + const Duration(milliseconds: 100);
          if (_currentPosition > _totalDuration) {
            _currentPosition = _totalDuration;
          }
          _positionNotifier.value = _currentPosition;
        } catch (e) {
          print('Error updating position: $e');
        }
      }
    });
  }

  // Stop position timer
  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  // Dispose resources
  Future<void> dispose() async {
    _stopPositionTimer();
    if (_player != null) {
      await _player!.stopPlayer();
      await _player!.closePlayer();
      _player = null;
    }
    _currentMusicNotifier.dispose();
    _positionNotifier.dispose();
    _durationNotifier.dispose();
    _isPlayingNotifier.dispose();
  }
}