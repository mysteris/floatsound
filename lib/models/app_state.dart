import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:pinyin/pinyin.dart' as pinyin;
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
  
  // Get sorted albums (0-9, A-Z, Chinese by initial consonant)
  List<AlbumGroup> get sortedAlbums {
    final sortedAlbums = List<AlbumGroup>.from(albums);
    sortedAlbums.sort((a, b) {
      // Get first character of album name
      final aFirst = a.album.isNotEmpty ? a.album[0] : '';
      final bFirst = b.album.isNotEmpty ? b.album[0] : '';
      
      // Define character priority with pinyin support for Chinese characters
      int getCharPriority(String char) {
        if (char.isEmpty) return 999;
        final code = char.codeUnitAt(0);
        
        // Numbers 0-9 (highest priority)
        if (code >= 48 && code <= 57) return code - 48;
        // Uppercase A-Z
        if (code >= 65 && code <= 90) return code - 65 + 10;
        // Lowercase a-z
        if (code >= 97 && code <= 122) return code - 97 + 36;
        // Chinese characters (will be sorted by pinyin)
        if (code >= 0x4E00 && code <= 0x9FFF) return 100;
        // Other characters (lowest priority)
        return 999;
      }
      
      final aPriority = getCharPriority(aFirst);
      final bPriority = getCharPriority(bFirst);
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // If same priority, handle special cases
      if (aPriority == 100) { // Both are Chinese characters
        final aPinyin = pinyin.PinyinHelper.getFirstWordPinyin(aFirst.toString());
        final bPinyin = pinyin.PinyinHelper.getFirstWordPinyin(bFirst.toString());
        return aPinyin.compareTo(bPinyin);
      }
      
      // If same priority and not Chinese, sort alphabetically
      return a.album.toLowerCase().compareTo(b.album.toLowerCase());
    });
    return sortedAlbums;
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
  
  // Get sorted artists (0-9, A-Z, Chinese by initial consonant)
  List<ArtistGroup> get sortedArtists {
    final sortedArtists = List<ArtistGroup>.from(artists);
    sortedArtists.sort((a, b) {
      // Get first character of artist name
      final aFirst = a.artist.isNotEmpty ? a.artist[0] : '';
      final bFirst = b.artist.isNotEmpty ? b.artist[0] : '';
      
      // Define character priority with pinyin support for Chinese characters
      int getCharPriority(String char) {
        if (char.isEmpty) return 999;
        final code = char.codeUnitAt(0);
        
        // Numbers 0-9 (highest priority)
        if (code >= 48 && code <= 57) return code - 48;
        // Uppercase A-Z
        if (code >= 65 && code <= 90) return code - 65 + 10;
        // Lowercase a-z
        if (code >= 97 && code <= 122) return code - 97 + 36;
        // Chinese characters (will be sorted by pinyin)
        if (code >= 0x4E00 && code <= 0x9FFF) return 100;
        // Other characters (lowest priority)
        return 999;
      }
      
      final aPriority = getCharPriority(aFirst);
      final bPriority = getCharPriority(bFirst);
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // If same priority, handle special cases
      if (aPriority == 100) { // Both are Chinese characters
        final aPinyin = pinyin.PinyinHelper.getFirstWordPinyin(aFirst.toString());
        final bPinyin = pinyin.PinyinHelper.getFirstWordPinyin(bFirst.toString());
        return aPinyin.compareTo(bPinyin);
      }
      
      // If same priority and not Chinese, sort alphabetically
      return a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
    });
    return sortedArtists;
  }
  
  // Get unique folders (excluding top-level directory)
  List<FolderGroup> get folders {
    final folderMap = <String, List<Music>>{};
    
    for (final music in _musicList) {
      final folderPath = File(music.filePath).parent.path;
      
      // Skip if this is the root selected directory
      if (_selectedDirectory != null && folderPath == _selectedDirectory) {
        continue;
      }
      
      if (!folderMap.containsKey(folderPath)) {
        folderMap[folderPath] = [];
      }
      folderMap[folderPath]!.add(music);
    }
    
    return folderMap.entries.map((entry) {
      // Get relative path from selected directory
      String folderName = entry.key.split('/').last.split('\\').last;
      if (_selectedDirectory != null) {
        final relativePath = entry.key.replaceFirst(_selectedDirectory!, '').trim();
        if (relativePath.isNotEmpty) {
          // Remove leading slash/backslash
          folderName = relativePath.replaceFirst(RegExp(r'^[\/]'), '');
          // If still contains path separators, show the relative structure
          if (folderName.contains('/') || folderName.contains('\\')) {
            folderName = folderName.replaceAll('\\', '/');
          }
        }
      }
      
      return FolderGroup(
        path: entry.key,
        songs: entry.value,
        name: folderName.isEmpty ? '根目录' : folderName,
      );
    }).toList();
  }
  
  // Get sorted folders (0-9, A-Z, Chinese by initial consonant)
  List<FolderGroup> get sortedFolders {
    final sortedFolders = List<FolderGroup>.from(folders);
    sortedFolders.sort((a, b) {
      // Get first character of folder name
      final aFirst = a.name.isNotEmpty ? a.name[0] : '';
      final bFirst = b.name.isNotEmpty ? b.name[0] : '';
      
      // Define character priority with pinyin support for Chinese characters
      int getCharPriority(String char) {
        if (char.isEmpty) return 999;
        final code = char.codeUnitAt(0);
        
        // Numbers 0-9 (highest priority)
        if (code >= 48 && code <= 57) return code - 48;
        // Uppercase A-Z
        if (code >= 65 && code <= 90) return code - 65 + 10;
        // Lowercase a-z
        if (code >= 97 && code <= 122) return code - 97 + 36;
        // Chinese characters (will be sorted by pinyin)
        if (code >= 0x4E00 && code <= 0x9FFF) return 100;
        // Other characters (lowest priority)
        return 999;
      }
      
      final aPriority = getCharPriority(aFirst);
      final bPriority = getCharPriority(bFirst);
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // If same priority, handle special cases
      if (aPriority == 100) { // Both are Chinese characters
        final aPinyin = pinyin.PinyinHelper.getFirstWordPinyin(aFirst.toString());
        final bPinyin = pinyin.PinyinHelper.getFirstWordPinyin(bFirst.toString());
        return aPinyin.compareTo(bPinyin);
      }
      
      // If same priority and not Chinese, sort alphabetically
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sortedFolders;
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

  // Get alphabetically sorted music list
  List<Music> get sortedMusicList {
    final sortedList = List<Music>.from(_musicList);
    sortedList.sort((a, b) {
      // Get first character of title
      final aFirst = a.title.isNotEmpty ? a.title[0] : '';
      final bFirst = b.title.isNotEmpty ? b.title[0] : '';
      
      // Define character priority with pinyin support for Chinese characters
      int getCharPriority(String char) {
        if (char.isEmpty) return 999;
        final code = char.codeUnitAt(0);
        
        // Numbers 0-9 (highest priority)
        if (code >= 48 && code <= 57) return code - 48;
        // Uppercase A-Z
        if (code >= 65 && code <= 90) return code - 65 + 10;
        // Lowercase a-z
        if (code >= 97 && code <= 122) return code - 97 + 36;
        // Chinese characters (will be sorted by pinyin)
        if (code >= 0x4E00 && code <= 0x9FFF) return 100;
        // Other characters (lowest priority)
        return 999;
      }
      
      final aPriority = getCharPriority(aFirst);
      final bPriority = getCharPriority(bFirst);
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // If same priority, handle special cases
      if (aPriority == 100) { // Both are Chinese characters
        final aPinyin = pinyin.PinyinHelper.getFirstWordPinyin(aFirst.toString());
        final bPinyin = pinyin.PinyinHelper.getFirstWordPinyin(bFirst.toString());
        return aPinyin.compareTo(bPinyin);
      }
      
      // If same priority and not Chinese, sort alphabetically
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return sortedList;
  }

  // Get available letters for indexing (only alphabet letters)
  List<String> getAvailableLetters() {
    if (_musicList.isEmpty) return [];
    
    final letters = <String>{};
    for (final music in _musicList) {
      if (music.title.isNotEmpty) {
        final firstChar = music.title[0].toUpperCase();
        // Only include alphabet letters A-Z
        if (firstChar.codeUnitAt(0) >= 65 && firstChar.codeUnitAt(0) <= 90) {
          letters.add(firstChar);
        }
      }
    }
    
    // Sort letters: A-Z
    final sortedLetters = letters.toList();
    sortedLetters.sort((a, b) {
      final aCode = a.codeUnitAt(0);
      final bCode = b.codeUnitAt(0);
      return aCode.compareTo(bCode);
    });
    
    return sortedLetters;
  }

  // Get available letters for indexing (all characters for complete sorting)
  List<String> getAllAvailableLetters() {
    if (_musicList.isEmpty) return [];
    
    final letters = <String>{};
    for (final music in _musicList) {
      if (music.title.isNotEmpty) {
        final firstChar = music.title[0].toUpperCase();
        letters.add(firstChar);
      }
    }
    
    // Sort letters: numbers, A-Z, then Chinese characters by pinyin initial consonant
    final sortedLetters = letters.toList();
    sortedLetters.sort((a, b) {
      final aCode = a.codeUnitAt(0);
      final bCode = b.codeUnitAt(0);
      
      // Numbers first (0-9)
      if (aCode >= 48 && aCode <= 57) {
        if (bCode >= 48 && bCode <= 57) {
          return aCode.compareTo(bCode);
        }
        return -1; // Numbers come first
      }
      
      // A-Z second
      if (aCode >= 65 && aCode <= 90) {
        if (bCode >= 65 && bCode <= 90) {
          return aCode.compareTo(bCode);
        }
        if (bCode >= 48 && bCode <= 57) return 1; // A-Z after numbers
        return -1; // A-Z before Chinese
      }
      
      // Chinese characters: sort by pinyin initial consonant
      if (aCode >= 0x4E00 && aCode <= 0x9FFF) { // Chinese character range
        if (bCode >= 48 && bCode <= 57) return 1; // Chinese after numbers
        if (bCode >= 65 && bCode <= 90) return 1; // Chinese after A-Z
        
        // Both are Chinese characters, sort by pinyin initial
        final aPinyin = pinyin.PinyinHelper.getFirstWordPinyin(a);
        final bPinyin = pinyin.PinyinHelper.getFirstWordPinyin(b);
        return aPinyin.compareTo(bPinyin);
      }
      
      // Other characters (non-Chinese, non-alphabet, non-number)
      if (bCode >= 48 && bCode <= 57) return 1;
      if (bCode >= 65 && bCode <= 90) return 1;
      if (bCode >= 0x4E00 && bCode <= 0x9FFF) return 1; // Other characters after Chinese
      return aCode.compareTo(bCode);
    });
    
    return sortedLetters;
  }

  // Get music grouped by first letter
  Map<String, List<Music>> getMusicByLetter() {
    final grouped = <String, List<Music>>{};
    
    for (final music in sortedMusicList) {
      if (music.title.isNotEmpty) {
        final firstLetter = music.title[0].toUpperCase();
        if (!grouped.containsKey(firstLetter)) {
          grouped[firstLetter] = [];
        }
        grouped[firstLetter]!.add(music);
      }
    }
    
    return grouped;
  }
}