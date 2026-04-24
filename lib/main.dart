import 'package:flutter/material.dart';

import 'screens/piano_screen.dart';

void main() {
  runApp(const PianoApp());
}

class PianoApp extends StatelessWidget {
  const PianoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piano',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007BA7),
          brightness: Brightness.dark,
        ),
      ),
      home: const PianoScreen(),
    );
  }
}
