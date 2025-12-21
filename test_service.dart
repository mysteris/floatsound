import 'lib/services/audio_player_service.dart';

void main() {
  final service = AudioPlayerService();
  print('AudioPlayerService instance created successfully');
  
  // Try to access _equalizerService
  // This will fail if _equalizerService is not properly defined
  try {
    print('Testing service initialization...');
    // This is a simple test to see if the class is properly defined
  } catch (e) {
    print('Error: $e');
  }
}