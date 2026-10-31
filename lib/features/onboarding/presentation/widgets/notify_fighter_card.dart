import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_motion.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/fighter.dart';
import 'package:walkout/shared/widgets/pressable.dart';
import '../../../../shared/widgets/app_image.dart';

/// Portrait card with a bell toggle used on the notifications step.
/// Image sits inset (contained) in the upper area; name/division live on a
/// solid strip below so text is always crisp and never overflows the art.
class NotifyFighterCard extends StatelessWidget {
  const NotifyFighterCard({
    super.key,
    required this.fighter,
    required this.selected,
    required this.onTap,
  });

  final Fighter fighter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.brLg,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: selected ? c.brand : c.border),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x22FFFFFF), Color(0x00000000)],
                      ),
                    ),
                  ),
                  if (fighter.imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Image(image: appImageProvider(fighter.imageUrl),
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: AnimatedContainer(
                      duration: AppDuration.fast,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: selected ? c.brand : const Color(0x99000000),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        selected
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, 2, AppSpacing.sm, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fighter.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    fighter.weightClass.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: c.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
