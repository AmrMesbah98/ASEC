/// Module: core/security
///
///*************************** FILE INFO ****************************///
/// File Name: secure_video_server.dart
/// Purpose: `SecureVideoServer` — see secure_video_server_io.dart. The web
///          build has no local server and plays links as they are.

export 'secure_video_server_web.dart' if (dart.library.io) 'secure_video_server_io.dart';
