class Environment {
  static const String telnyxApiUrl = 'https://api.telnyx.com/v2';
  static const String telnyxWsUrl = 'wss://api.telnyx.com/v2/websocket';

  // These will come from actual .env or --dart-define later
  static String get telnyxApiKey =>
      const String.fromEnvironment('TELNYX_API_KEY');

  static String get telnyxConnectionId =>
      const String.fromEnvironment('TELNYX_CONNECTION_ID');
}


