import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/music.dart';
import '../services/audio_player_service.dart';
import '../widgets/bottom_player_widget.dart';
import 'library_screen.dart';
import 'equalizer_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const LibraryScreen(), // Filter page with categories
    const EqualizerScreen(), // Professional equalizer
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissionsOnFirstLaunch();
    _loadSavedPlayerState();
  }

  // Check if permissions have been requested before, and only request on first launch
  Future<void> _checkAndRequestPermissionsOnFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool permissionsRequested =
          prefs.getBool('permissions_requested') ?? false;

      if (!permissionsRequested) {
        // First launch - request permissions
        await _requestPermissions();
        // Mark that permissions have been requested
        await prefs.setBool('permissions_requested', true);
      } else {
        print('Permissions have already been requested on first launch');
      }
    } catch (e) {
      print('Error checking first launch status: $e');
      // If there's an error, still try to request permissions
      await _requestPermissions();
    }
  }

  // Request permissions on first app launch
  Future<void> _requestPermissions() async {
    try {
      // Check and request storage permissions based on Android version
      Map<Permission, PermissionStatus> statuses;

      if (await Permission.manageExternalStorage.isGranted) {
        // Already have manage external storage permission
        print('Manage external storage permission already granted');
        return;
      }

      // For Android 13 and above, request READ_MEDIA_AUDIO permission
      if (await Permission.photos.isRestricted) {
        // This indicates Android 13+
        statuses = await [
          Permission.audio,
          Permission.mediaLibrary,
        ].request();
      } else {
        // For Android 12 and below, request READ_EXTERNAL_STORAGE
        statuses = await [
          Permission.storage,
        ].request();
      }

      // Check if permissions were granted
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (status != PermissionStatus.granted) {
          allGranted = false;
          print('Permission ${permission.toString()} not granted: $status');
        }
      });

      if (allGranted) {
        print('All permissions granted successfully');
      } else {
        print('Some permissions were denied');
        // Show a dialog to explain why permissions are needed
        if (mounted) {
          _showPermissionExplanation();
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  void _showPermissionExplanation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            '需要权限',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '流韵需要访问存储权限来扫描和播放音乐文件。请在设置中授予权限。',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('去设置', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  // Load saved player state when app starts
  Future<void> _loadSavedPlayerState() async {
    try {
      print('Loading saved player state...');
      final audioPlayerService = AudioPlayerService();

      // Load the saved player state
      await audioPlayerService.loadPlayerState();

      // If there was music playing, resume from saved position
      if (audioPlayerService.currentMusic != null) {
        print('Found saved music: ${audioPlayerService.currentMusic!.title}');
        print('Saved position: ${audioPlayerService.currentPosition}');

        // Resume playback from saved position if needed
        // This will be handled by the audio player service
        await audioPlayerService.resumeFromSavedPosition();
      } else {
        print('No saved player state found');
      }
    } catch (e) {
      print('Error loading saved player state: $e');
    }
  }

  Widget _buildTabItem(int index, IconData icon, String label,
      {double fontSize = 14}) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.red : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.red : Colors.grey,
                  height: 1.0,
                ),
                textScaleFactor: 1.0, // Disable text scaling
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              // Page content
              Expanded(
                child: _pages[_currentIndex],
              ),
              // Bottom player widget - only show when music is available or playing
              Consumer<AppState>(
                builder: (context, appState, child) {
                  final audioPlayerService = AudioPlayerService();
                  return ValueListenableBuilder<Music?>(
                    valueListenable: audioPlayerService.currentMusicNotifier,
                    builder: (context, currentMusic, child) {
                      return currentMusic != null
                          ? const BottomPlayerWidget()
                          : const SizedBox.shrink();
                    },
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: Colors.black,
            child: SafeArea(
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabItem(0, Icons.filter_list, '流韵',
                        fontSize: 14), // Same font size as 均衡器
                    _buildTabItem(1, Icons.equalizer, '均衡器',
                        fontSize: 14), // Keep same size for consistency
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
