import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class RideSearchingScreen extends StatefulWidget {
  const RideSearchingScreen({
    super.key,
    required this.rideType,
    required this.destination,
    required this.fare,
  });

  final String rideType;
  final String destination;
  final String fare;

  @override
  State<RideSearchingScreen> createState() =>
      _RideSearchingScreenState();
}

class _RideSearchingScreenState extends State<RideSearchingScreen> {
  bool driverFound = false;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;

      setState(() {
        driverFound = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          driverFound ? 'Driver found' : 'Finding your driver',
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: driverFound
                    ? _driverFoundView()
                    : _searchingView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchingView() {
    return Column(
      key: const ValueKey('searching'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF6ED),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.local_taxi_rounded,
              size: 58,
              color: RimaColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 35),

        const CircularProgressIndicator(
          color: RimaColors.primary,
        ),

        const SizedBox(height: 28),

        Text(
          'Finding your ${widget.rideType}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Searching for nearby drivers...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 35),

        _tripSummary(),
      ],
    );
  }

  Widget _driverFoundView() {
    return SingleChildScrollView(
      key: const ValueKey('found'),
      child: Column(
        children: [
          const SizedBox(height: 30),

          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF6ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 50,
              color: RimaColors.primary,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Your driver is on the way',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: RimaColors.primary,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Arriving in approximately 3 minutes',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 28),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black12),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFEAF6ED),
                  child: Icon(
                    Icons.person,
                    color: RimaColors.primary,
                    size: 32,
                  ),
                ),

                SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mohamed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Toyota Corolla • 1234 AB',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: RimaColors.gold,
                    ),
                    Text(
                      '4.9',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          _tripSummary(),
        ],
      ),
    );
  }

  Widget _tripSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _summaryRow(
            Icons.local_taxi_outlined,
            'Ride',
            widget.rideType,
          ),
          const Divider(height: 25),
          _summaryRow(
            Icons.location_on_outlined,
            'Destination',
            widget.destination,
          ),
          const Divider(height: 25),
          _summaryRow(
            Icons.payments_outlined,
            'Estimated fare',
            widget.fare,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: RimaColors.primary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}