import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/file_scanner_service.dart';
import '../services/audio_player_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final FileScannerService _fileScannerService = FileScannerService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  bool _isScanning = false;

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
      // Request multiple permissions that might be needed
      final List<Permission> permissions = [
        Permission.storage, // For older Android versions
        Permission.audio, // For Android 13+ audio access
        Permission.photos, // For Android 13+ image access (for album covers)
      ];

      final Map<Permission, PermissionStatus> statuses =
          await permissions.request();

      // Check if any of the permissions is granted
      return statuses[Permission.storage]?.isGranted == true ||
          statuses[Permission.audio]?.isGranted == true;
    } catch (e) {
      // If anything goes wrong, try a simpler approach
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return true;
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

    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _isScanning = true;
      });

      try {
        final musicList = await _fileScannerService.scanDirectory(result);
        setState(() {
          _isScanning = false;
        });

        // Update app state with music list and directory
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setMusicList(musicList);
        appState.setSelectedDirectory(result);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('找到 ${musicList.length} 个音乐文件')),
        );
      } catch (e) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描目录错误: $e')),
        );
      }
    }
  }

  // Filter music by category
  void _filterByCategory(BuildContext context, String category) {
    // Update app state with selected category
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('流韵'),
        actions: [
          IconButton(
            onPressed: _selectDirectory,
            icon: const Icon(Icons.folder_open),
            color: Colors.white,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
          ),
        ],
      ),
      body: Center(
        child: _isScanning
            ? const CircularProgressIndicator(color: Colors.red)
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20.0,
                  crossAxisSpacing: 20.0,
                  shrinkWrap: true,
                  children: [
                    _buildCategoryItem(Icons.music_note, '所有歌曲',
                        () => _filterByCategory(context, 'all')),
                    _buildCategoryItem(Icons.folder, '文件夹',
                        () => _filterByCategory(context, 'folders')),
                    _buildCategoryItem(Icons.album, '专辑',
                        () => _filterByCategory(context, 'albums')),
                    _buildCategoryItem(Icons.person, '歌手',
                        () => _filterByCategory(context, 'artists')),
                    _buildCategoryItem(Icons.star, '加星',
                        () => _filterByCategory(context, 'favorites')),
                    _buildCategoryItem(Icons.playlist_play, '歌单',
                        () => _filterByCategory(context, 'playlists')),
                  ],
                ),
              ),
      ),
    );
  }

  // Build category item
  Widget _buildCategoryItem(
      IconData icon, String title, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.red.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
