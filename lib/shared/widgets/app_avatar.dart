import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/utils/context_extensions.dart';
import 'app_image.dart';

/// Circular avatar. Loads a network image when available, otherwise renders a
/// deterministic gradient with the person's initials — so the app looks
/// complete even with no image assets.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl = '',
    this.size = 48,
    this.borderColor,
  });

  final String name;
  final String imageUrl;
  final double size;
  final Color? borderColor;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final border = borderColor != null
        ? Border.all(color: borderColor!, width: 2)
        : null;

    final c = context.colors;
    // Neutral, on-brand fallback (no rainbow) so unmatched fighters read as
    // intentional rather than noisy.
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [c.surfaceElevated, c.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: border ?? Border.all(color: c.border),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTypography.h4.copyWith(
          color: c.textSecondary,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (imageUrl.isEmpty) return fallback;

    // Bundled asset portraits use an "assets/" path; everything else is network.
    final isAsset = imageUrl.startsWith('assets/');
    final Widget image = isAsset
        ? Image(image: appImageProvider(imageUrl),
            width: size,
            height: size,
            fit: BoxFit.cover,
            // Portraits are top-weighted; bias the crop to the head/torso.
            alignment: const Alignment(0, -0.6),
            errorBuilder: (_, __, ___) => fallback,
          )
        : CachedNetworkImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.6),
            placeholder: (_, __) => ColoredBox(color: context.colors.skeleton),
            errorWidget: (_, __, ___) => fallback,
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: border),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}
