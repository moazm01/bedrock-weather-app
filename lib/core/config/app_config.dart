// Clean Architecture: Environment configuration
enum Environment { dev, staging, prod }

class AppConfig {
  // TODO: Initialize from .env or build flavors
  static Environment currentEnv = Environment.dev;
  static bool get isProduction => currentEnv == Environment.prod;

  static String get apiBaseUrl {
    switch (currentEnv) {
      case Environment.prod:
        return 'https://api.bedrock-abbottabad.com/v1';
      case Environment.staging:
        return 'https://staging.api.bedrock-abbottabad.com/v1';
      case Environment.dev:
        return 'http://localhost:8080/v1';
    }
  }
}
