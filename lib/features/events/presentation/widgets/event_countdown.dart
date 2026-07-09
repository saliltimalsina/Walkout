import 'dart:async';

import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';

import 'aura_card.dart';

/// Live-aware DAYS / HRS / MIN / SEC countdown shared by the featured hero
/// ([compact]) and the event detail card.
///
/// Ticks once a second while the event is upcoming. Once `DateTime.now()`
/// reaches [Event.date] — or the event is flagged [EventStatus.live] — the
/// digits are replaced by a pulsing red LIVE badge instead of freezing at
/// zeros.
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

  bool get _isLive =>
      widget.event.status == EventStatus.live ||
      !DateTime.now().isBefore(widget.event.date);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _syncMode();
  }

  /// Ticks every second while counting down; hands over to the repeating
  /// pulse the moment the clock crosses zero (or the event goes live).
  void _syncMode() {
    if (_isLive) {
      _timer?.cancel();
      _timer = null;
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
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
    if (widget.compact) {
      return _isLive ? _liveBadge(context) : _compactRow(context);
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
            if (_isLive) _liveBadge(context) else _cardRow(context),
            AppSpacing.vGapMd,
            _dateLine(context),
          ],
        ),
      ),
    );
  }

  /// Pulsing red dot + letterspaced LIVE label, shown instead of zeros.
  Widget _liveBadge(BuildContext context) {
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
            'LIVE • MAIN CARD IN PROGRESS',
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
