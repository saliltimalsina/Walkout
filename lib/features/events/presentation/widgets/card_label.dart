import 'package:flutter/material.dart';

import 'package:walkout/core/utils/context_extensions.dart';

/// The one label recipe for event and fight cards: uppercase, extra-bold,
/// wide-tracked labelSmall — as used on the event detail bout cards
/// ("MAIN EVENT", weight-class tags).
///
/// Defaults to brand red; pass [color] for on-art (white70) or on-brand
/// variants.
TextStyle? cardLabelStyle(BuildContext context, {Color? color}) =>
    context.text.labelSmall?.copyWith(
      color: color ?? context.colors.brand,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
    );
