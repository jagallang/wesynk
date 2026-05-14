import 'package:flutter/material.dart';

/// Stub — 조건부 import에서 기본값
Widget buildVideoPlayer(String url) {
  return const SizedBox(
    height: 300,
    child: Center(child: Text('Video not supported on this platform')),
  );
}
