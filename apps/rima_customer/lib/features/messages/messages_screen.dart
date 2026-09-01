import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/localization/rima_localization.dart';
import '../../app/theme/colors.dart';
import '../rides/ride_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool loading = true;
  List<Map<String, dynamic>> conversations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rides = await Supabase.instance.client
          .from('rides')
          .select('id, destination_label, requested_at, assigned_driver_id')
          .eq('customer_id', uid)
          .order('requested_at', ascending: false)
          .limit(50);
      final result = <Map<String, dynamic>>[];
      for (final raw in rides) {
        final ride = Map<String, dynamic>.from(raw);
        final msgs = await Supabase.instance.client
            .from('ride_messages')
            .select('message_text, created_at, read_at, sender_user_id')
            .eq('ride_id', ride['id'])
            .order('created_at', ascending: false)
            .limit(1);
        if (msgs.isNotEmpty) {
          final last = Map<String, dynamic>.from(msgs.first);
          result.add({
            ...ride,
            'last_message': last['message_text'],
            'last_message_at': last['created_at'],
          });
        }
      }
      if (!mounted) return;
      setState(() {
        conversations = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RimaColors.background,
      appBar: AppBar(title: Text(RimaText.ui('Messages'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 52,
                          color: RimaColors.primary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          RimaText.ui('No messages yet'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          RimaText.ui('Messages with your driver will appear here.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: RimaColors.muted),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = conversations[i];
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: RimaColors.primarySoft,
                            child: Icon(Icons.local_taxi, color: RimaColors.primary),
                          ),
                          title: Text(
                            c['destination_label']?.toString() ?? RimaText.ui('RIMA ride'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            c['last_message']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            RimaLocaleController.isArabic
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RideChatScreen(
                                rideId: c['id'].toString(),
                                otherPartyLabel: RimaText.ui('RIMA Driver'),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
