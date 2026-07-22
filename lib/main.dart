// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/screens/main_screen.dart';

void main() {
  if (GetIt.I.isRegistered<PersonBloc>()) {
    GetIt.I.reset();
  }
  // Настраиваем DI контейнер
  configureDependencies();

  // Регистрируем Use Cases и BLoC
  registerUseCasesAndBlocs();

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
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: BlocProvider(
        create: (BuildContext context) => getIt<PersonBloc>(),
        child: const MainScreen(), // <-- ИЗМЕНЕНО: теперь MainScreen
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
