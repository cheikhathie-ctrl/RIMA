import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/localization/rima_localization.dart';
import '../../app/theme/colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final subject = TextEditingController();
  final message = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    subject.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || message.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      final p = await Supabase.instance.client
          .from('profiles')
          .select('first_name,last_name,email,phone')
          .eq('id', uid)
          .maybeSingle();
      await Supabase.instance.client.from('contact_messages').insert({
        'name': '${p?['first_name'] ?? ''} ${p?['last_name'] ?? ''}'.trim(),
        'email': p?['email'],
        'phone': p?['phone'],
        'subject': subject.text.trim().isEmpty
            ? 'RIMA app support'
            : subject.text.trim(),
        'message': message.text.trim(),
        'status': 'new',
      });
      if (mounted) {
        message.clear();
        subject.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(RimaText.ui('Your support request was sent.'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(RimaText.ui('Unable to send support request.'))),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RimaColors.background,
        appBar: AppBar(title: Text(RimaText.ui('Help & support'))),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              RimaText.ui('How can we help?'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              RimaText.ui('Send a message to the RIMA support team.'),
              style: const TextStyle(color: RimaColors.muted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: subject,
              decoration: InputDecoration(labelText: RimaText.ui('Subject')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: message,
              minLines: 5,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: RimaText.ui('Message'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: sending ? null : _send,
                child: Text(RimaText.ui(sending ? 'Sending...' : 'Send to support')),
              ),
            ),
          ],
        ),
      );
}
