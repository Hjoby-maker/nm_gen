// lib/core/utils/date_formatters.dart

/// Простое форматирование даты в формате ДД.ММ.ГГГГ.
/// Вынесено в общий файл, т.к. использовалось одинаковым кодом сразу в
/// нескольких местах person_detail_screen.dart до его разделения на файлы.
String formatDate(DateTime date) {
  return '${date.day}.${date.month}.${date.year}';
}

/// Форматирование диапазона дат события (начало/конец, любое из которых
/// может отсутствовать).
String formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Даты не указаны';
  if (start != null && end == null) return formatDate(start);
  if (start == null && end != null) return '... - ${formatDate(end)}';
  return '${formatDate(start!)} - ${formatDate(end!)}';
}