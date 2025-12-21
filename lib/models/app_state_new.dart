import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/persistence_service.dart';
import 'music.dart';
import 'album_group.dart';
import 'artist_group.dart';
import 'folder_group.dart';

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
  
  // Favorites list
  List<String> _favoriteMusicIds = [];
  List<String> get favoriteMusicIds => _favoriteMusicIds;
  
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
    
    // Load favorites
    final favorites = await _persistenceService.loadFavorites();
    _favoriteMusicIds = favorites;
    
    notifyListeners();
  }
  
  // Save data to storage
  Future<void> saveData() async {
    if (_selectedDirectory != null) {
      await _persistenceService.saveSelectedDirectory(_selectedDirectory!);
    }
    await _persistenceService.saveMusicList(_musicList);
    await _persistenceService.saveFavorites(_favoriteMusicIds);
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
  
  // Toggle favorite status
  void toggleFavorite(String musicId) {
    if (_favoriteMusicIds.contains(musicId)) {
      _favoriteMusicIds.remove(musicId);
    } else {
      _favoriteMusicIds.add(musicId);
    }
    notifyListeners();
    // Save to storage
    _persistenceService.saveFavorites(_favoriteMusicIds);
  }
  
  // Check if music is favorite
  bool isFavorite(String musicId) {
    return _favoriteMusicIds.contains(musicId);
  }
  
  // Get unique albums
  List<AlbumGroup> get albums {
    final albumMap = <String, List<Music>>{};
    
    for (final music in _musicList) {
      final albumKey = '${music.artist}|${music.album}';
      if (!albumMap.containsKey(albumKey)) {
        albumMap[albumKey] = [];
      }
      albumMap[albumKey]!.add(music);
    }
    
    return albumMap.entries.map((entry) {
      final parts = entry.key.split('|');
      final artist = parts[0];
      final album = parts[1];
      return AlbumGroup(
        artist: artist,
        album: album,
        songs: entry.value,
        coverPath: entry.value.first.coverPath,
      );
    }).toList();
  }
  
  // Get unique artists
  List<ArtistGroup> get artists {
    final artistMap = <String, List<Music>>{};
    
    for (final music in _musicList) {
      if (!artistMap.containsKey(music.artist)) {
        artistMap[music.artist] = [];
      }
      artistMap[music.artist]!.add(music);
    }
    
    return artistMap.entries.map((entry) {
      return ArtistGroup(
        artist: entry.key,
        songs: entry.value,
        albumCount: entry.value.map((m) => m.album).toSet().length,
      );
    }).toList();
  }
  
  // Get unique folders
  List<FolderGroup> get folders {
    final folderMap = <String, List<Music>>{};
    
    for (final music in _musicList) {
      final folderPath = File(music.filePath).parent.path;
      if (!folderMap.containsKey(folderPath)) {
        folderMap[folderPath] = [];
      }
      folderMap[folderPath]!.add(music);
    }
    
    return folderMap.entries.map((entry) {
      return FolderGroup(
        path: entry.key,
        songs: entry.value,
        name: entry.key.split('/').last.split('\\').last,
      );
    }).toList();
  }
  
  // Filter music by selected category
  List<Music> get filteredMusicList {
    switch (_selectedCategory) {
      case 'all':
        return _musicList;
      case 'albums':
        return _musicList; // Return all songs for now, will be handled in UI
      case 'artists':
        return _musicList; // Return all songs for now, will be handled in UI
      case 'favorites':
        return _musicList.where((music) => isFavorite(music.id)).toList();
      case 'playlists':
        return []; // Not implemented yet
      case 'folders':
        return _musicList; // Return all songs for now, will be handled in UI
      default:
        return _musicList;
    }
  }
}