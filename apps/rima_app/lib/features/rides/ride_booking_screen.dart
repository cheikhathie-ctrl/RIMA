import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme/colors.dart';
import 'location_search_screen.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  String pickupText = 'Use current location';
  bool isLoadingLocation = false;
  bool pickupConfirmed = false;

  LatLng? currentLatLng;
  LatLng? selectedPickupLatLng;

  GoogleMapController? mapController;

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
      pickupText = 'Getting your location...';
      pickupConfirmed = false;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          pickupText = 'Location services are disabled';
          isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          pickupText = 'Location permission denied';
          isLoadingLocation = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          pickupText = 'Location permission permanently denied';
          isLoadingLocation = false;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        currentLatLng = newPosition;
        selectedPickupLatLng = newPosition;
        pickupText = 'Your current location';
        isLoadingLocation = false;
      });

      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 16),
        );
      }
    } catch (e) {
      debugPrint('RIMA LOCATION ERROR: $e');

      setState(() {
        pickupText = 'Unable to get location';
        isLoadingLocation = false;
      });
    }
  }

  void _confirmPickup() {
    if (selectedPickupLatLng == null) {
      return;
    }

    setState(() {
      pickupConfirmed = true;
      pickupText = 'Pickup confirmed';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pickup location confirmed')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'RIMA Go',
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Where would you like to go?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: RimaColors.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Choose your pickup and destination.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  const SizedBox(height: 28),

                  _locationCard(
                    icon: Icons.my_location_rounded,
                    title: 'Pickup',
                    value: pickupText,
                    iconColor: RimaColors.primary,
                    isLoading: isLoadingLocation,
                    onTap: _getCurrentLocation,
                  ),

                  const SizedBox(height: 14),

                  _locationCard(
                    icon: Icons.location_on_rounded,
                    title: 'Destination',
                    value: 'Where are you going?',
                    iconColor: RimaColors.gold,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationSearchScreen(
                            pickupPosition: selectedPickupLatLng!,
                          ),
                        ),
                      );
                    },
                  ),

                  if (currentLatLng != null) ...[
                    const SizedBox(height: 28),

                    const Text(
                      'Your pickup',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Move the map to fine-tune your pickup point.',
                      style: TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: currentLatLng!,
                                zoom: 16,
                              ),
                              onMapCreated: (controller) {
                                mapController = controller;
                              },
                              gestureRecognizers:
                                  <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  EagerGestureRecognizer.new,
                                ),
                              },
                              onCameraMove: (position) {
                                selectedPickupLatLng = position.target;

                                if (pickupConfirmed) {
                                  setState(() {
                                    pickupConfirmed = false;
                                    pickupText = 'Pickup changed';
                                  });
                                }
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: false,
                              compassEnabled: true,
                            ),

                            IgnorePointer(
                              child: Transform.translate(
                                offset: const Offset(0, -20),
                                child: const Icon(
                                  Icons.location_pin,
                                  size: 52,
                                  color: RimaColors.primary,
                                ),
                              ),
                            ),

                            const Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: _MapInstruction(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _confirmPickup,
                        icon: Icon(
                          pickupConfirmed
                              ? Icons.check_circle_rounded
                              : Icons.my_location_rounded,
                        ),
                        label: Text(
                          pickupConfirmed
                              ? 'Pickup confirmed'
                              : 'Confirm pickup',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  const Text(
                    'Quick locations',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _quickLocation(
                          icon: Icons.home_outlined,
                          label: 'Home',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickLocation(
                          icon: Icons.work_outline_rounded,
                          label: 'Work',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickLocation(
                          icon: Icons.star_border_rounded,
                          label: 'Saved',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Pickup help',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6DC),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: RimaColors.primary,
                          size: 30,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Use GPS, move the pin, or choose a nearby landmark.',
                            style: TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: pickupConfirmed
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LocationSearchScreen(
                                    pickupPosition: selectedPickupLatLng!,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: const Text(
                        'Choose destination',
                        style: TextStyle(
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

  static Widget _locationCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: RimaColors.primary,
                        ),
                      )
                    : Icon(icon, color: iconColor),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
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

              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _quickLocation({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: RimaColors.primary, size: 27),
              const SizedBox(height: 7),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapInstruction extends StatelessWidget {
  const _MapInstruction();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.open_with_rounded, size: 18, color: RimaColors.primary),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Move map to adjust pickup',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
