// Clean Architecture: Custom API exceptions
// TODO: Map HTTP status codes to specific exceptions in ApiClient

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class TimeoutException extends ApiException {
  TimeoutException(super.message);
}
