import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/home/home_screen.dart';

class RimaApp extends StatelessWidget {
  const RimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIMA',
      debugShowCheckedModeBanner: false,
      theme: RimaTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}