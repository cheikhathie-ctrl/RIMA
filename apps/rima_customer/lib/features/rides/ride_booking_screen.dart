import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/localization/rima_localization.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/wallet_screen.dart';
import 'location_search_screen.dart';
import 'ride_history_screen.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  static const Color _green = Color(0xFF006B4F);
  static const Color _deepGreen = Color(0xFF00513D);
  static const Color _gold = Color(0xFFFFC52F);
  static const Color _cream = Color(0xFFFFFDF7);
  static const Color _softGold = Color(0xFFFFF5D9);

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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          pickupText = 'Location services are disabled';
          isLoadingLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
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
      });

      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 16),
      );
    } catch (e) {
      debugPrint('RIMA LOCATION ERROR: $e');
      if (!mounted) return;
      setState(() {
        pickupText = 'Unable to get location';
        isLoadingLocation = false;
      });
    }
  }

  void _confirmPickup() {
    if (selectedPickupLatLng == null) return;

    setState(() {
      pickupConfirmed = true;
      pickupText = 'Pickup confirmed';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(RimaText.ui('Pickup location confirmed')),
      ),
    );
  }

  void _openDestination() {
    final pickup = selectedPickupLatLng;
    if (pickup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(RimaText.ui('Use current location')),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSearchScreen(
          pickupPosition: pickup,
        ),
      ),
    );
  }

  void _open(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        elevation: 0,
        foregroundColor: _green,
        centerTitle: true,
        title: const Text(
          'RIMA Go',
          style: TextStyle(
            color: _green,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RimaText.ui('Where would you like to go?'),
                    style: const TextStyle(
                      fontSize: 29,
                      height: 1.18,
                      fontWeight: FontWeight.w900,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    RimaText.ui('Choose your pickup and destination.'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _locationCard(
                    icon: Icons.my_location_rounded,
                    title: RimaText.ui('Pickup'),
                    value: RimaText.ui(pickupText),
                    isLoading: isLoadingLocation,
                    onTap: _getCurrentLocation,
                  ),
                  const SizedBox(height: 14),
                  _locationCard(
                    icon: Icons.location_on_rounded,
                    title: RimaText.ui('Destination'),
                    value: RimaText.ui('Where are you going?'),
                    onTap: _openDestination,
                  ),

                  if (currentLatLng != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      RimaText.ui('Your pickup'),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      RimaText.ui(
                        'Move the map to fine-tune your pickup point.',
                      ),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _green, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 215,
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
                                  offset: Offset(0, -20),
                                  child: Icon(
                                    Icons.location_pin,
                                    size: 50,
                                    color: _green,
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: 10,
                                left: 10,
                                right: 10,
                                child: _MapInstruction(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: _gold,
                          disabledBackgroundColor: _green,
                          disabledForegroundColor: _gold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _confirmPickup,
                        icon: Icon(
                          pickupConfirmed
                              ? Icons.check_circle_rounded
                              : Icons.my_location_rounded,
                        ),
                        label: Text(
                          pickupConfirmed
                              ? RimaText.ui('Pickup confirmed')
                              : RimaText.ui('Confirm pickup'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 26),
                  Text(
                    RimaText.ui('Quick locations'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _quickLocation(
                          icon: Icons.home_rounded,
                          label: RimaText.get('home'),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickLocation(
                          icon: Icons.work_rounded,
                          label: RimaText.ui('Work'),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickLocation(
                          icon: Icons.star_rounded,
                          label: RimaText.ui('Saved'),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),
                  Text(
                    RimaText.ui('Pickup help'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: _softGold,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFD875),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          color: _green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            RimaText.ui(
                              'Use GPS, move the pin, or choose a nearby landmark.',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 66,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: _gold,
                        disabledBackgroundColor: _green,
                        disabledForegroundColor: _gold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      onPressed: pickupConfirmed ? _openDestination : null,
                      child: Text(
                        RimaText.ui('Choose destination'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: _cream,
            border: Border(
              top: BorderSide(
                color: Color(0xFFE6E2D8),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                Expanded(
                  child: _navItem(
                    icon: Icons.home_rounded,
                    label: RimaText.get('home'),
                    onTap: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                  ),
                ),
                Expanded(
                  child: _navItem(
                    icon: Icons.receipt_long_rounded,
                    label: RimaText.get('activity'),
                    onTap: () => _open(const RideHistoryScreen()),
                  ),
                ),
                Expanded(
                  child: _navItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: RimaText.get('wallet'),
                    onTap: () => _open(const WalletScreen()),
                  ),
                ),
                Expanded(
                  child: _navItem(
                    icon: Icons.chat_bubble_rounded,
                    label: RimaText.get('messages'),
                    onTap: () => _open(const MessagesScreen()),
                  ),
                ),
                Expanded(
                  child: _navItem(
                    icon: Icons.person_rounded,
                    label: RimaText.get('profile'),
                    onTap: () => _open(const ProfileScreen()),
                  ),
                ),
              ],
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
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _green,
              width: 1.7,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _gold,
                        ),
                      )
                    : Icon(
                        icon,
                        color: _gold,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: _green,
                size: 24,
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
      color: _green,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          height: 108,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 13,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: _gold,
                  size: 30,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _navItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _gold,
              size: 22,
            ),
            const SizedBox(height: 1),
            SizedBox(
              height: 15,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: _deepGreen,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapInstruction extends StatelessWidget {
  const _MapInstruction();

  static const Color _green = Color(0xFF006B4F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.open_with_rounded,
            size: 17,
            color: _green,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              RimaText.ui('Move map to adjust pickup'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}





