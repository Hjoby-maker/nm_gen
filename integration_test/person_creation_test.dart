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
      await tester.pump(const Duration(seconds: 3));
      print('⏳ Ожидание 3 секунды...');

      // ============================================================
      // КОНЕЦ НОВОГО КОДА
      // ============================================================

      print('🎉 ТЕСТ ПРОШЕЛ УСПЕШНО!');
    });
  });

  group('Редактирование человека', () {
    testWidgets('редактирование созданного человека', (tester) async {
      // ============================================================
      // ШАГ 2: ОТКРЫВАЕМ РЕДАКТИРОВАНИЕ
      // ============================================================
      await tester.pump(const Duration(seconds: 3));
      print('⏳ Старт шага 2');

      // Находим карточку человека в списке (свайп влево для открытия меню)
      final personTile = find.widgetWithText(ListTile, 'Иван Петров');
      expect(personTile, findsOneWidget);
      print('✅ Карточка человека найдена');

      // Свайпаем влево для открытия меню редактирования
      await tester.drag(
        personTile,
        const Offset(-300, 0), // Свайп влево
      );
      await tester.pumpAndSettle();

      // Альтернативный способ: нажимаем на карточку для перехода на экран деталей
      // await tester.tap(personCard);
      // await tester.pumpAndSettle();

      // Находим кнопку "Редактировать" в меню (после свайпа)
      final editButton = find.text('Редактировать');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();
      print('✅ Открыт диалог редактирования');

      // ============================================================
      // ШАГ 3: РЕДАКТИРУЕМ ДАННЫЕ
      // ============================================================

      // Проверяем, что диалог редактирования открыт
      expect(find.text('Редактировать человека'), findsOneWidget);
      print('✅ Диалог редактирования успешно открыт');

      // Изменяем имя
      final editNameField = find.widgetWithText(TextField, 'Имя *');
      await tester.enterText(editNameField, 'Алексей');
      print('✅ Имя изменено: Алексей');

      // Изменяем дату рождения
      final editBirthDateField = find.widgetWithText(
        TextField,
        'Дата рождения',
      );
      if (editBirthDateField.evaluate().isNotEmpty) {
        // Сначала очищаем поле
        await tester.enterText(editBirthDateField, '');
        // Вводим новую дату
        await tester.enterText(editBirthDateField, '20051985');
        await tester.pumpAndSettle();
        print('✅ Дата рождения изменена: 20.05.1985');
      }

      // Добавляем место рождения (если не было)
      final editBirthPlaceField = find.widgetWithText(
        TextField,
        'Место рождения',
      );
      if (editBirthPlaceField.evaluate().isNotEmpty) {
        await tester.enterText(editBirthPlaceField, 'Санкт-Петербург, Россия');
        print('✅ Добавлено место рождения: Санкт-Петербург, Россия');
      }

      // Добавляем профессию
      final editOccupationField = find.widgetWithText(TextField, 'Профессия');
      if (editOccupationField.evaluate().isNotEmpty) {
        await tester.enterText(editOccupationField, 'Программист');
        print('✅ Добавлена профессия: Программист');
      }

      // Сохраняем изменения
      final updateButton = find.text('Сохранить').last;
      expect(updateButton, findsOneWidget);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();
      print('✅ Изменения сохранены');

      // ============================================================
      // ШАГ 4: ПРОВЕРЯЕМ, ЧТО ИЗМЕНЕНИЯ ПРИМЕНИЛИСЬ
      // ============================================================

      // Проверяем, что имя изменилось
      expect(find.text('Алексей Петров'), findsOneWidget);
      print('✅ Имя изменено на "Алексей Петров"');

      // Проверяем, что старое имя больше не отображается
      expect(find.text('Иван Петров'), findsNothing);
      print('✅ Старое имя "Иван Петров" больше не отображается');

      print('🎉 ТЕСТ РЕДАКТИРОВАНИЯ ПРОШЕЛ УСПЕШНО!');
    });
  });
}
