// integration_test/person_creation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nm_gen/main.dart' as app;
import 'package:nm_gen/core/enums/gender.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Создание и редактирование человека', () {
    testWidgets('создание, а затем редактирование человека', (tester) async {
      // ============================================================
      // ШАГ 1: ЗАПУСК ПРИЛОЖЕНИЯ
      // ============================================================
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

      // ============================================================
      // ШАГ 2: ЗАПОЛНЕНИЕ ФОРМЫ
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

      // Дата рождения
      final birthDateField = find.widgetWithText(TextField, 'Дата рождения');
      if (birthDateField.evaluate().isNotEmpty) {
        // Вводим дату с маской: 15.05.1990
        await tester.enterText(birthDateField, '15051990');
        // Маска автоматически преобразует в 15.05.1990
        await tester.pumpAndSettle();
        print('✅ Введена дата рождения: 15.05.1990');
      }

      // Место рождения
      final birthPlaceField = find.widgetWithText(TextField, 'Место рождения');
      if (birthPlaceField.evaluate().isNotEmpty) {
        await tester.enterText(birthPlaceField, 'Москва, Россия');
        print('✅ Введено место рождения: Москва, Россия');
      }

      // Профессия
      final occupationField = find.widgetWithText(TextField, 'Профессия');
      if (occupationField.evaluate().isNotEmpty) {
        await tester.enterText(occupationField, 'Инженер-программист');
        print('✅ Введена профессия: Инженер-программист');
      }

      // Биография
      final biographyField = find.widgetWithText(TextField, 'Биография');
      if (biographyField.evaluate().isNotEmpty) {
        await tester.enterText(
          biographyField,
          'Родился в Москве. Окончил МГТУ им. Баумана. Работает в IT-компании.',
        );
        print('✅ Введена биография');
      }

      // Ждём пока форма "устаканится"
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

      print('🎉 ШАГ 1 (СОЗДАНИЕ) ПРОШЕЛ УСПЕШНО!');

      // ============================================================
      // ШАГ 3: ОТКРЫВАЕМ РЕДАКТИРОВАНИЕ
      // (важно: это продолжение ТОГО ЖЕ теста, а не отдельный testWidgets —
      // иначе виджет-дерево и состояние приложения сбрасываются, и запись
      // "Иван Петров" из шага 1 недоступна в новом тесте)
      // ============================================================

      // Находим карточку человека в списке
      final personTile = find.widgetWithText(ListTile, 'Иван Петров');
      expect(personTile, findsOneWidget);
      print('✅ Карточка человека найдена');

      // Прокручиваем к карточке, чтобы drag/fling попадал точно по ней
      await tester.ensureVisible(personTile);
      await tester.pumpAndSettle();

      // Свайпаем влево для открытия меню редактирования.
      // Используем fling вместо drag: Dismissible реагирует на скорость жеста,
      // а не только на итоговое смещение, и fling надёжнее пересекает порог.
      await tester.fling(personTile, const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      // Находим кнопку "Редактировать" в открывшемся bottom sheet
      final editButton = find.text('Редактировать');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();
      print('✅ Открыт диалог редактирования');

      // ============================================================
      // ШАГ 4: РЕДАКТИРУЕМ ДАННЫЕ
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
        await tester.enterText(editBirthDateField, '');
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
      await tester.pump(const Duration(seconds: 2)); // дать время LoadPersonsEvent отработать
await tester.pumpAndSettle();
      print('✅ Изменения сохранены');

      // ============================================================
      // ШАГ 5: ПРОВЕРЯЕМ, ЧТО ИЗМЕНЕНИЯ ПРИМЕНИЛИСЬ
      // ============================================================

      expect(find.text('Алексей Петров'), findsOneWidget);
      print('✅ Имя изменено на "Алексей Петров"');

      expect(find.text('Иван Петров'), findsNothing);
      print('✅ Старое имя "Иван Петров" больше не отображается');

      print('🎉 ТЕСТ (СОЗДАНИЕ + РЕДАКТИРОВАНИЕ) ПРОШЕЛ УСПЕШНО!');
    });
  });
}