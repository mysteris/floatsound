import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/artist_group.dart';
import '../models/app_state.dart';
import '../models/music.dart';
import '../services/audio_player_service.dart';
import 'player_screen.dart';

class ArtistSongsScreen extends StatelessWidget {
  final ArtistGroup artist;
  
  const ArtistSongsScreen({super.key, required this.artist});

  // Play music with error handling
  void _playMusic(BuildContext context, AudioPlayerService audioPlayerService,
      List<Music> musicList, int index) async {
    try {
      await audioPlayerService.setPlaylist(musicList, startIndex: index);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PlayerScreen()),
      );
    } catch (e) {
      print('Playback error: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DSF和APE格式暂不支持播放，建议转换为FLAC或WAV格式'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = AudioPlayerService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(artist.artist),
            Text(
              '${artist.songs.length}首歌曲 · ${artist.albumCount}专辑',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: artist.songs.length,
        itemBuilder: (context, index) {
          final music = artist.songs[index] as Music;
          return _buildMusicListItem(context, music, artist.songs.cast<Music>(), index, audioPlayerService);
        },
      ),
    );
  }

  // Build music list item with favorite toggle
  Widget _buildMusicListItem(BuildContext context, Music music, List<Music> musicList, int index, AudioPlayerService audioPlayerService) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isFavorite = appState.isFavorite(music.id);
        return ListTile(
          leading: const Icon(Icons.music_note, color: Colors.red),
          title: Text(
            music.title,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '${music.artist} - ${music.album}',
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  appState.toggleFavorite(music.id);
                },
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.yellow : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () {
                  _playMusic(context, audioPlayerService, musicList, index);
                },
                icon: const Icon(Icons.play_arrow, color: Colors.red),
              ),
            ],
          ),
          onTap: () {
            _playMusic(context, audioPlayerService, musicList, index);
          },
        );
      },
    );
  }
}