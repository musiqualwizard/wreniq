import '../models/diy_video.dart';

// Generates smart YouTube search URLs from vehicle + part data.
// Phase 2: replace mock cards with YouTube Data API v3 results.
class DiyVideoService {
  // Returns a direct YouTube search URL for the given parameters.
  static String buildSearchUrl({
    required String year,
    required String make,
    required String model,
    required String partName,
    String action = 'replacement',
  }) {
    final query = Uri.encodeComponent('$year $make $model $partName $action');
    return 'https://www.youtube.com/results?search_query=$query';
  }

  // Returns 4 mock video cards. Each videoUrl is a live YouTube search query
  // that will surface real results — no fake video IDs.
  static List<DiyVideo> forScan({
    required String year,
    required String make,
    required String model,
    required String partName,
    String difficulty = 'Intermediate',
  }) {
    final v = '$year $make $model'.trim();

    String yt(String terms) =>
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(terms)}';

    return [
      DiyVideo(
        id:              '1',
        title:           '$partName Replacement — $v (Step by Step)',
        channelName:     'ChrisFix',
        thumbnailUrl:    '',
        videoUrl:        yt('$v $partName replacement chrisfix'),
        difficulty:      difficulty,
        duration:        '15–25 min',
        views:           'YouTube search',
        beginnerFriendly: difficulty == 'Beginner',
      ),
      DiyVideo(
        id:              '2',
        title:           'How to Replace $partName on $make $model',
        channelName:     'Scotty Kilmer',
        thumbnailUrl:    '',
        videoUrl:        yt('$make $model $partName how to scotty kilmer'),
        difficulty:      'Beginner',
        duration:        '10–20 min',
        views:           'YouTube search',
        beginnerFriendly: true,
      ),
      DiyVideo(
        id:              '3',
        title:           '$partName DIY — Mistakes to Avoid',
        channelName:     '1A Auto Parts',
        thumbnailUrl:    '',
        videoUrl:        yt('$partName replacement mistakes avoid 1a auto'),
        difficulty:      'Intermediate',
        duration:        '20–35 min',
        views:           'YouTube search',
        beginnerFriendly: false,
      ),
      DiyVideo(
        id:              '4',
        title:           'Pro Tips: $make $model $partName',
        channelName:     'EricTheCarGuy',
        thumbnailUrl:    '',
        videoUrl:        yt('$make $model $partName ericthecarGuy'),
        difficulty:      'Advanced',
        duration:        '30–45 min',
        views:           'YouTube search',
        beginnerFriendly: false,
      ),
    ];
  }
}
