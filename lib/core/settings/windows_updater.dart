/// `WindowsUpdater` — "Update now" on Windows downloads the new installer
/// INSIDE ASEC (with progress) and opens it; the member just clicks Next.
/// See windows_updater_io.dart. Elsewhere (web, phones) it does nothing.
library;

export 'windows_updater_stub.dart' if (dart.library.io) 'windows_updater_io.dart';
