// Clean Architecture: Network client wrapper
import 'api_response.dart';

class ApiClient {
  // TODO: Implement with dio or http package. Add interceptors for auth tokens, logging, retry.

  Future<ApiResponse<T>> get<T>(String endpoint) {
    throw UnimplementedError('TODO: Implement GET');
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    throw UnimplementedError('TODO: Implement POST');
  }

  Future<ApiResponse<T>> put<T>(String endpoint, {Map<String, dynamic>? body}) {
    throw UnimplementedError('TODO: Implement PUT');
  }

  Future<ApiResponse<T>> delete<T>(String endpoint) {
    throw UnimplementedError('TODO: Implement DELETE');
  }
}
