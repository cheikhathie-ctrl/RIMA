import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import 'driver_active_ride_screen.dart';

class DriverAvailableRidesScreen extends StatefulWidget {
  const DriverAvailableRidesScreen({super.key});

  @override
  State<DriverAvailableRidesScreen> createState() =>
      _DriverAvailableRidesScreenState();
}

class _DriverAvailableRidesScreenState
    extends State<DriverAvailableRidesScreen> {
  Timer? _refreshTimer;

  bool isLoading = true;
  bool isAcceptingRide = false;
  bool _isOpeningActiveRide = false;

  String? loadError;
  String? driverId;
  String? vehicleId;

  List<Map<String, dynamic>> availableRides = [];

  @override
  void initState() {
    super.initState();

    _initializeDriver();

    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _loadAvailableRides();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDriver() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = 'No authenticated driver account found.';
      });

      return;
    }

    try {
      final driverData = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final foundDriverId = driverData['id']?.toString();

      if (foundDriverId == null || foundDriverId.isEmpty) {
        throw Exception('Driver profile not found.');
      }

      final vehicleData = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('driver_id', foundDriverId)
          .eq('is_verified', true)
          .eq('is_active', true)
          .limit(1)
          .single();

      final foundVehicleId = vehicleData['id']?.toString();

      if (foundVehicleId == null || foundVehicleId.isEmpty) {
        throw Exception('Verified active vehicle not found.');
      }

      if (!mounted) return;

      setState(() {
        driverId = foundDriverId;
        vehicleId = foundVehicleId;
      });

      final resumedActiveRide = await _resumeActiveRideIfNeeded();

      if (!resumedActiveRide) {
        await _loadAvailableRides();
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA DRIVER INIT ERROR: ${e.message}');

      setState(() {
        isLoading = false;
        loadError = 'Unable to load driver profile: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA DRIVER INIT ERROR: $e');

      setState(() {
        isLoading = false;
        loadError = 'Unable to load driver profile.';
      });
    }
  }

  Future<bool> _resumeActiveRideIfNeeded() async {
    final currentDriverId = driverId;

    if (currentDriverId == null || _isOpeningActiveRide) {
      return false;
    }

    try {
      final rows = await Supabase.instance.client
          .from('rides')
          .select('id, status, updated_at')
          .eq('assigned_driver_id', currentDriverId)
          .inFilter('status', [
            'driver_assigned',
            'driver_arriving',
            'driver_arrived',
            'in_progress',
          ])
          .order('updated_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) {
        return false;
      }

      final activeRideId = rows.first['id']?.toString();

      if (activeRideId == null || activeRideId.isEmpty) {
        return false;
      }

      if (!mounted) return true;

      _isOpeningActiveRide = true;
      _refreshTimer?.cancel();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverActiveRideScreen(rideId: activeRideId),
        ),
      );

      return true;
    } on PostgrestException catch (e) {
      debugPrint('RIMA ACTIVE RIDE RECOVERY ERROR: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('RIMA ACTIVE RIDE RECOVERY ERROR: $e');
      return false;
    }
  }

  Future<void> _loadAvailableRides() async {
    if (driverId == null || vehicleId == null || _isOpeningActiveRide) {
      return;
    }

    final resumedActiveRide = await _resumeActiveRideIfNeeded();

    if (resumedActiveRide || !mounted) {
      return;
    }

    try {
      final data = await Supabase.instance.client.rpc('get_available_rides');

      if (!mounted) return;

      setState(() {
        availableRides = List<Map<String, dynamic>>.from(data);

        isLoading = false;
        loadError = null;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA AVAILABLE RIDES ERROR: ${e.message}');

      setState(() {
        isLoading = false;
        loadError = 'Unable to load available rides: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA AVAILABLE RIDES ERROR: $e');

      setState(() {
        isLoading = false;
        loadError = 'Unable to load available rides.';
      });
    }
  }

  Future<void> _acceptRide(Map<String, dynamic> ride) async {
    if (isAcceptingRide || vehicleId == null) {
      return;
    }

    final rideId = ride['id']?.toString();

    if (rideId == null || rideId.isEmpty) {
      return;
    }

    setState(() {
      isAcceptingRide = true;
    });

    try {
      await Supabase.instance.client.rpc(
        'accept_ride',
        params: {'p_ride_id': rideId, 'p_vehicle_id': vehicleId},
      );

      if (!mounted) return;

      _refreshTimer?.cancel();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverActiveRideScreen(rideId: rideId),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA ACCEPT RIDE ERROR: ${e.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to accept ride: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA ACCEPT RIDE ERROR: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to accept ride.')));
    } finally {
      if (mounted) {
        setState(() {
          isAcceptingRide = false;
        });
      }
    }
  }

  String _formatDistance(dynamic value) {
    if (value == null) {
      return '--';
    }

    final meters = value is int ? value : int.tryParse(value.toString());

    if (meters == null) {
      return '--';
    }

    if (meters < 1000) {
      return '$meters m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(dynamic value) {
    if (value == null) {
      return '--';
    }

    final seconds = value is int ? value : int.tryParse(value.toString());

    if (seconds == null) {
      return '--';
    }

    final minutes = (seconds / 60).ceil();

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (remaining == 0) {
      return '$hours h';
    }

    return '$hours h $remaining min';
  }

  String _serviceLabel(String? serviceType) {
    switch (serviceType) {
      case 'rima_comfort':
        return 'RIMA Comfort';

      case 'rima_xl':
        return 'RIMA XL';

      case 'rima_go':
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
          'Available rides',
          style: TextStyle(
            color: RimaColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadAvailableRides,
            icon: const Icon(Icons.refresh_rounded, color: RimaColors.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
                onPressed: _initializeDriver,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (availableRides.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_taxi_outlined,
                size: 64,
                color: RimaColors.primary,
              ),
              SizedBox(height: 18),
              Text(
                'No available rides right now',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'New RIMA requests will appear here automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAvailableRides,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        itemCount: availableRides.length,
        itemBuilder: (context, index) {
          final ride = availableRides[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _rideCard(ride),
          );
        },
      ),
    );
  }

  Widget _rideCard(Map<String, dynamic> ride) {
    final service = _serviceLabel(ride['service_type']?.toString());

    final pickup = ride['pickup_label']?.toString() ?? 'Pickup';

    final destination = ride['destination_label']?.toString() ?? 'Destination';

    final distance = _formatDistance(ride['distance_meters']);

    final duration = _formatDuration(ride['estimated_duration_seconds']);

    final fare = ride['quoted_fare_mru']?.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6ED),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  color: RimaColors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  service,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (fare != null)
                Text(
                  '$fare MRU',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: RimaColors.primary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          _rideDetail(Icons.my_location_rounded, 'Pickup', pickup),

          const SizedBox(height: 12),

          _rideDetail(Icons.location_on_rounded, 'Destination', destination),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _metricBox(Icons.route_outlined, 'Trip', distance),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(Icons.schedule_outlined, 'Time', duration),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isAcceptingRide
                  ? null
                  : () {
                      _acceptRide(ride);
                    },
              icon: isAcceptingRide
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                isAcceptingRide ? 'Accepting...' : 'Accept ride',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: RimaColors.primary, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: RimaColors.primary),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
