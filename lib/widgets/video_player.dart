import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../utils/youtube_utils.dart';

class VideoLinkTile extends StatefulWidget {
  final String? url;
  final String title;

  const VideoLinkTile({super.key, this.url, required this.title});

  @override
  State<VideoLinkTile> createState() => VideoLinkTileState();
}

class VideoLinkTileState extends State<VideoLinkTile> {
  bool _isExpanded = false;
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
  }

  String? get _videoId {
    final urlStr = widget.url;
    if (urlStr == null || urlStr.isEmpty) return null;
    return YouTubeUtils.getYouTubeId(urlStr);
  }

  YoutubePlayerController _createController(String videoId) {
    return YoutubePlayerController.fromVideoId(
      videoId: videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        showVideoAnnotations: false,
      ),
    );
  }

  @override
  void didUpdateWidget(VideoLinkTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _controller?.close();
      _controller = null;
      _isExpanded = false;
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    final urlStr = widget.url;
    if (urlStr == null || urlStr.isEmpty) return;

    try {
      final uri = Uri.parse(urlStr);
      await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      debugPrint('Could not launch $urlStr: $e');
    }
  }

  void toggleExpand() {
    final urlStr = widget.url;
    if (urlStr == null || urlStr.isEmpty) return;

    final videoId = YouTubeUtils.getYouTubeId(urlStr);

    if (videoId == null) {
      _launchUrl();
      return;
    }

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded && _controller == null) {
        _controller = _createController(videoId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final urlStr = widget.url;
    if (urlStr == null || urlStr.isEmpty) return const SizedBox.shrink();

    final videoId = YouTubeUtils.getYouTubeId(urlStr);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(
            videoId != null ? Icons.play_circle_filled : Icons.link,
            color: Colors.teal,
          ),
          title: Text(widget.title, style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            videoId != null
              ? (_isExpanded ? 'Tap to hide video' : 'Watch reference video')
              : 'Open link',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: toggleExpand,
          mouseCursor: SystemMouseCursors.click,
          dense: true,
          visualDensity: VisualDensity.compact,
          trailing: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
            size: 20, 
            color: Colors.grey
          ),
        ),
        if (_isExpanded)
          _buildPlayer(),
      ],
    );
  }

  Widget _buildPlayer() {
    if (kIsWeb) {
      return _buildWebPlayer();
    }

    final ctrl = _controller;
    if (ctrl == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(controller: ctrl),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _launchUrl,
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('Open in YouTube', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebPlayer() {
    final videoId = _videoId;
    if (videoId == null) return const SizedBox.shrink();

    // Small clickable thumbnail. Tap opens the YouTube URL in a new browser
    // tab via _launchUrl (which passes webOnlyWindowName: "_blank").
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _launchUrl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.black12),
                      ),
                      Container(color: Colors.black26),
                      const Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('YouTube', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
