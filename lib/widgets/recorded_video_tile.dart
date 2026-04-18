import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RecordedVideoTile extends StatefulWidget {
  final String url;
  final String title;

  const RecordedVideoTile({
    super.key,
    required this.url,
    this.title = 'Recorded Clip',
  });

  @override
  State<RecordedVideoTile> createState() => _RecordedVideoTileState();
}

class _RecordedVideoTileState extends State<RecordedVideoTile> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _expanded = false;
  bool _initializing = false;
  Object? _error;

  Future<void> _ensureInitialized() async {
    if (_chewie != null || _initializing) return;
    setState(() => _initializing = true);
    try {
      final video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await video.initialize();
      if (!mounted) {
        await video.dispose();
        return;
      }
      final chewie = ChewieController(
        videoPlayerController: video,
        aspectRatio: video.value.aspectRatio,
        autoPlay: false,
        looping: false,
      );
      setState(() {
        _video = video;
        _chewie = chewie;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _initializing = false;
      });
    }
  }

  Future<void> _toggle() async {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      await _ensureInitialized();
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.play_circle_fill,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_initializing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPlayer(theme),
          ),
      ],
    );
  }

  Widget _buildPlayer(ThemeData theme) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Could not load clip: $_error',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.red)),
      );
    }
    final chewie = _chewie;
    if (chewie == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AspectRatio(
      aspectRatio: chewie.videoPlayerController.value.aspectRatio,
      child: Chewie(controller: chewie),
    );
  }
}
