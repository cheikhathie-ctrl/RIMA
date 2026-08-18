import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverLocationService {
  DriverLocationService({required this.rideId});

  final String rideId;

  StreamSubscription<Position>? _positionSubscription;

  bool _started = false;
  bool _sending = false;

  Position? _lastSentPosition;

  Future<void> start() async {
    if (_started) {
      return;
    }

    await _checkLocationPermission();

    _started = true;

    //
    // SEND CURRENT LOCATION IMMEDIATELY
    //
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _sendLocation(position, force: true);
    } catch (e) {
      debugPrint('RIMA INITIAL DRIVER LOCATION ERROR: $e');
    }

    //
    // CONTINUOUS LOCATION STREAM
    //
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (Position position) {
            _sendLocation(position);
          },
          onError: (Object error) {
            debugPrint('RIMA DRIVER LOCATION STREAM ERROR: $error');
          },
        );

    debugPrint('RIMA LIVE DRIVER LOCATION STARTED FOR $rideId');
  }

  Future<void> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
  }

  Future<void> _sendLocation(Position position, {bool force = false}) async {
    if (!_started || _sending) {
      return;
    }

    final previous = _lastSentPosition;

    if (!force && previous != null) {
      final distance = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );

      //
      // Ignore tiny GPS movement.
      //
      if (distance < 8) {
        return;
      }
    }

    _sending = true;

    try {
      await Supabase.instance.client.rpc(
        'driver_update_location',
        params: {
          'p_ride_id': rideId,
          'p_latitude': position.latitude,
          'p_longitude': position.longitude,
        },
      );

      _lastSentPosition = position;

      debugPrint(
        'RIMA DRIVER LOCATION SENT: '
        '${position.latitude}, '
        '${position.longitude}',
      );
    } on PostgrestException catch (e) {
      debugPrint('RIMA DRIVER LOCATION RPC ERROR: ${e.message}');
    } catch (e) {
      debugPrint('RIMA DRIVER LOCATION ERROR: $e');
    } finally {
      _sending = false;
    }
  }

  Future<void> stop() async {
    _started = false;

    await _positionSubscription?.cancel();

    _positionSubscription = null;

    _lastSentPosition = null;

    debugPrint('RIMA LIVE DRIVER LOCATION STOPPED FOR $rideId');
  }
}
