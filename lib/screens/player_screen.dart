import 'dart:io';
import 'package:flutter/material.dart';
import '../models/music.dart';
import '../services/audio_player_service.dart';

class PlayerScreen extends StatelessWidget {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Album art section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Stack(
                  children: [
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.red[900]!,
                            Colors.black,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    // Album art with tap to return to songs list
                    ValueListenableBuilder<Music?>(
                      valueListenable: _audioPlayerService.currentMusicNotifier,
                      builder: (context, currentMusic, child) {
                        return GestureDetector(
                          onTap: () {
                            // Navigate back to songs list page
                            Navigator.pop(context);
                          },
                          child: Center(
                            child: currentMusic?.coverPath != null
                                ? Image.file(
                                    File(currentMusic!.coverPath!),
                                    width: 300,
                                    height: 300,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _defaultAlbumArt(),
                                  )
                                : _defaultAlbumArt(),
                          ),
                        );
                      },
                    ),

                    // Song title and artist
                    ValueListenableBuilder<Music?>(
                      valueListenable: _audioPlayerService.currentMusicNotifier,
                      builder: (context, currentMusic, child) {
                        return Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                currentMusic?.title ?? 'No Song Playing',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentMusic?.artist ?? '',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Equalizer button and audio info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.equalizer),
                    color: Colors.white,
                  ),
                  Text(
                    'FFMPEG AUDIO 48 KHZ',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.volume_up),
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            // Seek bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: ValueListenableBuilder<Duration>(
                valueListenable: _audioPlayerService.positionNotifier,
                builder: (context, position, child) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: _audioPlayerService.durationNotifier,
                    builder: (context, duration, child) {
                      return Column(
                        children: [
                          Slider(
                            value: position.inSeconds.toDouble(),
                            max: duration.inSeconds.toDouble(),
                            onChanged: (value) {
                              _audioPlayerService
                                  .seek(Duration(seconds: value.toInt()));
                            },
                            activeColor: Colors.red,
                            inactiveColor: Colors.grey[700],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Playback controls
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.skip_previous),
                    color: Colors.white,
                    iconSize: 30,
                  ),
                  IconButton(
                    onPressed: () => _audioPlayerService.previous(),
                    icon: const Icon(Icons.fast_rewind),
                    color: Colors.white,
                    iconSize: 30,
                  ),

                  // Play/Pause button
                  GestureDetector(
                    onTap: () => _audioPlayerService.togglePlayPause(),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        shape: BoxShape.circle,
                      ),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _audioPlayerService.isPlayingNotifier,
                        builder: (context, isPlaying, child) {
                          return Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 50,
                          );
                        },
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () => _audioPlayerService.next(),
                    icon: const Icon(Icons.fast_forward),
                    color: Colors.white,
                    iconSize: 30,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.skip_next),
                    color: Colors.white,
                    iconSize: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Default album art
  Widget _defaultAlbumArt() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 100,
      ),
    );
  }

  // Format duration to mm:ss
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}