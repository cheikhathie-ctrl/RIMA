import 'package:flutter/material.dart';
import 'ride_searching_screen.dart';
import '../../app/theme/colors.dart';

class RideOptionsScreen extends StatefulWidget {
  const RideOptionsScreen({super.key, required this.destination});

  final String destination;

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  String selectedRide = 'RIMA Go';

  final Map<String, String> prices = {
    'RIMA Go': '250 MRU',
    'RIMA Comfort': '350 MRU',
    'RIMA XL': '450 MRU',
  };

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
                    eta: '3 min',
                    price: '250 MRU',
                  ),

                  const SizedBox(height: 12),

                  _rideOption(
                    icon: Icons.local_taxi_rounded,
                    title: 'RIMA Comfort',
                    subtitle: 'More comfort and space',
                    eta: '5 min',
                    price: '350 MRU',
                  ),

                  const SizedBox(height: 12),

                  _rideOption(
                    icon: Icons.airport_shuttle_rounded,
                    title: 'RIMA XL',
                    subtitle: 'For groups and more luggage',
                    eta: '7 min',
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RideSearchingScreen(
                              rideType: selectedRide,
                              destination: widget.destination,
                              fare: prices[selectedRide]!,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Request $selectedRide',
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
