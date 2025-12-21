import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'models/app_state.dart';
import 'services/audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio player service in background
  final audioPlayerService = AudioPlayerService();
  // Don't wait for initialization to complete, start it in background
  audioPlayerService.init().catchError((e) {
    print('Error initializing audio player service: $e');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState()..loadData(),
      child: MaterialApp(
        title: '流韵',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.red[900],
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.red[900],
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        themeMode: ThemeMode.dark,
        home: const MainScreen(),
      ),
    );
  }
}
