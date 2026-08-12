import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),

      // =========================
      // MAIN PAGE
      // =========================
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20,100 ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================
                  // RIMA HEADER
                  // =========================
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

                      _circleButton(
                        Icons.notifications_none_rounded,
                        () {},
                      ),

                      const SizedBox(width: 8),

                      _circleButton(
                        Icons.person_outline_rounded,
                        () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =========================
                  // WELCOME CARD
                  // =========================
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
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================
                  // DESTINATION SEARCH
                  // =========================
                  Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.black12,
                      ),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: RimaColors.primary,
                        ),
                        hintText: 'Where are you going?',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // SERVICES
                  // =========================
                  const Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
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
                        onTap: () {},
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

                  // =========================
                  // QUICK ACCESS
                  // =========================
                  const Text(
                    'Quick access',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.black12,
                      ),
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
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
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

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),

      // =========================
      // BOTTOM NAVIGATION
      // =========================
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
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

  // =========================
  // HEADER BUTTON
  // =========================
  static Widget _circleButton(
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6DC),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: RimaColors.primary,
        ),
      ),
    );
  }

  // =========================
  // SERVICE TILE
  // =========================
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
              Icon(
                icon,
                size: 36,
                color: RimaColors.primary,
              ),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}