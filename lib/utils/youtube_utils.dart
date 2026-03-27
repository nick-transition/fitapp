import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubeUtils {
  /// Extracts the YouTube video ID from various YouTube URL formats.
  /// 
  /// Supports:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/shorts/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  /// - https://www.youtube.com/v/VIDEO_ID
  /// - https://www.youtube.com/live/VIDEO_ID
  /// - https://music.youtube.com/watch?v=VIDEO_ID
  static String? getYouTubeId(String? url) {
    if (url == null || url.isEmpty) return null;

    final cleanUrl = url.trim();

    try {
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null) return null;

      // Handle common path-based IDs
      if (uri.pathSegments.isNotEmpty) {
        // shorts, live, v, embed
        final segments = ['shorts', 'live', 'v', 'embed'];
        for (final segment in segments) {
          final index = uri.pathSegments.indexOf(segment);
          if (index >= 0 && index < uri.pathSegments.length - 1) {
            return uri.pathSegments[index + 1];
          }
        }
      }

      // If it's just the ID
      if (!cleanUrl.contains('/') && cleanUrl.length == 11) {
        return cleanUrl;
      }

      // Fallback to library
      final id = YoutubePlayerController.convertUrlToId(cleanUrl);
      if (id == null || id.isEmpty) {
        // Manual fallback for some music.youtube.com or other variants
        if (uri.queryParameters.containsKey('v')) {
          return uri.queryParameters['v'];
        }
        return null;
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  /// Returns a canonical YouTube URL for a given URL or ID.
  static String? normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return url;
    final id = getYouTubeId(url);
    if (id == null) return url;
    return 'https://www.youtube.com/watch?v=$id';
  }

  /// Checks if a URL is a YouTube URL.
  static bool isYouTubeUrl(String? url) {
    return getYouTubeId(url) != null;
  }
}
