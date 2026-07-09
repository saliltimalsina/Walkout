import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Centered identity block: avatar, name, handle, and membership date.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      children: [
        AppAvatar(
          name: user.name,
          imageUrl: user.avatarUrl,
          size: 88,
          borderColor: c.brand,
        ),
        AppSpacing.vGapMd,
        Text(
          user.name,
          style: context.text.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (user.handle.isNotEmpty) ...[
          AppSpacing.vGapXs,
          Text(
            user.handle,
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
        AppSpacing.vGapXs,
        Text(
          'Member since ${user.memberSince.monthShort} ${user.memberSince.year}',
          style: context.text.labelMedium?.copyWith(color: c.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
