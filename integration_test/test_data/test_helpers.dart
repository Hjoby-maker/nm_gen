// integration_test/test_data/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Вспомогательные функции для интеграционных тестов

/// Найти и нажать на кнопку с определенным текстом
Future<void> tapButtonWithText(
  WidgetTester tester,
  String text, {
  bool waitForSettle = true,
}) async {
  final button = find.widgetWithText(ElevatedButton, text);
  expect(button, findsOneWidget);
  await tester.tap(button);
  if (waitForSettle) {
    await tester.pumpAndSettle();
  }
}

/// Заполнить текстовое поле по индексу
Future<void> fillTextField(
  WidgetTester tester,
  int index,
  String value, {
  bool waitForSettle = true,
}) async {
  final field = find.byType(TextField).at(index);
  expect(field, findsOneWidget);
  await tester.enterText(field, value);
  if (waitForSettle) {
    await tester.pumpAndSettle();
  }
}

/// Проверить, что виджет с текстом существует
void expectTextExists(String text) {
  expect(find.text(text), findsOneWidget);
}

/// Проверить, что виджет с текстом не существует
void expectTextNotExists(String text) {
  expect(find.text(text), findsNothing);
}

/// Найти и нажать на кнопку с tooltip
Future<void> tapByTooltip(
  WidgetTester tester,
  String tooltip, {
  bool waitForSettle = true,
}) async {
  final button = find.byTooltip(tooltip);
  expect(button, findsOneWidget);
  await tester.tap(button);
  if (waitForSettle) {
    await tester.pumpAndSettle();
  }
}
