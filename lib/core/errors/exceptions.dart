class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class ImportExportException implements Exception {
  final String message;
  const ImportExportException(this.message);

  @override
  String toString() => 'ImportExportException: $message';
}
