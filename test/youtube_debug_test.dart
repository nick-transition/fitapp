import 'package:fitapp/utils/youtube_utils.dart';

void main() {
  final url = 'https://youtu.be/xGji6K6tqT0?si=xCTURZBhNKoPchkM';
  final id = YouTubeUtils.getYouTubeId(url);
  print('URL: $url');
  print('Extracted ID: $id');
  if (id == 'xGji6K6tqT0') {
    print('SUCCESS');
  } else {
    print('FAILED');
  }
}
