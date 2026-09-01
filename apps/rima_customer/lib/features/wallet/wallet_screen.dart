import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme/colors.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> payments = [];

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
          .from('ride_payments')
          .select('id, ride_id, amount_mru, payment_method, payment_status, provider, paid_at, created_at')
          .eq('customer_id', uid)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        payments = List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e)));
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = 'Unable to load wallet activity.'; loading = false; });
    }
  }

  String _money(dynamic v) {
    final n = double.tryParse(v?.toString() ?? '');
    return n == null ? '-- MRU' : '${n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2)} MRU';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RimaColors.background,
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? ListView(children: [SizedBox(height: 260), Center(child: CircularProgressIndicator())])
            : error != null
                ? ListView(children: [const SizedBox(height: 220), Center(child: Text('Unable to load wallet activity.'))])
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [RimaColors.primaryDark, RimaColors.primary]),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RIMA Wallet', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            SizedBox(height: 8),
                            Text('Ride payments', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                            SizedBox(height: 8),
                            Text('Your completed and pending ride transactions appear here.', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      if (payments.isEmpty)
                        _empty()
                      else
                        ...payments.map((p) => Card(
                          color: RimaColors.surface,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: RimaColors.primarySoft, child: Icon(Icons.receipt_long, color: RimaColors.primary)),
                            title: Text(_money(p['amount_mru']), style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${p['payment_method'] ?? 'Payment'} • ${p['payment_status'] ?? 'unknown'}'),
                            trailing: Text((p['created_at'] ?? '').toString().split('T').first),
                          ),
                        )),
                    ],
                  ),
      ),
    );
  }

  Widget _empty() => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
    child: const Column(children: [
      Icon(Icons.account_balance_wallet_outlined, size: 46, color: RimaColors.primary),
      SizedBox(height: 12),
      Text('No transactions yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      SizedBox(height: 4),
      Text('Your RIMA ride payments will appear here.', textAlign: TextAlign.center, style: TextStyle(color: RimaColors.muted)),
    ]),
  );
}
