// Environment configuration for sensitive data
// Use const.fromEnvironment() untuk read dari --dart-define atau environment variables

class EnvConfig {
  // Parse Server credentials
  static const String parseAppId = String.fromEnvironment('PARSE_APP_ID', defaultValue: '');
  static const String parseServerUrl = String.fromEnvironment('PARSE_SERVER_URL', defaultValue: 'https://parseapi.back4app.com');
  static const String parseClientKey = String.fromEnvironment('PARSE_CLIENT_KEY', defaultValue: '');

  // Validate configuration
  static bool isConfigured() {
    return parseAppId.isNotEmpty && parseClientKey.isNotEmpty;
  }

  // Get configuration status for debugging
  static String getConfigStatus() {
    return '''
Parse Configuration:
- App ID: ${parseAppId.isEmpty ? 'NOT SET' : 'SET'}
- Server URL: $parseServerUrl
- Client Key: ${parseClientKey.isEmpty ? 'NOT SET' : 'SET'}
''';
  }
}
