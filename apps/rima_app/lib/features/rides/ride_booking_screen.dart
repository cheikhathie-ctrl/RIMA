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
  String pickupText = 'Getting your current location...';

  bool isLoadingLocation = false;
  bool pickupConfirmed = false;

  LatLng? currentLatLng;
  LatLng? selectedPickupLatLng;

  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (isLoadingLocation) {
      return;
    }

    setState(() {
      isLoadingLocation = true;
      pickupConfirmed = false;

      pickupText = 'Getting your current location...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

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
        if (!mounted) return;

        setState(() {
          pickupText = 'Location permission denied';

          isLoadingLocation = false;
        });

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          pickupText = 'Location permission permanently denied';

          isLoadingLocation = false;
        });

        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newPosition = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        currentLatLng = newPosition;

        selectedPickupLatLng = newPosition;

        pickupText = 'Your current location';

        isLoadingLocation = false;

        pickupConfirmed = false;
      });

      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 16),
        );
      }
    } catch (e) {
      debugPrint('RIMA LOCATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        pickupText = 'Unable to get location';

        isLoadingLocation = false;
      });
    }
  }

  Future<void> _searchPickupLocation() async {
    final referencePosition = selectedPickupLatLng ?? currentLatLng;

    if (referencePosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for your current location.')),
      );

      return;
    }

    final result = await Navigator.push<LocationSearchResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSearchScreen(
          pickupPosition: referencePosition,

          mode: LocationSearchMode.pickup,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      selectedPickupLatLng = result.position;

      pickupText = result.name;

      pickupConfirmed = false;
    });

    if (mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(result.position, 16),
      );
    }
  }

  void _confirmPickup() {
    final pickup = selectedPickupLatLng;

    if (pickup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location first.')),
      );

      return;
    }

    setState(() {
      pickupConfirmed = true;

      if (pickupText == 'Pickup adjusted' ||
          pickupText == 'Adjust your pickup location') {
        pickupText = 'Pickup confirmed';
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pickup location confirmed.')));
  }

  void _changePickup() {
    setState(() {
      pickupConfirmed = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You can search for a pickup, use your current location, or move the map pin.',
        ),
      ),
    );
  }

  void _chooseDestination() {
    final pickup = selectedPickupLatLng;

    if (!pickupConfirmed || pickup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm your pickup location first.')),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSearchScreen(
          pickupPosition: pickup,
          mode: LocationSearchMode.destination,
        ),
      ),
    );
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
                    'Set your pickup',

                    style: TextStyle(
                      fontSize: 28,

                      fontWeight: FontWeight.w800,

                      color: RimaColors.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    pickupConfirmed
                        ? 'Pickup confirmed. You can now choose your destination.'
                        : 'Choose where your RIMA driver should pick you up.',

                    style: const TextStyle(
                      fontSize: 16,

                      color: Colors.black54,

                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  //
                  // PICKUP CARD
                  //
                  _locationCard(
                    icon: pickupConfirmed
                        ? Icons.check_circle_rounded
                        : Icons.my_location_rounded,

                    title: 'Pickup',

                    value: pickupText,

                    iconColor: pickupConfirmed
                        ? Colors.green
                        : RimaColors.primary,

                    isLoading: isLoadingLocation,

                    trailingText: pickupConfirmed ? 'Change' : 'Search',

                    onTap: pickupConfirmed
                        ? _changePickup
                        : _searchPickupLocation,
                  ),

                  if (!pickupConfirmed) ...[
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isLoadingLocation
                                ? null
                                : _getCurrentLocation,

                            icon: const Icon(Icons.my_location_rounded),

                            label: const Text('Current location'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _searchPickupLocation,

                            icon: const Icon(Icons.search_rounded),

                            label: const Text('Search pickup'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  //
                  // DESTINATION CARD
                  //
                  _locationCard(
                    icon: Icons.location_on_rounded,

                    title: 'Destination',

                    value: pickupConfirmed
                        ? 'Where are you going?'
                        : 'Confirm pickup first',

                    iconColor: pickupConfirmed
                        ? RimaColors.gold
                        : Colors.black26,

                    enabled: pickupConfirmed,

                    onTap: _chooseDestination,
                  ),

                  if (currentLatLng != null) ...[
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pickupConfirmed
                                ? 'Confirmed pickup'
                                : 'Your pickup',

                            style: const TextStyle(
                              fontSize: 21,

                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        if (pickupConfirmed)
                          TextButton.icon(
                            onPressed: _changePickup,

                            icon: const Icon(
                              Icons.edit_location_alt_outlined,

                              size: 19,
                            ),

                            label: const Text(
                              'Change',

                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      pickupConfirmed
                          ? 'This is where your driver will meet you.'
                          : 'Search for a pickup or move the map to fine-tune the exact point.',

                      style: const TextStyle(color: Colors.black54),
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
                                target: selectedPickupLatLng ?? currentLatLng!,

                                zoom: 16,
                              ),

                              onMapCreated: (controller) {
                                mapController = controller;
                              },

                              onCameraMove: pickupConfirmed
                                  ? null
                                  : (position) {
                                      selectedPickupLatLng = position.target;

                                      if (pickupText != 'Pickup adjusted') {
                                        setState(() {
                                          pickupText = 'Pickup adjusted';
                                        });
                                      }
                                    },

                              myLocationEnabled: true,

                              myLocationButtonEnabled: !pickupConfirmed,

                              zoomControlsEnabled: false,

                              compassEnabled: true,

                              scrollGesturesEnabled: !pickupConfirmed,

                              zoomGesturesEnabled: !pickupConfirmed,

                              rotateGesturesEnabled: !pickupConfirmed,

                              tiltGesturesEnabled: !pickupConfirmed,
                            ),

                            IgnorePointer(
                              child: Transform.translate(
                                offset: const Offset(0, -20),

                                child: Icon(
                                  pickupConfirmed
                                      ? Icons.check_circle_rounded
                                      : Icons.location_pin,

                                  size: pickupConfirmed ? 46 : 52,

                                  color: pickupConfirmed
                                      ? Colors.green
                                      : RimaColors.primary,
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 12,

                              left: 12,

                              right: 12,

                              child: _MapInstruction(
                                confirmed: pickupConfirmed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,

                      height: 56,

                      child: pickupConfirmed
                          ? OutlinedButton.icon(
                              onPressed: _changePickup,

                              icon: const Icon(
                                Icons.edit_location_alt_outlined,
                              ),

                              label: const Text(
                                'Change pickup location',

                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: isLoadingLocation
                                  ? null
                                  : _confirmPickup,

                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                              ),

                              label: const Text(
                                'Confirm pickup location',

                                style: TextStyle(fontWeight: FontWeight.w700),
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
                            'Use GPS, search for a place or landmark, or move the pin to the exact pickup point.',

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

                    child: ElevatedButton.icon(
                      onPressed: pickupConfirmed ? _chooseDestination : null,

                      icon: const Icon(Icons.arrow_forward_rounded),

                      label: Text(
                        pickupConfirmed
                            ? 'Choose destination'
                            : 'Confirm pickup to continue',

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

  static Widget _locationCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLoading = false,
    bool enabled = true,
    String? trailingText,
  }) {
    return Material(
      color: enabled ? Colors.white : const Color(0xFFF3F3F1),

      borderRadius: BorderRadius.circular(20),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: enabled ? onTap : null,

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

                      style: TextStyle(
                        fontSize: 16,

                        fontWeight: FontWeight.w700,

                        color: enabled ? Colors.black87 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailingText != null)
                Text(
                  trailingText,

                  style: const TextStyle(
                    color: RimaColors.primary,

                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,

                  color: enabled ? Colors.black38 : Colors.black12,
                ),
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
  const _MapInstruction({required this.confirmed});

  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(
            confirmed ? Icons.check_circle_rounded : Icons.open_with_rounded,

            size: 18,

            color: confirmed ? Colors.green : RimaColors.primary,
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              confirmed
                  ? 'Pickup location locked'
                  : 'Move map to adjust pickup',

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
