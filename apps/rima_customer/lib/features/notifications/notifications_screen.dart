import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/localization/rima_localization.dart';
import '../../app/theme/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await Supabase.instance.client
          .from('push_notifications')
          .select('id, title, body, notification_type, created_at, sent_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(100);
      if (!mounted) return;
      setState(() {
        items = List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e)),
        );
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RimaColors.background,
        appBar: AppBar(title: Text(RimaText.ui('Notifications'))),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? Center(child: Text(RimaText.ui('No notifications yet.')))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final n = items[i];
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: RimaColors.goldSoft,
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: RimaColors.primary,
                              ),
                            ),
                            title: Text(
                              n['title']?.toString() ?? 'RIMA',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(n['body']?.toString() ?? ''),
                          ),
                        );
                      },
                    ),
                  ),
      );
}
