abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ImportExportFailure extends Failure {
  const ImportExportFailure(super.message);
}
