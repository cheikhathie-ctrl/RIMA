import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/localization/rima_localization.dart';
import '../../app/theme/colors.dart';
import '../onboarding/welcome_screen.dart';
import 'personal_information_screen.dart';
import 'saved_places_screen.dart';
import 'language_screen.dart';
import 'notification_settings_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'RIMA customer';
  String phone = '';
  bool loggingOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final p = await Supabase.instance.client
        .from('profiles')
        .select('first_name,last_name,phone')
        .eq('id', uid)
        .maybeSingle();

    if (mounted && p != null) {
      setState(() {
        name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
        phone = p['phone']?.toString() ?? '';
      });
    }
  }

  void _open(Widget page) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ).then((_) => _load());

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(RimaText.ui('Log out?')),
        content: Text(RimaText.ui('Are you sure you want to log out?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(RimaText.ui('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(RimaText.ui('Log out')),
          ),
        ],
      ),
    );

    if (confirmed != true || loggingOut) return;

    setState(() => loggingOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RimaColors.background,
        appBar: AppBar(title: Text(RimaText.ui('Profile'))),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: RimaColors.primaryDark,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: RimaColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? RimaText.ui('RIMA customer') : name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(phone, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _tile(Icons.person_outline_rounded, RimaText.ui('Personal information'), () => _open(const PersonalInformationScreen())),
            _tile(Icons.bookmark_border_rounded, RimaText.ui('Saved places'), () => _open(const SavedPlacesScreen())),
            _tile(Icons.language_rounded, RimaText.ui('Language'), () => _open(const LanguageScreen())),
            _tile(Icons.notifications_none_rounded, RimaText.ui('Notifications'), () => _open(const NotificationSettingsScreen())),
            _tile(Icons.help_outline_rounded, RimaText.ui('Help & support'), () => _open(const HelpSupportScreen())),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                leading: loggingOut
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: Text(
                  RimaText.ui('Logout'),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: loggingOut ? null : _logout,
              ),
            ),
          ],
        ),
      );

  Widget _tile(IconData icon, String text, VoidCallback tap) => Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          leading: Icon(icon, color: RimaColors.primary),
          title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Icon(
            RimaLocaleController.isArabic
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
          ),
          onTap: tap,
        ),
      );
}
