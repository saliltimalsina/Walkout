import 'package:flutter/material.dart';

import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Card presenting the fighter's biography copy.
class FighterBioCard extends StatelessWidget {
  const FighterBioCard({super.key, required this.bio});

  final String bio;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Bio'),
          Text(
            bio,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
