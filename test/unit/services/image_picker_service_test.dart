// test/unit/services/image_picker_service_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/core/utils/image_picker_service.dart';

void main() {
  group('ImagePickerService', () {
    test('существует и может быть создан', () {
      final service = ImagePickerService();
      expect(service, isNotNull);
    });

    testWidgets('показывает диалог с правильными опциями', (tester) async {
      // Arrange
      final service = ImagePickerService();
      bool dialogShown = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    dialogShown = true;
                    await service.pickImage(context);
                  },
                  child: const Text('Pick Image'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick Image'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogShown, true);
      expect(find.text('Выберите действие'), findsOneWidget);
      expect(find.text('Камера'), findsOneWidget);
      expect(find.text('Галерея'), findsOneWidget);
      expect(find.text('Удалить фото'), findsOneWidget);
    });
  });
}
