import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import '../models/app_state.dart';
import '../models/music.dart';
import '../models/album_group.dart';
import '../models/artist_group.dart';
import '../models/folder_group.dart';
import '../services/audio_player_service.dart';
import 'player_screen.dart';
import 'album_songs_screen.dart';
import 'artist_songs_screen.dart';
import 'folder_songs_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // Format duration to mm:ss
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Play music with error handling
  void _playMusic(BuildContext context, AudioPlayerService audioPlayerService,
      List<Music> musicList, int index) async {
    try {
      await audioPlayerService.setPlaylist(musicList, startIndex: index);
      // Automatically start playing the selected song
      await audioPlayerService.play();
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      }
    } catch (e) {
      debugPrint('Playback error: $e');
      // Show error message to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DSF和APE格式暂不支持播放，建议转换为FLAC或WAV格式'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Get category title based on selected category
  String _getCategoryTitle(String category) {
    switch (category) {
      case 'all':
        return '所有歌曲';
      case 'albums':
        return '专辑';
      case 'artists':
        return '歌手';
      case 'favorites':
        return '加星';
      case 'folders':
        return '文件夹';
      default:
        return '歌曲列表';
    }
  }

  // Build content based on selected category
  Widget _buildContentByCategory(BuildContext context, AppState appState, AudioPlayerService audioPlayerService) {
    switch (appState.selectedCategory) {
      case 'all':
        return _buildMusicList(context, appState.sortedMusicList, audioPlayerService);
      case 'favorites':
        return _buildMusicList(context, appState.filteredMusicList, audioPlayerService);
      case 'albums':
        return _buildAlbumList(context, appState.sortedAlbums, audioPlayerService);
      case 'artists':
        return _buildArtistList(context, appState.sortedArtists, audioPlayerService);
      case 'folders':
        return _buildFolderList(context, appState.sortedFolders, audioPlayerService);
      default:
        return _buildMusicList(context, appState.filteredMusicList, audioPlayerService);
    }
  }

  // Build music list (for 'all' and 'favorites' categories)
  Widget _buildMusicList(BuildContext context, List<Music> musicList, AudioPlayerService audioPlayerService) {
    if (musicList.isEmpty) {
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
      itemCount: musicList.length,
      itemBuilder: (context, index) {
        final music = musicList[index];
        return _buildMusicListItem(context, music, musicList, index, audioPlayerService);
      },
    );
  }

  // Build music list item with favorite toggle
  Widget _buildMusicListItem(BuildContext context, Music music, List<Music> musicList, int index, AudioPlayerService audioPlayerService) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isFavorite = appState.isFavorite(music.id);
        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: music.coverPath != null && File(music.coverPath!).existsSync()
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
            music.title.length > 30 ? music.title.substring(0, 30) : music.title,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.clip,
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

  // Build album list
  Widget _buildAlbumList(BuildContext context, List<AlbumGroup> albums, AudioPlayerService audioPlayerService) {
    if (albums.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album, size: 60, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              '没有找到专辑',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return ListTile(
          leading: album.coverPath != null
              ? Image.file(
                  File(album.coverPath!),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.album, color: Colors.red),
          title: Text(
            album.album,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            album.artist,
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: Text(
            '${album.songs.length}首',
            style: TextStyle(color: Colors.grey[400]),
          ),
          onTap: () {
            // Navigate to album songs
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumSongsScreen(album: album),
              ),
            );
          },
        );
      },
    );
  }

  // Build artist list
  Widget _buildArtistList(BuildContext context, List<ArtistGroup> artists, AudioPlayerService audioPlayerService) {
    if (artists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 60, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              '没有找到歌手',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          leading: const Icon(Icons.person, color: Colors.red, size: 50),
          title: Text(
            artist.artist,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '${artist.songs.length}首 · ${artist.albumCount}专辑',
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          onTap: () {
            // Navigate to artist songs
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArtistSongsScreen(artist: artist),
              ),
            );
          },
        );
      },
    );
  }

  // Build folder list
  Widget _buildFolderList(BuildContext context, List<FolderGroup> folders, AudioPlayerService audioPlayerService) {
    if (folders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 60, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              '没有找到文件夹',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return ListTile(
          leading: const Icon(Icons.folder, color: Colors.red, size: 50),
          title: Text(
            folder.name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            folder.path,
            style: TextStyle(color: Colors.grey[400]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${folder.songs.length}首',
            style: TextStyle(color: Colors.grey[400]),
          ),
          onTap: () {
            // Navigate to folder songs
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FolderSongsScreen(folder: folder),
              ),
            );
          },
        );
      },
    );
  }

  // Build search results
  Widget _buildSearchResults(BuildContext context, AppState appState, AudioPlayerService audioPlayerService) {
    // Filter music based on search query
    final searchResults = appState.filteredMusicList.where((music) {
      final titleMatch = music.title.toLowerCase().contains(_searchQuery);
      final artistMatch = music.artist.toLowerCase().contains(_searchQuery);
      final albumMatch = music.album.toLowerCase().contains(_searchQuery);
      return titleMatch || artistMatch || albumMatch;
    }).toList();

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              '没有找到包含"$_searchQuery"的内容',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              '试试其他关键词',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '找到 ${searchResults.length} 个结果',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
        Expanded(
          child: _buildMusicList(context, searchResults, audioPlayerService),
        ),
      ],
    );
  }

  // Build alphabetical music list with side letter selector
  Widget _buildAlphabeticalMusicList(BuildContext context, AppState appState, AudioPlayerService audioPlayerService) {
    final musicByLetter = appState.getMusicByLetter();
    final availableLetters = appState.getAvailableLetters();
    
    if (availableLetters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 60, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              '没有找到歌曲',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    // Create a ScrollController for smooth scrolling
    final scrollController = ScrollController();
    
    // Calculate positions for each letter section
    final sectionPositions = <String, double>{};
    double currentPosition = 0;
    
    return Row(
      children: [
        // Main content area
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Build sections for each letter
              for (final letter in availableLetters)
                Builder(
                  builder: (context) {
                    final songs = musicByLetter[letter] ?? [];
                    sectionPositions[letter] = currentPosition;
                    currentPosition += (songs.length * 64.0) + 32.0; // Compact height
                    
                    return SliverStickyHeader(
                      header: Container(
                        height: 32,
                        color: Colors.grey[850],
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          letter,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final music = songs[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: music.coverPath != null && File(music.coverPath!).existsSync()
                                      ? Image.file(
                                          File(music.coverPath!),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                        ),
                                ),
                                title: Text(
                                  music.title.length > 30 
                                    ? music.title.substring(0, 30) 
                                    : music.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                ),
                                subtitle: Text(
                                  music.artist,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  _formatDuration(music.duration),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                                onTap: () {
                                  // Find the index of this music in the sorted list
                                  final sortedMusicList = appState.sortedMusicList;
                                  final musicIndex = sortedMusicList.indexOf(music);
                                  if (musicIndex != -1) {
                                    _playMusic(context, audioPlayerService, sortedMusicList, musicIndex);
                                  }
                                },
                              ),
                            );
                          },
                          childCount: songs.length,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        
        // Side letter selector
        Container(
          width: 32,
          color: Colors.grey[900],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Letter selector with tap and swipe support
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  // Calculate which letter is being swiped over
                  final renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.globalPosition);
                  final letterIndex = (localPosition.dy / 16).clamp(0, availableLetters.length - 1).toInt();
                  if (letterIndex >= 0 && letterIndex < availableLetters.length) {
                    final selectedLetter = availableLetters[letterIndex];
                    final position = sectionPositions[selectedLetter];
                    if (position != null) {
                      scrollController.animateTo(
                        position,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                },
                child: Column(
                  children: availableLetters.map((letter) {
                    return GestureDetector(
                      onTap: () {
                        final position = sectionPositions[letter];
                        if (position != null) {
                          scrollController.animateTo(
                            position,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 16,
                        alignment: Alignment.center,
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = AudioPlayerService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索歌曲、专辑或艺术家...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (query) {
                  // Handle search submission (return key)
                  if (query.isNotEmpty) {
                    _onSearchChanged(query);
                  }
                },
              )
            : Consumer<AppState>(
                builder: (context, appState, child) {
                  final title = _getCategoryTitle(appState.selectedCategory);
                  return Text(title);
                },
              ),
        actions: [
          if (_isSearching)
            IconButton(
              onPressed: _stopSearch,
              icon: const Icon(Icons.close),
              color: Colors.white,
            )
          else
            IconButton(
              onPressed: _startSearch,
              icon: const Icon(Icons.search),
              color: Colors.white,
            ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (_isSearching && _searchQuery.isNotEmpty) {
            return _buildSearchResults(context, appState, audioPlayerService);
          } else {
            return _buildContentByCategory(context, appState, audioPlayerService);
          }
        },
      ),
    );
  }
}