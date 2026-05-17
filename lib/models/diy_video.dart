class DiyVideo {
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String videoUrl;
  final String difficulty;
  final String duration;
  final String views;
  final bool beginnerFriendly;

  const DiyVideo({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.difficulty,
    required this.duration,
    required this.views,
    required this.beginnerFriendly,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'channelName': channelName,
    'thumbnailUrl': thumbnailUrl,
    'videoUrl': videoUrl,
    'difficulty': difficulty,
    'duration': duration,
    'views': views,
    'beginnerFriendly': beginnerFriendly,
  };

  factory DiyVideo.fromJson(Map<String, dynamic> j) => DiyVideo(
    id:              j['id']              as String,
    title:           j['title']           as String,
    channelName:     j['channelName']     as String,
    thumbnailUrl:    j['thumbnailUrl']    as String? ?? '',
    videoUrl:        j['videoUrl']        as String,
    difficulty:      j['difficulty']      as String,
    duration:        j['duration']        as String,
    views:           j['views']           as String,
    beginnerFriendly: j['beginnerFriendly'] as bool? ?? false,
  );

  DiyVideo copyWith({bool? saved}) => DiyVideo(
    id:              id,
    title:           title,
    channelName:     channelName,
    thumbnailUrl:    thumbnailUrl,
    videoUrl:        videoUrl,
    difficulty:      difficulty,
    duration:        duration,
    views:           views,
    beginnerFriendly: beginnerFriendly,
  );
}
