enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String value) => switch (value.trim().toLowerCase()) {
        'development' || 'dev' => AppEnvironment.development,
        'staging' || 'stg' => AppEnvironment.staging,
        'production' || 'prod' => AppEnvironment.production,
        _ => throw ConfigException('APP_ENV must be development, staging or production.'),
      };

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isProduction => this == AppEnvironment.production;
}

class ConfigException implements Exception {
  const ConfigException(this.message);
  final String message;

  @override
  String toString() => 'ConfigException: $message';
}
