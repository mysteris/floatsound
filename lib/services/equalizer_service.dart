import 'package:flutter/services.dart';

class EqualizerService {
  static final EqualizerService _instance = EqualizerService._internal();
  factory EqualizerService() => _instance;
  EqualizerService._internal();

  // Method channel for native communication
  static const MethodChannel _channel =
      MethodChannel('com.mysteris.floatsound/equalizer');

  // Track method calls for debugging
  Future<T?> _invokeMethod<T>(String method,
      [Map<String, dynamic>? arguments]) async {
    try {
      print('📡 Calling method channel: $method');
      if (arguments != null) {
        print('📡 Arguments: $arguments');
      }

      final result = await _channel.invokeMethod<T>(method, arguments);
      print('📥 Method channel response: $result');
      return result;
    } catch (e) {
      print('❌ Method channel error for $method: $e');
      rethrow;
    }
  }

  bool _initialized = false;
  bool _enabled = false;
  List<int> _bandLevelRange = [-1500, 1500]; // Default range in millibels
  List<int> _centerFrequencies = [];
  int? _audioSessionId;

  // Initialize the equalizer
  Future<bool> initialize(int audioSessionId) async {
    try {
      print(
          '🎵 Initializing EqualizerService with session ID: $audioSessionId');

      // Check if already initialized with this session ID
      if (_initialized && _audioSessionId == audioSessionId) {
        print(
            '⚠️ EqualizerService already initialized with session ID: $audioSessionId');
        return true;
      }

      // If initialized with different session ID, reinitialize
      if (_initialized && _audioSessionId != audioSessionId) {
        print(
            '🔄 Reinitializing EqualizerService from session ID $_audioSessionId to $audioSessionId');
      }

      _audioSessionId = audioSessionId;

      print('📡 Calling method channel: initializeEqualizer');

      // Initialize the equalizer using method channel
      final Map<Object?, Object?>? result =
          await _invokeMethod('initializeEqualizer', {
        'audioSessionId': audioSessionId,
      });

      print('📥 Method channel response: $result');

      // Convert Map<Object?, Object?> to Map<String, dynamic>
      final Map<String, dynamic> convertedResult = {};
      if (result != null) {
        result.forEach((key, value) {
          if (key != null) {
            convertedResult[key.toString()] = value;
          }
        });
      }

      if (convertedResult.isNotEmpty && convertedResult['success'] == true) {
        _initialized = true;

        // Get equalizer properties
        _bandLevelRange =
            List<int>.from(convertedResult['bandLevelRange'] ?? [-1500, 1500]);
        _centerFrequencies =
            List<int>.from(convertedResult['centerFrequencies'] ?? []);
        _enabled = convertedResult['enabled'] ?? false;

        print('✅ EqualizerService initialized successfully');
        print('📊 Band level range: $_bandLevelRange');
        print('🎼 Center frequencies: $_centerFrequencies');
        print('🔧 Enabled: $_enabled');
        print('🔧 Number of bands: ${_centerFrequencies.length}');

        return true;
      } else {
        print(
            '❌ Failed to initialize EqualizerService: ${convertedResult['error'] ?? 'Unknown error'}');
        print('📥 Full result: $convertedResult');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing EqualizerService: $e');
      print('📋 Stack trace: $stackTrace');
      return false;
    }
  }

  // Enable/disable equalizer
  Future<bool> setEnabled(bool enabled) async {
    if (!_initialized) {
      print('⚠️ EqualizerService not initialized');
      return false;
    }

    try {
      print('🔧 Setting equalizer enabled: $enabled');
      final Map<Object?, Object?>? result =
          await _channel.invokeMethod('setEqualizerEnabled', {
        'enabled': enabled,
      });

      // Convert Map<Object?, Object?> to Map<String, dynamic>
      final Map<String, dynamic> convertedResult = {};
      if (result != null) {
        result.forEach((key, value) {
          if (key != null) {
            convertedResult[key.toString()] = value;
          }
        });
      }

      if (convertedResult['success'] == true) {
        _enabled = enabled;
        print('✅ Equalizer enabled set to: $enabled');
        return true;
      } else {
        print('❌ Failed to set equalizer enabled: ${convertedResult['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Error setting equalizer enabled: $e');
      return false;
    }
  }

  // Set band level
  Future<bool> setBandLevel(int band, int level) async {
    if (!_initialized) {
      print('⚠️ EqualizerService not initialized');
      return false;
    }

    try {
      print('🎚️ Setting band $band to level $level');
      final Map<Object?, Object?>? result =
          await _channel.invokeMethod('setEqualizerBand', {
        'band': band,
        'level': level,
      });

      // Convert Map<Object?, Object?> to Map<String, dynamic>
      final Map<String, dynamic> convertedResult = {};
      if (result != null) {
        result.forEach((key, value) {
          if (key != null) {
            convertedResult[key.toString()] = value;
          }
        });
      }

      if (convertedResult['success'] == true) {
        print('✅ Band $band level set to: $level');
        return true;
      } else {
        print('❌ Failed to set band level: ${convertedResult['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Error setting band level: $e');
      return false;
    }
  }

  // Set multiple band levels
  Future<bool> setBandLevels(List<int> levels) async {
    if (!_initialized) {
      print('⚠️ EqualizerService not initialized');
      return false;
    }

    try {
      print('🎚️ Setting multiple band levels: $levels');

      for (int i = 0; i < levels.length; i++) {
        await setBandLevel(i, levels[i]);
      }

      // Ensure equalizer is enabled after setting band levels
      print('🔧 Ensuring equalizer is enabled after setting band levels');
      await setEnabled(true);

      print('✅ All band levels set successfully and equalizer enabled');
      return true;
    } catch (e) {
      print('❌ Error setting band levels: $e');
      return false;
    }
  }

  // Get current band levels
  Future<List<int>> getBandLevels() async {
    if (!_initialized) {
      print('⚠️ EqualizerService not initialized');
      return [];
    }

    try {
      final Map<Object?, Object?>? result =
          await _channel.invokeMethod('getEqualizerBandLevels');

      // Convert Map<Object?, Object?> to Map<String, dynamic>
      final Map<String, dynamic> convertedResult = {};
      if (result != null) {
        result.forEach((key, value) {
          if (key != null) {
            convertedResult[key.toString()] = value;
          }
        });
      }

      if (convertedResult['success'] == true) {
        final levels = List<int>.from(convertedResult['levels'] ?? []);
        print('📊 Current band levels: $levels');
        return levels;
      } else {
        print('❌ Failed to get band levels: ${convertedResult['error']}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting band levels: $e');
      return [];
    }
  }

  // Get equalizer state
  Future<Map<String, dynamic>> getEqualizerState() async {
    try {
      if (!_initialized) {
        return {
          'initialized': false,
          'enabled': false,
          'bandLevels': [],
          'centerFrequencies': [],
          'bandLevelRange': _bandLevelRange,
          'audioSessionId': _audioSessionId,
          'error': 'EqualizerService not initialized',
        };
      }

      final bandLevels = await getBandLevels();

      return {
        'initialized': _initialized,
        'enabled': _enabled,
        'bandLevels': bandLevels,
        'centerFrequencies': _centerFrequencies,
        'bandLevelRange': _bandLevelRange,
        'audioSessionId': _audioSessionId,
        'error': null,
      };
    } catch (e) {
      print('❌ Error getting equalizer state: $e');
      return {
        'initialized': _initialized,
        'enabled': _enabled,
        'bandLevels': [],
        'centerFrequencies': _centerFrequencies,
        'bandLevelRange': _bandLevelRange,
        'audioSessionId': _audioSessionId,
        'error': e.toString(),
      };
    }
  }

  // Get service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    return {
      'available': true, // Service is always available
      'initialized': _initialized,
      'enabled': _enabled,
      'audioSessionId': _audioSessionId,
      'bandCount': _centerFrequencies.length,
      'bandLevelRange': _bandLevelRange,
    };
  }

  // Dispose equalizer
  Future<void> dispose() async {
    try {
      print('🧹 Disposing EqualizerService');
      await _channel.invokeMethod('releaseEqualizer');
      _initialized = false;
      _enabled = false;
      _audioSessionId = null;
      print('✅ EqualizerService disposed');
    } catch (e) {
      print('❌ Error disposing EqualizerService: $e');
    }
  }

  // Getters
  bool get isInitialized => _initialized;
  bool get isEnabled => _enabled;
  List<int> get bandLevelRange => _bandLevelRange;
  List<int> get centerFrequencies => _centerFrequencies;
  int? get audioSessionId => _audioSessionId;
}
