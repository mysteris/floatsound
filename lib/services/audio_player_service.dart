import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/music.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  
  AudioPlayerService._internal();
  
  final AudioPlayer _player = AudioPlayer();
  List<Music> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  
  // ValueNotifier to notify listeners when current music changes
  final ValueNotifier<Music?> _currentMusicNotifier = ValueNotifier<Music?>(null);
  
  // Getters
  List<Music> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Music? get currentMusic => _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  ValueNotifier<Music?> get currentMusicNotifier => _currentMusicNotifier;
  
  // Initialize player
  Future<void> init() async {
    // Just Audio 0.9.x doesn't have AudioSource.empty()
    // Initialize player without audio source
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
    });
  }
  
  // Set playlist and play
  Future<void> setPlaylist(List<Music> playlist, {int startIndex = 0}) async {
    _playlist = playlist;
    _currentIndex = startIndex;
    await _playCurrent();
  }
  
  // Play current music
  Future<void> _playCurrent() async {
    if (_playlist.isEmpty) return;
    
    final music = _playlist[_currentIndex];
    await _player.setFilePath(music.filePath);
    await _player.play();
    // Update current music notifier
    _currentMusicNotifier.value = music;
  }
  
  // Play
  Future<void> play() async {
    if (_player.playing) return;
    await _player.play();
  }
  
  // Pause
  Future<void> pause() async {
    await _player.pause();
  }
  
  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }
  
  // Next track
  Future<void> next() async {
    if (_playlist.isEmpty) return;
    
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await _playCurrent();
  }
  
  // Previous track
  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    
    if (_player.position.inSeconds > 3) {
      // If played more than 3 seconds, restart current track
      await _player.seek(Duration.zero);
    } else {
      // Otherwise, go to previous track
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      await _playCurrent();
    }
  }
  
  // Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  // Set volume
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }
  
  // Get current position stream
  Stream<Duration> get positionStream => _player.positionStream;
  
  // Get duration stream
  Stream<Duration?> get durationStream => _player.durationStream;
  
  // Get player state stream
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  
  // Dispose player
  Future<void> dispose() async {
    await _player.dispose();
  }
}
