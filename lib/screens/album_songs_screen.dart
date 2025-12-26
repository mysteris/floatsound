import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album_group.dart';
import '../models/app_state.dart';
import '../models/music.dart';
import '../services/audio_player_service.dart';
import 'player_screen.dart';

class AlbumSongsScreen extends StatelessWidget {
  final AlbumGroup album;

  const AlbumSongsScreen({super.key, required this.album});

  // Play music with error handling
  void _playMusic(BuildContext context, AudioPlayerService audioPlayerService,
      List<Music> musicList, int index) async {
    try {
      await audioPlayerService.setPlaylist(musicList, startIndex: index);
      // Automatically start playing the selected song
      await audioPlayerService.play();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PlayerScreen()),
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
            Text(album.album),
            Text(
              album.artist,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: album.songs.length,
        itemBuilder: (context, index) {
          final music = album.songs[index] as Music;
          return _buildMusicListItem(context, music, album.songs.cast<Music>(),
              index, audioPlayerService);
        },
      ),
    );
  }

  // Build music list item with favorite toggle
  Widget _buildMusicListItem(BuildContext context, Music music,
      List<Music> musicList, int index, AudioPlayerService audioPlayerService) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isFavorite = appState.isFavorite(music.id);
        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: music.coverPath != null &&
                    File(music.coverPath!).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(music.coverPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.music_note,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.music_note,
                    color: Colors.red,
                    size: 32,
                  ),
          ),
          title: Text(
            music.title,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.left,
          ),
          subtitle: Text(
            '${music.artist} - ${music.album}',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.left,
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
