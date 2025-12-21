class AlbumGroup {
  final String artist;
  final String album;
  final List<dynamic> songs;
  final String? coverPath;

  AlbumGroup({
    required this.artist,
    required this.album,
    required this.songs,
    this.coverPath,
  });
}