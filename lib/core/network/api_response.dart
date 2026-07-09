// Clean Architecture: Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  ApiResponse.success(this.data, this.statusCode) : error = null;
  ApiResponse.failure(this.error, this.statusCode) : data = null;
}
