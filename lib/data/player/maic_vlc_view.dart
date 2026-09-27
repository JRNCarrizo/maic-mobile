import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player_16kb/flutter_vlc_player.dart';
import 'package:video_player/video_player.dart';

import '../../core/logging/app_logger.dart';

/// Único widget de video. Recibe una URL; no sabe de MAIC.
/// MP4 (archivo local o red) usa [VideoPlayer]; MPEG-TS live usa VLC.
class MaicVlcView extends StatelessWidget {
  const MaicVlcView({
    super.key,
    required this.streamUrl,
    this.startOffset = Duration.zero,
    this.onError,
    this.onPlaying,
  });

  final String streamUrl;
  final Duration startOffset;
  final VoidCallback? onError;
  final VoidCallback? onPlaying;

  @override
  Widget build(BuildContext context) {
    if (_isProgressiveMp4(streamUrl)) {
      return _Mp4View(
        streamUrl: streamUrl,
        startOffset: startOffset,
        onError: onError,
        onPlaying: onPlaying,
      );
    }
    return _VlcView(
      streamUrl: streamUrl,
      onError: onError,
      onPlaying: onPlaying,
    );
  }
}

bool _isProgressiveMp4(String url) {
  if (url.startsWith('asset:')) return true;
  final uri = Uri.tryParse(url);
  return uri != null && uri.path.toLowerCase().endsWith('.mp4');
}

VideoPlayerController _mp4Controller(String url) {
  final options = VideoPlayerOptions(mixWithOthers: true);
  if (url.startsWith('asset:')) {
    return VideoPlayerController.asset(
      url.substring('asset:'.length),
      videoPlayerOptions: options,
    );
  }
  return VideoPlayerController.networkUrl(
    Uri.parse(url),
    videoPlayerOptions: options,
  );
}

class _Mp4View extends StatefulWidget {
  const _Mp4View({
    required this.streamUrl,
    this.startOffset = Duration.zero,
    this.onError,
    this.onPlaying,
  });

  final String streamUrl;
  final Duration startOffset;
  final VoidCallback? onError;
  final VoidCallback? onPlaying;

  @override
  State<_Mp4View> createState() => _Mp4ViewState();
}

class _Mp4ViewState extends State<_Mp4View> {
  late final VideoPlayerController _controller;
  var _ready = false;
  var _failed = false;
  var _resuming = false;

  @override
  void initState() {
    super.initState();
    _controller = _mp4Controller(widget.streamUrl);
    _start();
  }

  Future<void> _start() async {
    try {
      _controller.addListener(_keepPlaying);
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      await _controller.initialize();
      if (widget.startOffset > Duration.zero) {
        await _controller.seekTo(widget.startOffset);
      }
      if (!mounted) return;
      setState(() => _ready = true);
      await _controller.play();
      widget.onPlaying?.call();
    } catch (error) {
      AppLogger.error('Player MP4: ${error.runtimeType}');
      _fail();
    }
  }

  void _keepPlaying() {
    if (!mounted || _failed || !_ready || _resuming) return;
    final value = _controller.value;
    if (value.isInitialized && !value.isPlaying && !value.isBuffering) {
      _resuming = true;
      _controller.play().whenComplete(() => _resuming = false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_keepPlaying);
    _controller.dispose();
    super.dispose();
  }

  void _fail() {
    if (!mounted || _failed) return;
    setState(() => _failed = true);
    widget.onError?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _PlayerFailed();
    if (!_ready) return const _PlayerLoading();
    final ratio = _controller.value.aspectRatio;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: ratio == 0 ? 16 / 9 : ratio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

class _VlcView extends StatefulWidget {
  const _VlcView({
    required this.streamUrl,
    this.onError,
    this.onPlaying,
  });

  final String streamUrl;
  final VoidCallback? onError;
  final VoidCallback? onPlaying;

  @override
  State<_VlcView> createState() => _VlcViewState();
}

class _VlcViewState extends State<_VlcView> {
  late final VlcPlayerController _controller;
  var _notifiedError = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _controller = VlcPlayerController.network(
      widget.streamUrl,
      hwAcc: HwAcc.disabled,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    _controller.addOnInitListener(_onInit);
    _controller.addListener(_onChanged);
    _timeout = Timer(const Duration(seconds: 12), _onTimeout);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onInit() {
    if (!mounted) return;
    widget.onPlaying?.call();
  }

  void _onChanged() {
    if (!mounted || _notifiedError) return;
    final value = _controller.value;
    if (value.hasError) {
      _fail();
    } else if (value.isPlaying) {
      _timeout?.cancel();
      widget.onPlaying?.call();
    }
  }

  void _onTimeout() {
    if (!mounted || _notifiedError || _controller.value.isPlaying) return;
    _fail();
  }

  void _fail() {
    if (!mounted || _notifiedError) return;
    _notifiedError = true;
    _timeout?.cancel();
    widget.onError?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_notifiedError) return const _PlayerFailed();
    return ColoredBox(
      color: Colors.black,
      child: VlcPlayer(
        controller: _controller,
        aspectRatio: 16 / 9,
        placeholder: const _PlayerLoading(),
      ),
    );
  }
}

class _PlayerLoading extends StatelessWidget {
  const _PlayerLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PlayerFailed extends StatelessWidget {
  const _PlayerFailed();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, size: 40),
            SizedBox(height: 8),
            Text('No se pudo reproducir', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
