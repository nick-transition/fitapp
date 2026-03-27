import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/utils/youtube_utils.dart';

void main() {
  group('YouTubeUtils', () {
    test('getYouTubeId extracts ID from various formats', () {
      final testCases = {
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ': 'dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
        'https://www.youtube.com/embed/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
        'https://www.youtube.com/v/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
        'https://www.youtube.com/live/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ': 'dQw4w9WgXcQ',
        'dQw4w9WgXcQ': 'dQw4w9WgXcQ',
        '  https://www.youtube.com/watch?v=dQw4w9WgXcQ  ': 'dQw4w9WgXcQ',
        'not a youtube link': null,
        '': null,
        null: null,
      };

      testCases.forEach((url, expected) {
        expect(YouTubeUtils.getYouTubeId(url), expected, reason: 'Failed for $url');
      });
    });

    test('normalizeUrl returns canonical URL', () {
      final testCases = {
        'https://youtu.be/dQw4w9WgXcQ': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'dQw4w9WgXcQ': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'not a youtube link': 'not a youtube link',
      };

      testCases.forEach((url, expected) {
        expect(YouTubeUtils.normalizeUrl(url), expected, reason: 'Failed for $url');
      });
    });
  });
}
