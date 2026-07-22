// integration_test/person_creation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nm_gen/main.dart' as app;
import 'package:nm_gen/core/enums/gender.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Создание человека', () {
    testWidgets('добавление нового человека через форму', (tester) async {
      // ⬇️ Сбрасываем GetIt ПЕРЕД запуском приложения
      GetIt.I.reset();
      print('🔍 GetIt сброшен');

      app.main();
      await tester.pumpAndSettle();

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
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Доп. ожидание для полной анимации AlertDialog
      await tester.pump(const Duration(milliseconds: 500));

      // Проверяем, что диалог открылся
      expect(find.text('Добавить человека'), findsOneWidget);
      print('✅ Диалог добавления открыт');

      // ============================================================
      // ШАГ 3: Заполнение формы
      // ============================================================
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);

      final textFields = find.descendant(
        of: dialog,
        matching: find.byType(TextField),
      );

      expect(textFields, findsWidgets);
      print('📝 Найдено TextField в диалоге: ${textFields.evaluate().length}');

      // Заполняем имя (первое поле)
      await tester.ensureVisible(textFields.first);
      await tester.enterText(textFields.first, 'Тест');
      print('✅ Введено имя: Тест');

      // Заполняем фамилию (второе поле)
      await tester.ensureVisible(textFields.at(1));
      await tester.enterText(textFields.at(1), 'Тестов');
      print('✅ Введена фамилия: Тестов');

      // Заполняем отчество (третье поле), если есть
      if (textFields.evaluate().length > 2) {
        await tester.ensureVisible(textFields.at(2));
        await tester.enterText(textFields.at(2), 'Тестович');
        print('✅ Введено отчество: Тестович');
      }

      // ============================================================
      // ШАГ 4: Выбор пола
      // ============================================================
      final genderDropdown = find.descendant(
        of: dialog,
        matching: find.byType(DropdownButtonFormField<Gender>),
      );

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
      // ШАГ 5: Сохранение
      // ============================================================
      final saveButton = find.descendant(
        of: dialog,
        matching: find.text('Добавить'),
      );
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Ждём закрытия диалога и обновления списка
      await tester.pump(const Duration(milliseconds: 800));
      print('✅ Форма отправлена');

      // ============================================================
      // ШАГ 6: Проверка
      // ============================================================
      expect(find.text('Тест Тестов'), findsOneWidget);
      print('✅ Человек "Тест Тестов" найден в списке');

      print('🎉 ТЕСТ ПРОШЕЛ УСПЕШНО!');
    });
  });
}
