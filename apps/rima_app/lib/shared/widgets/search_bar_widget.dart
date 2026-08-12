import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class RimaSearchBar extends StatelessWidget {
  const RimaSearchBar({
    super.key,
    required this.hintText,
    this.onTap,
  });

  final String hintText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: onTap != null,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search,
          color: RimaColors.primary,
        ),
        filled: true,
        fillColor: RimaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}