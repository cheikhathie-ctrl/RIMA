import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/colors.dart';

enum RideSafetyRole { customer, driver }

class RideSafetyScreen extends StatelessWidget {
  const RideSafetyScreen({
    super.key,
    required this.rideId,
    required this.role,
    required this.otherPartyName,
    required this.pickupLabel,
    required this.destinationLabel,
    required this.rideStatus,
  });

  final String rideId;
  final RideSafetyRole role;
  final String otherPartyName;
  final String pickupLabel;
  final String destinationLabel;
  final String rideStatus;

  bool get _isCustomer => role == RideSafetyRole.customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'RIMA Safety',
          style: TextStyle(
            color: RimaColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                _hero(),
                const SizedBox(height: 18),
                _actionCard(
                  icon: Icons.emergency_outlined,
                  title: 'Emergency assistance',
                  subtitle: 'Guidance for an urgent safety situation during this ride.',
                  onTap: () => _showEmergencyGuidance(context),
                ),
                const SizedBox(height: 12),
                _actionCard(
                  icon: Icons.share_location_outlined,
                  title: 'Share trip',
                  subtitle: 'Copy trip details to share with someone you trust.',
                  onTap: () => _shareTrip(context),
                ),
                const SizedBox(height: 12),
                _actionCard(
                  icon: Icons.report_gmailerrorred_rounded,
                  title: 'Report a safety issue',
                  subtitle: 'Record a concern about this ride for RIMA support.',
                  onTap: () => _showReportSheet(context),
                ),
                const SizedBox(height: 18),
                _tripCard(),
                const SizedBox(height: 12),
                _actionCard(
                  icon: Icons.copy_rounded,
                  title: 'Copy ride ID',
                  subtitle: rideId,
                  onTap: () => _copyRideId(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6ED),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(Icons.shield_rounded, size: 38, color: RimaColors.primary),
          ),
          SizedBox(height: 14),
          Text(
            'Your safety matters',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: RimaColors.primary),
          ),
          SizedBox(height: 7),
          Text(
            'Use these tools if you need help or want to share information about your active ride.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: RimaColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.35)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tripCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Current ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: RimaColors.primary)),
          ),
          const SizedBox(height: 14),
          _detailRow(Icons.person_outline_rounded, _isCustomer ? 'Driver' : 'Customer', otherPartyName),
          const Divider(height: 24),
          _detailRow(Icons.my_location_rounded, 'Pickup', pickupLabel),
          const Divider(height: 24),
          _detailRow(Icons.location_on_outlined, 'Destination', destinationLabel),
          const Divider(height: 24),
          _detailRow(Icons.info_outline_rounded, 'Status', rideStatus.replaceAll('_', ' ')),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: RimaColors.primary),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '--' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _copyRideId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: rideId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride ID copied.')));
  }

  Future<void> _shareTrip(BuildContext context) async {
    final details = [
      'RIMA active ride',
      'Ride ID: $rideId',
      '${_isCustomer ? 'Driver' : 'Customer'}: $otherPartyName',
      'Pickup: $pickupLabel',
      'Destination: $destinationLabel',
      'Status: ${rideStatus.replaceAll('_', ' ')}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: details));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip details copied. You can share them with a trusted person.')),
    );
  }

  void _showEmergencyGuidance(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Emergency assistance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text(
                'If there is immediate danger, move to a safe place when possible and contact the appropriate local emergency service.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Country-aware emergency calling and trusted contacts will be connected before production launch.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.report_gmailerrorred_rounded, size: 42, color: RimaColors.primary),
              const SizedBox(height: 10),
              const Text('Report a safety issue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text(
                'The Safety Center interface is ready. Next we will connect reports to RIMA support and store them securely.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
