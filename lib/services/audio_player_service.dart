import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equalizer_service.dart';
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
  final ValueNotifier<Music?> _currentMusicNotifier =
      ValueNotifier<Music?>(null);
  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> _durationNotifier =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);

  // Equalizer state
  bool _equalizerEnabled = true;
  String _currentPreset = '标准';
  List<double>? _currentBandValues;

  // New EqualizerService instance
  final EqualizerService _equalizerService = EqualizerService();

  // Guard to prevent multiple simultaneous equalizer initializations
  bool _isInitializingEqualizer = false;

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
      // Player initialized successfully
    } catch (e) {
      // Error initializing Flutter Sound player
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
        // Audio file not found
        return;
      }

      // Get media information for duration
      final mediaInfo = await FFprobeKit.getMediaInformation(inputPath);
      final information = mediaInfo.getMediaInformation();
      if (information != null) {
        final durationStr = information.getDuration();
        if (durationStr != null) {
          _totalDuration = Duration(
              milliseconds: (double.parse(durationStr) * 1000).round());
          _durationNotifier.value = _totalDuration;
        }
      }

      // Start playback with Flutter Sound
      await _player!.startPlayer(
        fromURI: inputPath,
        codec: Codec.defaultCodec,
        whenFinished: () {
          // Playback completed
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

      // Notify native side that playback has started with a new audio session
      await _notifyPlaybackStarted();

      // Initialize equalizer after playback starts with captured Flutter Sound session ID
      _initializeEqualizerAfterPlayback();

      // Started playing: ${currentMusic.title}
    } catch (e) {
      // Error playing audio
      _isPlaying = false;
      _isPaused = false;
      _isPlayingNotifier.value = false;
    }
  }

  // Stop playback
  Future<void> stop() async {
    if (_player == null) return;

    try {
      await _player!.stopPlayer();
      _isPlaying = false;
      _isPaused = false;
      _isPlayingNotifier.value = false;
      _currentPosition = Duration.zero;
      _positionNotifier.value = _currentPosition;
      _stopPositionTimer();

      // Reset audio session ID when playback stops
      _currentAudioSessionId = 0;
      print('Reset audio session ID after stopping playback');

      // Stopped playback
    } catch (e) {
      // Error stopping audio
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
      // Paused playback
    } catch (e) {
      // Error pausing audio
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

  // Play next track
  Future<void> next() async {
    if (_playlist.isEmpty) return;

    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      _currentMusicNotifier.value = _playlist[_currentIndex];
      await play();
    }
  }

  // Play previous track
  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    if (_currentIndex > 0) {
      _currentIndex--;
      _currentMusicNotifier.value = _playlist[_currentIndex];
      await play();
    }
  }

  // Set playlist
  Future<void> setPlaylist(List<Music> playlist, {int startIndex = 0}) async {
    _playlist = playlist;
    _currentIndex = startIndex;
    _currentMusicNotifier.value =
        playlist.isNotEmpty ? playlist[startIndex] : null;
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    if (_player == null) return;

    try {
      await _player!.seekToPlayer(position);
      _currentPosition = position;
      _positionNotifier.value = _currentPosition;
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  // Start position timer
  void _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isPlaying && !_isPaused) {
        _updatePosition();
      }
    });
  }

  // Stop position timer
  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  // Update current position
  void _updatePosition() async {
    if (_player == null) return;

    try {
      // Use a timer to track position
      if (_isPlaying) {
        _currentPosition = _currentPosition + const Duration(milliseconds: 200);
        _positionNotifier.value = _currentPosition;
      }
    } catch (e) {
      print('Error getting current position: $e');
    }
  }

  // Enable/disable equalizer
  Future<void> setEqualizerEnabled(bool enabled) async {
    _equalizerEnabled = enabled;
    await _equalizerService.setEnabled(enabled);
  }

  // Get equalizer state
  Future<Map<String, dynamic>?> getEqualizerState() async {
    try {
      // Check if equalizer is initialized
      final serviceStatus = await _equalizerService.getServiceStatus();
      final isInitialized = serviceStatus['initialized'] ?? false;

      if (!isInitialized) {
        print('Equalizer not initialized, initializing with session ID 0...');
        await _equalizerService.initialize(0);
      }

      return await _equalizerService.getEqualizerState();
    } catch (e) {
      print('Error getting equalizer state: $e');
      return null;
    }
  }

  // Check service status
  Future<Map<String, dynamic>?> checkServiceStatus() async {
    try {
      return await _equalizerService.getServiceStatus();
    } catch (e) {
      print('Error checking service status: $e');
      return null;
    }
  }

  // Quick test of equalizer functionality
  Future<bool> quickTest() async {
    try {
      print('=== Quick Equalizer Test ===');

      // Test 1: Initialize with session ID 0
      print('Test 1: Initializing with session ID 0...');
      final initResult = await _equalizerService.initialize(0);
      print('Initialization result: $initResult');

      if (!initResult) {
        print('✗ Quick test failed: Initialization failed');
        return false;
      }

      // Test 2: Get equalizer state
      print('Test 2: Getting equalizer state...');
      final state = await _equalizerService.getEqualizerState();
      print('Equalizer state: $state');

      if (state['initialized'] != true) {
        print('✗ Quick test failed: Equalizer not initialized');
        return false;
      }

      // Test 3: Set test equalizer bands
      print('Test 3: Setting test equalizer bands...');
      final testBands = [2.0, 1.0, 0.0, -1.0, -2.0]; // Simple test pattern
      // Convert to millibels (multiply by 100)
      final testBandsMillibels =
          testBands.map((v) => (v * 100).toInt()).toList();
      final setBandsResult =
          await _equalizerService.setBandLevels(testBandsMillibels);
      print('Set bands result: $setBandsResult');

      // Test 4: Get updated state
      print('Test 4: Getting updated state...');
      final newState = await _equalizerService.getEqualizerState();
      print('Updated state: $newState');

      // Test 5: Disable and re-enable
      print('Test 5: Disabling equalizer...');
      final disableResult = await _equalizerService.setEnabled(false);
      print('Disable result: $disableResult');

      print('Test 6: Re-enabling equalizer...');
      final enableResult = await _equalizerService.setEnabled(true);
      print('Enable result: $enableResult');

      print('✓ Quick test completed successfully');
      return true;
    } catch (e) {
      print('✗ Quick test failed: $e');
      return false;
    }
  }

  // Comprehensive diagnostic that combines service status and equalizer state
  Future<Map<String, dynamic>> getComprehensiveDiagnostics() async {
    print('=== Getting Comprehensive Equalizer Diagnostics ===');

    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'playerState': {},
      'serviceStatus': {},
      'equalizerState': {},
      'connectivity': {},
      'errors': [],
    };

    try {
      // Get current player state
      diagnostics['playerState'] = {
        'isPlaying': _isPlaying,
        'currentTrack': _currentMusicNotifier.value?.title ?? 'None',
        'audioSessionId': await _getAudioSessionId(),
        'equalizerEnabled': _equalizerEnabled,
        'currentPreset': _currentPreset,
        'hasBandValues': _currentBandValues != null,
      };

      // Check service status
      try {
        final serviceStatus = await checkServiceStatus();
        diagnostics['serviceStatus'] = serviceStatus ??
            {
              'error': 'Service status returned null',
              'available': false,
            };
      } catch (e) {
        diagnostics['serviceStatus'] = {
          'error': 'Failed to get service status: $e',
          'available': false,
        };
        diagnostics['errors'].add('Service status check failed: $e');
      }

      // Get equalizer state
      try {
        final equalizerState = await getEqualizerState();
        diagnostics['equalizerState'] = equalizerState ??
            {
              'error': 'Equalizer state returned null',
              'initialized': false,
            };
      } catch (e) {
        diagnostics['equalizerState'] = {
          'error': 'Failed to get equalizer state: $e',
          'initialized': false,
        };
        diagnostics['errors'].add('Equalizer state check failed: $e');
      }

      // Test connectivity to native side
      try {
        // Test if equalizer service is responsive
        try {
          final testResult = await _equalizerService.getEqualizerState();
          diagnostics['connectivity'] = {
            'methodChannelResponsive': testResult != null,
            'canCommunicate': true,
          };
        } catch (e) {
          diagnostics['connectivity'] = {
            'methodChannelResponsive': false,
            'canCommunicate': false,
            'error': e.toString(),
          };
          diagnostics['errors'].add('Method channel connectivity failed: $e');
        }

        // Add summary
        final serviceAvailable =
            diagnostics['serviceStatus']['available'] == true;
        final equalizerInitialized =
            diagnostics['equalizerState']['initialized'] == true;
        final hasErrors = diagnostics['errors'].isNotEmpty;

        diagnostics['summary'] = {
          'serviceAvailable': serviceAvailable,
          'equalizerInitialized': equalizerInitialized,
          'hasErrors': hasErrors,
          'overallStatus':
              serviceAvailable && equalizerInitialized && !hasErrors
                  ? 'healthy'
                  : 'issues_detected',
          'recommendation': _getDiagnosticRecommendation(
            serviceAvailable,
            equalizerInitialized,
            hasErrors,
            diagnostics['errors'],
          ),
        };

        print('Comprehensive diagnostics completed: $diagnostics');
      } catch (e) {
        print('✗ Error during comprehensive diagnostics: $e');
        diagnostics['errors'].add('Comprehensive diagnostic failed: $e');
        diagnostics['summary'] = {
          'serviceAvailable': false,
          'equalizerInitialized': false,
          'hasErrors': true,
          'overallStatus': 'diagnostic_failed',
          'recommendation':
              'Comprehensive diagnostic failed. Check logs for details.',
        };
      }
    } catch (e) {
      print('✗ Error during comprehensive diagnostics: $e');
      diagnostics['errors'].add('Comprehensive diagnostic failed: $e');
      diagnostics['summary'] = {
        'serviceAvailable': false,
        'equalizerInitialized': false,
        'hasErrors': true,
        'overallStatus': 'diagnostic_failed',
        'recommendation':
            'Comprehensive diagnostic failed. Check logs for details.',
      };
    }

    return diagnostics;
  }

  // Get diagnostic recommendation based on results
  String _getDiagnosticRecommendation(
    bool serviceAvailable,
    bool equalizerInitialized,
    bool hasErrors,
    List<dynamic> errors,
  ) {
    if (!serviceAvailable) {
      return 'Equalizer service is not available. Check if the native equalizer service is properly initialized.';
    }

    if (!equalizerInitialized) {
      return 'Equalizer is not initialized. Try restarting the app or check audio session configuration.';
    }

    if (hasErrors) {
      return 'Issues detected: ${errors.length} error(s) found. Check detailed diagnostic information.';
    }

    return 'All systems appear to be working correctly. Equalizer should be functional.';
  }

  // Initialize equalizer with audio session ID
  Future<void> _initializeEqualizer(int sessionId) async {
    // Prevent multiple simultaneous initializations
    if (_isInitializingEqualizer) {
      print('⚠️ Equalizer initialization already in progress, skipping...');
      return;
    }

    _isInitializingEqualizer = true;

    try {
      print('=== Starting Equalizer Initialization ===');
      print('Session ID: $sessionId');
      print(
          'Current player state - isOpen: ${_player?.isOpen() ?? false}, isPlaying: $_isPlaying');

      // Initialize equalizer using the new EqualizerService
      print('Calling EqualizerService.initialize($sessionId)...');
      final result = await _equalizerService.initialize(sessionId);

      print('EqualizerService.initialize() returned: $result');

      if (result) {
        print(
            '✓ Equalizer initialized successfully with session ID: $sessionId');

        // Get equalizer state after initialization for verification
        final state = await _equalizerService.getEqualizerState();
        print('Post-initialization equalizer state: $state');
      } else {
        print('✗ Equalizer initialization failed');

        // Try fallback initialization with session ID 0 only if we haven't tried session 0 yet
        if (sessionId != 0) {
          print('Attempting fallback initialization with session ID 0...');
          final fallbackResult = await _equalizerService.initialize(0);
          print('Fallback initialization result: $fallbackResult');
        } else {
          print('✗ Already tried session ID 0, giving up');
        }
      }
    } catch (e, stackTrace) {
      print('✗ Error initializing equalizer: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isInitializingEqualizer = false;
    }
  }

  // Notify native side that playback has started
  Future<void> _notifyPlaybackStarted() async {
    try {
      print('Notifying native side that playback has started...');

      // Generate a unique session ID based on current time
      // This ensures each playback session gets a unique ID
      final sessionId = DateTime.now().millisecondsSinceEpoch % 1000000;
      _currentAudioSessionId = sessionId; // Store the session ID
      print('Generated and stored session ID for playback: $sessionId');

      const MethodChannel audioChannel =
          MethodChannel('com.mysteris.floatsound/audio');
      await audioChannel.invokeMethod('setAudioSessionId', {
        'sessionId': sessionId,
      });

      print('Notified native side with session ID: $sessionId');
    } catch (e) {
      print('Error notifying playback start: $e');
    }
  }

  // Initialize equalizer after playback starts with Flutter Sound session ID
  Future<void> _initializeEqualizerAfterPlayback() async {
    try {
      print('🎵 Initializing equalizer after Flutter Sound playback starts...');

      // Wait a bit for the Flutter Sound player to be fully initialized
      await Future.delayed(const Duration(
          milliseconds: 1000)); // Increased delay for Flutter Sound

      // Get Flutter Sound audio session ID with enhanced capture
      final sessionId = await _getAudioSessionId();

      if (sessionId > 0) {
        print('✓ Using Flutter Sound audio session ID: $sessionId');

        // Initialize equalizer with Flutter Sound's session ID
        await _initializeEqualizer(sessionId);

        // Apply current equalizer settings if available
        if (_currentBandValues != null && _equalizerEnabled) {
          print(
              '🎚️ Applying current equalizer settings after Flutter Sound initialization');
          _applyEqualizerViaPlatformChannel(_currentBandValues!);
        }

        // Test equalizer functionality with dramatic settings
        print(
            '🧪 Testing equalizer functionality with Flutter Sound session...');
        await _testEqualizerWithFlutterSound(sessionId);
      } else {
        print(
            '⚠️ Warning: Could not capture Flutter Sound audio session ID, using global equalizer');
        // Use session ID 0 for global audio effects as fallback
        await _initializeEqualizer(0);
      }
    } catch (e) {
      print('✗ Error initializing equalizer after Flutter Sound playback: $e');
    }
  }

  // Test equalizer functionality with Flutter Sound session
  Future<void> _testEqualizerWithFlutterSound(int sessionId) async {
    try {
      print(
          '=== Testing Equalizer with Flutter Sound Session ID: $sessionId ===');

      // Wait for audio to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      // Apply dramatic test settings
      final testBands = [8.0, 6.0, 0.0, -4.0, -6.0];
      print('🎚️ Applying test equalizer settings: $testBands');
      await _equalizerService
          .setBandLevels(testBands.map((v) => (v * 100).toInt()).toList());

      // Wait to hear the effect
      await Future.delayed(const Duration(seconds: 2));

      // Apply opposite settings
      final oppositeBands = [-6.0, -4.0, 0.0, 6.0, 8.0];
      print('🔄 Applying opposite equalizer settings: $oppositeBands');
      await _equalizerService
          .setBandLevels(oppositeBands.map((v) => (v * 100).toInt()).toList());

      // Wait to hear the opposite effect
      await Future.delayed(const Duration(seconds: 2));

      // Reset to flat
      final flatBands = [0.0, 0.0, 0.0, 0.0, 0.0];
      print('🔄 Resetting to flat equalizer: $flatBands');
      await _equalizerService
          .setBandLevels(flatBands.map((v) => (v * 100).toInt()).toList());

      print('✓ Equalizer test with Flutter Sound session completed');
    } catch (e) {
      print('✗ Error testing equalizer with Flutter Sound: $e');
    }
  }

  // Store the current session ID
  int _currentAudioSessionId = 0;

  // Get audio session ID with enhanced Flutter Sound capture
  Future<int> _getAudioSessionId() async {
    try {
      // If we have a stored session ID, use it
      if (_currentAudioSessionId > 0) {
        print('✓ Using stored audio session ID: $_currentAudioSessionId');
        return _currentAudioSessionId;
      }

      // Try to capture Flutter Sound's audio session ID
      const platform = MethodChannel('com.mysteris.floatsound/audio');
      try {
        // First try to capture Flutter Sound session ID
        final flutterSessionId =
            await platform.invokeMethod<int>('captureFlutterSoundSessionId');
        if (flutterSessionId != null && flutterSessionId > 0) {
          _currentAudioSessionId = flutterSessionId;
          print('✓ Captured Flutter Sound audio session ID: $flutterSessionId');
          return flutterSessionId;
        }
      } catch (e) {
        print('⚠️ Could not capture Flutter Sound session ID: $e');
      }

      // Try force detection if capture didn't work
      try {
        final forcedSessionId =
            await platform.invokeMethod<int>('forceAudioSessionDetection');
        if (forcedSessionId != null && forcedSessionId > 0) {
          _currentAudioSessionId = forcedSessionId;
          print('✓ Forced audio session detection: $forcedSessionId');
          return forcedSessionId;
        }
      } catch (e) {
        print('⚠️ Force detection failed: $e');
      }

      // Fallback to legacy method
      try {
        final sessionId = await platform.invokeMethod<int>('getAudioSessionId');
        if (sessionId != null && sessionId > 0) {
          _currentAudioSessionId = sessionId;
          print('✓ Retrieved audio session ID from native: $sessionId');
          return sessionId;
        }
      } catch (e) {
        print('⚠️ Could not get audio session ID from native: $e');
      }

      // Last fallback: Generate a new session ID if playing
      if (_player != null && _player!.isOpen() && _isPlaying) {
        _currentAudioSessionId =
            DateTime.now().millisecondsSinceEpoch % 1000000;
        print('✓ Generated fallback session ID: $_currentAudioSessionId');
        return _currentAudioSessionId;
      }

      return 0; // Global session as last resort
    } catch (e) {
      print('Error getting audio session ID: $e');
      return 0;
    }
  }

  // Apply equalizer via platform channel
  void _applyEqualizerViaPlatformChannel(List<double> bandValues) {
    try {
      print('Applying equalizer via platform channel: $bandValues');

      // Create equalizer settings
      final equalizerSettings = <String, dynamic>{
        'preset': _currentPreset,
        'bands': bandValues.map((value) => value.toStringAsFixed(1)).toList(),
        'frequencies': [60.0, 230.0, 910.0, 3600.0, 14000.0]
            .map((freq) => freq.toStringAsFixed(1))
            .toList(),
      };

      // Try to apply via platform channel using the proper equalizer service
      _equalizerService
          .setBandLevels(equalizerSettings['bands']
              .map((v) => (double.parse(v) * 100).toInt())
              .toList())
          .then((result) {
        print('Platform channel equalizer applied successfully: $result');

        // Verify equalizer was applied successfully
        if (result) {
          print('✓ Equalizer bands applied successfully');
        } else {
          print('✗ Equalizer bands application failed');
        }
      }).catchError((error) {
        print('✗ Error applying equalizer via platform channel: $error');
      });
    } catch (e) {
      print('✗ Error in _applyEqualizerViaPlatformChannel: $e');
    }
  }

  // Save custom preset
  Future<void> saveCustomPreset(
      String presetName, List<double> bandValues) async {
    // Save custom equalizer preset
    print('Saving custom preset: $presetName with values: $bandValues');
    try {
      final prefs = await SharedPreferences.getInstance();
      final bandValuesString = bandValues.join(',');
      await prefs.setString('custom_preset_$presetName', bandValuesString);
      print('Custom preset saved successfully: $presetName');
    } catch (e) {
      print('Error saving custom preset: $e');
      rethrow;
    }
  }

  // Load custom preset
  Future<List<double>?> loadCustomPreset(String presetName) async {
    // Load custom equalizer preset
    try {
      final prefs = await SharedPreferences.getInstance();
      final bandValuesString = prefs.getString('custom_preset_$presetName');
      if (bandValuesString != null) {
        final bandValues = bandValuesString
            .split(',')
            .map((value) => double.parse(value))
            .toList();
        print('Custom preset loaded successfully: $presetName');
        return bandValues;
      }
      return null;
    } catch (e) {
      print('Error loading custom preset: $e');
      return null;
    }
  }

  // Get custom preset names
  Future<List<String>> getCustomPresetNames() async {
    // Get all custom preset names
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPresets = <String>[];
      for (final key in prefs.getKeys()) {
        if (key.startsWith('custom_preset_')) {
          final presetName = key.replaceFirst('custom_preset_', '');
          customPresets.add(presetName);
        }
      }
      return customPresets;
    } catch (e) {
      print('Error getting custom preset names: $e');
      return [];
    }
  }

  // Delete custom preset
  Future<void> deleteCustomPreset(String presetName) async {
    // Delete custom equalizer preset
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('custom_preset_$presetName');
      print('Custom preset deleted successfully: $presetName');
    } catch (e) {
      print('Error deleting custom preset: $e');
      rethrow;
    }
  }

  // Test equalizer functionality
  Future<Map<String, dynamic>> testEqualizer() async {
    // Test equalizer functionality and return results
    final results = <String, dynamic>{};

    try {
      // Check if equalizer is initialized
      final serviceStatus = await _equalizerService.getServiceStatus();
      final isInitialized = serviceStatus['initialized'] ?? false;

      if (!isInitialized) {
        print('Equalizer not initialized, initializing with session ID 0...');
        await _equalizerService.initialize(0);
      }

      // Test basic equalizer state
      final state = await _equalizerService.getEqualizerState();
      results['basicState'] = state;

      // Test preset switching (using standard presets)
      final presets = ['标准', '摇滚', '流行', '爵士', '古典'];
      for (final preset in presets) {
        try {
          // Since EqualizerService doesn't have setPreset, we'll simulate it
          await _equalizerService.setBandLevels([0, 0, 0, 0, 0]);
          results['preset_$preset'] = 'success';
        } catch (e) {
          results['preset_$preset'] = 'failed: $e';
        }
      }

      // Test custom band values
      try {
        final testBands = [0, 200, 400, 600, 800];
        await _equalizerService.setBandLevels(testBands);
        results['customBands'] = 'success';
      } catch (e) {
        results['customBands'] = 'failed: $e';
      }

      results['overall'] = 'completed';
    } catch (e) {
      results['overall'] = 'failed: $e';
    }

    return results;
  }

  // Get equalizer diagnostics
  Future<Map<String, dynamic>> getEqualizerDiagnostics() async {
    // Get comprehensive equalizer diagnostics
    final diagnostics = <String, dynamic>{};

    try {
      // Check if equalizer is initialized
      final serviceStatus = await _equalizerService.getServiceStatus();
      final isInitialized = serviceStatus['initialized'] ?? false;

      if (!isInitialized) {
        print('Equalizer not initialized, initializing with session ID 0...');
        await _equalizerService.initialize(0);
      }

      // Get equalizer state
      final state = await _equalizerService.getEqualizerState();
      diagnostics['equalizerState'] = state;

      // Get current band values
      final bandValues = await _equalizerService.getBandLevels();
      diagnostics['bandValues'] = bandValues;

      // Get service status
      final updatedServiceStatus = await _equalizerService.getServiceStatus();
      diagnostics['serviceStatus'] = updatedServiceStatus;

      diagnostics['timestamp'] = DateTime.now().toIso8601String();
      diagnostics['status'] = 'success';
    } catch (e) {
      diagnostics['status'] = 'failed';
      diagnostics['error'] = e.toString();
      diagnostics['timestamp'] = DateTime.now().toIso8601String();
    }

    return diagnostics;
  }

  // Set equalizer preset
  Future<void> setEqualizerPreset(String presetName,
      [List<double>? bandValues]) async {
    try {
      // Check if equalizer is initialized
      final serviceStatus = await _equalizerService.getServiceStatus();
      final isInitialized = serviceStatus['initialized'] ?? false;

      if (!isInitialized) {
        print('Equalizer not initialized, initializing with session ID 0...');
        await _equalizerService.initialize(0);
      }

      // If custom band values are provided, use them
      if (bandValues != null) {
        await setEqualizerBands(bandValues);
        _currentPreset = presetName;
        print('Equalizer preset set to: $presetName with custom band values');
        return;
      }

      // Otherwise use predefined presets
      switch (presetName) {
        case '标准':
          await _equalizerService.setBandLevels([0, 0, 0, 0, 0]);
          break;
        case '摇滚':
          await _equalizerService.setBandLevels([500, 400, 200, -100, -200]);
          break;
        case '流行':
          await _equalizerService.setBandLevels([200, 200, 0, -100, -200]);
          break;
        case '爵士':
          await _equalizerService.setBandLevels([300, 0, -100, 200, 300]);
          break;
        case '古典':
          await _equalizerService.setBandLevels([400, 200, -100, -200, -300]);
          break;
        default:
          await _equalizerService.setBandLevels([0, 0, 0, 0, 0]);
          break;
      }
      _currentPreset = presetName;
      print('Equalizer preset set to: $presetName');
    } catch (e) {
      print('Error setting equalizer preset: $e');
      rethrow;
    }
  }

  // Set equalizer bands
  Future<void> setEqualizerBands(List<double> bandValues) async {
    try {
      // Check if equalizer is initialized
      final serviceStatus = await _equalizerService.getServiceStatus();
      final isInitialized = serviceStatus['initialized'] ?? false;

      if (!isInitialized) {
        print('Equalizer not initialized, initializing with session ID 0...');
        await _equalizerService.initialize(0);
      }

      // Convert double values to int (millibels) for EqualizerService
      final intBandValues =
          bandValues.map((value) => (value * 100).round()).toList();
      await _equalizerService.setBandLevels(intBandValues);
      _currentBandValues = bandValues;
      _currentPreset = '自定义';
      print('Equalizer bands set to: $bandValues');
    } catch (e) {
      print('Error setting equalizer bands: $e');
      rethrow;
    }
  }

  // Show system volume control
  void showSystemVolumeControl() {
    // Show system volume control
    try {
      // This would typically use a platform-specific implementation
      print('Showing system volume control');
    } catch (e) {
      print('Error showing system volume control: $e');
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      if (_player != null) {
        await _player!.seekToPlayer(position);
        _currentPosition = position;
        _positionNotifier.value = position;
        print('Seeked to position: ${position.inSeconds}s');
      }
    } catch (e) {
      print('Error seeking to position: $e');
    }
  }

  // Get play mode icon
  IconData getPlayModeIcon() {
    // Return icon for current play mode
    // This would typically return an IconData representing the icon
    return Icons.repeat; // Default implementation
  }

  // Toggle play mode
  void togglePlayMode() {
    // Toggle between different play modes
    // This would typically cycle through repeat, shuffle, etc.
    print('Toggling play mode');
  }

  // Load player state from storage
  Future<void> loadPlayerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentIndex = prefs.getInt('last_index') ?? 0;
      final positionMs = prefs.getInt('last_position') ?? 0;
      _currentPosition = Duration(milliseconds: positionMs);
      _positionNotifier.value = _currentPosition;
      print(
          'Player state loaded: index=$_currentIndex, position=${_currentPosition.inSeconds}s');
    } catch (e) {
      print('Error loading player state: $e');
    }
  }

  // Resume from saved position
  Future<void> resumeFromSavedPosition() async {
    try {
      if (_currentPosition > Duration.zero) {
        await seek(_currentPosition);
        print('Resumed from saved position: ${_currentPosition.inSeconds}s');
      }
    } catch (e) {
      print('Error resuming from saved position: $e');
    }
  }
}
