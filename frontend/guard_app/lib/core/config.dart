import 'package:flutter/foundation.dart';

// The Android emulator reaches the host PC at 10.0.2.2; web runs on the host.
// For a physical phone, pass the PC's LAN address:
//   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000
const String _override = String.fromEnvironment('API_BASE_URL');

final String apiBaseUrl = _override.isNotEmpty
    ? _override
    : kIsWeb
    ? 'http://localhost:3000'
    : 'http://10.0.2.2:3000';
