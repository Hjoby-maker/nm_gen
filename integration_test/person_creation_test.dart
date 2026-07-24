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
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Персоны'), findsAtLeastNWidgets(1));
      print('✅ Приложение запущено');

      final addButton = find.byType(FloatingActionButton);
      expect(addButton, findsOneWidget);

      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('Добавить человека'), findsOneWidget);
      print('✅ Диалог добавления открыт');

      // Ищем TextField с учётом того, что они могут быть offstage
      final textFields = find.byType(TextField, skipOffstage: false);
      expect(textFields, findsWidgets);
      print('📝 Найдено TextField: ${textFields.evaluate().length}');

      // Заполняем поля
      await tester.ensureVisible(textFields.first);
      await tester.enterText(textFields.first, 'Тест');
      print('✅ Введено имя: Тест');

      await tester.ensureVisible(textFields.at(1));
      await tester.enterText(textFields.at(1), 'Тестов');
      print('✅ Введена фамилия: Тестов');

      if (textFields.evaluate().length > 2) {
        await tester.ensureVisible(textFields.at(2));
        await tester.enterText(textFields.at(2), 'Тестович');
        print('✅ Введено отчество: Тестович');
      }

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

      final saveButton = find.text('Добавить').last;
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Тест Тестов'), findsOneWidget);
      print('✅ Человек "Тест Тестов" найден в списке');

      print('🎉 ТЕСТ ПРОШЕЛ УСПЕШНО!');
    });
  });
}
