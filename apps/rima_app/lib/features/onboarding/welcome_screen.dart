import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import 'language_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          child: Column(
            children: [
              const Spacer(),

              // Temporary logo until we import the final image asset.
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: RimaColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.route_rounded,
                      color: RimaColors.gold,
                      size: 65,
                    ),
                    Icon(
                      Icons.star_rounded,
                      color: RimaColors.gold,
                      size: 28,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'RIMA',
                style: TextStyle(
                  color: RimaColors.primary,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'MOVE  •  EAT  •  SEND',
                style: TextStyle(
                  color: RimaColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 45),

              const Text(
                'Welcome to RIMA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Bienvenue chez RIMA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'مرحباً بكم في ريما',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.black54,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LanguageScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Your everyday life, simplified.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}