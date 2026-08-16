import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme/colors.dart';
import 'ride_searching_screen.dart';

class RideOptionsScreen extends StatefulWidget {
  const RideOptionsScreen({
    super.key,
    required this.pickupPosition,
    required this.destinationPosition,
    required this.destination,
  });

  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final String destination;

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  String selectedRide = 'RIMA Go';

  bool isRequestingRide = false;
  bool isLoadingRoute = true;

  int? distanceMeters;
  int? durationSeconds;
  String? encodedPolyline;

  String? routeError;

  final Map<String, String> prices = {
    'RIMA Go': '250 MRU',
    'RIMA Comfort': '350 MRU',
    'RIMA XL': '450 MRU',
  };

  final Map<String, double> numericPrices = {
    'RIMA Go': 250,
    'RIMA Comfort': 350,
    'RIMA XL': 450,
  };

  final Map<String, String> serviceTypes = {
    'RIMA Go': 'rima_go',
    'RIMA Comfort': 'rima_comfort',
    'RIMA XL': 'rima_xl',
  };

  @override
  void initState() {
    super.initState();

    _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() {
      isLoadingRoute = true;
      routeError = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'calculate-route',
        body: {
          'pickup': {
            'latitude': widget.pickupPosition.latitude,
            'longitude': widget.pickupPosition.longitude,
          },
          'destination': {
            'latitude': widget.destinationPosition.latitude,
            'longitude': widget.destinationPosition.longitude,
          },
        },
      );

      if (!mounted) return;

      final data = response.data;

      if (data == null || data is! Map) {
        throw Exception('Invalid route response.');
      }

      if (data['error'] != null) {
        throw Exception(data['error'].toString());
      }

      final rawDistance = data['distance_meters'];

      final rawDuration = data['duration_seconds'];

      final parsedDistance = rawDistance is int
          ? rawDistance
          : int.tryParse(rawDistance?.toString() ?? '');

      final parsedDuration = rawDuration is int
          ? rawDuration
          : int.tryParse(rawDuration?.toString() ?? '');

      if (parsedDistance == null || parsedDuration == null) {
        throw Exception('Route distance or duration is missing.');
      }

      setState(() {
        distanceMeters = parsedDistance;
        durationSeconds = parsedDuration;

        encodedPolyline = data['encoded_polyline']?.toString();

        isLoadingRoute = false;
      });
    } on FunctionException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA ROUTE FUNCTION ERROR: ${e.details}');

      setState(() {
        routeError = 'Unable to calculate route.';
        isLoadingRoute = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA ROUTE ERROR: $e');

      setState(() {
        routeError = 'Unable to calculate route.';
        isLoadingRoute = false;
      });
    }
  }

  String get formattedDistance {
    final value = distanceMeters;

    if (value == null) {
      return '--';
    }

    if (value < 1000) {
      return '$value m';
    }

    final km = value / 1000;

    if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    }

    return '${km.toStringAsFixed(0)} km';
  }

  String get formattedDuration {
    final value = durationSeconds;

    if (value == null) {
      return '--';
    }

    final totalMinutes = (value / 60).ceil();

    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final hours = totalMinutes ~/ 60;

    final minutes = totalMinutes % 60;

    if (minutes == 0) {
      return '$hours h';
    }

    return '$hours h $minutes min';
  }

  Future<void> _requestRide() async {
    if (isRequestingRide) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before requesting a ride.'),
        ),
      );
      return;
    }

    if (distanceMeters == null || durationSeconds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while RIMA calculates your route.'),
        ),
      );
      return;
    }

    setState(() {
      isRequestingRide = true;
    });

    try {
      final result = await Supabase.instance.client.rpc(
        'request_ride',
        params: {
          'p_service_type': serviceTypes[selectedRide],

          'p_pickup_latitude': widget.pickupPosition.latitude,

          'p_pickup_longitude': widget.pickupPosition.longitude,

          'p_pickup_label': 'Your current location',

          'p_destination_latitude': widget.destinationPosition.latitude,

          'p_destination_longitude': widget.destinationPosition.longitude,

          'p_destination_label': widget.destination,

          'p_pickup_area_id': null,
          'p_destination_area_id': null,
          'p_destination_landmark_id': null,

          'p_google_destination_place_id': null,

          'p_quoted_fare_mru': numericPrices[selectedRide],

          'p_distance_meters': distanceMeters,

          'p_estimated_duration_seconds': durationSeconds,
        },
      );

      if (!mounted) return;

      if (result == null) {
        throw Exception('No ride was returned by Supabase.');
      }

      String? rideId;

      if (result is Map<String, dynamic>) {
        rideId = result['id']?.toString();
      } else if (result is Map) {
        rideId = result['id']?.toString();
      }

      if (rideId == null || rideId.isEmpty) {
        throw Exception('Supabase did not return a ride ID.');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideSearchingScreen(
            rideId: rideId!,
            rideType: selectedRide,
            destination: widget.destination,
            fare: prices[selectedRide]!,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RIMA ride created • ${rideId.substring(0, 8)}'),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA REQUEST RIDE ERROR: ${e.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to request ride: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA REQUEST RIDE ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to request your ride. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRequestingRide = false;
        });
      }
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
          'Choose your ride',
          style: TextStyle(
            color: RimaColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: RimaColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.destination,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _routeSummary(),

                  const SizedBox(height: 26),

                  const Text(
                    'Ride options',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 14),

                  _rideOption(
                    icon: Icons.directions_car_rounded,
                    title: 'RIMA Go',
                    subtitle: 'Affordable everyday ride',
                    eta: 'Pickup ETA later',
                    price: '250 MRU',
                  ),

                  const SizedBox(height: 12),

                  _rideOption(
                    icon: Icons.local_taxi_rounded,
                    title: 'RIMA Comfort',
                    subtitle: 'More comfort and space',
                    eta: 'Pickup ETA later',
                    price: '350 MRU',
                  ),

                  const SizedBox(height: 12),

                  _rideOption(
                    icon: Icons.airport_shuttle_rounded,
                    title: 'RIMA XL',
                    subtitle: 'For groups and more luggage',
                    eta: 'Pickup ETA later',
                    price: '450 MRU',
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: RimaColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Estimated fare',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          prices[selectedRide] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: RimaColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: isRequestingRide || isLoadingRoute
                          ? null
                          : _requestRide,
                      child: isRequestingRide
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isLoadingRoute
                                  ? 'Calculating route...'
                                  : 'Request $selectedRide',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _routeSummary() {
    if (isLoadingRoute) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: RimaColors.primary,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Calculating driving route...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (routeError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: RimaColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(routeError!)),
            TextButton(onPressed: _loadRoute, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _routeValue(
              icon: Icons.route_outlined,
              label: 'Trip distance',
              value: formattedDistance,
            ),
          ),
          Container(height: 45, width: 1, color: Colors.black12),
          Expanded(
            child: _routeValue(
              icon: Icons.schedule_outlined,
              label: 'Trip time',
              value: formattedDuration,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeValue({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: RimaColors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _rideOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String eta,
    required String price,
  }) {
    final bool isSelected = selectedRide == title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            selectedRide = title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF3D6) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? RimaColors.gold : Colors.black12,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: RimaColors.primary),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$subtitle • $eta',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: RimaColors.primary,
                    ),
                  ),

                  if (isSelected) ...[
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: RimaColors.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
