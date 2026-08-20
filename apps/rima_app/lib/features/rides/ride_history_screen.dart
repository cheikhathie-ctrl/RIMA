import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  bool isLoading = true;
  String? loadError;
  List<Map<String, dynamic>> rides = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await Supabase.instance.client.rpc(
        'get_my_ride_history',
        params: {'p_limit': 50},
      );

      if (!mounted) return;

      setState(() {
        rides = List<Map<String, dynamic>>.from(data as List);
        isLoading = false;
        loadError = null;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = 'Unable to load ride history: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = 'Unable to load ride history.';
      });
    }
  }

  String _fare(Map<String, dynamic> ride) {
    final value = ride['final_fare_mru'] ?? ride['quoted_fare_mru'];
    if (value == null) return '-- MRU';
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return '${value.toString()} MRU';
    return parsed == parsed.roundToDouble()
        ? '${parsed.toStringAsFixed(0)} MRU'
        : '${parsed.toStringAsFixed(2)} MRU';
  }

  String _date(Map<String, dynamic> ride) {
    final raw = ride['completed_at'] ??
        ride['cancelled_at'] ??
        ride['requested_at'];
    if (raw == null) return 'Unknown date';

    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return 'Unknown date';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • '
        '${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _service(String? value) {
    switch (value) {
      case 'rima_comfort':
        return 'RIMA Comfort';
      case 'rima_xl':
        return 'RIMA XL';
      default:
        return 'RIMA Go';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ride history',
          style: TextStyle(
            color: RimaColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _body(),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: RimaColors.primary),
      );
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 52,
                color: RimaColors.primary,
              ),
              const SizedBox(height: 14),
              Text(loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    loadError = null;
                  });
                  _loadHistory();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (rides.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: RimaColors.primary,
              ),
              SizedBox(height: 18),
              Text(
                'No ride history yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Completed and cancelled rides will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        itemCount: rides.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _rideCard(rides[index]),
      ),
    );
  }

  Widget _rideCard(Map<String, dynamic> ride) {
    final status = ride['status']?.toString() ?? '';
    final completed = status == 'completed';
    final rating = ride['my_rating'];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideReceiptScreen(ride: ride),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _service(ride['service_type']?.toString()),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    _fare(ride),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: RimaColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _date(ride),
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 15),
              _location(
                Icons.my_location_rounded,
                ride['pickup_label']?.toString() ?? 'Pickup',
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: SizedBox(
                  height: 15,
                  child: VerticalDivider(width: 1),
                ),
              ),
              _location(
                Icons.location_on_rounded,
                ride['destination_label']?.toString() ?? 'Destination',
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: completed
                          ? const Color(0xFFEAF6ED)
                          : const Color(0xFFFFF3D6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      completed ? 'Completed' : 'Cancelled',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: RimaColors.primary,
                      ),
                    ),
                  ),
                  if (rating != null) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: RimaColors.gold,
                    ),
                    Text(
                      'You rated $rating/5',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black38,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _location(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: RimaColors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class RideReceiptScreen extends StatelessWidget {
  const RideReceiptScreen({
    super.key,
    required this.ride,
  });

  final Map<String, dynamic> ride;

  String _value(dynamic value, {String fallback = '--'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _fare() {
    final value = ride['final_fare_mru'] ?? ride['quoted_fare_mru'];
    if (value == null) return '-- MRU';
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return '${value.toString()} MRU';
    return parsed == parsed.roundToDouble()
        ? '${parsed.toStringAsFixed(0)} MRU'
        : '${parsed.toStringAsFixed(2)} MRU';
  }

  String _distance() {
    final value = ride['distance_meters'];
    final meters = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (meters == null) return '--';
    return meters < 1000
        ? '$meters m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _duration() {
    final value = ride['estimated_duration_seconds'];
    final seconds = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (seconds == null) return '--';
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '$hours h' : '$hours h $remainder min';
  }

  String _dateTime(dynamic raw) {
    if (raw == null) return '--';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '--';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final status = _value(ride['status']);
    final role = _value(ride['user_role']);
    final otherParty = _value(ride['other_party_name']);
    final vehicle = _value(ride['vehicle_description']);
    final plate = _value(ride['vehicle_plate']);
    final rating = ride['my_rating'];
    final comment = _value(ride['my_rating_comment'], fallback: '');

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ride receipt',
          style: TextStyle(
            color: RimaColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 52,
                          color: RimaColors.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          status == 'completed'
                              ? 'Ride completed'
                              : 'Ride cancelled',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _fare(),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: RimaColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _section(
                    'Trip',
                    [
                      _row('Ride ID', _value(ride['ride_id'])),
                      _row(
                        'Date',
                        _dateTime(
                          ride['completed_at'] ??
                              ride['cancelled_at'] ??
                              ride['requested_at'],
                        ),
                      ),
                      _row('Pickup', _value(ride['pickup_label'])),
                      _row(
                        'Destination',
                        _value(ride['destination_label']),
                      ),
                      _row('Distance', _distance()),
                      _row('Duration', _duration()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _section(
                    role == 'customer' ? 'Driver' : 'Customer',
                    [
                      _row(
                        role == 'customer' ? 'Driver' : 'Customer',
                        otherParty,
                      ),
                      if (role == 'customer' && vehicle != '--')
                        _row('Vehicle', vehicle),
                      if (role == 'customer' && plate != '--')
                        _row('Plate', plate),
                    ],
                  ),
                  if (rating != null) ...[
                    const SizedBox(height: 14),
                    _section(
                      'Your rating',
                      [
                        _row('Rating', '$rating / 5'),
                        if (comment.isNotEmpty)
                          _row('Comment', comment),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: RimaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
