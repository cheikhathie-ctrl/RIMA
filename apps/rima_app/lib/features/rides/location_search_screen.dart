import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme/colors.dart';
import 'destination_map_screen.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';

  final List<_RimaArea> areas = const [
    // OFFICIAL / MAJOR AREAS
    _RimaArea(
      name: 'Tevragh Zeina',
      category: 'Major area',
      center: LatLng(18.1020, -15.9900),
    ),

    _RimaArea(
      name: 'Ksar',
      category: 'Major area',
      center: LatLng(18.1000, -15.9650),
    ),

    _RimaArea(
      name: 'Arafat',
      category: 'Major area',
      center: LatLng(18.0350, -15.9500),
    ),

    _RimaArea(
      name: 'Dar Naim',
      category: 'Major area',
      center: LatLng(18.1150, -15.9300),
    ),

    _RimaArea(
      name: 'Riyadh',
      category: 'Major area',
      center: LatLng(18.0200, -15.9750),
    ),

    _RimaArea(
      name: 'Teyarett',
      category: 'Major area',
      center: LatLng(18.1200, -15.9650),
    ),

    _RimaArea(
      name: 'Toujounine',
      category: 'Major area',
      center: LatLng(18.0750, -15.8900),
    ),

    _RimaArea(
      name: 'Sebkha',
      category: 'Major area',
      center: LatLng(18.0650, -16.0150),
    ),

    _RimaArea(
      name: 'El Mina',
      category: 'Major area',
      center: LatLng(18.0400, -16.0000),
    ),

    // LOCAL / COMMON NAMES
    _RimaArea(
      name: 'Socogim',
      category: 'Local area',
      center: LatLng(18.0750, -15.9800),
    ),

    _RimaArea(
      name: 'Sixième',
      category: 'Local area',
      center: LatLng(18.0700, -15.9700),
    ),

    _RimaArea(
      name: 'Premier',
      category: 'Local area',
      center: LatLng(18.0850, -15.9750),
    ),

    _RimaArea(
      name: 'PK 7',
      category: 'PK area',
      center: LatLng(18.0100, -15.9550),
    ),

    _RimaArea(
      name: 'PK 8',
      category: 'PK area',
      center: LatLng(18.0000, -15.9500),
    ),

    _RimaArea(
      name: 'PK 9',
      category: 'PK area',
      center: LatLng(17.9900, -15.9450),
    ),

    _RimaArea(
      name: 'PK 10',
      category: 'PK area',
      center: LatLng(17.9800, -15.9400),
    ),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<_RimaArea> get filteredAreas {
    if (searchText.trim().isEmpty) {
      return areas;
    }

    final value = searchText.toLowerCase();

    return areas.where((area) {
      return area.name.toLowerCase().contains(value) ||
          area.category.toLowerCase().contains(value);
    }).toList();
  }

  void _openArea(BuildContext context, _RimaArea area) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationMapScreen(
          areaName: area.name,
          areaCenter: area.center,
          landmarks: _landmarksForArea(area),
        ),
      ),
    );
  }

  List<RimaLandmark> _landmarksForArea(_RimaArea area) {
    // TEMPORARY DEVELOPMENT LANDMARKS.
    // Later these will come from the RIMA location database.

    final LatLng center = area.center;

    return [
      RimaLandmark(
        name: '${area.name} Central Mosque',
        type: 'Mosque',
        position: LatLng(center.latitude + 0.0020, center.longitude + 0.0010),
      ),

      RimaLandmark(
        name: '${area.name} Market',
        type: 'Market',
        position: LatLng(center.latitude - 0.0015, center.longitude + 0.0020),
      ),

      RimaLandmark(
        name: '${area.name} School',
        type: 'School',
        position: LatLng(center.latitude + 0.0010, center.longitude - 0.0020),
      ),

      RimaLandmark(
        name: '${area.name} Health Center',
        type: 'Hospital',
        position: LatLng(center.latitude - 0.0020, center.longitude - 0.0010),
      ),

      RimaLandmark(
        name: '${area.name} Poteau',
        type: 'Poteau',
        position: LatLng(center.latitude + 0.0005, center.longitude + 0.0030),
      ),
    ];
  }

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
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search area, PK or landmark',
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
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                    children: [
                      const _SectionTitle(title: 'Popular areas'),

                      const SizedBox(height: 12),

                      ...filteredAreas.map(
                        (area) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AreaCard(
                            area: area,
                            onTap: () {
                              _openArea(context, area);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Material(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  color: RimaColors.primary,
                                ),

                                SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Choose directly on map',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Use a pin when you know the location.',
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),

                                Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RimaArea {
  const _RimaArea({
    required this.name,
    required this.category,
    required this.center,
  });

  final String name;
  final String category;
  final LatLng center;
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.onTap});

  final _RimaArea area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: area.category == 'Major area'
                      ? const Color(0xFFEAF6ED)
                      : const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  area.category == 'PK area'
                      ? Icons.route_outlined
                      : Icons.location_city_outlined,
                  color: RimaColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      area.category,
                      style: const TextStyle(color: Colors.black54),
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
    );
  }
}
