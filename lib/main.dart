import 'package:flutter/material.dart';
import 'package:programming_keyboard_trainer/pages/home_page.dart';
import 'package:programming_keyboard_trainer/pages/practice_page.dart'
    as practice;
import 'pages/statistics_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YHA Computer',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/practice': (context) => practice.PracticePage(),
        '/statistics': (context) => const StatisticsPage(),
      },
    );
  }
}
