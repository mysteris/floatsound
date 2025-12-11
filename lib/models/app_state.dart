
import 'package:flutter/foundation.dart';
import '../services/persistence_service.dart';
import 'music.dart';

class AppState with ChangeNotifier {
  // Currently selected category
  String _selectedCategory = 'all';
  String get selectedCategory => _selectedCategory;
  
  // Music list
  List<Music> _musicList = [];
  List<Music> get musicList => _musicList;
  
  // Selected directory path
  String? _selectedDirectory;
  String? get selectedDirectory => _selectedDirectory;
  
  // Persistence service
  final _persistenceService = PersistenceService();
  
  // Load data from storage
  Future<void> loadData() async {
    // Load selected directory
    final directory = await _persistenceService.loadSelectedDirectory();
    if (directory != null) {
      _selectedDirectory = directory;
    }
    
    // Load music list
    final musicList = await _persistenceService.loadMusicList();
    if (musicList.isNotEmpty) {
      _musicList = musicList;
    }
    
    notifyListeners();
  }
  
  // Save data to storage
  Future<void> saveData() async {
    if (_selectedDirectory != null) {
      await _persistenceService.saveSelectedDirectory(_selectedDirectory!);
    }
    await _persistenceService.saveMusicList(_musicList);
  }
  
  // Update selected category
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  // Update music list
  void setMusicList(List<Music> musicList) {
    _musicList = musicList;
    notifyListeners();
    // Save to storage
    _persistenceService.saveMusicList(musicList);
  }
  
  // Update selected directory
  void setSelectedDirectory(String? directory) {
    _selectedDirectory = directory;
    notifyListeners();
    // Save to storage
    if (directory != null) {
      _persistenceService.saveSelectedDirectory(directory);
    }
  }
  
  // Filter music by selected category
  List<Music> get filteredMusicList {
    switch (_selectedCategory) {
      case 'all':
        return _musicList;
      case 'albums':
        // For albums, we need to group by album
        // This is a simplified version - in a real app, we'd show album covers and allow tapping to see songs
        return _musicList;
      case 'artists':
        // For artists, we need to group by artist
        return _musicList;
      case 'favorites':
        // Return empty list for favorites since we haven't implemented favorite functionality yet
        return [];
      case 'playlists':
        // Return empty list for playlists since we haven't implemented playlist functionality yet
        return [];
      case 'folders':
        // For folders, we need to extract unique folders from file paths
        return _musicList;
      default:
        return _musicList;
    }
  }
}