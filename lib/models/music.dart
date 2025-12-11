class Music {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final String? coverPath;
  final int duration;
  final String genre;
  final int year;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    this.coverPath,
    required this.duration,
    required this.genre,
    required this.year,
  });

  Music copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    String? coverPath,
    int? duration,
    String? genre,
    int? year,
  }) {
    return Music(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'filePath': filePath,
      'coverPath': coverPath,
      'duration': duration,
      'genre': genre,
      'year': year,
    };
  }

  factory Music.fromMap(Map<String, dynamic> map) {
    return Music(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      album: map['album'] ?? '',
      filePath: map['filePath'] ?? '',
      coverPath: map['coverPath'],
      duration: map['duration'] ?? 0,
      genre: map['genre'] ?? '',
      year: map['year'] ?? 0,
    );
  }
  
  // JSON serialization for shared_preferences
  Map<String, dynamic> toJson() {
    return toMap();
  }
  
  factory Music.fromJson(Map<String, dynamic> json) {
    return Music.fromMap(json);
  }
}
