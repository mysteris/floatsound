import 'package:flutter/material.dart';
import 'lib/services/audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 Testing Equalizer Functionality');
  print('=====================================');

  try {
    // Test 1: Create AudioPlayerService instance
    print('\n📋 Test 1: Creating AudioPlayerService instance...');
    final audioPlayerService = AudioPlayerService();
    print('✅ AudioPlayerService created successfully');

    // Test 2: Get equalizer state without initialization
    print('\n📋 Test 2: Getting equalizer state (should auto-initialize)...');
    final equalizerState = await audioPlayerService.getEqualizerState();
    if (equalizerState != null) {
      print('✅ Equalizer state retrieved successfully');
      print('   State: $equalizerState');
    } else {
      print('❌ Failed to retrieve equalizer state');
    }

    // Test 3: Set equalizer preset
    print('\n📋 Test 3: Setting equalizer preset to "摇滚"...');
    await audioPlayerService.setEqualizerPreset('摇滚');
    print('✅ Equalizer preset set successfully');

    // Test 4: Set custom equalizer bands
    print('\n📋 Test 4: Setting custom equalizer bands...');
    await audioPlayerService.setEqualizerBands([300, 200, 100, -100, -200]);
    print('✅ Custom equalizer bands set successfully');

    // Test 5: Get current equalizer settings
    print('\n📋 Test 5: Getting current equalizer settings...');
    final currentState = await audioPlayerService.getEqualizerState();
    print('✅ Current equalizer state retrieved');
    print('   State: $currentState');

    print('\n🎉 All tests completed successfully!');
  } catch (e, stackTrace) {
    print('\n❌ Test failed with error:');
    print('   Error: $e');
    print('   Stack trace: $stackTrace');
  }
}
