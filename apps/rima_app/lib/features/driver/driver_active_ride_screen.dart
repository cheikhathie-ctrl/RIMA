import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import '../rides/widgets/ride_live_map.dart';
import '../rides/ride_chat_screen.dart';
import 'driver_available_rides_screen.dart';
import 'services/driver_location_service.dart';

class DriverActiveRideScreen extends StatefulWidget {
  const DriverActiveRideScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  Timer? _refreshTimer;

  DriverLocationService? _locationService;

  bool isLoading = true;
  bool isUpdatingStatus = false;

  bool _completionHandled = false;
  bool _cancellationHandled = false;
  bool _invalidRideHandled = false;

  String? loadError;

  int unreadMessageCount = 0;

  String rideStatus = 'driver_assigned';

  String pickupLabel = '';
  String destinationLabel = '';
  String serviceType = '';
  String fare = '';

  int? distanceMeters;
  int? durationSeconds;

  static const Set<String> _activeStatuses = {
    'driver_assigned',
    'driver_arriving',
    'driver_arrived',
    'in_progress',
  };

  @override
  void initState() {
    super.initState();

    //
    // LIVE DRIVER GPS
    //
    _locationService = DriverLocationService(rideId: widget.rideId);

    _startDriverTracking();

    //
    // LOAD ACTIVE RIDE
    //
    _loadRide();
    _loadUnreadMessageCount();

    //
    // REFRESH RIDE STATUS
    //
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        _loadRide();
        _loadUnreadMessageCount();
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();

    //
    // Stop sending driver GPS when
    // this active ride screen closes.
    //
    _locationService?.stop();

    super.dispose();
  }

  Future<void> _startDriverTracking() async {
    try {
      await _locationService?.start();
    } catch (e) {
      debugPrint('RIMA DRIVER TRACKING START ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to start live location: $e')),
      );
    }
  }

  Future<void> _stopDriverTracking() async {
    try {
      await _locationService?.stop();
    } catch (e) {
      debugPrint('RIMA DRIVER TRACKING STOP ERROR: $e');
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

    return '${(value / 1000).toStringAsFixed(1)} km';
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

  String get serviceLabel {
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

  Future<void> _loadRide() async {
    if (_invalidRideHandled || _completionHandled || _cancellationHandled) {
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('rides')
          .select(
            'id, status, assigned_driver_id, vehicle_id, '
            'service_type, pickup_label, destination_label, '
            'distance_meters, estimated_duration_seconds, '
            'quoted_fare_mru',
          )
          .eq('id', widget.rideId)
          .maybeSingle();

      if (!mounted) return;

      if (data == null) {
        debugPrint('RIMA DRIVER ACTIVE: ride ${widget.rideId} does not exist.');

        _handleInvalidRide();
        return;
      }

      final newStatus = data['status']?.toString() ?? '';

      if (newStatus == 'completed') {
        setState(() {
          rideStatus = 'completed';
          isLoading = false;
        });

        _refreshTimer?.cancel();

        await _stopDriverTracking();

        _handleCompletedRide();

        return;
      }

      if (newStatus == 'cancelled') {
        setState(() {
          rideStatus = 'cancelled';
          isLoading = false;
        });

        _refreshTimer?.cancel();

        await _stopDriverTracking();

        _handleCancelledRide();

        return;
      }

      if (!_activeStatuses.contains(newStatus)) {
        debugPrint(
          'RIMA DRIVER ACTIVE: '
          '${widget.rideId} has invalid active status $newStatus.',
        );

        _handleInvalidRide();

        return;
      }

      //
      // Confirm that this exact ride is still the
      // authenticated driver's genuine active ride.
      //
      final activeResult = await Supabase.instance.client.rpc(
        'get_driver_active_ride',
      );

      if (!mounted) return;

      if (activeResult is! List || activeResult.isEmpty) {
        debugPrint('RIMA DRIVER ACTIVE: backend reports no active ride.');

        _handleInvalidRide();

        return;
      }

      final activeRow = Map<String, dynamic>.from(activeResult.first as Map);

      final backendRideId = activeRow['ride_id']?.toString();

      if (backendRideId == null || backendRideId != widget.rideId) {
        debugPrint(
          'RIMA DRIVER ACTIVE MISMATCH: '
          'screen=${widget.rideId}, '
          'backend=$backendRideId',
        );

        _handleInvalidRide();

        return;
      }

      setState(() {
        rideStatus = newStatus;

        serviceType = data['service_type']?.toString() ?? 'rima_go';

        pickupLabel = data['pickup_label']?.toString() ?? 'Pickup';

        destinationLabel =
            data['destination_label']?.toString() ?? 'Destination';

        final rawDistance = data['distance_meters'];

        distanceMeters = rawDistance is int
            ? rawDistance
            : int.tryParse(rawDistance?.toString() ?? '');

        final rawDuration = data['estimated_duration_seconds'];

        durationSeconds = rawDuration is int
            ? rawDuration
            : int.tryParse(rawDuration?.toString() ?? '');

        final rawFare = data['quoted_fare_mru'];

        fare = rawFare == null ? '--' : '${_formatFare(rawFare)} MRU';

        isLoading = false;
        loadError = null;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA DRIVER ACTIVE RIDE LOAD ERROR: ${e.message}');

      setState(() {
        isLoading = false;

        loadError = 'Unable to load active ride: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA DRIVER ACTIVE RIDE LOAD ERROR: $e');

      setState(() {
        isLoading = false;

        loadError = 'Unable to load active ride.';
      });
    }
  }

  String _formatFare(dynamic value) {
    final parsed = double.tryParse(value.toString());

    if (parsed == null) {
      return value.toString();
    }

    if (parsed == parsed.roundToDouble()) {
      return parsed.toStringAsFixed(0);
    }

    return parsed.toStringAsFixed(2);
  }

  void _handleInvalidRide() {
    if (_invalidRideHandled) {
      return;
    }

    _invalidRideHandled = true;

    _refreshTimer?.cancel();

    //
    // Stop GPS because this is no longer
    // a valid active ride.
    //
    _stopDriverTracking();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DriverAvailableRidesScreen()),
        (route) => false,
      );
    });
  }

  void _handleCompletedRide() {
    if (_completionHandled) {
      return;
    }

    _completionHandled = true;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DriverAvailableRidesScreen()),
        (route) => false,
      );
    });
  }

  void _handleCancelledRide() {
    if (_cancellationHandled) {
      return;
    }

    _cancellationHandled = true;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DriverAvailableRidesScreen()),
        (route) => false,
      );
    });
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
        'RIMA DRIVER UNREAD MESSAGE ERROR: $e',
      );
    }
  }

  Future<void> _updateRideStatus(String newStatus) async {
    if (isUpdatingStatus) {
      return;
    }

    setState(() {
      isUpdatingStatus = true;
    });

    try {
      await Supabase.instance.client.rpc(
        'driver_update_ride_status',
        params: {'p_ride_id': widget.rideId, 'p_new_status': newStatus},
      );

      await _loadRide();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_successMessage(newStatus))));
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA DRIVER STATUS ERROR: ${e.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update ride: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA DRIVER STATUS ERROR: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to update ride.')));
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingStatus = false;
        });
      }
    }
  }

  String _successMessage(String status) {
    switch (status) {
      case 'driver_arriving':
        return 'Navigation to pickup started.';

      case 'driver_arrived':
        return 'Customer notified that you arrived.';

      case 'in_progress':
        return 'Ride started.';

      case 'completed':
        return 'Ride completed.';

      default:
        return 'Ride updated.';
    }
  }

  String get _screenTitle {
    switch (rideStatus) {
      case 'driver_assigned':
        return 'Ride accepted';

      case 'driver_arriving':
        return 'Heading to pickup';

      case 'driver_arrived':
        return 'At pickup';

      case 'in_progress':
        return 'Ride in progress';

      case 'completed':
        return 'Ride completed';

      case 'cancelled':
        return 'Ride cancelled';

      default:
        return 'Active ride';
    }
  }

  String get _primaryButtonText {
    switch (rideStatus) {
      case 'driver_assigned':
        return 'Start navigation to pickup';

      case 'driver_arriving':
        return 'I have arrived';

      case 'driver_arrived':
        return 'Start ride';

      case 'in_progress':
        return 'Complete ride';

      default:
        return '';
    }
  }

  IconData get _primaryButtonIcon {
    switch (rideStatus) {
      case 'driver_assigned':
        return Icons.navigation_rounded;

      case 'driver_arriving':
        return Icons.location_on_rounded;

      case 'driver_arrived':
        return Icons.play_arrow_rounded;

      case 'in_progress':
        return Icons.check_circle_outline_rounded;

      default:
        return Icons.local_taxi_rounded;
    }
  }

  String? get _nextStatus {
    switch (rideStatus) {
      case 'driver_assigned':
        return 'driver_arriving';

      case 'driver_arriving':
        return 'driver_arrived';

      case 'driver_arrived':
        return 'in_progress';

      case 'in_progress':
        return 'completed';

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        title: Text(
          _screenTitle,

          style: const TextStyle(
            color: RimaColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
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

              ElevatedButton(onPressed: _loadRide, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),

      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,

            decoration: const BoxDecoration(
              color: Color(0xFFEAF6ED),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.local_taxi_rounded,
              size: 48,
              color: RimaColors.primary,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            _screenTitle,

            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: RimaColors.primary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _statusDescription(),

            textAlign: TextAlign.center,

            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),

          const SizedBox(height: 22),

          //
          // LIVE DRIVER MAP
          //
          // driver_assigned / driver_arriving:
          // Driver -> Pickup
          //
          // driver_arrived:
          // Pickup -> Destination
          //
          // in_progress:
          // Driver -> Destination
          //
          if (_activeStatuses.contains(rideStatus))
            RideLiveMap(
              key: ValueKey('driver-map-${widget.rideId}'),

              rideId: widget.rideId,

              height: 250,

              mode: RideMapMode.driver,
            ),

          if (_activeStatuses.contains(rideStatus)) const SizedBox(height: 22),

          _locationCard(
            icon: Icons.my_location_rounded,

            title: 'Pickup',

            value: pickupLabel,

            background: const Color(0xFFEAF6ED),
          ),

          const SizedBox(height: 12),

          _locationCard(
            icon: Icons.location_on_rounded,

            title: 'Destination',

            value: destinationLabel,

            background: const Color(0xFFFFF3D6),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _metricCard(
                  Icons.route_outlined,
                  formattedDistance,
                  'Trip distance',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _metricCard(
                  Icons.schedule_outlined,
                  formattedDuration,
                  'Trip time',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _metricCard(
                  Icons.local_taxi_outlined,
                  serviceLabel,
                  'Service',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _metricCard(Icons.payments_outlined, fare, 'Fare'),
              ),
            ],
          ),

          const SizedBox(height: 28),

          if (_activeStatuses.contains(rideStatus)) _statusTimeline(),

          if (_activeStatuses.contains(rideStatus)) ...[
            const SizedBox(height: 18),
            _driverRideActions(),
            const SizedBox(height: 28),
          ],

          if (_nextStatus != null)
            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton.icon(
                onPressed: isUpdatingStatus
                    ? null
                    : () {
                        _updateRideStatus(_nextStatus!);
                      },

                icon: isUpdatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_primaryButtonIcon),

                label: Text(
                  isUpdatingStatus ? 'Updating...' : _primaryButtonText,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          if (rideStatus == 'completed')
            _terminalCard(
              icon: Icons.check_circle_rounded,

              title: 'Ride completed successfully',

              message: 'Returning to available rides...',
            ),

          if (rideStatus == 'cancelled')
            _terminalCard(
              icon: Icons.cancel_outlined,

              title: 'Ride cancelled',

              message: 'Returning to available rides...',
            ),
        ],
      ),
    );
  }

  Widget _driverRideActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideChatScreen(
                    rideId: widget.rideId,
                    otherPartyLabel: 'customer',
                  ),
                ),
              );

              await _loadUnreadMessageCount();
            },
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                ),
                const SizedBox(width: 8),
                const Text('Message customer'),
                if (unreadMessageCount > 0) ...[
                  const SizedBox(width: 8),
                  _messageBadge(
                    unreadMessageCount,
                  ),
                ],
              ],
            ),
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

  Widget _terminalCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF6ED),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          Icon(icon, size: 42, color: RimaColors.primary),

          const SizedBox(height: 10),

          Text(
            title,

            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 4),

          Text(
            message,

            textAlign: TextAlign.center,

            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  String _statusDescription() {
    switch (rideStatus) {
      case 'driver_assigned':
        return 'The ride is assigned to you. Head to the customer pickup.';

      case 'driver_arriving':
        return 'You are heading to the customer pickup location.';

      case 'driver_arrived':
        return 'You are at the pickup. Start the ride when the customer is ready.';

      case 'in_progress':
        return 'Drive safely to the customer destination.';

      case 'completed':
        return 'This ride has been completed.';

      case 'cancelled':
        return 'The customer cancelled this ride. Returning to available rides...';

      default:
        return 'Checking active RIMA ride...';
    }
  }

  Widget _locationCard({
    required IconData icon,
    required String title,
    required String value,
    required Color background,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: background,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Icon(icon, color: RimaColors.primary),

          const SizedBox(width: 13),

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

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: Colors.black12),
      ),

      child: Column(
        children: [
          Icon(icon, color: RimaColors.primary),

          const SizedBox(height: 6),

          Text(
            value,

            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 2),

          Text(
            label,

            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _statusTimeline() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.black12),
      ),

      child: Column(
        children: [
          _statusStep('Ride accepted', true),

          _statusStep('Heading to pickup', rideStatus != 'driver_assigned'),

          _statusStep(
            'Arrived at pickup',
            rideStatus == 'driver_arrived' || rideStatus == 'in_progress',
          ),

          _statusStep('Ride started', rideStatus == 'in_progress'),

          _statusStep('Ride completed', false),
        ],
      ),
    );
  }

  Widget _statusStep(String label, bool complete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),

      child: Row(
        children: [
          Icon(
            complete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,

            color: complete ? RimaColors.primary : Colors.black26,
          ),

          const SizedBox(width: 12),

          Text(
            label,

            style: TextStyle(
              fontWeight: complete ? FontWeight.w700 : FontWeight.w500,

              color: complete ? Colors.black87 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
