import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import '../rides/ride_booking_screen.dart';
import '../rides/ride_searching_screen.dart';
import '../rides/ride_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkingLatestRide = true;
  bool _resumeHandled = false;

  static const Set<String> _activeRideStatuses = {
    'requested',
    'searching',
    'driver_assigned',
    'driver_arriving',
    'driver_arrived',
    'in_progress',
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLatestRide();
    });
  }

  Future<void> _checkLatestRide() async {
    if (_resumeHandled) {
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _checkingLatestRide = false;
        });

        return;
      }

      debugPrint('RIMA CUSTOMER HOME: checking newest ride for ${user.id}');

      //
      // IMPORTANT:
      // We check the customer's newest ride OVERALL.
      //
      // We do NOT search all historical "searching" rides,
      // because an old unfinished test ride must never
      // override a newer completed/cancelled ride.
      //
      final result = await Supabase.instance.client
          .from('rides')
          .select(
            'id, status, service_type, destination_label, '
            'quoted_fare_mru, requested_at, updated_at',
          )
          .eq('customer_id', user.id)
          .order('requested_at', ascending: false)
          .limit(1);

      if (!mounted) return;

      //
      // Customer has never requested a ride.
      //
      if (result.isEmpty) {
        setState(() {
          _checkingLatestRide = false;
        });

        return;
      }

      final ride = Map<String, dynamic>.from(result.first);

      final rideId = ride['id']?.toString();

      final status = ride['status']?.toString() ?? '';

      final destination =
          ride['destination_label']?.toString() ?? 'Destination';

      debugPrint(
        'RIMA CUSTOMER HOME LATEST RIDE: '
        'id=$rideId '
        'status=$status '
        'destination=$destination',
      );

      //
      // COMPLETED / CANCELLED
      //
      // Latest ride is finished.
      // Customer stays on Home.
      //
      if (status == 'completed' || status == 'cancelled') {
        setState(() {
          _checkingLatestRide = false;
        });

        return;
      }

      //
      // Any unexpected status should NOT automatically
      // reopen an old ride.
      //
      if (!_activeRideStatuses.contains(status)) {
        setState(() {
          _checkingLatestRide = false;
        });

        return;
      }

      if (rideId == null || rideId.isEmpty) {
        setState(() {
          _checkingLatestRide = false;
        });

        return;
      }

      //
      // Latest ride is genuinely active.
      // Resume that exact ride.
      //
      final serviceType = ride['service_type']?.toString() ?? 'rima_go';

      final fare = _formatFare(ride['quoted_fare_mru']);

      _resumeHandled = true;

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RideSearchingScreen(
            rideId: rideId,
            rideType: _serviceLabel(serviceType),
            destination: destination,
            fare: fare,
          ),
        ),
        (route) => false,
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      debugPrint('RIMA CUSTOMER HOME RIDE CHECK ERROR: ${e.message}');

      setState(() {
        _checkingLatestRide = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('RIMA CUSTOMER HOME RIDE CHECK ERROR: $e');

      setState(() {
        _checkingLatestRide = false;
      });
    }
  }

  String _serviceLabel(String serviceType) {
    switch (serviceType) {
      case 'rima_comfort':
        return 'RIMA Comfort';

      case 'rima_xl':
        return 'RIMA XL';

      case 'rima_go':
      default:
        return 'RIMA Go';
    }
  }

  String _formatFare(dynamic value) {
    if (value == null) {
      return '-- MRU';
    }

    final parsed = double.tryParse(value.toString());

    if (parsed == null) {
      return '${value.toString()} MRU';
    }

    if (parsed == parsed.roundToDouble()) {
      return '${parsed.toStringAsFixed(0)} MRU';
    }

    return '${parsed.toStringAsFixed(2)} MRU';
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLatestRide) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFDF7),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: RimaColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),

            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  //
                  // HEADER
                  //
                  Row(
                    children: [
                      Expanded(
                        child: Image.asset(
                          'assets/images/rima_logo.png',
                          height: 100,
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(width: 12),

                      _circleButton(Icons.notifications_none_rounded, () {}),

                      const SizedBox(width: 8),

                      _circleButton(Icons.person_outline_rounded, () {}),
                    ],
                  ),

                  const SizedBox(height: 28),

                  //
                  // WELCOME
                  //
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6DC),
                      borderRadius: BorderRadius.circular(24),
                    ),

                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Welcome to RIMA 👋',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: RimaColors.primary,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'How can we help you today?',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  //
                  // SEARCH
                  //
                  Container(
                    height: 58,

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(18),

                      border: Border.all(color: Colors.black12),
                    ),

                    child: const TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,

                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: RimaColors.primary,
                        ),

                        hintText: 'Where are you going?',

                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  //
                  // SERVICES
                  //
                  const Text(
                    'Services',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 16),

                  GridView(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 135,
                        ),

                    children: [
                      _serviceTile(
                        icon: Icons.local_taxi_rounded,

                        title: 'RIMA Go',

                        subtitle: 'Book a ride',

                        background: const Color(0xFFEAF6ED),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RideBookingScreen(),
                            ),
                          );
                        },
                      ),

                      _serviceTile(
                        icon: Icons.restaurant_rounded,

                        title: 'RIMA Food',

                        subtitle: 'Order food',

                        background: const Color(0xFFFFF3D6),

                        onTap: () {},
                      ),

                      _serviceTile(
                        icon: Icons.inventory_2_outlined,

                        title: 'RIMA Express',

                        subtitle: 'Send a package',

                        background: const Color(0xFFEAF6ED),

                        onTap: () {},
                      ),

                      _serviceTile(
                        icon: Icons.account_balance_wallet_outlined,

                        title: 'RIMA Pay',

                        subtitle: 'Pay & transfer',

                        background: const Color(0xFFFFF3D6),

                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  //
                  // QUICK ACCESS
                  //
                  const Text(
                    'Quick access',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 15),

                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RideHistoryScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: RimaColors.primary,
                          size: 30,
                        ),

                        SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                'Recent activity',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              SizedBox(height: 3),

                              Text(
                                'Your rides, orders and deliveries',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.black45,
                        ),
                      ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RideHistoryScreen(),
              ),
            );
          }
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Activity',
          ),

          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Wallet',
          ),

          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Messages',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  static Widget _circleButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6DC),
        shape: BoxShape.circle,
      ),

      child: IconButton(
        onPressed: onPressed,

        icon: Icon(icon, color: RimaColors.primary),
      ),
    );
  }

  static Widget _serviceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,

      borderRadius: BorderRadius.circular(22),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(22),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(icon, size: 36, color: RimaColors.primary),

              const SizedBox(height: 14),

              Text(
                title,

                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,

                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
