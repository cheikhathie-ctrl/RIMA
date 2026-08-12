import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/search_bar_widget.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/service_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: RimaColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: RimaColors.gold,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RIMA',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: RimaColors.primary,
                        ),
                      ),
                      Text(
                        'Mauritania',
                        style: RimaTextStyles.subtitle,
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'How can RIMA help you today?',
                style: RimaTextStyles.heading,
              ),
              const SizedBox(height: 8),
              const Text(
                'كيف يمكن لريما مساعدتك اليوم؟',
                textDirection: TextDirection.rtl,
                style: RimaTextStyles.subtitle,
              ),
              const SizedBox(height: 24),
              const RimaSearchBar(
                hintText: 'Search destination, restaurant or service',
              ),
              const SizedBox(height: 30),
              const RimaSectionTitle(
                title: 'Services',
              ),
              const SizedBox(height: 14),
              RimaServiceCard(
                icon: Icons.local_taxi_rounded,
                title: 'RIMA Go',
                subtitle: 'Get there safely and quickly.',
                onTap: () {},
              ),
              const SizedBox(height: 14),
              RimaServiceCard(
                icon: Icons.restaurant_rounded,
                title: 'RIMA Food',
                subtitle: 'Your favorite restaurants, delivered.',
                onTap: () {},
              ),
              const SizedBox(height: 14),
              RimaServiceCard(
                icon: Icons.inventory_2_outlined,
                title: 'RIMA Express',
                subtitle: 'Send packages across the city.',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}