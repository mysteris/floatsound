import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/music.dart';
import '../models/app_state.dart';
import '../services/audio_player_service.dart';
import 'category_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 1.0).animate(_fadeController);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleVolumeBar() {
    // Instead of showing app volume bar, trigger system volume control
    // This will show the system's native volume adjustment UI
    _audioPlayerService.showSystemVolumeControl();
  }

  // Handle swipe animation
  Future<void> _handleSwipeAnimation(bool isUpSwipe) async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    // Fade out
    await _fadeController.animateTo(0.0,
        duration: const Duration(milliseconds: 150));

    // Change song
    if (isUpSwipe) {
      _audioPlayerService.previous();
    } else {
      _audioPlayerService.next();
    }

    // Small delay to let the song change
    await Future.delayed(const Duration(milliseconds: 100));

    // Fade in
    await _fadeController.animateTo(1.0,
        duration: const Duration(milliseconds: 150));

    setState(() {
      _isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main player content
          SafeArea(
            child: Column(
              children: [
                // Album art and song info section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Album art with tap to return to songs list
                        ValueListenableBuilder<Music?>(
                          valueListenable:
                              _audioPlayerService.currentMusicNotifier,
                          builder: (context, currentMusic, child) {
                            return GestureDetector(
                              onTap: () {
                                // Navigate back to songs list page
                                Navigator.pop(context);
                              },
                              onVerticalDragEnd: (details) {
                                // Handle vertical swipe gestures for song switching
                                if (details.primaryVelocity != null &&
                                    !_isAnimating) {
                                  if (details.primaryVelocity! < 0) {
                                    // Up swipe - previous song with animation
                                    _handleSwipeAnimation(true);
                                  } else if (details.primaryVelocity! > 0) {
                                    // Down swipe - next song with animation
                                    _handleSwipeAnimation(false);
                                  }
                                }
                              },
                              child: AnimatedBuilder(
                                animation: _fadeAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: currentMusic?.coverPath != null
                                        ? Image.file(
                                            File(currentMusic!.coverPath!),
                                            width: 280,
                                            height: 280,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _defaultAlbumArt(),
                                          )
                                        : _defaultAlbumArt(),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        const SizedBox(
                            height: 40), // Space between album and text

                        // Song title and artist
                        ValueListenableBuilder<Music?>(
                          valueListenable:
                              _audioPlayerService.currentMusicNotifier,
                          builder: (context, currentMusic, child) {
                            return GestureDetector(
                              onVerticalDragEnd: (details) {
                                // Handle vertical swipe gestures for song switching
                                if (details.primaryVelocity != null &&
                                    !_isAnimating) {
                                  if (details.primaryVelocity! < 0) {
                                    // Up swipe - previous song with animation
                                    _handleSwipeAnimation(true);
                                  } else if (details.primaryVelocity! > 0) {
                                    // Down swipe - next song with animation
                                    _handleSwipeAnimation(false);
                                  }
                                }
                              },
                              child: AnimatedBuilder(
                                animation: _fadeAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          currentMusic?.title ??
                                              'No Song Playing',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.clip,
                                        ),
                                        const SizedBox(height: 20),
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
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Favorite button and audio info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Consumer<AppState>(
                        builder: (context, appState, child) {
                          final currentMusic =
                              _audioPlayerService.currentMusicNotifier.value;
                          final isFavorite = currentMusic != null &&
                              appState.isFavorite(currentMusic.id);

                          return IconButton(
                            onPressed: () {
                              if (currentMusic != null) {
                                appState.toggleFavorite(currentMusic.id);
                              }
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                            ),
                          );
                        },
                      ),
                      Text(
                        'FFMPEG AUDIO 48 KHZ',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      // Volume control button
                      IconButton(
                        onPressed: _toggleVolumeBar,
                        icon: const Icon(Icons.volume_up,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),

                // Seek bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Play mode button (first button)
                      IconButton(
                        onPressed: () {
                          _audioPlayerService.togglePlayMode();
                          setState(() {}); // Refresh UI
                        },
                        icon: Icon(
                          _audioPlayerService.getPlayModeIcon(),
                          color: Colors.white,
                        ),
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
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: ValueListenableBuilder<bool>(
                            valueListenable:
                                _audioPlayerService.isPlayingNotifier,
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
                      // Playlist button (last button)
                      IconButton(
                        onPressed: () {
                          final appState =
                              Provider.of<AppState>(context, listen: false);
                          final currentMusic = _audioPlayerService.currentMusic;

                          // Determine the best category to show based on current context
                          if (currentMusic != null) {
                            // If we have current music, try to show its album or artist
                            // For now, default to 'all' but we can enhance this later
                            appState.setSelectedCategory('all');
                          } else {
                            // If no current music, show all songs
                            appState.setSelectedCategory('all');
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.playlist_play),
                        color: Colors.white,
                        iconSize: 30,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Default album art
  Widget _defaultAlbumArt() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 90,
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
