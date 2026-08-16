import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import 'data/nouakchott_locations.dart';
import 'destination_map_screen.dart';

class GooglePlaceResult {
  const GooglePlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.position,
    this.primaryType,
  });

  final String placeId;
  final String name;
  final String address;
  final LatLng position;
  final String? primaryType;
}

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key, required this.pickupPosition});

  final LatLng pickupPosition;

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  String searchText = '';

  bool isSearchingGoogle = false;

  String? googleSearchError;

  List<GooglePlaceResult> googlePlaces = [];

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  List<RimaArea> get filteredAreas {
    if (searchText.trim().isEmpty) {
      return NouakchottLocations.areas;
    }

    final String value = searchText.toLowerCase().trim();

    return NouakchottLocations.areas.where((area) {
      final bool nameMatch = area.name.toLowerCase().contains(value);

      final bool categoryMatch = area.category.toLowerCase().contains(value);

      final bool aliasMatch = area.aliases.any(
        (alias) => alias.toLowerCase().contains(value),
      );

      return nameMatch || categoryMatch || aliasMatch;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchText = value;
      googleSearchError = null;
    });

    _debounce?.cancel();

    if (value.trim().length < 2) {
      setState(() {
        googlePlaces = [];
        isSearchingGoogle = false;
      });

      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchGooglePlaces(value);
    });
  }

  Future<void> _searchGooglePlaces(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      return;
    }

    setState(() {
      isSearchingGoogle = true;
      googleSearchError = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'search-places',
        body: {
          'query': trimmedQuery,
          'latitude': widget.pickupPosition.latitude,
          'longitude': widget.pickupPosition.longitude,
          'radius_meters': 50000,
        },
      );

      if (!mounted) return;

      final data = response.data;

      if (data == null || data is! Map) {
        throw Exception('Invalid places response.');
      }

      if (data['error'] != null) {
        throw Exception(data['error'].toString());
      }

      final rawPlaces = data['places'];

      if (rawPlaces is! List) {
        setState(() {
          googlePlaces = [];
          isSearchingGoogle = false;
        });

        return;
      }

      final results = <GooglePlaceResult>[];

      for (final item in rawPlaces) {
        if (item is! Map) {
          continue;
        }

        final latitude = _toDouble(item['latitude']);

        final longitude = _toDouble(item['longitude']);

        if (latitude == null || longitude == null) {
          continue;
        }

        results.add(
          GooglePlaceResult(
            placeId: item['place_id']?.toString() ?? '',
            name: item['name']?.toString() ?? 'Unknown place',
            address: item['address']?.toString() ?? '',
            position: LatLng(latitude, longitude),
            primaryType: item['primary_type']?.toString(),
          ),
        );
      }

      if (!mounted) return;

      // Ignore an older search response if the user
      // has already typed something different.
      if (searchController.text.trim() != trimmedQuery) {
        return;
      }

      setState(() {
        googlePlaces = results;
        isSearchingGoogle = false;
      });
    } on FunctionException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA PLACES FUNCTION ERROR: ${e.details}');

      setState(() {
        googlePlaces = [];
        googleSearchError = 'Unable to search Google places.';
        isSearchingGoogle = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA PLACES SEARCH ERROR: $e');

      setState(() {
        googlePlaces = [];
        googleSearchError = 'Unable to search Google places.';
        isSearchingGoogle = false;
      });
    }
  }

  static double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  void _openArea(BuildContext context, RimaArea area) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationMapScreen(
          pickupPosition: widget.pickupPosition,
          areaName: area.name,
          areaCenter: area.center,
          landmarks: _landmarksForArea(area),
        ),
      ),
    );
  }

  void _openGooglePlace(GooglePlaceResult place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationMapScreen(
          pickupPosition: widget.pickupPosition,
          areaName: place.name,
          areaCenter: place.position,
          landmarks: const [],
        ),
      ),
    );
  }

  void _openDirectMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationMapScreen(
          pickupPosition: widget.pickupPosition,
          areaName: 'Pinned destination',
          areaCenter: widget.pickupPosition,
          landmarks: const [],
        ),
      ),
    );
  }

  List<RimaLandmark> _landmarksForArea(RimaArea area) {
    // DEVELOPMENT DATA ONLY.
    // These names/coordinates will later be
    // replaced by the verified RIMA landmark
    // database.

    final center = area.center;

    return [
      RimaLandmark(
        name: '${area.name} Mosque',
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
    final areas = filteredAreas;

    final bool hasSearch = searchText.trim().isNotEmpty;

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
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search place, area, PK or landmark',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: RimaColors.primary,
                      ),
                      suffixIcon: isSearchingGoogle
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: RimaColors.primary,
                                ),
                              ),
                            )
                          : searchText.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();

                                _debounce?.cancel();

                                setState(() {
                                  searchText = '';
                                  googlePlaces = [];
                                  googleSearchError = null;
                                  isSearchingGoogle = false;
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
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
                      if (hasSearch) ...[
                        const Text(
                          'Places',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (googleSearchError != null)
                          _SearchErrorCard(
                            message: googleSearchError!,
                            onRetry: () {
                              _searchGooglePlaces(searchController.text);
                            },
                          ),

                        if (!isSearchingGoogle &&
                            googleSearchError == null &&
                            googlePlaces.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No Google places found yet.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),

                        ...googlePlaces.map(
                          (place) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GooglePlaceCard(
                              place: place,
                              onTap: () => _openGooglePlace(place),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],

                      Text(
                        hasSearch ? 'RIMA local areas' : 'Popular areas',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (areas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No matching RIMA local area found.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),

                      ...areas.map(
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
                          onTap: _openDirectMap,
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
                                        'Move the pin to the exact destination.',
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

class _GooglePlaceCard extends StatelessWidget {
  const _GooglePlaceCard({required this.place, required this.onTap});

  final GooglePlaceResult place;
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
                  color: const Color(0xFFEAF6ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: RimaColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    if (place.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.onTap});

  final RimaArea area;
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
                  color: area.type == RimaLocationType.officialArea
                      ? const Color(0xFFEAF6ED)
                      : const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  area.type == RimaLocationType.pkArea
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            area.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        if (area.verified) ...[
                          const SizedBox(width: 7),
                          const Icon(
                            Icons.verified_rounded,
                            size: 17,
                            color: RimaColors.primary,
                          ),
                        ],
                      ],
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

class _SearchErrorCard extends StatelessWidget {
  const _SearchErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: RimaColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
