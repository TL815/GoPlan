class DifyGatewayConfig {
  const DifyGatewayConfig({
    required this.apiBaseUri,
    required this.apiKey,
    this.timeout = const Duration(seconds: 180),
    this.maxAttempts = 3,
    this.userAgent = 'GoPlan/0.1 Flutter',
  });

  factory DifyGatewayConfig.fromEnvironment() {
    return DifyGatewayConfig(
      apiBaseUri: Uri.parse(
        const String.fromEnvironment(
          'DIFY_API_BASE',
          defaultValue: 'https://api.dify.ai/v1',
        ),
      ),
      apiKey: const String.fromEnvironment('DIFY_API_KEY'),
    );
  }

  final Uri apiBaseUri;
  final String apiKey;
  final Duration timeout;
  final int maxAttempts;
  final String userAgent;

  @override
  String toString() {
    return 'DifyGatewayConfig('
        'apiBaseUri: $apiBaseUri, '
        'timeout: $timeout, '
        'maxAttempts: $maxAttempts, '
        'userAgent: $userAgent, '
        'apiKey: ${apiKey.isEmpty ? 'missing' : 'redacted'}'
        ')';
  }
}
