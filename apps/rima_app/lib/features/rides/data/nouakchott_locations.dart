import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RimaLocationType {
  officialArea,
  localArea,
  pkArea,
}

class RimaArea {
  const RimaArea({
    required this.id,
    required this.name,
    required this.type,
    required this.center,
    required this.verified,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final RimaLocationType type;
  final LatLng center;
  final bool verified;
  final List<String> aliases;

  String get category {
    switch (type) {
      case RimaLocationType.officialArea:
        return 'Major area';
      case RimaLocationType.localArea:
        return 'Local area';
      case RimaLocationType.pkArea:
        return 'PK area';
    }
  }
}

class NouakchottLocations {
  NouakchottLocations._();

  static const List<RimaArea> areas = [
    RimaArea(
      id: 'tevragh_zeina',
      name: 'Tevragh Zeina',
      type: RimaLocationType.officialArea,
      center: LatLng(18.1020, -15.9900),
      verified: true,
      aliases: ['Tevragh Zeïna', 'Tevragh Zein'],
    ),
    RimaArea(
      id: 'ksar',
      name: 'Ksar',
      type: RimaLocationType.officialArea,
      center: LatLng(18.1000, -15.9650),
      verified: true,
    ),
    RimaArea(
      id: 'arafat',
      name: 'Arafat',
      type: RimaLocationType.officialArea,
      center: LatLng(18.0350, -15.9500),
      verified: true,
    ),
    RimaArea(
      id: 'dar_naim',
      name: 'Dar Naim',
      type: RimaLocationType.officialArea,
      center: LatLng(18.1150, -15.9300),
      verified: true,
      aliases: ['Dar-Naim'],
    ),
    RimaArea(
      id: 'riyadh',
      name: 'Riyadh',
      type: RimaLocationType.officialArea,
      center: LatLng(18.0200, -15.9750),
      verified: true,
      aliases: ['Riad', 'Riyad'],
    ),
    RimaArea(
      id: 'teyarett',
      name: 'Teyarett',
      type: RimaLocationType.officialArea,
      center: LatLng(18.1200, -15.9650),
      verified: true,
    ),
    RimaArea(
      id: 'toujounine',
      name: 'Toujounine',
      type: RimaLocationType.officialArea,
      center: LatLng(18.0750, -15.8900),
      verified: true,
    ),
    RimaArea(
      id: 'sebkha',
      name: 'Sebkha',
      type: RimaLocationType.officialArea,
      center: LatLng(18.0650, -16.0150),
      verified: true,
    ),
    RimaArea(
      id: 'el_mina',
      name: 'El Mina',
      type: RimaLocationType.officialArea,
      center: LatLng(18.0400, -16.0000),
      verified: true,
    ),

    // Local/common names
    RimaArea(
      id: 'socogim',
      name: 'Socogim',
      type: RimaLocationType.localArea,
      center: LatLng(18.0750, -15.9800),
      verified: false,
    ),
    RimaArea(
      id: 'sixieme',
      name: 'Sixième',
      type: RimaLocationType.localArea,
      center: LatLng(18.0700, -15.9700),
      verified: false,
      aliases: ['6ème', 'Sixieme'],
    ),
    RimaArea(
      id: 'premier',
      name: 'Premier',
      type: RimaLocationType.localArea,
      center: LatLng(18.0850, -15.9750),
      verified: false,
    ),

    // PK areas
    RimaArea(
      id: 'pk_7',
      name: 'PK 7',
      type: RimaLocationType.pkArea,
      center: LatLng(18.0100, -15.9550),
      verified: false,
      aliases: ['PK7', 'PK-7'],
    ),
    RimaArea(
      id: 'pk_8',
      name: 'PK 8',
      type: RimaLocationType.pkArea,
      center: LatLng(18.0000, -15.9500),
      verified: false,
      aliases: ['PK8', 'PK-8'],
    ),
    RimaArea(
      id: 'pk_9',
      name: 'PK 9',
      type: RimaLocationType.pkArea,
      center: LatLng(17.9900, -15.9450),
      verified: false,
      aliases: ['PK9', 'PK-9'],
    ),
    RimaArea(
      id: 'pk_10',
      name: 'PK 10',
      type: RimaLocationType.pkArea,
      center: LatLng(17.9800, -15.9400),
      verified: false,
      aliases: ['PK10', 'PK-10'],
    ),
  ];
}