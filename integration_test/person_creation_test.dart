// integration_test/person_creation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nm_gen/main.dart' as app;
import 'package:nm_gen/core/enums/gender.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Создание человека', () {
    testWidgets('открытие диалога добавления человека', (tester) async {
      // Запускаем приложение
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Проверяем, что мы на экране "Персоны"
      expect(find.text('Персоны'), findsAtLeastNWidgets(1));
      print('✅ Приложение запущено, экран "Персоны" загружен');

      // Находим кнопку добавления (FAB)
      final addButton = find.byType(FloatingActionButton);
      expect(addButton, findsOneWidget);
      print('✅ Кнопка добавления найдена');

      // Нажимаем на кнопку
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Проверяем, что диалог с заголовком "Добавить человека" появился
      expect(find.text('Добавить человека'), findsAtLeastNWidgets(1));
      print('✅ Диалог добавления успешно открыт');
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // (Опционально) можно проверить наличие хотя бы одного поля ввода,
      // но для простоты теста мы этого не делаем.
      // ============================================================
      // НОВЫЙ КОД: ЗАПОЛНЕНИЕ ФОРМЫ
      // ============================================================

      // Заполняем имя
      final nameField = find.widgetWithText(TextField, 'Имя *');
      await tester.enterText(nameField, 'Иван');
      print('✅ Введено имя: Иван');

      // Заполняем фамилию
      final surnameField = find.widgetWithText(TextField, 'Фамилия *');
      await tester.enterText(surnameField, 'Петров');
      print('✅ Введена фамилия: Петров');

      // Заполняем отчество (если есть)
      final middleNameField = find.widgetWithText(TextField, 'Отчество');
      if (middleNameField.evaluate().isNotEmpty) {
        await tester.enterText(middleNameField, 'Иванович');
        print('✅ Введено отчество: Иванович');
      }

      // Выбираем пол
      final genderDropdown = find.byType(DropdownButtonFormField<Gender>);
      if (genderDropdown.evaluate().isNotEmpty) {
        await tester.tap(genderDropdown);
        await tester.pumpAndSettle();

        final maleOption = find.text('Мужской').last;
        await tester.tap(maleOption);
        await tester.pumpAndSettle();
        print('✅ Выбран пол: Мужской');
      }

      // 5. Дата рождения
      final birthDateField = find.widgetWithText(TextField, 'Дата рождения');
      if (birthDateField.evaluate().isNotEmpty) {
        // Вводим дату с маской: 15.05.1990
        await tester.enterText(birthDateField, '15051990');
        // Маска автоматически преобразует в 15.05.1990
        await tester.pumpAndSettle();
        print('✅ Введена дата рождения: 15.05.1990');
      }

      // 6. Место рождения
      final birthPlaceField = find.widgetWithText(TextField, 'Место рождения');
      if (birthPlaceField.evaluate().isNotEmpty) {
        await tester.enterText(birthPlaceField, 'Москва, Россия');
        print('✅ Введено место рождения: Москва, Россия');
      }

      // 7. Профессия
      final occupationField = find.widgetWithText(TextField, 'Профессия');
      if (occupationField.evaluate().isNotEmpty) {
        await tester.enterText(occupationField, 'Инженер-программист');
        print('✅ Введена профессия: Инженер-программист');
      }

      // 8. Биография
      final biographyField = find.widgetWithText(TextField, 'Биография');
      if (biographyField.evaluate().isNotEmpty) {
        await tester.enterText(
          biographyField,
          'Родился в Москве. Окончил МГТУ им. Баумана. Работает в IT-компании.',
        );
        print('✅ Введена биография');
      }

      // Ждём 3 секунды
      await tester.pump(const Duration(seconds: 3));
      print('⏳ Ожидание 3 секунды...');

      // Сохраняем
      final saveButton = find.text('Добавить').last;
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      print('✅ Форма сохранена');

      // Проверяем, что человек появился в списке
      expect(find.text('Иван Петров'), findsOneWidget);
      print('✅ Человек "Иван Петров" найден в списке');

      // ============================================================
      // КОНЕЦ НОВОГО КОДА
      // ============================================================

      print('🎉 ТЕСТ ПРОШЕЛ УСПЕШНО!');
    });
  });
}
