import 'dart:async';

import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';

import 'aura_card.dart';

/// Phase-aware DAYS / HRS / MIN / SEC countdown shared by the featured hero
/// ([compact]) and the event detail card.
///
/// Follows [Event.phaseAt]: upcoming → ticking digits; prelims → digits (to
/// the main-card walk) plus a pulsing PRELIMS LIVE pill; mainCard → pulsing
/// LIVE badge; ended → a static FINAL row. The 1s timer keeps running through
/// the live window so LIVE → FINAL happens without an external rebuild.
class EventCountdown extends StatefulWidget {
  const EventCountdown({
    super.key,
    required this.event,
    this.compact = false,
  });

  final Event event;

  /// Hero variant: a transparent row of white digits meant to sit over the
  /// featured card art. When false, renders the bordered card variant with
  /// larger digits and the date line underneath.
  final bool compact;

  @override
  State<EventCountdown> createState() => _EventCountdownState();
}

class _EventCountdownState extends State<EventCountdown>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulse;

  EventPhase get _phase => widget.event.phaseAt(DateTime.now());

  bool get _isLive =>
      _phase == EventPhase.prelims || _phase == EventPhase.mainCard;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _syncMode();
  }

  /// Ticks every second until the event ends; the pulse runs only while live.
  /// The timer must survive the live window — it is what flips LIVE → FINAL.
  void _syncMode() {
    if (_isLive) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
    if (_phase == EventPhase.ended) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(_syncMode);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Duration get _left {
    final left = widget.event.date.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phase;

    if (widget.compact) {
      return switch (phase) {
        EventPhase.upcoming => _compactRow(context),
        EventPhase.prelims => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _compactRow(context),
              AppSpacing.vGapSm,
              _liveBadge(context, label: 'PRELIMS LIVE'),
            ],
          ),
        EventPhase.mainCard => _liveBadge(context),
        EventPhase.ended => _finalRow(context),
      };
    }

    return AuraCard(
      glowAlpha: 0.12,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            switch (phase) {
              EventPhase.upcoming => _cardRow(context),
              EventPhase.prelims => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _cardRow(context),
                    AppSpacing.vGapMd,
                    _liveBadge(context, label: 'PRELIMS LIVE'),
                  ],
                ),
              EventPhase.mainCard => _liveBadge(context),
              EventPhase.ended => _finalRow(context),
            },
            AppSpacing.vGapMd,
            _dateLine(context),
          ],
        ),
      ),
    );
  }

  /// Static row shown once the card is over — LIVE must visibly die.
  Widget _finalRow(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.check, size: widget.compact ? 12 : 14, color: c.brand),
          AppSpacing.hGapSm,
          Text(
            'FINAL • EVENT COMPLETE',
            style: context.text.labelSmall?.copyWith(
              color: widget.compact ? Colors.white : c.textPrimary,
              fontSize: widget.compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Pulsing red dot + letterspaced LIVE label, shown instead of zeros.
  Widget _liveBadge(BuildContext context,
      {String label = 'LIVE • MAIN CARD IN PROGRESS'}) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _pulse.drive(
              Tween<double>(begin: 0.35, end: 1)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: Container(
              width: widget.compact ? 8 : 10,
              height: widget.compact ? 8 : 10,
              decoration: BoxDecoration(
                color: c.brand,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.brand.withValues(alpha: 0.8),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.hGapSm,
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: widget.compact ? Colors.white : c.textPrimary,
              fontSize: widget.compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Hero variant: white digits with red labels and hairline dividers.
  Widget _compactRow(BuildContext context) {
    final c = context.colors;
    final left = _left;

    Widget cell(int value, String label) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value'.padLeft(2, '0'),
              style: context.text.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: context.text.labelSmall?.copyWith(
                color: c.brand,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        );

    Widget divider() => Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          color: Colors.white24,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        cell(left.inDays, 'DAYS'),
        divider(),
        cell(left.inHours % 24, 'HRS'),
        divider(),
        cell(left.inMinutes % 60, 'MIN'),
        divider(),
        cell(left.inSeconds % 60, 'SEC'),
      ],
    );
  }

  /// Card variant: large digits spread across the full width.
  Widget _cardRow(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final left = _left;

    Widget cell(int value, String label) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value'.padLeft(2, '0'),
                style: t.headlineMedium?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              AppSpacing.vGapXs,
              Text(
                label,
                style: t.labelSmall?.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );

    return Row(
      children: [
        cell(left.inDays, 'DAYS'),
        cell(left.inHours % 24, 'HRS'),
        cell(left.inMinutes % 60, 'MIN'),
        cell(left.inSeconds % 60, 'SEC'),
      ],
    );
  }

  Widget _dateLine(BuildContext context) {
    final c = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: widget.event.date.mediumDate),
          TextSpan(
            text: ' • ',
            style: TextStyle(color: c.brand),
          ),
          TextSpan(text: widget.event.date.timeLabel),
        ],
      ),
      style: context.text.bodyMedium?.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
