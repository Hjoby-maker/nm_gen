import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injector.config.dart';

/// Глобальный экземпляр GetIt для внедрения зависимостей
final getIt = GetIt.instance;

/// Конфигурация DI контейнера
/// @injectable - аннотация для автоматической генерации
@InjectableInit(
  initializerName: r'$initGetIt', // имя метода инициализации
  preferRelativeImports: true, // использовать относительные импорты
  asExtension: true, // использовать как расширение
)
void configureDependencies() => getIt.$initGetIt();
