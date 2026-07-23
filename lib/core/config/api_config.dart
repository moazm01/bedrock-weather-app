// Clean Architecture: API configuration (endpoints, base URLs)
class ApiConfig {
  // TODO: Replace with actual API base URL and configure per environment
  static const String baseUrl = 'https://api.bedrock-abbottabad.com/v1';
  static const String weatherEndpoint = '/weather';
  static const String hazardsEndpoint = '/hazards';
  static const String forecastEndpoint = '/forecast';
  static const String usersEndpoint = '/users';
  static const String adminEndpoint = '/admin';
  static const String mlModelEndpoint = '/ml/predict';
}
