/// Базовый класс для всех ошибок в приложении
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

/// Ошибка сервера/базы данных
class ServerFailure extends Failure {
  const ServerFailure(String message, {String? code})
    : super(message, code: code);
}

/// Ошибка валидации данных
class ValidationFailure extends Failure {
  const ValidationFailure(String message, {String? code})
    : super(message, code: code);
}

/// Ошибка - объект не найден
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message, {String? code})
    : super(message, code: code);
}

/// Непредвиденная ошибка
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message, {String? code})
    : super(message, code: code);
}
