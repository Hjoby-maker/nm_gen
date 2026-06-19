/// Базовый класс для всех ошибок в приложении
abstract class Failure {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Ошибка сервера/базы данных
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Ошибка валидации данных
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Ошибка - объект не найден
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Непредвиденная ошибка
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.code});
}
