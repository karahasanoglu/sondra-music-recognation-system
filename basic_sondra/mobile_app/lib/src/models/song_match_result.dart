class SongMatchResult {
  const SongMatchResult({
    required this.found,
    required this.message,
    this.songId,
    this.title,
    this.artist,
    this.score,
    this.previewUrl,
    this.albumCoverUrl,
  });

  final bool found;
  final String message;
  final int? songId;
  final String? title;
  final String? artist;
  final int? score;
  final String? previewUrl;
  final String? albumCoverUrl;

  factory SongMatchResult.fromJson(Map<String, dynamic> json) {
    final rawSongId = json['song_id'];
    final rawScore = json['score'];

    return SongMatchResult(
      found: json['found'] == true,
      message: (json['message'] ?? 'Beklenmeyen bir cevap geldi.').toString(),
      songId: rawSongId is num
          ? rawSongId.toInt()
          : int.tryParse(rawSongId?.toString() ?? ''),
      title: json['title']?.toString(),
      artist: json['artist']?.toString(),
      score: rawScore is num
          ? rawScore.toInt()
          : int.tryParse(rawScore?.toString() ?? ''),
      // These are injected later by our iTunes enrichment service natively
      previewUrl: json['previewUrl']?.toString(),
      albumCoverUrl: json['albumCoverUrl']?.toString(),
    );
  }

  SongMatchResult copyWith({
    bool? found,
    String? message,
    int? songId,
    String? title,
    String? artist,
    int? score,
    String? previewUrl,
    String? albumCoverUrl,
  }) {
    return SongMatchResult(
      found: found ?? this.found,
      message: message ?? this.message,
      songId: songId ?? this.songId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      score: score ?? this.score,
      previewUrl: previewUrl ?? this.previewUrl,
      albumCoverUrl: albumCoverUrl ?? this.albumCoverUrl,
    );
  }
}
