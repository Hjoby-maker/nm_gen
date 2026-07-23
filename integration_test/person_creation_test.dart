// integration_test/person_creation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nm_gen/main.dart' as app;
import 'package:nm_gen/core/enums/gender.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Создание человека', () {
    testWidgets('добавление нового человека через форму', (tester) async {
      // Запускаем приложение
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Проверяем, что мы на главном экране
      expect(find.text('Персоны'), findsAtLeastNWidgets(1));
      print('✅ Приложение запущено');

      // ============================================================
      // ШАГ 2: Нажатие на FAB
      // ============================================================
      final addButton = find.byType(FloatingActionButton);
      expect(addButton, findsOneWidget);

      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 800)); // ждём анимацию

      // ============================================================
      // ШАГ 3: Проверка, что диалог открыт (по заголовку)
      // ============================================================
      expect(find.text('Добавить человека'), findsOneWidget);
      print('✅ Диалог добавления открыт');

      // ============================================================
      // ШАГ 4: Заполнение формы (ищем все TextField на экране)
      // ============================================================
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      print('📝 Найдено TextField: ${textFields.evaluate().length}');

      // Вводим имя (первое поле)
      await tester.ensureVisible(textFields.first);
      await tester.enterText(textFields.first, 'Тест');
      print('✅ Введено имя: Тест');

      // Вводим фамилию (второе поле)
      await tester.ensureVisible(textFields.at(1));
      await tester.enterText(textFields.at(1), 'Тестов');
      print('✅ Введена фамилия: Тестов');

      // Отчество (третье поле, если есть)
      if (textFields.evaluate().length > 2) {
        await tester.ensureVisible(textFields.at(2));
        await tester.enterText(textFields.at(2), 'Тестович');
        print('✅ Введено отчество: Тестович');
      }

      // ============================================================
      // ШАГ 5: Выбор пола
      // ============================================================
      final genderDropdown = find.byType(DropdownButtonFormField<Gender>);
      if (genderDropdown.evaluate().isNotEmpty) {
        await tester.ensureVisible(genderDropdown);
        await tester.tap(genderDropdown);
        await tester.pumpAndSettle();

        final maleOption = find.text('Мужской').last;
        await tester.ensureVisible(maleOption);
        await tester.tap(maleOption);
        await tester.pumpAndSettle();
        print('✅ Выбран пол: Мужской');
      }

      // ============================================================
      // ШАГ 6: Нажатие кнопки "Добавить"
      // ============================================================
      // Ищем кнопку с текстом "Добавить" (последнюю, т.к. она в диалоге)
      final saveButton = find.text('Добавить').last;
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      await tester.pump(
        const Duration(seconds: 1),
      ); // ждём закрытия диалога и обновления списка
      print('✅ Форма отправлена');

      // ============================================================
      // ШАГ 7: Проверка, что человек появился в списке
      // ============================================================
      expect(find.text('Тест Тестов'), findsOneWidget);
      print('✅ Человек "Тест Тестов" найден в списке');

      print('🎉 ТЕСТ ПРОШЕЛ УСПЕШНО!');
    });
  });
}
