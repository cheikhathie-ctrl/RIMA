import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../auth/auth_service.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _resolveStartup();
  }

  Future<void> _resolveStartup() async {
    //
    // Keep the splash visible briefly so startup
    // does not feel like a screen flash.
    //
    await Future.delayed(const Duration(seconds: 2));

    try {
      final nextScreen = await AuthService.resolveStartScreen();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
        (route) => false,
      );
    } catch (e) {
      debugPrint('RIMA STARTUP AUTH ERROR: $e');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RimaColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/rima_brand.png',
              width: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 35),
            const Text(
              'RIMA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mauritania',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
            const SizedBox(height: 70),
            const CircularProgressIndicator(color: RimaColors.gold),
          ],
        ),
      ),
    );
  }
}
