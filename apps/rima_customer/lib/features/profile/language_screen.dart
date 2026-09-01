import 'package:flutter/material.dart';

import '../../app/localization/rima_localization.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: RimaLocaleController.language,
      builder: (context, selected, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              RimaText.get('language'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                RimaText.get('chooseLanguage'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 24),

              _languageTile(
                context,
                code: 'ar',
                title: 'العربية',
                subtitle: 'Arabic',
                selected: selected == 'ar',
              ),

              _languageTile(
                context,
                code: 'fr',
                title: 'Français',
                subtitle: 'French',
                selected: selected == 'fr',
              ),

              _languageTile(
                context,
                code: 'en',
                title: 'English',
                subtitle: 'English',
                selected: selected == 'en',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _languageTile(
    BuildContext context, {
    required String code,
    required String title,
    required String subtitle,
    required bool selected,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          selected
              ? Icons.check_circle_rounded
              : Icons.circle_outlined,
          color: const Color(0xFFFFC52F),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight:
                selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        onTap: () async {
          await RimaLocaleController.changeLanguage(code);

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                code == 'ar'
                    ? 'تم تغيير اللغة'
                    : code == 'fr'
                        ? 'Langue modifiée'
                        : 'Language changed',
              ),
            ),
          );
        },
      ),
    );
  }
}