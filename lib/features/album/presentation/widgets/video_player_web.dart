import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// 웹 전용 — HTML5 <video> 요소 사용
Widget buildVideoPlayer(String url) {
  return _WebVideoPlayer(url: url);
}

class _WebVideoPlayer extends StatefulWidget {
  final String url;
  const _WebVideoPlayer({required this.url});

  @override
  State<_WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<_WebVideoPlayer> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'video-${widget.url.hashCode}';
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final video =
          web.document.createElement('video') as web.HTMLVideoElement;
      video.src = widget.url;
      video.controls = true;
      video.autoplay = true;
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.backgroundColor = 'black';
      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
