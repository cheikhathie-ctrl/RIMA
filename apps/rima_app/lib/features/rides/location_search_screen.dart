import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import 'data/nouakchott_locations.dart';
import 'destination_map_screen.dart';

enum LocationSearchMode { pickup, destination }

class LocationSearchResult {
  const LocationSearchResult({required this.name, required this.position});

  final String name;
  final LatLng position;
}

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
  const LocationSearchScreen({
    super.key,
    required this.pickupPosition,
    this.mode = LocationSearchMode.destination,
  });

  final LatLng pickupPosition;
  final LocationSearchMode mode;

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  String searchText = '';

  bool isSearchingGoogle = false;
  bool isGettingCurrentLocation = false;

  String? googleSearchError;

  List<GooglePlaceResult> googlePlaces = [];

  //
  // MODE HELPERS
  //

  bool get isPickup => widget.mode == LocationSearchMode.pickup;

  bool get isDestination => widget.mode == LocationSearchMode.destination;

  String get screenTitle {
    switch (widget.mode) {
      case LocationSearchMode.pickup:
        return 'Choose pickup';

      case LocationSearchMode.destination:
        return 'Choose destination';
    }
  }

  String get searchHint {
    switch (widget.mode) {
      case LocationSearchMode.pickup:
        return 'Search pickup place, area or landmark';

      case LocationSearchMode.destination:
        return 'Search destination, area, PK or landmark';
    }
  }

  String get googleSectionTitle {
    switch (widget.mode) {
      case LocationSearchMode.pickup:
        return 'Pickup places';

      case LocationSearchMode.destination:
        return 'Places';
    }
  }

  String get localSectionTitle {
    if (searchText.trim().isNotEmpty) {
      return 'RIMA local areas';
    }

    switch (widget.mode) {
      case LocationSearchMode.pickup:
        return 'Popular pickup areas';

      case LocationSearchMode.destination:
        return 'Popular areas';
    }
  }

  String get mapOptionTitle {
    switch (widget.mode) {
      case LocationSearchMode.pickup:
        return 'Adjust pickup on map';

      case LocationSearchMode.destination:
        return 'Choose directly on map';
    }
  }

  String get mapOptionSubtitle {
    switch (widget.mode) {
      case LocationSearchMode.pickup:
        return 'Move the pin to the exact pickup point.';

      case LocationSearchMode.destination:
        return 'Move the pin to the exact destination.';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  //
  // RIMA LOCAL AREAS
  //

  List<RimaArea> get filteredAreas {
    final query = searchText.toLowerCase().trim();

    if (query.isEmpty) {
      return NouakchottLocations.areas;
    }

    return NouakchottLocations.areas.where((area) {
      final matchesName = area.name.toLowerCase().contains(query);

      final matchesCategory = area.category.toLowerCase().contains(query);

      final matchesAlias = area.aliases.any(
        (alias) => alias.toLowerCase().contains(query),
      );

      return matchesName || matchesCategory || matchesAlias;
    }).toList();
  }

  //
  // SEARCH INPUT
  //

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

  //
  // GOOGLE PLACES
  //

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

  //
  // CURRENT LOCATION
  //
  // Pickup only.
  //

  Future<void> _useCurrentLocation() async {
    if (!isPickup || isGettingCurrentLocation) {
      return;
    }

    setState(() {
      isGettingCurrentLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission was denied.')),
        );

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is permanently denied.'),
          ),
        );

        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        LocationSearchResult(
          name: 'Your current location',
          position: LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      debugPrint('RIMA CURRENT LOCATION ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get your current location.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGettingCurrentLocation = false;
        });
      }
    }
  }

  //
  // LOCATION SELECTED
  //

  void _handleSelection({
    required String name,
    required LatLng position,
    List<RimaLandmark> landmarks = const [],
  }) {
    switch (widget.mode) {
      case LocationSearchMode.pickup:
        Navigator.pop(
          context,
          LocationSearchResult(name: name, position: position),
        );

        return;

      case LocationSearchMode.destination:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DestinationMapScreen(
              pickupPosition: widget.pickupPosition,
              areaName: name,
              areaCenter: position,
              landmarks: landmarks,
            ),
          ),
        );

        return;
    }
  }

  void _selectArea(RimaArea area) {
    _handleSelection(
      name: area.name,
      position: area.center,
      landmarks: _landmarksForArea(area),
    );
  }

  void _selectGooglePlace(GooglePlaceResult place) {
    _handleSelection(name: place.name, position: place.position);
  }

  void _chooseDirectlyOnMap() {
    switch (widget.mode) {
      case LocationSearchMode.pickup:
        Navigator.pop(context);
        return;

      case LocationSearchMode.destination:
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

        return;
    }
  }

  //
  // TEMP LANDMARKS
  //

  List<RimaLandmark> _landmarksForArea(RimaArea area) {
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

  static double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  //
  // CURRENT LOCATION CARD
  //

  Widget _buildCurrentLocationCard() {
    if (!isPickup) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Material(
        color: const Color(0xFFEAF6ED),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: isGettingCurrentLocation ? null : _useCurrentLocation,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: isGettingCurrentLocation
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: RimaColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: RimaColors.primary,
                        ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use current location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Use your GPS location as the pickup.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areas = filteredAreas;

    final hasSearch = searchText.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          screenTitle,
          style: const TextStyle(
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
                //
                // CURRENT LOCATION
                // PICKUP ONLY
                //
                _buildCurrentLocationCard(),

                //
                // SEARCH
                //
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),

                  child: TextField(
                    controller: searchController,

                    onChanged: _onSearchChanged,

                    textInputAction: TextInputAction.search,

                    decoration: InputDecoration(
                      hintText: searchHint,

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
                        Text(
                          googleSectionTitle,
                          style: const TextStyle(
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
                              onTap: () {
                                _selectGooglePlace(place);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],

                      //
                      // RIMA AREAS
                      //
                      Text(
                        localSectionTitle,
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
                              _selectArea(area);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      //
                      // MAP OPTION
                      //
                      Material(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: _chooseDirectlyOnMap,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.map_outlined,
                                  color: RimaColors.primary,
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mapOptionTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),

                                      const SizedBox(height: 3),

                                      Text(
                                        mapOptionSubtitle,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(Icons.chevron_right_rounded),
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
