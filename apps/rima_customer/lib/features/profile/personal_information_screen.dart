import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/localization/rima_localization.dart';
import '../../app/theme/colors.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  final email = TextEditingController();
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final p = await Supabase.instance.client
        .from('profiles')
        .select('first_name,last_name,email,phone')
        .eq('id', uid)
        .maybeSingle();
    if (!mounted) return;
    if (p != null) {
      first.text = p['first_name']?.toString() ?? '';
      last.text = p['last_name']?.toString() ?? '';
      email.text = p['email']?.toString() ?? '';
    }
    setState(() => loading = false);
  }

  Future<void> _save() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => saving = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'first_name': first.text.trim(),
        'last_name': last.text.trim(),
        'email': email.text.trim().isEmpty ? null : email.text.trim(),
      }).eq('id', uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(RimaText.ui('Personal information updated.'))),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RimaColors.background,
        appBar: AppBar(title: Text(RimaText.ui('Personal information'))),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: first,
                    decoration: InputDecoration(labelText: RimaText.ui('First name')),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: last,
                    decoration: InputDecoration(labelText: RimaText.ui('Last name')),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: RimaText.ui('Email')),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: saving ? null : _save,
                      child: Text(RimaText.ui(saving ? 'Saving...' : 'Save changes')),
                    ),
                  ),
                ],
              ),
      );
}
