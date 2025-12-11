import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/music.dart';
import '../services/audio_player_service.dart';
import 'player_screen.dart';
import 'tag_editor_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

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
        title: const Text('歌曲列表'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            color: Colors.white,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final filteredMusicList = appState.filteredMusicList;

          if (filteredMusicList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, size: 60, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    '没有找到音乐',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '请选择音乐目录开始扫描',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredMusicList.length,
            itemBuilder: (context, index) {
              final music = filteredMusicList[index];
              return ListTile(
                leading: music.coverPath != null
                    ? Image.file(
                        File(music.coverPath!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.music_note, color: Colors.red),
                title: Text(
                  music.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${music.artist} - ${music.album}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: IconButton(
                  onPressed: () {
                    // Play music with error handling
                    _playMusic(
                        context, audioPlayerService, filteredMusicList, index);
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.red),
                ),
                onTap: () {
                  // Play music with error handling
                  _playMusic(
                      context, audioPlayerService, filteredMusicList, index);
                },
              );
            },
          );
        },
      ),
    );
  }
}
