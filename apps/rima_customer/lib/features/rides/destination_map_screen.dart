import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme/colors.dart';
import '../../app/localization/rima_localization.dart';
import 'ride_options_screen.dart';

class RimaLandmark {
  const RimaLandmark({
    required this.name,
    required this.position,
    required this.type,
  });

  final String name;
  final LatLng position;
  final String type;
}

class DestinationMapScreen extends StatefulWidget {
  const DestinationMapScreen({
    super.key,
    required this.pickupPosition,
    required this.areaName,
    required this.areaCenter,
    required this.landmarks,
  });

  final LatLng pickupPosition;
  final String areaName;
  final LatLng areaCenter;
  final List<RimaLandmark> landmarks;

  @override
  State<DestinationMapScreen> createState() =>
      _DestinationMapScreenState();
}

class _DestinationMapScreenState
    extends State<DestinationMapScreen> {
  GoogleMapController? mapController;

  late LatLng selectedDestination;
  String selectedDestinationName = '';

  @override
  void initState() {
    super.initState();

    selectedDestination = widget.areaCenter;
    selectedDestinationName = widget.areaName;
  }

  String _localText(String en, String fr, String ar) {
    switch (RimaLocaleController.code) {
      case 'ar':
        return ar;
      case 'fr':
        return fr;
      default:
        return en;
    }
  }

  String _pinnedLocationName() {
    return _localText(
      'Pinned location in ${widget.areaName}',
      'Emplacement sélectionné à ${widget.areaName}',
      'الموقع المحدد في ${widget.areaName}',
    );
  }

  String _landmarkType(String type) {
    final key = type.toLowerCase().trim();
    if (RimaLocaleController.code == 'ar') {
      const values = <String, String>{
        'mosque': 'مسجد',
        'market': 'سوق',
        'clinic': 'عيادة',
        'hospital': 'مستشفى',
        'school': 'مدرسة',
        'university': 'جامعة',
        'pharmacy': 'صيدلية',
        'hotel': 'فندق',
        'restaurant': 'مطعم',
        'supermarket': 'سوبرماركت',
        'landmark': 'معلم',
      };
      return values[key] ?? type;
    }
    if (RimaLocaleController.code == 'fr') {
      const values = <String, String>{
        'mosque': 'Mosquée',
        'market': 'Marché',
        'clinic': 'Clinique',
        'hospital': 'Hôpital',
        'school': 'École',
        'university': 'Université',
        'pharmacy': 'Pharmacie',
        'hotel': 'Hôtel',
        'restaurant': 'Restaurant',
        'supermarket': 'Supermarché',
        'landmark': 'Repère',
      };
      return values[key] ?? type;
    }
    return type;
  }

  String _landmarkDisplayName(RimaLandmark landmark) {
    if (RimaLocaleController.code != 'ar') return landmark.name;

    var result = landmark.name;
    const replacements = <String, String>{
      'Tevragh Zeina': 'تفرغ زينة',
      'Ksar': 'لكصر',
      'Arafat': 'عرفات',
      'Dar Naim': 'دار النعيم',
      'Riyadh': 'الرياض',
      'Teyarett': 'تيارت',
      'Toujounine': 'توجنين',
      'Sebkha': 'السبخة',
      'El Mina': 'الميناء',
      'Mosque': 'مسجد',
      'Market': 'سوق',
      'Clinic': 'عيادة',
      'Hospital': 'مستشفى',
      'School': 'مدرسة',
      'University': 'جامعة',
      'Pharmacy': 'صيدلية',
      'Hotel': 'فندق',
      'Restaurant': 'مطعم',
      'Supermarket': 'سوبرماركت',
    };

    replacements.forEach((from, to) {
      result = result.replaceAll(from, to);
    });

    return '${landmark.name} — $result';
  }
  void _selectLandmark(RimaLandmark landmark) {
    setState(() {
      selectedDestination = landmark.position;
      selectedDestinationName = _landmarkDisplayName(landmark);
    });

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        landmark.position,
        16,
      ),
    );
  }

  void _confirmDestination() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideOptionsScreen(
          pickupPosition: widget.pickupPosition,
          destinationPosition: selectedDestination,
          destination: selectedDestinationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> landmarkMarkers =
        widget.landmarks.map((landmark) {
      return Marker(
        markerId: MarkerId(landmark.name),
        position: landmark.position,
        infoWindow: InfoWindow(
          title: _landmarkDisplayName(landmark),
          snippet: _landmarkType(landmark.type),
        ),
        onTap: () {
          _selectLandmark(landmark);
        },
      );
    }).toSet();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.areaName,
          style: const TextStyle(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.areaName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: RimaColors.primary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _localText('Choose a landmark or move the map to your destination.', 'Choisissez un repère ou déplacez la carte vers votre destination.', 'اختر معلماً أو حرّك الخريطة إلى وجهتك.'),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 22),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 330,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GoogleMap(
                            initialCameraPosition:
                                CameraPosition(
                              target: widget.areaCenter,
                              zoom: 14,
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
                              selectedDestination =
                                  position.target;

                              setState(() {
                                selectedDestinationName = _pinnedLocationName();
                              });
                            },
                            markers: landmarkMarkers,
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                          ),

                          IgnorePointer(
                            child: Transform.translate(
                              offset: const Offset(0, -22),
                              child: const Icon(
                                Icons.location_pin,
                                size: 54,
                                color: RimaColors.primary,
                              ),
                            ),
                          ),

                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.94),
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.open_with_rounded,
                                    size: 18,
                                    color: RimaColors.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _localText('Move map to adjust destination', 'Déplacez la carte pour ajuster la destination', 'حرّك الخريطة لضبط الوجهة'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

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
                          size: 30,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _localText('Selected destination', 'Destination sélectionnée', 'الوجهة المحددة'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selectedDestinationName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    _localText('Nearby landmarks', 'Repères à proximité', 'المعالم القريبة'),
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...widget.landmarks.map(
                    (landmark) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () =>
                              _selectLandmark(landmark),
                          borderRadius:
                              BorderRadius.circular(18),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(
                                      0xFFFFF3D6,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: Icon(
                                    _iconForType(
                                      _landmarkType(landmark.type),
                                    ),
                                    color:
                                        RimaColors.primary,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        _landmarkDisplayName(landmark),
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _landmarkType(landmark.type),
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons
                                      .chevron_right_rounded,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: _confirmDestination,
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                      ),
                      label: const Text(
                        'Confirm destination',
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

  static IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'mosque':
        return Icons.mosque_outlined;

      case 'market':
        return Icons.storefront_outlined;

      case 'hospital':
        return Icons.local_hospital_outlined;

      case 'school':
        return Icons.school_outlined;

      case 'hotel':
        return Icons.hotel_outlined;

      case 'restaurant':
        return Icons.restaurant_outlined;

      case 'poteau':
        return Icons.signpost_outlined;

      default:
        return Icons.place_outlined;
    }
  }
}
