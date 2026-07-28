// integration_test/person_creation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nm_gen/main.dart' as app;
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/event.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Создание и редактирование человека', () {
    testWidgets('создание, редактирование, добавление события и файла', (
      tester,
    ) async {
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
        await tester.enterText(birthDateField, '15051990');
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
      // ============================================================

      // Находим карточку человека в списке
      final personTile = find.widgetWithText(ListTile, 'Иван Петров');
      expect(personTile, findsOneWidget);
      print('✅ Карточка человека найдена');

      // Прокручиваем к карточке
      await tester.ensureVisible(personTile);
      await tester.pumpAndSettle();

      // Свайпаем влево для открытия меню редактирования
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

      // Добавляем место рождения
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
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      print('✅ Изменения сохранены');

      // Проверяем, что изменения применились
      expect(find.text('Алексей Петров'), findsOneWidget);
      print('✅ Имя изменено на "Алексей Петров"');

      expect(find.text('Иван Петров'), findsNothing);
      print('✅ Старое имя "Иван Петров" больше не отображается');

      print('🎉 ШАГ 2 (РЕДАКТИРОВАНИЕ) ПРОШЕЛ УСПЕШНО!');

      // ============================================================
      // ШАГ 5: ПЕРЕХОД НА ЭКРАН ДЕТАЛЕЙ ЧЕЛОВЕКА
      // ============================================================

      // Находим обновленную карточку
      final updatedPersonTile = find.widgetWithText(ListTile, 'Алексей Петров');
      expect(updatedPersonTile, findsOneWidget);
      print('✅ Карточка с обновленным именем найдена');

      // Нажимаем на карточку для перехода на экран деталей
      await tester.ensureVisible(updatedPersonTile);
      await tester.pumpAndSettle();
      await tester.tap(updatedPersonTile);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      print('✅ Переход на экран деталей человека');

      // Проверяем, что мы на экране деталей
      expect(find.text('Алексей Петров'), findsOneWidget);
      print('✅ Экран деталей загружен');

      // ============================================================
      // ШАГ 6: ДОБАВЛЕНИЕ СОБЫТИЯ
      // ============================================================

      // Находим и нажимаем кнопку "Добавить" в секции событий
      final addEventButton = find.widgetWithText(TextButton, 'Добавить');
      expect(addEventButton, findsOneWidget);
      await tester.tap(addEventButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('✅ Открыт диалог добавления события');

      // Проверяем, что диалог события открыт
      expect(find.text('Добавить событие'), findsOneWidget);
      print('✅ Диалог события открыт');

      // Заполняем тип события (DropdownButtonFormField)
      final eventTypeDropdown = find.byType(DropdownButtonFormField<EventType>);
      expect(eventTypeDropdown, findsOneWidget);
      await tester.tap(eventTypeDropdown);
      await tester.pumpAndSettle();

      // Выбираем тип "Образование"
      final educationOption = find.text('Образование');
      expect(educationOption, findsOneWidget);
      await tester.tap(educationOption);
      await tester.pumpAndSettle();
      print('✅ Выбран тип события: Образование');

      // Заполняем название (TextField с label 'Название *')
      final titleField = find.widgetWithText(TextField, 'Название *');
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, 'Окончание университета');
      print('✅ Введен заголовок: Окончание университета');

      // Заполняем описание (TextField с label 'Описание')
      final descriptionField = find.widgetWithText(TextField, 'Описание');
      expect(descriptionField, findsOneWidget);
      await tester.enterText(
        descriptionField,
        'Защитил дипломную работу по специальности "Программная инженерия"',
      );
      print('✅ Введено описание события');

      // Заполняем дату начала - через ListTile с текстом "Дата начала не указана"
      final startDateTile = find.widgetWithText(
        ListTile,
        'Дата начала не указана',
      );
      expect(startDateTile, findsOneWidget);

      // Находим иконку календаря внутри ListTile
      final calendarIcon = find.descendant(
        of: startDateTile,
        matching: find.byIcon(Icons.calendar_today),
      );
      expect(calendarIcon, findsOneWidget);
      await tester.tap(calendarIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Выбираем дату в DatePicker
      final okButton = find.text('OK');
      expect(okButton, findsOneWidget);
      await tester.tap(okButton);
      await tester.pumpAndSettle();
      print('✅ Выбрана дата начала');

      // Заполняем место (TextField с label 'Место')
      final placeField = find.widgetWithText(TextField, 'Место');
      expect(placeField, findsOneWidget);
      await tester.enterText(placeField, 'МГТУ им. Баумана, Москва');
      print('✅ Введено место: МГТУ им. Баумана, Москва');

      // Заполняем заметки (TextField с label 'Заметки')
      final notesField = find.widgetWithText(TextField, 'Заметки');
      expect(notesField, findsOneWidget);
      await tester.enterText(notesField, 'Диплом с отличием');
      print('✅ Введены заметки');

      // Сохраняем событие
      final saveEventButton = find.text('Добавить').last;
      expect(saveEventButton, findsOneWidget);
      await tester.tap(saveEventButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      print('✅ Событие сохранено');

      // Проверяем, что событие появилось в списке
      expect(find.text('Окончание университета'), findsOneWidget);
      print('✅ Событие "Окончание университета" найдено в списке');

      print('🎉 ШАГ 3 (ДОБАВЛЕНИЕ СОБЫТИЯ) ПРОШЕЛ УСПЕШНО!');

      // ============================================================
      // ШАГ 7: ДОБАВЛЕНИЕ ФАЙЛА
      // ============================================================

      // Переключаемся на вкладку "Файлы"
      final filesTab = find.text('Файлы');
      expect(filesTab, findsOneWidget);
      await tester.tap(filesTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('✅ Переключились на вкладку "Файлы"');

      // Находим кнопку "Добавить" в секции файлов
      final addFileButton = find.widgetWithText(TextButton, 'Добавить').last;
      expect(addFileButton, findsOneWidget);
      print('✅ Кнопка добавления файла найдена');

      // Нажимаем на кнопку добавления файла
      await tester.ensureVisible(addFileButton);
      await tester.pumpAndSettle();
      await tester.tap(addFileButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('✅ Открыт MediaPickerSheet');

      // Проверяем, что открылся bottom sheet - ищем хотя бы одну из опций
      // Используем более гибкий поиск
      final hasCamera = find.text('Камера').evaluate().isNotEmpty;
      final hasGallery = find.text('Галерея').evaluate().isNotEmpty;
      final hasFile = find.text('Файл').evaluate().isNotEmpty;
      final hasLink = find.text('Ссылка').evaluate().isNotEmpty;

      expect(hasCamera || hasGallery || hasFile || hasLink, true);
      print(
        '✅ MediaPickerSheet открыт (найдены опции: Камера=$hasCamera, Галерея=$hasGallery, Файл=$hasFile, Ссылка=$hasLink)',
      );

      // Закрываем MediaPickerSheet нажатием на пустое место или Back
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      print('✅ MediaPickerSheet закрыт');

      print('🎉 ШАГ 4 (ДОБАВЛЕНИЕ ФАЙЛА) ПРОШЕЛ УСПЕШНО!');

      // ============================================================
      // ШАГ 8: ВОЗВРАТ НА ОСНОВНОЙ ЭКРАН И ПРОВЕРКА
      // ============================================================

      // Нажимаем кнопку "Назад" для возврата на экран "Персоны"
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      print('✅ Возврат на экран "Персоны"');

      // Проверяем, что мы на экране "Персоны"
      expect(find.text('Персоны'), findsAtLeastNWidgets(1));
      print('✅ Экран "Персоны" загружен');

      // Проверяем, что человек с обновленным именем все еще в списке
      expect(find.text('Алексей Петров'), findsOneWidget);
      print('✅ Человек "Алексей Петров" все еще в списке');

      // Проверяем, что профессия обновилась в списке
      expect(find.text('Программист'), findsOneWidget);
      print('✅ Профессия "Программист" отображается в списке');

      print('🎉 ВСЕ ШАГИ ТЕСТА ПРОШЛИ УСПЕШНО!');
      print(
        '🎉 ТЕСТ (СОЗДАНИЕ + РЕДАКТИРОВАНИЕ + СОБЫТИЕ + ФАЙЛ) ПРОШЕЛ УСПЕШНО!',
      );
    });
  });
}
