import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/colors.dart';
import '../home/home_screen.dart';
import 'ride_chat_screen.dart';
import 'ride_rating_screen.dart';
import '../safety/ride_safety_screen.dart';
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

  // Tracks which assigned driver/vehicle details were loaded
  // so we do not call the details RPC on every poll.
  String? _loadedDriverDetailsKey;

  int? distanceMeters;
  int? estimatedDurationSeconds;

  String? driverName;
  String? driverAvatarUrl;
  double? driverRating;
  int? driverRatingCount;
  int? driverCompletedRides;

  String? vehicleMake;
  String? vehicleModel;
  int? vehicleYear;
  String? vehicleColor;
  String? vehiclePlate;

  bool isLoading = true;
  bool isCancelling = false;

  bool _completionHandled = false;
  bool _cancellationHandled = false;

  String? loadError;

  int unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();

    _loadRide();
    _loadUnreadMessageCount();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        _loadRide();
        _loadUnreadMessageCount();
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
        final detailsKey =
            '$newDriverId|${newVehicleId ?? ''}';

        if (_loadedDriverDetailsKey != detailsKey) {
          await _loadDriverDetails();

          _loadedDriverDetailsKey =
              detailsKey;
        }
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideRatingScreen(
            rideId: widget.rideId,
            role: RideRatingRole.customer,
            otherPartyName:
                driverName?.trim().isNotEmpty == true
                    ? driverName!.trim()
                    : 'your driver',
          ),
        ),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    });
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

  Future<void> _loadDriverDetails() async {
    try {
      final result =
          await Supabase.instance.client.rpc(
        'get_ride_driver_details',
        params: {
          'p_ride_id': widget.rideId,
        },
      );

      if (!mounted) return;

      if (result is! List ||
          result.isEmpty) {
        debugPrint(
          'RIMA DRIVER DETAILS: no public driver details returned.',
        );
        return;
      }

      final row =
          Map<String, dynamic>.from(
        result.first as Map,
      );

      setState(() {
        assignedDriverId =
            row['driver_id']?.toString() ??
                assignedDriverId;

        driverName =
            row['driver_name']?.toString();

        driverAvatarUrl =
            row['driver_avatar_url']?.toString();

        final rawRating =
            row['driver_rating'];

        driverRating =
            rawRating == null
                ? null
                : double.tryParse(
                    rawRating.toString(),
                  );

        final rawCompleted =
            row['driver_completed_rides'];

        driverCompletedRides =
            rawCompleted is int
                ? rawCompleted
                : int.tryParse(
                    rawCompleted?.toString() ?? '',
                  );

        vehicleId =
            row['vehicle_id']?.toString() ??
                vehicleId;

        vehicleMake =
            row['vehicle_make']?.toString();

        vehicleModel =
            row['vehicle_model']?.toString();

        final rawYear =
            row['vehicle_year'];

        vehicleYear =
            rawYear is int
                ? rawYear
                : int.tryParse(
                    rawYear?.toString() ?? '',
                  );

        vehicleColor =
            row['vehicle_color']?.toString();

        vehiclePlate =
            row['vehicle_plate']?.toString();
      });

      await _loadDriverRatingSummary();

      debugPrint(
        'RIMA DRIVER DETAILS LOADED: '
        '${driverName ?? 'RIMA Driver'} | '
        '${vehicleYear ?? ''} '
        '${vehicleColor ?? ''} '
        '${vehicleMake ?? ''} '
        '${vehicleModel ?? ''} '
        '${vehiclePlate ?? ''}',
      );
    } on PostgrestException catch (e) {
      debugPrint(
        'RIMA DRIVER DETAILS RPC ERROR: ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'RIMA DRIVER DETAILS ERROR: $e',
      );
    }
  }

  Future<void> _loadDriverRatingSummary() async {
    final driverId = assignedDriverId;

    if (driverId == null || driverId.isEmpty) {
      return;
    }

    try {
      final result = await Supabase.instance.client.rpc(
        'get_driver_rating_summary',
        params: {
          'p_driver_id': driverId,
        },
      );

      if (!mounted) return;

      if (result is! List || result.isEmpty) {
        setState(() {
          driverRating = null;
          driverRatingCount = 0;
        });
        return;
      }

      final row = Map<String, dynamic>.from(result.first as Map);

      final rawAverage = row['average_rating'];
      final rawCount = row['rating_count'];

      final parsedAverage = rawAverage == null
          ? null
          : double.tryParse(rawAverage.toString());

      final parsedCount = rawCount is int
          ? rawCount
          : int.tryParse(rawCount?.toString() ?? '') ?? 0;

      setState(() {
        driverRating = parsedCount > 0 ? parsedAverage : null;
        driverRatingCount = parsedCount;
      });
    } on PostgrestException catch (e) {
      debugPrint(
        'RIMA DRIVER RATING SUMMARY RPC ERROR: ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'RIMA DRIVER RATING SUMMARY ERROR: $e',
      );
    }
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final result =
          await Supabase.instance.client.rpc(
        'get_ride_unread_message_count',
        params: {
          'p_ride_id': widget.rideId,
        },
      );

      if (!mounted) return;

      final count = result is int
          ? result
          : int.tryParse(
                result?.toString() ?? '',
              ) ??
              0;

      if (count != unreadMessageCount) {
        setState(() {
          unreadMessageCount = count;
        });
      }
    } catch (e) {
      debugPrint(
        'RIMA CUSTOMER UNREAD MESSAGE ERROR: $e',
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
        return 'Thank you for riding with RIMA. Please rate your driver.';

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

            if (!rideCancelled && !rideCompleted) ...[
              const SizedBox(height: 14),
              _customerRideActions(),
            ],
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


  Future<void> _callRideContact() async {
    try {
      final result = await Supabase.instance.client.rpc(
        'get_ride_call_contact',
        params: {
          'p_ride_id': widget.rideId,
        },
      );

      if (!mounted) return;

      if (result is! List || result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number is available for this ride.'),
          ),
        );
        return;
      }

      final row = Map<String, dynamic>.from(result.first as Map);
      final phone = row['phone']?.toString().trim() ?? '';

      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number is available for this ride.'),
          ),
        );
        return;
      }

      final uri = Uri(
        scheme: 'tel',
        path: phone,
      );

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the phone dialer.'),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA CALL CONTACT ERROR: ${e.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to call: ${e.message}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA CALL ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the phone dialer.'),
        ),
      );
    }
  }

  Widget _customerRideActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RideChatScreen(
                        rideId: widget.rideId,
                        otherPartyLabel:
                            driverName?.trim().isNotEmpty == true
                                ? driverName!.trim()
                                : 'your driver',
                      ),
                    ),
                  );
                  await _loadUnreadMessageCount();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded),
                    const SizedBox(width: 7),
                    const Text('Message'),
                    if (unreadMessageCount > 0) ...[
                      const SizedBox(width: 7),
                      _messageBadge(unreadMessageCount),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _callRideContact,
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Call'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideSafetyScreen(
                    rideId: widget.rideId,
                    role: RideSafetyRole.customer,
                    otherPartyName:
                        driverName?.trim().isNotEmpty == true
                            ? driverName!.trim()
                            : 'RIMA Driver',
                    pickupLabel: 'Pickup location',
                    destinationLabel: widget.destination,
                    rideStatus: rideStatus,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Safety'),
          ),
        ),
      ],
    );
  }

  Widget _messageBadge(int count) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _driverCard() {
    final displayName =
        (driverName == null ||
                driverName!.trim().isEmpty)
            ? 'RIMA Driver'
            : driverName!.trim();

    final vehicleDescription = [
      if (vehicleYear != null)
        vehicleYear.toString(),
      vehicleColor,
      vehicleMake,
      vehicleModel,
    ].whereType<String>().join(' ');

    final hasAvatar =
        driverAvatarUrl != null &&
            driverAvatarUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black12,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor:
                    const Color(0xFFEAF6ED),
                backgroundImage:
                    hasAvatar
                        ? NetworkImage(
                            driverAvatarUrl!,
                          )
                        : null,
                child: hasAvatar
                    ? null
                    : const Icon(
                        Icons.person_rounded,
                        color:
                            RimaColors.primary,
                        size: 36,
                      ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Wrap(
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      spacing: 5,
                      runSpacing: 3,
                      children: [
                        if (driverRating != null &&
                            (driverRatingCount ?? 0) > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 19,
                            color: RimaColors.gold,
                          ),
                          Text(
                            driverRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '(${driverRatingCount == 1 ? '1 rating' : '$driverRatingCount ratings'})',
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ] else
                          const Text(
                            'New driver',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (driverCompletedRides != null) ...[
                          const Text(
                            '•',
                            style: TextStyle(
                              color: Colors.black38,
                            ),
                          ),
                          Text(
                            '$driverCompletedRides rides',
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF6ED),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: RimaColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),
          const Divider(height: 1),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 52,
                height: 45,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFF6DC),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: RimaColors.primary,
                  size: 29,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicleDescription.isEmpty
                          ? 'Driver vehicle'
                          : vehicleDescription,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),

                    if (vehiclePlate != null &&
                        vehiclePlate!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        vehiclePlate!,
                        style:
                            const TextStyle(
                          color:
                              Colors.black54,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Text(
                'Check plate',
                style: TextStyle(
                  color: RimaColors.primary,
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 12,
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