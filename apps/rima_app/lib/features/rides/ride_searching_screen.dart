import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import '../home/home_screen.dart';
import 'widgets/ride_live_map.dart';

class RideSearchingScreen extends StatefulWidget {
  const RideSearchingScreen({
    super.key,
    required this.rideId,
    required this.rideType,
    required this.destination,
    required this.fare,
  });

  final String rideId;
  final String rideType;
  final String destination;
  final String fare;

  @override
  State<RideSearchingScreen> createState() =>
      _RideSearchingScreenState();
}

class _RideSearchingScreenState
    extends State<RideSearchingScreen> {
  Timer? _pollTimer;

  String rideStatus = 'searching';

  String? assignedDriverId;
  String? vehicleId;

  int? distanceMeters;
  int? estimatedDurationSeconds;

  double? driverRating;

  String? vehicleMake;
  String? vehicleModel;
  String? vehicleColor;
  String? vehiclePlate;

  bool isLoading = true;
  bool isCancelling = false;

  bool _completionHandled = false;
  bool _cancellationHandled = false;

  String? loadError;

  @override
  void initState() {
    super.initState();

    _loadRide();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        _loadRide();
      },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool get driverAssigned {
    return rideStatus == 'driver_assigned' ||
        rideStatus == 'driver_arriving' ||
        rideStatus == 'driver_arrived' ||
        rideStatus == 'in_progress' ||
        rideStatus == 'completed';
  }

  bool get rideCancelled {
    return rideStatus == 'cancelled';
  }

  bool get rideCompleted {
    return rideStatus == 'completed';
  }

  String get formattedDistance {
    final value = distanceMeters;

    if (value == null) {
      return '--';
    }

    if (value < 1000) {
      return '$value m';
    }

    return '${(value / 1000).toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final value =
        estimatedDurationSeconds;

    if (value == null) {
      return '--';
    }

    final totalMinutes =
        (value / 60).ceil();

    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final hours =
        totalMinutes ~/ 60;

    final minutes =
        totalMinutes % 60;

    if (minutes == 0) {
      return '$hours h';
    }

    return '$hours h $minutes min';
  }

  Future<void> _loadRide() async {
    try {
      final data =
          await Supabase.instance.client
              .from('rides')
              .select(
                'status, assigned_driver_id, vehicle_id, '
                'distance_meters, estimated_duration_seconds',
              )
              .eq(
                'id',
                widget.rideId,
              )
              .single();

      final newStatus =
          data['status']?.toString() ??
              'searching';

      final newDriverId =
          data['assigned_driver_id']
              ?.toString();

      final newVehicleId =
          data['vehicle_id']
              ?.toString();

      final rawDistance =
          data['distance_meters'];

      final rawDuration =
          data['estimated_duration_seconds'];

      final parsedDistance =
          rawDistance is int
              ? rawDistance
              : int.tryParse(
                  rawDistance
                          ?.toString() ??
                      '',
                );

      final parsedDuration =
          rawDuration is int
              ? rawDuration
              : int.tryParse(
                  rawDuration
                          ?.toString() ??
                      '',
                );

      if (newDriverId != null) {
        await _loadDriver(
          newDriverId,
        );
      }

      if (newVehicleId != null) {
        await _loadVehicle(
          newVehicleId,
        );
      }

      if (!mounted) return;

      setState(() {
        rideStatus = newStatus;

        assignedDriverId =
            newDriverId;

        vehicleId =
            newVehicleId;

        distanceMeters =
            parsedDistance;

        estimatedDurationSeconds =
            parsedDuration;

        isLoading = false;
        loadError = null;
      });

      if (newStatus ==
          'completed') {
        _pollTimer?.cancel();
        _handleCompletedRide();
      } else if (newStatus ==
          'cancelled') {
        _pollTimer?.cancel();
        _handleCancelledRide();
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint(
        'RIMA RIDE STATUS ERROR: ${e.message}',
      );

      setState(() {
        isLoading = false;
        loadError =
            'Unable to check ride status.';
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'RIMA RIDE STATUS ERROR: $e',
      );

      setState(() {
        isLoading = false;
        loadError =
            'Unable to check ride status.';
      });
    }
  }

  void _handleCompletedRide() {
    if (_completionHandled) {
      return;
    }

    _completionHandled = true;

    Future.delayed(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const HomeScreen(),
          ),
          (route) => false,
        );
      },
    );
  }

  void _handleCancelledRide() {
    if (_cancellationHandled) {
      return;
    }

    _cancellationHandled = true;

    Future.delayed(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const HomeScreen(),
          ),
          (route) => false,
        );
      },
    );
  }

  Future<void> _loadDriver(
    String driverId,
  ) async {
    try {
      final data =
          await Supabase.instance.client
              .from('drivers')
              .select('rating')
              .eq(
                'id',
                driverId,
              )
              .single();

      final rawRating =
          data['rating'];

      driverRating =
          rawRating == null
              ? null
              : double.tryParse(
                  rawRating.toString(),
                );
    } catch (e) {
      debugPrint(
        'RIMA DRIVER LOAD ERROR: $e',
      );
    }
  }

  Future<void> _loadVehicle(
    String vehicleId,
  ) async {
    try {
      final data =
          await Supabase.instance.client
              .from('vehicles')
              .select(
                'make, model, color, license_plate',
              )
              .eq(
                'id',
                vehicleId,
              )
              .single();

      vehicleMake =
          data['make']?.toString();

      vehicleModel =
          data['model']?.toString();

      vehicleColor =
          data['color']?.toString();

      vehiclePlate =
          data['license_plate']
              ?.toString();
    } catch (e) {
      debugPrint(
        'RIMA VEHICLE LOAD ERROR: $e',
      );
    }
  }

  Future<void> _cancelRide() async {
    if (isCancelling) {
      return;
    }

    final shouldCancel =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Cancel ride?',
          ),
          content:
              const Text(
            'Are you sure you want to cancel this RIMA ride?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Keep ride',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text(
                'Cancel ride',
              ),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) {
      return;
    }

    setState(() {
      isCancelling = true;
    });

    try {
      await Supabase.instance.client.rpc(
        'cancel_ride',
        params: {
          'p_ride_id':
              widget.rideId,
          'p_reason':
              'Cancelled by customer',
        },
      );

      await _loadRide();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Ride cancelled.'),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to cancel ride: ${e.message}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCancelling = false;
        });
      }
    }
  }

  String get _statusTitle {
    switch (rideStatus) {
      case 'requested':
      case 'searching':
        return 'Finding your driver';

      case 'driver_assigned':
        return 'Driver found';

      case 'driver_arriving':
        return 'Driver on the way';

      case 'driver_arrived':
        return 'Driver has arrived';

      case 'in_progress':
        return 'Ride in progress';

      case 'completed':
        return 'Ride completed';

      case 'cancelled':
        return 'Ride cancelled';

      default:
        return 'RIMA Go';
    }
  }

  String get _statusMessage {
    switch (rideStatus) {
      case 'requested':
      case 'searching':
        return 'Searching for available RIMA drivers nearby.';

      case 'driver_assigned':
        return 'A RIMA driver accepted your ride.';

      case 'driver_arriving':
        return 'Your driver is heading to your pickup location.';

      case 'driver_arrived':
        return 'Your driver is waiting at your pickup location.';

      case 'in_progress':
        return 'You are on your way to your destination.';

      case 'completed':
        return 'Thank you for riding with RIMA. Returning home...';

      case 'cancelled':
        return 'This ride has been cancelled. Returning home...';

      default:
        return 'Checking your ride status...';
    }
  }

  IconData get _statusIcon {
    switch (rideStatus) {
      case 'driver_assigned':
      case 'driver_arriving':
        return Icons.local_taxi_rounded;

      case 'driver_arrived':
        return Icons
            .directions_car_filled_rounded;

      case 'in_progress':
        return Icons.route_rounded;

      case 'completed':
        return Icons
            .check_circle_rounded;

      case 'cancelled':
        return Icons.cancel_outlined;

      default:
        return Icons.search_rounded;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFFFFDF7,
      ),

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        title: Text(
          _statusTitle,
          style:
              const TextStyle(
            color:
                RimaColors.primary,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 520,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child:
                  _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: RimaColors.primary,
        ),
      );
    }

    if (loadError != null) {
      return Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 54,
              color: RimaColors.primary,
            ),

            const SizedBox(height: 15),

            Text(
              loadError!,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _loadRide,
              child: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          Container(
            width: 105,
            height: 105,

            decoration:
                const BoxDecoration(
              color: Color(0xFFEAF6ED),
              shape: BoxShape.circle,
            ),

            child: Icon(
              _statusIcon,
              size: 50,
              color: RimaColors.primary,
            ),
          ),

          const SizedBox(height: 22),

          if (!driverAssigned &&
              !rideCancelled) ...[
            const CircularProgressIndicator(
              color: RimaColors.primary,
            ),

            const SizedBox(height: 20),
          ],

          Text(
            _statusTitle,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.w800,
              color:
                  RimaColors.primary,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _statusMessage,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          //
          // CUSTOMER MAP
          //
          // Before ride starts:
          //     Pickup -> Destination
          //
          // During ride:
          //     Driver -> Destination
          //
          RideLiveMap(
            key: ValueKey(
              'customer-map-${widget.rideId}',
            ),
            rideId:
                widget.rideId,
            height: 250,
            mode:
                RideMapMode.customer,
          ),

          if (driverAssigned) ...[
            const SizedBox(height: 24),
            _driverCard(),
          ],

          const SizedBox(height: 24),

          _tripSummary(),

          if (!rideCancelled &&
              !rideCompleted &&
              rideStatus !=
                  'in_progress') ...[
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,

              child: OutlinedButton.icon(
                onPressed:
                    isCancelling
                        ? null
                        : _cancelRide,

                icon: isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.close_rounded,
                      ),

                label:
                    const Text(
                  'Cancel ride',
                ),
              ),
            ),
          ],

          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _driverCard() {
    final vehicleDescription = [
      vehicleColor,
      vehicleMake,
      vehicleModel,
    ].whereType<String>().join(' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black12,
        ),
      ),

      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor:
                Color(0xFFEAF6ED),
            child: Icon(
              Icons.person_rounded,
              color: RimaColors.primary,
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'RIMA Driver',
                  style:
                      TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                if (vehicleDescription
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    vehicleDescription,
                    style:
                        const TextStyle(
                      color:
                          Colors.black54,
                    ),
                  ),
                ],

                if (vehiclePlate !=
                    null) ...[
                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    vehiclePlate!,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (driverRating != null)
            Column(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: RimaColors.gold,
                ),

                Text(
                  driverRating!
                      .toStringAsFixed(
                    1,
                  ),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tripSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            const Color(
          0xFFFFF6DC,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          _summaryRow(
            Icons.local_taxi_outlined,
            'Ride',
            widget.rideType,
          ),

          const Divider(height: 25),

          _summaryRow(
            Icons.location_on_outlined,
            'Destination',
            widget.destination,
          ),

          const Divider(height: 25),

          _summaryRow(
            Icons.route_outlined,
            'Distance',
            formattedDistance,
          ),

          const Divider(height: 25),

          _summaryRow(
            Icons.schedule_outlined,
            'Trip time',
            formattedDuration,
          ),

          const Divider(height: 25),

          _summaryRow(
            Icons.payments_outlined,
            'Estimated fare',
            widget.fare,
          ),

          const Divider(height: 25),

          _summaryRow(
            Icons.info_outline_rounded,
            'Status',
            rideStatus.replaceAll(
              '_',
              ' ',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: RimaColors.primary,
        ),

        const SizedBox(width: 12),

        Text(
          label,
          style:
              const TextStyle(
            color: Colors.black54,
          ),
        ),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}