import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/file_scanner_service.dart';
import '../services/audio_player_service.dart';
import 'category_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final FileScannerService _fileScannerService = FileScannerService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  bool _isScanning = false;
  int _scanProgress = 0;
  int _totalFiles = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // Request storage permissions
  Future<void> _requestPermissions() async {
    if (await _checkAndRequestPermissions()) {
      // Permission granted, no need to show message
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要存储权限才能访问音乐文件')),
      );
    }
  }

  // Check and request permissions
  Future<bool> _checkAndRequestPermissions() async {
    try {
      print('Checking permissions...'); // Debug log

      // For Android 13+ (API 33+), we need READ_MEDIA_AUDIO permission
      // For Android 12 and below, we need READ_EXTERNAL_STORAGE permission

      // Let's try a simple approach - attempt to list a directory to check if we have access
      try {
        final testDir = Directory('/storage/emulated/0/Music');
        if (await testDir.exists()) {
          await testDir.list().take(1).toList();
          print(
              'Permission check passed - can access directories'); // Debug log
          return true;
        }
      } catch (e) {
        print('Permission check failed: $e'); // Debug log
        // If we can't access directories, we might need to request permissions
        // But for now, let's proceed and let FilePicker handle it
      }

      print(
          'Proceeding with folder selection - FilePicker will handle permissions'); // Debug log
      return true; // Assume permissions are handled by FilePicker
    } catch (e) {
      print('Permission error: $e'); // Debug log
      return true; // Default to true to allow folder selection to proceed
    }
  }

  // Select directory and scan music
  Future<void> _selectDirectory() async {
    // Check permissions first
    if (!(await _checkAndRequestPermissions())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要存储权限才能访问音乐文件')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.getDirectoryPath();
      print('FilePicker result: $result'); // Debug log for release mode

      if (result == null) {
        print('User cancelled folder selection'); // Debug log
        return;
      }

      setState(() {
        _isScanning = true;
        _scanProgress = 0;
        _totalFiles = 0;
      });

      print('Starting scan of directory: $result'); // Debug log

      // First, run a test scan to debug the issue
      print('Running test scan first...'); // Debug log
      final testResult = await _fileScannerService.testScanDirectory(result);
      print('Test scan completed: $testResult'); // Debug log

      // Test results are logged but not shown to user as requested

      // Now run the actual scan
      final musicList = await _fileScannerService.scanDirectory(
        result,
        onProgress: (current, total) {
          setState(() {
            _scanProgress = current;
            _totalFiles = total;
          });
          print(
              'Scanning progress: $current/$total files processed'); // Debug log
        },
      );

      print(
          'Scan completed. Found ${musicList.length} music files'); // Debug log

      setState(() {
        _isScanning = false;
      });

      // Update app state with music list and directory
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setMusicList(musicList);
      appState.setSelectedDirectory(result);

      if (musicList.isEmpty) {
        print('No music files found in selected directory'); // Debug log
        // Removed notification as requested
      } else {
        print(
            'Music scan completed successfully. Found ${musicList.length} files'); // Debug log
        // Removed notification as requested
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      print('Folder selection error: $e'); // Debug log
      print('Error type: ${e.runtimeType}'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('扫描音乐文件时出错: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Filter music by category and navigate to category screen
  void _filterByCategory(BuildContext context, String category) {
    // Update app state with selected category
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedCategory(category);

    // Navigate to category screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryScreen()),
    );
  }

  // Show about dialog
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            '关于',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '流韵 - 一个简约的HiFi播放器',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '版本号：v0.0.1',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('流韵'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey[850],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              switch (value) {
                case 'select_folder':
                  _selectDirectory();
                  break;
                case 'about':
                  _showAboutDialog(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'select_folder',
                child: Row(
                  children: [
                    Icon(Icons.folder_open, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('选择文件夹', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('关于', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: _isScanning
            ? _buildScanningProgress()
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20.0,
                  crossAxisSpacing: 20.0,
                  shrinkWrap: true,
                  children: [
                    _buildCategoryItem(Icons.music_note, '所有歌曲',
                        () => _filterByCategory(context, 'all'), 'all'),
                    _buildCategoryItem(Icons.folder, '文件夹',
                        () => _filterByCategory(context, 'folders'), 'folders'),
                    _buildCategoryItem(Icons.album, '专辑',
                        () => _filterByCategory(context, 'albums'), 'albums'),
                    _buildCategoryItem(Icons.person, '歌手',
                        () => _filterByCategory(context, 'artists'), 'artists'),
                    _buildCategoryItem(
                        Icons.star,
                        '加星',
                        () => _filterByCategory(context, 'favorites'),
                        'favorites'),
                    // _buildCategoryItem(Icons.playlist_play, '歌单',
                    //     () => _filterByCategory(context, 'playlists'), 'playlists'),
                  ],
                ),
              ),
      ),
    );
  }

  // Build elegant scanning progress widget
  Widget _buildScanningProgress() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant circular progress indicator with gradient
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress text
          Text(
            '扫描音乐文件中...',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Progress numbers
          Text(
            '$_scanProgress / $_totalFiles 文件',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),

          // Progress bar
          if (_totalFiles > 0) ...[
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _totalFiles > 0 ? _scanProgress / _totalFiles : 0,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build category item with selected state
  Widget _buildCategoryItem(
      IconData icon, String title, VoidCallback? onPressed, String category) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isSelected = appState.selectedCategory == category;

        return SizedBox(
          width: double.infinity,
          height: 120,
          child: InkWell(
            onTap: onPressed,
            splashColor: Colors.red.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.red[900] : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.red[400]! : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.red,
                    size: isSelected ? 42 : 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white,
                      fontSize: isSelected ? 17 : 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
