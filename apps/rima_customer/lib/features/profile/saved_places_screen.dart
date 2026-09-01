import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/localization/rima_localization.dart';
import '../../app/theme/colors.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  bool loading = true;
  List<Map<String, dynamic>> places = [];

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
          .from('saved_places')
          .select()
          .eq('user_id', uid)
          .order('created_at');
      if (mounted) {
        setState(() {
          places = List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e)),
          );
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _delete(String id) async {
    await Supabase.instance.client.from('saved_places').delete().eq('id', id);
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RimaColors.background,
        appBar: AppBar(title: Text(RimaText.ui('Saved places'))),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : places.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bookmark_border_rounded,
                            size: 52,
                            color: RimaColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            RimaText.ui('No saved places yet'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            RimaText.ui('Places saved during booking will appear here.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: RimaColors.muted),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: places.length,
                      itemBuilder: (_, i) {
                        final p = places[i];
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          child: ListTile(
                            leading: const Icon(
                              Icons.place_outlined,
                              color: RimaColors.primary,
                            ),
                            title: Text(
                              p['label']?.toString() ?? RimaText.ui('Saved place'),
                            ),
                            subtitle: Text(
                              p['place_type']?.toString() ?? RimaText.ui('Location'),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(p['id'].toString()),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      );
}
