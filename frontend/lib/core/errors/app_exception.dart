/// Thrown by repositories when a backend call fails. `message` is already
/// human-readable (extracted from the backend's error response) and safe
/// to show directly in UI.
class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
