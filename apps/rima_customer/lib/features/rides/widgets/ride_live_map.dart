import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/colors.dart';

enum RideMapMode { customer, driver }

class RideLiveMap extends StatefulWidget {
  const RideLiveMap({
    super.key,
    required this.rideId,
    this.height = 330,
    this.mode = RideMapMode.customer,
  });

  final String rideId;
  final double height;
  final RideMapMode mode;

  @override
  State<RideLiveMap> createState() => _RideLiveMapState();
}

class _RideLiveMapState extends State<RideLiveMap> {
  Timer? _refreshTimer;
  GoogleMapController? _mapController;

  bool isLoading = true;
  bool isLoadingRoute = false;

  String? loadError;

  String rideStatus = 'searching';

  LatLng? pickupPosition;
  LatLng? destinationPosition;
  LatLng? driverPosition;

  LatLng? _lastLoggedDriverPosition;

  String pickupLabel = 'Pickup';
  String destinationLabel = 'Destination';

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  int? activeLegDistanceMeters;
  int? activeLegDurationSeconds;

  LatLng? _lastRouteOrigin;
  LatLng? _lastRouteDestination;

  String? _loadedRideId;
  int _loadGeneration = 0;

  // Changes whenever the active route leg changes.
  // This prevents an older async route request from
  // overwriting a newer route.
  int _routeGeneration = 0;

  static const double _nearPickupThresholdMeters = 150.0;

  @override
  void initState() {
    super.initState();

    _loadedRideId = widget.rideId;

    _loadMapState();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _loadMapState(),
    );
  }

  @override
  void didUpdateWidget(covariant RideLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rideId != widget.rideId || oldWidget.mode != widget.mode) {
      _resetMap();
      _loadMapState();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();

    // GoogleMap owns the platform map lifecycle.
    // Do not manually dispose the controller.
    _mapController = null;

    super.dispose();
  }

  void _resetMap() {
    _loadGeneration++;
    _routeGeneration++;

    _loadedRideId = widget.rideId;

    rideStatus = 'searching';

    pickupPosition = null;
    destinationPosition = null;
    driverPosition = null;

    _lastLoggedDriverPosition = null;

    pickupLabel = 'Pickup';
    destinationLabel = 'Destination';

    markers = {};
    polylines = {};

    activeLegDistanceMeters = null;
    activeLegDurationSeconds = null;

    _lastRouteOrigin = null;
    _lastRouteDestination = null;

    isLoadingRoute = false;
    loadError = null;

    _mapController = null;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    } else {
      isLoading = true;
    }
  }

  bool get driverHeadingToPickup {
    return rideStatus == 'driver_assigned' || rideStatus == 'driver_arriving';
  }

  bool get driverArrived {
    return rideStatus == 'driver_arrived';
  }

  bool get rideInProgress {
    return rideStatus == 'in_progress';
  }

  String get activeLegTitle {
    if (driverHeadingToPickup) {
      return 'Driver to pickup';
    }

    if (driverArrived) {
      return 'Pickup to destination';
    }

    if (rideInProgress) {
      return 'To destination';
    }

    return 'Trip route';
  }

  String get formattedActiveDistance {
    final value = activeLegDistanceMeters;

    if (value == null) {
      return '--';
    }

    if (value < 1000) {
      return '$value m';
    }

    return '${(value / 1000).toStringAsFixed(1)} km';
  }

  String get formattedActiveDuration {
    final value = activeLegDurationSeconds;

    if (value == null) {
      return '--';
    }

    final minutes = math.max(1, (value / 60).ceil());

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours h';
    }

    return '$hours h $remainingMinutes min';
  }

  Future<void> _loadMapState() async {
    final requestedRideId = widget.rideId;
    final generation = _loadGeneration;

    if (_loadedRideId != requestedRideId) {
      _resetMap();
    }

    try {
      final result = await Supabase.instance.client.rpc(
        'get_ride_map_state',
        params: {'p_ride_id': requestedRideId},
      );

      if (!mounted ||
          requestedRideId != widget.rideId ||
          generation != _loadGeneration) {
        return;
      }

      if (result is! List || result.isEmpty) {
        throw Exception('Ride map data was not returned.');
      }

      final row = Map<String, dynamic>.from(result.first as Map);

      final pickupLat = _toDouble(row['pickup_latitude']);

      final pickupLng = _toDouble(row['pickup_longitude']);

      final destinationLat = _toDouble(row['destination_latitude']);

      final destinationLng = _toDouble(row['destination_longitude']);

      final driverLat = _toDouble(row['driver_latitude']);

      final driverLng = _toDouble(row['driver_longitude']);

      if (pickupLat == null ||
          pickupLng == null ||
          destinationLat == null ||
          destinationLng == null) {
        throw Exception('Pickup or destination coordinates are missing.');
      }

      final newPickup = LatLng(pickupLat, pickupLng);

      final newDestination = LatLng(destinationLat, destinationLng);

      LatLng? newDriver;

      if (driverLat != null && driverLng != null) {
        newDriver = LatLng(driverLat, driverLng);
      }
      if (widget.mode == RideMapMode.customer &&
          newDriver != null &&
          !_sameNullablePosition(_lastLoggedDriverPosition, newDriver)) {
        debugPrint(
          'RIMA CUSTOMER RECEIVED NEW DRIVER GPS: '
          '${newDriver.latitude}, '
          '${newDriver.longitude}',
        );

        _lastLoggedDriverPosition = newDriver;
      }

      final previousOrigin = _routeOrigin;
      final previousDestination = _routeDestination;
      final previousStatus = rideStatus;

      setState(() {
        rideStatus = row['status']?.toString() ?? 'searching';

        pickupPosition = newPickup;
        destinationPosition = newDestination;
        driverPosition = newDriver;

        pickupLabel = row['pickup_label']?.toString() ?? 'Pickup';

        destinationLabel =
            row['destination_label']?.toString() ?? 'Destination';

        markers = _buildMarkers();

        isLoading = false;
        loadError = null;
      });

      final newOrigin = _routeOrigin;
      final newRouteDestination = _routeDestination;

      final routeChanged =
          previousStatus != rideStatus ||
          !_sameNullablePosition(previousOrigin, newOrigin) ||
          !_sameNullablePosition(previousDestination, newRouteDestination);

      if (routeChanged) {
        _routeGeneration++;

        _lastRouteOrigin = null;
        _lastRouteDestination = null;

        if (mounted) {
          setState(() {
            polylines = {};
            activeLegDistanceMeters = null;
            activeLegDurationSeconds = null;
          });
        }
      }

      await _loadActiveRoute();

      if (polylines.isEmpty) {
        await _fitMapToActivePoints();
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA LIVE MAP RPC ERROR: ${e.message}');

      setState(() {
        isLoading = false;
        loadError = 'Unable to load ride map.';
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA LIVE MAP ERROR: $e');

      setState(() {
        isLoading = false;
        loadError = 'Unable to load ride map.';
      });
    }
  }

  Set<Marker> _buildMarkers() {
    final result = <Marker>{};

    final pickup = pickupPosition;
    final destination = destinationPosition;
    final driver = driverPosition;

    if (widget.mode == RideMapMode.customer) {
      if (driverHeadingToPickup) {
        if (driver != null) {
          result.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: driver,
              infoWindow: const InfoWindow(title: 'Your RIMA Driver'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }

        if (pickup != null) {
          result.add(
            Marker(
              markerId: const MarkerId('pickup'),
              position: pickup,
              infoWindow: InfoWindow(
                title: 'Your pickup',
                snippet: pickupLabel,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
        }

        return result;
      }

      if (driverArrived) {
        if (pickup != null) {
          result.add(
            Marker(
              markerId: const MarkerId('pickup'),
              position: pickup,
              infoWindow: InfoWindow(title: 'Pickup', snippet: pickupLabel),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
        }

        if (destination != null) {
          result.add(
            Marker(
              markerId: const MarkerId('destination'),
              position: destination,
              infoWindow: InfoWindow(
                title: 'Destination',
                snippet: destinationLabel,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        }

        if (driver != null) {
          result.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: driver,
              infoWindow: const InfoWindow(title: 'Your RIMA Driver'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }

        return result;
      }

      if (rideInProgress) {
        if (driver != null) {
          result.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: driver,
              infoWindow: const InfoWindow(title: 'Your RIMA Driver'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }

        if (destination != null) {
          result.add(
            Marker(
              markerId: const MarkerId('destination'),
              position: destination,
              infoWindow: InfoWindow(
                title: 'Destination',
                snippet: destinationLabel,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        }

        return result;
      }

      if (pickup != null) {
        result.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            infoWindow: InfoWindow(title: 'Pickup', snippet: pickupLabel),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      if (destination != null) {
        result.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: destinationLabel,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      return result;
    }

    if (driverHeadingToPickup) {
      if (driver != null) {
        result.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: driver,
            infoWindow: const InfoWindow(title: 'RIMA Driver'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }

      if (pickup != null) {
        result.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            infoWindow: InfoWindow(title: 'Pickup', snippet: pickupLabel),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      return result;
    }

    if (driverArrived) {
      if (pickup != null) {
        result.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            infoWindow: InfoWindow(title: 'Pickup', snippet: pickupLabel),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      if (destination != null) {
        result.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: destinationLabel,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      if (driver != null) {
        result.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: driver,
            infoWindow: const InfoWindow(title: 'RIMA Driver'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }

      return result;
    }

    if (rideInProgress) {
      if (driver != null) {
        result.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: driver,
            infoWindow: const InfoWindow(title: 'RIMA Driver'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }

      if (destination != null) {
        result.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: destinationLabel,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      return result;
    }

    if (pickup != null) {
      result.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: InfoWindow(title: 'Pickup', snippet: pickupLabel),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (destination != null) {
      result.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: destinationLabel,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    return result;
  }

  LatLng? get _routeOrigin {
    final pickup = pickupPosition;
    final driver = driverPosition;

    if (widget.mode == RideMapMode.customer) {
      if (driverHeadingToPickup) {
        return driver ?? pickup;
      }

      if (driverArrived) {
        return pickup;
      }

      if (rideInProgress) {
        return driver ?? pickup;
      }

      return pickup;
    }

    if (driverHeadingToPickup) {
      return driver ?? pickup;
    }

    if (driverArrived) {
      return pickup;
    }

    if (rideInProgress) {
      return driver ?? pickup;
    }

    return pickup;
  }

  LatLng? get _routeDestination {
    final pickup = pickupPosition;
    final destination = destinationPosition;

    if (widget.mode == RideMapMode.customer) {
      if (driverHeadingToPickup) {
        return pickup;
      }

      return destination;
    }

    if (driverHeadingToPickup) {
      return pickup;
    }

    return destination;
  }

  bool get _shouldUseDirectPickupRoute {
    if (!driverHeadingToPickup) {
      return false;
    }

    final driver = driverPosition;
    final pickup = pickupPosition;

    if (driver == null || pickup == null) {
      return false;
    }

    final distance = _distanceBetweenMeters(driver, pickup);

    return distance <= _nearPickupThresholdMeters;
  }

  Future<void> _loadActiveRoute() async {
    final routeRideId = widget.rideId;
    final generation = _loadGeneration;
    final routeGeneration = _routeGeneration;

    final routeOrigin = _routeOrigin;
    final routeDestination = _routeDestination;

    if (routeOrigin == null || routeDestination == null) {
      return;
    }

    if (_shouldUseDirectPickupRoute) {
      final distance = _distanceBetweenMeters(
        routeOrigin,
        routeDestination,
      ).round();

      _lastRouteOrigin = routeOrigin;
      _lastRouteDestination = routeDestination;

      if (!mounted ||
          routeRideId != widget.rideId ||
          generation != _loadGeneration ||
          routeGeneration != _routeGeneration) {
        return;
      }

      setState(() {
        activeLegDistanceMeters = distance;

        activeLegDurationSeconds = 60;

        polylines = {
          Polyline(
            polylineId: PolylineId(
              'direct_${widget.mode.name}_${routeRideId}_$rideStatus',
            ),
            points: [routeOrigin, routeDestination],
            width: 6,
            color: const Color(0xFF1A73E8),
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
          ),
        };

        isLoadingRoute = false;
      });

      if (routeGeneration != _routeGeneration) {
        return;
      }

      await _fitMapToRoute([routeOrigin, routeDestination]);

      return;
    }

    if (_samePosition(routeOrigin, _lastRouteOrigin) &&
        _samePosition(routeDestination, _lastRouteDestination) &&
        polylines.isNotEmpty) {
      return;
    }

    _lastRouteOrigin = routeOrigin;
    _lastRouteDestination = routeDestination;

    if (mounted) {
      setState(() {
        isLoadingRoute = true;
        polylines = {};
        activeLegDistanceMeters = null;
        activeLegDurationSeconds = null;
      });
    }

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'calculate-route',
        body: {
          'pickup': {
            'latitude': routeOrigin.latitude,
            'longitude': routeOrigin.longitude,
          },
          'destination': {
            'latitude': routeDestination.latitude,
            'longitude': routeDestination.longitude,
          },
        },
      );

      if (!mounted ||
          routeRideId != widget.rideId ||
          generation != _loadGeneration ||
          routeGeneration != _routeGeneration) {
        return;
      }

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

      final rawRoutePoints = data['route_points'];

      if (rawRoutePoints is! List || rawRoutePoints.length < 2) {
        throw Exception('Google Routes did not return usable route points.');
      }

      final googlePoints = <LatLng>[];

      for (final item in rawRoutePoints) {
        if (item is! Map) {
          continue;
        }

        final latitude = _toDouble(item['latitude']);

        final longitude = _toDouble(item['longitude']);

        if (latitude == null || longitude == null) {
          continue;
        }

        if (latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          continue;
        }

        googlePoints.add(LatLng(latitude, longitude));
      }

      if (googlePoints.length < 2) {
        throw Exception('Google route geometry was invalid.');
      }

      final connectedPoints = <LatLng>[
        routeOrigin,
        ...googlePoints,
        routeDestination,
      ];

      if (!mounted ||
          routeRideId != widget.rideId ||
          generation != _loadGeneration ||
          routeGeneration != _routeGeneration) {
        return;
      }

      setState(() {
        activeLegDistanceMeters = parsedDistance;

        activeLegDurationSeconds = parsedDuration;

        polylines = {
          Polyline(
            polylineId: PolylineId(
              'route_${widget.mode.name}_${routeRideId}_$rideStatus',
            ),
            points: connectedPoints,
            width: 6,
            color: const Color(0xFF1A73E8),
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            geodesic: false,
          ),
        };

        isLoadingRoute = false;
      });

      if (routeGeneration != _routeGeneration) {
        return;
      }

      await _fitMapToRoute(connectedPoints);
    } on FunctionException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA LIVE ROUTE FUNCTION ERROR: ${e.details}');

      setState(() {
        isLoadingRoute = false;
        polylines = {};
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA LIVE ROUTE ERROR: $e');

      setState(() {
        isLoadingRoute = false;
        polylines = {};
      });
    }
  }

  double _distanceBetweenMeters(LatLng point1, LatLng point2) {
    const earthRadiusMeters = 6371000.0;

    final lat1 = _degreesToRadians(point1.latitude);

    final lat2 = _degreesToRadians(point2.latitude);

    final deltaLat = _degreesToRadians(point2.latitude - point1.latitude);

    final deltaLng = _degreesToRadians(point2.longitude - point1.longitude);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  bool _sameNullablePosition(LatLng? value, LatLng? other) {
    if (value == null && other == null) {
      return true;
    }

    if (value == null || other == null) {
      return false;
    }

    return _samePosition(value, other);
  }

  bool _samePosition(LatLng value, LatLng? other) {
    if (other == null) {
      return false;
    }

    const tolerance = 0.00001;

    return (value.latitude - other.latitude).abs() < tolerance &&
        (value.longitude - other.longitude).abs() < tolerance;
  }

  Future<void> _fitMapToActivePoints() async {
    final origin = _routeOrigin;
    final destination = _routeDestination;

    if (origin == null || destination == null) {
      return;
    }

    await _fitMapToPoints([origin, destination], padding: 140);
  }

  Future<void> _fitMapToRoute(List<LatLng> routePoints) async {
    if (routePoints.isEmpty) {
      return;
    }

    await _fitMapToPoints(routePoints, padding: 140);
  }

  Future<void> _fitMapToPoints(
    List<LatLng> positions, {
    required double padding,
  }) async {
    final controller = _mapController;

    if (controller == null || positions.isEmpty) {
      return;
    }

    if (positions.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(positions.first, 15),
      );
      return;
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final point in positions.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);

      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    //
    // Add geographic breathing room around the route.
    //
    // This is especially important on Flutter Web where
    // newLatLngBounds can otherwise place an endpoint too
    // close to the edge of the Google Map.
    //
    final latSpan = math.max((maxLat - minLat).abs(), 0.002);

    final lngSpan = math.max((maxLng - minLng).abs(), 0.002);

    final latMargin = latSpan * 0.18;
    final lngMargin = lngSpan * 0.18;

    final southwest = LatLng(minLat - latMargin, minLng - lngMargin);

    final northeast = LatLng(maxLat + latMargin, maxLng + lngMargin);

    try {
      if (controller != _mapController) {
        return;
      }

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: southwest, northeast: northeast),
          70,
        ),
      );

      //
      // Give the web map time to finish resizing,
      // then fit the same bounds again.
      //
      await Future.delayed(const Duration(milliseconds: 350));

      if (!mounted || controller != _mapController) {
        return;
      }

      if (controller != _mapController) {
        return;
      }

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: southwest, northeast: northeast),
          70,
        ),
      );
    } catch (e) {
      debugPrint('RIMA MAP FIT ERROR: $e');
    }
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  String get _mapInstanceKey {
    // Keep the same GoogleMap instance while the driver moves.
    // Route/state updates are handled by markers, polylines,
    // and _routeGeneration instead of recreating the platform map.
    return 'rima-${widget.mode.name}-${widget.rideId}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(color: RimaColors.primary),
        ),
      );
    }

    if (loadError != null ||
        pickupPosition == null ||
        destinationPosition == null) {
      return Container(
        height: widget.height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 44,
                color: RimaColors.primary,
              ),
              const SizedBox(height: 10),
              Text(
                loadError ?? 'Map unavailable.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadMapState, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: GoogleMap(
              key: ValueKey<String>(_mapInstanceKey),

              initialCameraPosition: CameraPosition(
                target: _routeOrigin ?? pickupPosition!,
                zoom: 14,
              ),

              onMapCreated: (controller) {
                // Flutter's GoogleMap widget owns the platform map lifecycle.
                // Keep only the latest controller reference.
                _mapController = controller;

                final rideId = widget.rideId;
                final mode = widget.mode;
                final generation = _loadGeneration;

                Future.delayed(const Duration(milliseconds: 350), () async {
                  if (!mounted ||
                      rideId != widget.rideId ||
                      mode != widget.mode ||
                      generation != _loadGeneration ||
                      _mapController != controller) {
                    return;
                  }

                  try {
                    if (polylines.isNotEmpty) {
                      await _fitMapToRoute(polylines.first.points);
                    } else {
                      await _fitMapToActivePoints();
                    }
                  } catch (e) {
                    debugPrint('RIMA MAP INITIAL FIT ERROR: $e');
                  }
                });
              },

              markers: markers,
              polylines: polylines,

              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: true,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              const Icon(Icons.navigation_rounded, color: RimaColors.primary),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeLegTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      isLoadingRoute
                          ? 'Calculating route...'
                          : '$formattedActiveDistance • '
                                '$formattedActiveDuration',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              if (driverPosition != null)
                const Icon(Icons.local_taxi_rounded, color: RimaColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}
