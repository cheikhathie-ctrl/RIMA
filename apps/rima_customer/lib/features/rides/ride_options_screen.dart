import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import 'location_search_screen.dart';
import 'ride_searching_screen.dart';

class RideOptionsScreen extends StatefulWidget {
  const RideOptionsScreen({
    super.key,
    required this.pickupPosition,
    required this.destinationPosition,
    required this.destination,
    this.pickupLabel = 'Your pickup',
  });

  final LatLng pickupPosition;
  final LatLng destinationPosition;

  final String destination;

  //
  // Optional so existing screens that already call
  // RideOptionsScreen do not break.
  //
  final String pickupLabel;

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  String selectedRide = 'RIMA Go';

  bool isRequestingRide = false;
  bool isLoadingRoute = true;
  bool isLoadingPaymentProviders = true;

  List<Map<String, dynamic>> paymentProviders = [];

  String? selectedPaymentMethod;

  int? distanceMeters;
  int? durationSeconds;

  String? routeError;

  //
  // LOCAL EDITABLE TRIP VALUES
  //
  late LatLng pickupPosition;
  late LatLng destinationPosition;

  late String pickupLabel;
  late String destinationLabel;

  final Map<String, double> quotedFares = {};

  bool isLoadingFares = false;
  String? fareError;

  final Map<String, String> serviceTypes = {
    'RIMA Go': 'rima_go',
    'RIMA Comfort': 'rima_comfort',
    'RIMA XL': 'rima_xl',
  };

  @override
  void initState() {
    super.initState();

    pickupPosition = widget.pickupPosition;

    destinationPosition = widget.destinationPosition;

    pickupLabel = widget.pickupLabel;

    destinationLabel = widget.destination;

    _loadRoute();
    _loadPaymentProviders();
  }

  Future<void> _loadPaymentProviders() async {
    try {
      final data = await Supabase.instance.client.rpc(
        'get_available_payment_providers',
      );
      if (!mounted) return;
      setState(() {
        paymentProviders = List<Map<String, dynamic>>.from(data as List);
        isLoadingPaymentProviders = false;
      });
    } catch (e) {
      debugPrint('RIMA PAYMENT PROVIDERS ERROR: $e');
      if (!mounted) return;
      setState(() {
        paymentProviders = [];
        isLoadingPaymentProviders = false;
      });
    }
  }

  //
  // ROUTE CALCULATION
  //
  Future<void> _loadRoute() async {
    setState(() {
      isLoadingRoute = true;
      routeError = null;

      distanceMeters = null;
      durationSeconds = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'calculate-route',
        body: {
          'pickup': {
            'latitude': pickupPosition.latitude,
            'longitude': pickupPosition.longitude,
          },
          'destination': {
            'latitude': destinationPosition.latitude,
            'longitude': destinationPosition.longitude,
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

        isLoadingRoute = false;
      });
      await _loadFares();
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

  Future<void> _loadFares() async {
    final distance = distanceMeters;
    final duration = durationSeconds;

    if (distance == null || duration == null) {
      return;
    }

    setState(() {
      isLoadingFares = true;
      fareError = null;
    });

    try {
      final newFares = <String, double>{};

      for (final entry in serviceTypes.entries) {
        final result = await Supabase.instance.client.rpc(
          'calculate_ride_fare',
          params: {
            'p_service_type': entry.value,
            'p_distance_meters': distance,
            'p_duration_seconds': duration,
          },
        );

        final fare = result is num
            ? result.toDouble()
            : double.tryParse(result.toString());

        if (fare == null) {
          throw Exception('Invalid fare returned for ${entry.key}.');
        }

        newFares[entry.key] = fare;
      }

      if (!mounted) return;

      setState(() {
        quotedFares
          ..clear()
          ..addAll(newFares);

        isLoadingFares = false;
      });
    } catch (e) {
      debugPrint('RIMA FARE ERROR: $e');

      if (!mounted) return;

      setState(() {
        quotedFares.clear();
        fareError = 'Unable to calculate fare.';
        isLoadingFares = false;
      });
    }
  }

  String _formattedFare(String rideType) {
    final fare = quotedFares[rideType];

    if (fare == null) {
      return '--';
    }

    final amount = fare == fare.roundToDouble()
        ? fare.toStringAsFixed(0)
        : fare.toStringAsFixed(2);

    return '$amount MRU';
  }

  //
  // CHANGE PICKUP
  //
  Future<void> _changePickup() async {
    if (isRequestingRide) {
      return;
    }

    final result = await Navigator.push<LocationSearchResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSearchScreen(
          pickupPosition: pickupPosition,

          mode: LocationSearchMode.pickup,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      pickupPosition = result.position;

      pickupLabel = result.name;
    });

    //
    // Every time customer changes pickup,
    // route must be recalculated.
    //
    await _loadRoute();
  }

  //
  // CHANGE DESTINATION
  //
  //
  // Destination selection currently continues through
  // DestinationMapScreen. Therefore the safest behavior
  // is to return the customer to the previous destination
  // confirmation screen instead of creating duplicate
  // RideOptionsScreen pages.
  //
  void _changeDestination() {
    if (isRequestingRide) {
      return;
    }

    Navigator.pop(context);
  }

  //
  // CHANGE ENTIRE TRIP
  //
  void _changeTrip() {
    if (isRequestingRide) {
      return;
    }

    Navigator.pop(context);
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

  //
  // REQUEST RIDE
  //
  Future<void> _requestRide() async {
    if (isRequestingRide) {
      return;
    }

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

    if (quotedFares[selectedRide] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while RIMA calculates your fare.'),
        ),
      );

      return;
    }

    setState(() {
      isRequestingRide = true;
    });

    try {
      //
      // 1. CREATE THE RIDE
      //
      final result = await Supabase.instance.client.rpc(
        'request_ride',
        params: {
          'p_service_type': serviceTypes[selectedRide],

          'p_pickup_latitude': pickupPosition.latitude,

          'p_pickup_longitude': pickupPosition.longitude,

          'p_pickup_label': pickupLabel,

          'p_destination_latitude': destinationPosition.latitude,

          'p_destination_longitude': destinationPosition.longitude,

          'p_destination_label': destinationLabel,

          'p_pickup_area_id': null,

          'p_destination_area_id': null,

          'p_destination_landmark_id': null,

          'p_google_destination_place_id': null,

          'p_quoted_fare_mru': quotedFares[selectedRide],

          'p_distance_meters': distanceMeters,

          'p_estimated_duration_seconds': durationSeconds,
        },
      );

      if (!mounted) return;

      if (result == null) {
        throw Exception('No ride was returned by Supabase.');
      }

      //
      // 2. GET THE NEW RIDE ID
      //
      String? rideId;

      if (result is Map<String, dynamic>) {
        rideId = result['id']?.toString();
      } else if (result is Map) {
        rideId = result['id']?.toString();
      }

      if (rideId == null || rideId.isEmpty) {
        throw Exception('Supabase did not return a ride ID.');
      }

      debugPrint('RIMA RIDE CREATED: $rideId');

      //
      // 3. SAVE PAYMENT METHOD
      //    IF ONE IS SELECTED
      //
      //
      // Payment providers are still disabled
      // during development, so this remains
      // optional for now.
      //
      final paymentMethod = selectedPaymentMethod;

      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        await Supabase.instance.client.rpc(
          'set_ride_payment_method',
          params: {'p_ride_id': rideId, 'p_payment_method': paymentMethod},
        );

        debugPrint(
          'RIMA PAYMENT METHOD SET: '
          '$paymentMethod',
        );
      }

      if (!mounted) return;

      //
      // 4. SEND NEW RIDE PUSH
      //    TO APPROVED DRIVERS
      //
      //
      // A push failure must NOT undo
      // a successfully created ride.
      //
      try {
        final pushResponse = await Supabase.instance.client.functions.invoke(
          'dispatch-new-ride',
          body: {'ride_id': rideId},
        );

        debugPrint(
          'RIMA NEW RIDE PUSH: '
          '${pushResponse.data}',
        );
      } on FunctionException catch (e) {
        debugPrint(
          'RIMA NEW RIDE PUSH '
          'FUNCTION ERROR: ${e.details}',
        );
      } catch (e) {
        debugPrint('RIMA NEW RIDE PUSH ERROR: $e');
      }

      if (!mounted) return;

      //
      // 5. MOVE CUSTOMER TO
      //    SEARCHING SCREEN
      //
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideSearchingScreen(
            rideId: rideId!,
            rideType: selectedRide,
            destination: destinationLabel,
            fare: _formattedFare(selectedRide),
          ),
        ),
      );

      //
      // 6. CONFIRM RIDE CREATION
      //
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'RIMA ride created • '
            '${rideId.substring(0, 8)}',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint(
        'RIMA REQUEST RIDE ERROR: '
        '${e.message}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to request ride: '
            '${e.message}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA REQUEST RIDE ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to request your ride. '
            'Please try again.',
          ),
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
                  //
                  // TRIP DETAILS HEADER
                  //
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Trip details',

                          style: TextStyle(
                            fontSize: 22,

                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      TextButton.icon(
                        onPressed: isRequestingRide ? null : _changeTrip,

                        icon: const Icon(Icons.edit_road_outlined, size: 18),

                        label: const Text(
                          'Change trip',

                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  //
                  // PICKUP
                  //
                  _tripLocationCard(
                    icon: Icons.radio_button_checked_rounded,

                    iconColor: RimaColors.primary,

                    title: 'Pickup',

                    value: pickupLabel,

                    changeText: 'Change pickup',

                    onChange: _changePickup,
                  ),

                  const SizedBox(height: 12),

                  //
                  // DESTINATION
                  //
                  _tripLocationCard(
                    icon: Icons.location_on_rounded,

                    iconColor: RimaColors.gold,

                    title: 'Destination',

                    value: destinationLabel,

                    changeText: 'Change destination',

                    onChange: _changeDestination,
                  ),

                  const SizedBox(height: 18),

                  //
                  // ROUTE SUMMARY
                  //
                  _routeSummary(),

                  const SizedBox(height: 26),

                  //
                  // RIDE OPTIONS
                  //
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

                    price: isLoadingFares
                        ? 'Calculating...'
                        : _formattedFare('RIMA Go'),
                  ),

                  const SizedBox(height: 12),

                  _rideOption(
                    icon: Icons.local_taxi_rounded,

                    title: 'RIMA Comfort',

                    subtitle: 'More comfort and space',

                    eta: 'Pickup ETA later',

                    price: isLoadingFares
                        ? 'Calculating...'
                        : _formattedFare('RIMA Comfort'),
                  ),

                  const SizedBox(height: 12),

                  _rideOption(
                    icon: Icons.airport_shuttle_rounded,

                    title: 'RIMA XL',

                    subtitle: 'For groups and more luggage',

                    eta: 'Pickup ETA later',

                    price: isLoadingFares
                        ? 'Calculating...'
                        : _formattedFare('RIMA XL'),
                  ),

                  const SizedBox(height: 30),

                  //
                  // ESTIMATED FARE
                  //
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(20),

                     border: Border.all(
  color: RimaColors.primary,
  width: 1.7,
),
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
                          isLoadingFares
                              ? 'Calculating...'
                              : _formattedFare(selectedRide),

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

                  _paymentMethodsCard(),

                  const SizedBox(height: 18),

                  //
                  // REQUEST RIDE
                  //
                  SizedBox(
                    width: double.infinity,

                    height: 58,

                    child: ElevatedButton(
                      onPressed:
                          isRequestingRide ||
                              isLoadingRoute ||
                              isLoadingFares ||
                              fareError != null ||
                              quotedFares[selectedRide] == null ||
                              routeError != null
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

                  const SizedBox(height: 12),

                  //
                  // SECOND CHANGE OPTION
                  //
                  SizedBox(
                    width: double.infinity,

                    child: TextButton.icon(
                      onPressed: isRequestingRide ? null : _changeTrip,

                      icon: const Icon(Icons.arrow_back_rounded),

                      label: const Text(
                        'Change trip details',

                        style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _paymentMethodsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
  color: RimaColors.primary,
  width: 1.7,
),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: RimaColors.primary,
              ),
              SizedBox(width: 10),
              Text(
                'Payment method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Choose how you want to pay for your RIMA ride.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 14),

          if (isLoadingPaymentProviders)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: RimaColors.primary,
                ),
              ),
            )
          else if (paymentProviders.isEmpty)
            const Text(
              'Payment methods are being prepared.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...paymentProviders.map((provider) {
              final code = provider['code']?.toString() ?? '';

              final name =
                  provider['display_name']?.toString() ?? 'Payment provider';

              final enabled = provider['is_enabled'] == true;

              final isSelected = selectedPaymentMethod == code;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: !enabled || isRequestingRide
                      ? null
                      : () {
                          setState(() {
                            selectedPaymentMethod = code;
                          });
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEAF6ED)
                          : const Color(0xFFF8F8F5),
                      borderRadius: BorderRadius.circular(14),
                     border: Border.all(
  color: RimaColors.primary,
  width: isSelected ? 2 : 1.4,
),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: enabled ? RimaColors.primary : Colors.black26,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: enabled ? Colors.black87 : Colors.black38,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: enabled
                                ? const Color(0xFFEAF6ED)
                                : const Color(0xFFFFF3D6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            enabled ? 'Available' : 'Coming soon',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: RimaColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  //
  // TRIP LOCATION CARD
  //
  Widget _tripLocationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String changeText,
    required VoidCallback onChange,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
  color: RimaColors.primary,
  width: 1.7,
),
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F2),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(icon, color: iconColor),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),

                const SizedBox(height: 3),

                Text(
                  value,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 16,

                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          TextButton(
            onPressed: isRequestingRide ? null : onChange,

            child: Text(
              changeText,

              style: const TextStyle(
                fontWeight: FontWeight.w700,

                color: RimaColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //
  // ROUTE SUMMARY
  //
  Widget _routeSummary() {
    if (isLoadingRoute) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(20),

        border: Border.all(
  color: RimaColors.primary,
  width: 1.7,
),
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

      border: Border.all(
  color: RimaColors.primary,
  width: 1.7,
),
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

          Container(
  height: 62,
  width: 2,
  color: RimaColors.primary,
),

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
    final isSelected = selectedRide == title;

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
  color: RimaColors.primary,
  width: isSelected ? 2 : 1.5,
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
