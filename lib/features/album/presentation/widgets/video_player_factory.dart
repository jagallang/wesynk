export 'video_player_stub.dart'
    if (dart.library.js_interop) 'video_player_web.dart'
    if (dart.library.io) 'video_player_mobile.dart';
