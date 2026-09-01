import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../profile/account_setup_screen.dart';

class AuthService {
  AuthService._();

  static Future<Widget> resolveStartScreen() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    final userId = user.id;

    final profile = await client
        .from('profiles')
        .select('id, first_name, last_name, is_active')
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) {
      return const AccountSetupScreen();
    }

    final firstName = profile['first_name']?.toString().trim() ?? '';

    final lastName = profile['last_name']?.toString().trim() ?? '';

    if (firstName.isEmpty || lastName.isEmpty) {
      return const AccountSetupScreen();
    }

    if (profile['is_active'] == false) {
      await client.auth.signOut();
      return const WelcomeScreen();
    }

    return const HomeScreen();
  }
}
