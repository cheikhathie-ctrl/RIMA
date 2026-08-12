import 'dart:async';
import 'package:flutter/material.dart';

import 'welcome_screen.dart';
import '../../app/theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 3),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
           builder: (_) => const WelcomeScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RimaColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  "R",
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: RimaColors.primary,
                  ),
                ),
              ),
            ),

            SizedBox(height: 35),

            Text(
              "RIMA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Mauritania",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
              ),
            ),

            SizedBox(height: 70),

            CircularProgressIndicator(
              color: RimaColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}