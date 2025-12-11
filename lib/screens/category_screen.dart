import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/audio_player_service.dart';
import 'player_screen.dart';
import 'tag_editor_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    '没有找到音乐',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  const Text(
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
                    // Play music
                    audioPlayerService.setPlaylist(filteredMusicList, startIndex: index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlayerScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.red),
                ),
                onTap: () {
                  // Play music
                  audioPlayerService.setPlaylist(filteredMusicList, startIndex: index);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PlayerScreen()),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}