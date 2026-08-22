import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabaseUrl.isEmpty ||
      supabasePublishableKey.isEmpty) {
    throw Exception(
      'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY',
    );
  }

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  await _configurePushNotifications();

  runApp(const RimaApp());
}

Future<void> _configurePushNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();

    if (token != null && token.isNotEmpty) {
      await _registerPushToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        await _registerPushToken(newToken);
      },
    );

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        debugPrint(
          'RIMA PUSH FOREGROUND: '
          '${message.notification?.title} | '
          '${message.notification?.body}',
        );
      },
    );
  } catch (e) {
    debugPrint(
      'RIMA PUSH SETUP ERROR: $e',
    );
  }
}

Future<void> _registerPushToken(
  String token,
) async {
  final user =
      Supabase.instance.client.auth.currentUser;

  if (user == null) {
    debugPrint(
      'RIMA PUSH: no logged-in user yet, token not registered.',
    );
    return;
  }

  final platform = Platform.isAndroid
      ? 'android'
      : Platform.isIOS
          ? 'ios'
          : 'web';

  try {
    await Supabase.instance.client.rpc(
      'register_push_token',
      params: {
        'p_push_token': token,
        'p_platform': platform,
        'p_device_label': Platform.operatingSystem,
      },
    );

    debugPrint(
      'RIMA PUSH TOKEN REGISTERED',
    );
  } catch (e) {
    debugPrint(
      'RIMA PUSH TOKEN REGISTER ERROR: $e',
    );
  }
}