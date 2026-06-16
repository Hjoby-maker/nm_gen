import 'package:flutter/material.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/presentation/screens/home_screen.dart';

void main() {
  // Настраиваем DI контейнер
  configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Генеалогическое древо',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
