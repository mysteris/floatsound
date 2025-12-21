import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music.dart';

class PersistenceService {
  static final PersistenceService _instance = PersistenceService._internal();
  factory PersistenceService() => _instance;

  PersistenceService._internal();

  // Keys for shared preferences
  static const String _selectedDirectoryKey = 'selected_directory';
  static const String _musicListKey = 'music_list';
  static const String _favoritesKey = 'favorites';

  // Save selected directory path to shared preferences
  Future<void> saveSelectedDirectory(String directoryPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedDirectoryKey, directoryPath);
  }

  // Load selected directory path from shared preferences
  Future<String?> loadSelectedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedDirectoryKey);
  }

  // Save music list to shared preferences
  Future<void> saveMusicList(List<Music> musicList) async {
    final prefs = await SharedPreferences.getInstance();
    final musicListJson = musicList.map((music) => music.toJson()).toList();
    await prefs.setString(_musicListKey, json.encode(musicListJson));
  }

  // Load music list from shared preferences
  Future<List<Music>> loadMusicList() async {
    final prefs = await SharedPreferences.getInstance();
    final musicListJson = prefs.getString(_musicListKey);
    if (musicListJson == null) {
      return [];
    }
    final List<dynamic> musicListMap = json.decode(musicListJson);
    return musicListMap.map((musicMap) => Music.fromJson(musicMap)).toList();
  }

  // Save favorites to shared preferences
  Future<void> saveFavorites(List<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey, json.encode(favoriteIds));
  }

  // Load favorites from shared preferences
  Future<List<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    if (favoritesJson == null) {
      return [];
    }
    final List<dynamic> favoritesList = json.decode(favoritesJson);
    return favoritesList.cast<String>();
  }

  // Clear all saved data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedDirectoryKey);
    await prefs.remove(_musicListKey);
    await prefs.remove(_favoritesKey);
  }
}