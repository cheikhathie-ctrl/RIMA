import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/localization/rima_localization.dart';
import '../../app/theme/colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool enabled = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final rows = await Supabase.instance.client
        .from('device_push_tokens')
        .select('is_active')
        .eq('user_id', uid);
    if (mounted) {
      setState(() {
        enabled = rows.isEmpty || rows.any((e) => e['is_active'] == true);
        loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    await Supabase.instance.client
        .from('device_push_tokens')
        .update({'is_active': value})
        .eq('user_id', uid);
    if (mounted) setState(() => enabled = value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RimaColors.background,
        appBar: AppBar(title: Text(RimaText.ui('Notifications'))),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  SwitchListTile(
                    value: enabled,
                    onChanged: _toggle,
                    title: Text(RimaText.ui('Push notifications')),
                    subtitle: Text(
                      RimaText.ui(
                        'Ride updates, driver arrival and important RIMA alerts',
                      ),
                    ),
                  ),
                ],
              ),
      );
}
