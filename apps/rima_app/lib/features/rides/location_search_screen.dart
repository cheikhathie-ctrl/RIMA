import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import 'ride_options_screen.dart';

class LocationSearchScreen extends StatelessWidget {
  const LocationSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Choose destination',
          style: TextStyle(
            color: RimaColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search destination or landmark',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: RimaColors.primary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Suggested places',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _placeTile(
                    context,
                    Icons.flight_rounded,
                    'Nouakchott International Airport',
                    'Oumtounsy',
                  ),

                  _placeTile(
                    context,
                    Icons.location_city_rounded,
                    'Tevragh-Zeina',
                    'Nouakchott',
                  ),

                  _placeTile(
                    context,
                    Icons.shopping_bag_outlined,
                    'City Center',
                    'Nouakchott',
                  ),

                  _placeTile(
                    context,
                    Icons.place_outlined,
                    'Choose on map',
                    'Drop a pin',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _placeTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 5,
      ),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6ED),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: RimaColors.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.chevron_right_rounded,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideOptionsScreen(
              destination: title,
            ),
          ),
        );
      },
    );
  }
}