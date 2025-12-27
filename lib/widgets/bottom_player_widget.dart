import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../screens/player_screen.dart';
import '../screens/category_screen.dart';
import '../models/app_state.dart';

class BottomPlayerWidget extends StatelessWidget {
  const BottomPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = AudioPlayerService();

    return ValueListenableBuilder<bool>(
      valueListenable: audioPlayerService.isPlayingNotifier,
      builder: (context, isPlaying, child) {
        return Container(
          height: 60,
          color: Colors.grey[900],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Album cover thumbnail, song title, and artist - with tap to navigate to player
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to player screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PlayerScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      // Album cover thumbnail
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child:
                            audioPlayerService.currentMusic?.coverPath != null && File(audioPlayerService.currentMusic!.coverPath!).existsSync()
                                ? Image.file(
                                    File(audioPlayerService
                                        .currentMusic!.coverPath!),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.music_note,
                                        color: Colors.white, size: 20),
                                  ),
                      ),
                      const SizedBox(width: 10),
                      // Song title and artist with width limit
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audioPlayerService.currentMusic?.title ??
                                  'No song playing',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              audioPlayerService.currentMusic?.artist ??
                                  'Unknown Artist',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Play button, next button
              Row(
                children: [
                  IconButton(
                    onPressed: () => audioPlayerService.togglePlayPause(),
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => audioPlayerService.next(),
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                  ),
                ],
              ),

              // Playlist button
              IconButton(
                onPressed: () {
                  // Get current category from AppState
                  final appState =
                      Provider.of<AppState>(context, listen: false);

                  // Navigate to category screen with current category
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.playlist_play, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
