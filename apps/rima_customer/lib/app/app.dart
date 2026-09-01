import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'localization/rima_localization.dart';
import 'theme/app_theme.dart';
import '../features/onboarding/splash_screen.dart';

class RimaApp extends StatefulWidget {
  const RimaApp({super.key});

  @override
  State<RimaApp> createState() => _RimaAppState();
}

class _RimaAppState extends State<RimaApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSignedInUser();
    });

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      authState,
    ) {
      final event = authState.event;
      final session = authState.session;

      if (session == null || event == AuthChangeEvent.signedOut) {
        RimaLocaleController.language.value = 'en';
        return;
      }

      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.userUpdated) {
        _syncSignedInUser();
      }
    });
  }

  Future<void> _syncSignedInUser() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return;
    }

    await RimaLocaleController.loadFromProfile();

    try {
      await Supabase.instance.client.rpc('cleanup_my_stale_rides');
    } catch (e) {
      debugPrint('RIMA STALE RIDE CLEANUP ERROR: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: RimaLocaleController.language,
      builder: (context, language, _) {
        return MaterialApp(
          title: 'RIMA',
          debugShowCheckedModeBanner: false,
          theme: RimaTheme.lightTheme,
          builder: (context, child) {
            return Directionality(
              textDirection: language == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
