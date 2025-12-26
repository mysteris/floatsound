import 'package:flutter/material.dart';
import 'lib/services/audio_player_service.dart';
import 'lib/services/equalizer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🎵 Starting Equalizer Test...');
  
  // Test 1: Test EqualizerService directly
  print('\n=== Test 1: EqualizerService Direct Test ===');
  final equalizerService = EqualizerService();
  
  try {
    // Initialize with session ID 0 (global)
    print('Initializing EqualizerService...');
    final initResult = await equalizerService.initialize(0);
    print('✓ EqualizerService initialization result: $initResult');
    
    if (initResult) {
      // Get current state
      final state = await equalizerService.getEqualizerState();
      print('📊 Equalizer state: $state');
      
      // Test setting band levels
      print('\n🎚️ Testing band level setting...');
      final testLevels = [500, 200, -100, -200, -300]; // Millibels
      final setResult = await equalizerService.setBandLevels(testLevels);
      print('✓ Band levels set result: $setResult');
      
      // Verify the levels were applied
      final newLevels = await equalizerService.getBandLevels();
      print('📊 New band levels: $newLevels');
      
      // Test enabling/disabling
      print('\n🔧 Testing enable/disable...');
      final disableResult = await equalizerService.setEnabled(false);
      print('✓ Disable result: $disableResult');
      
      final enableResult = await equalizerService.setEnabled(true);
      print('✓ Enable result: $enableResult');
      
      // Final state check
      final finalState = await equalizerService.getEqualizerState();
      print('📊 Final equalizer state: $finalState');
    }
  } catch (e) {
    print('❌ EqualizerService test failed: $e');
  }
  
  // Test 2: Test via AudioPlayerService
  print('\n=== Test 2: AudioPlayerService Integration Test ===');
  final audioPlayerService = AudioPlayerService();
  
  try {
    // Test equalizer diagnostics
    print('Getting equalizer diagnostics...');
    final diagnostics = await audioPlayerService.getEqualizerDiagnostics();
    print('📊 Equalizer diagnostics: $diagnostics');
    
    // Test setting equalizer bands
    print('\n🎚️ Testing equalizer bands via AudioPlayerService...');
    final testBands = [2.0, 1.0, 0.0, -1.0, -2.0]; // dB values
    await audioPlayerService.setEqualizerBands(testBands);
    print('✓ Equalizer bands set via AudioPlayerService');
    
    // Test equalizer state
    final state = await audioPlayerService.getEqualizerState();
    print('📊 Equalizer state via AudioPlayerService: $state');
    
  } catch (e) {
    print('❌ AudioPlayerService test failed: $e');
  }
  
  print('\n🎉 Equalizer test completed!');
}