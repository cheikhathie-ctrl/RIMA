import 'package:flutter/material.dart';

import '../../app/theme/text_styles.dart';

class RimaSectionTitle extends StatelessWidget {
  const RimaSectionTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: RimaTextStyles.title.copyWith(
        fontSize: 20,
      ),
    );
  }
}
