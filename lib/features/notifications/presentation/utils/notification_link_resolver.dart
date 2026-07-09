import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/shared/models/models.dart';

/// Where a notification should deep-link when tapped.
///
/// [NotificationItem] carries no target id (and the freezed model can't be
/// regenerated), so this is resolved best-effort by matching the notification
/// text against known fighter and event names.
class NotificationLink {
  const NotificationLink._({required this.routePath, this.fighter});

  NotificationLink.toFighter(Fighter fighter)
      : this._(routePath: AppRoutes.fighterPath(fighter.id), fighter: fighter);

  NotificationLink.toEvent(Event event)
      : this._(routePath: AppRoutes.eventPath(event.id));

  /// Route to push when the tile is tapped.
  final String routePath;

  /// Set when the link targets a fighter, so the tile can show their portrait.
  final Fighter? fighter;
}

/// Best-effort deep-link resolution for [item].
///
/// Scans the title + body for fighter names (full name, falling back to the
/// last name as a whole word) and event names/subtitles. When several
/// candidates match, the one mentioned earliest wins — the headline subject
/// is written first. Event-type notifications prefer an event match so
/// "UFC 312: Makhachev vs Oliveira 2" links to the card, not a fighter.
NotificationLink? resolveNotificationLink(
  NotificationItem item, {
  required List<Fighter> fighters,
  required List<Event> events,
}) {
  final text = '${item.title} ${item.body}'.toLowerCase();

  final fighter = _earliestFighterMatch(text, fighters);
  final event = _earliestEventMatch(text, events);

  if (item.type == NotificationType.event && event != null) {
    return NotificationLink.toEvent(event);
  }
  if (fighter != null) return NotificationLink.toFighter(fighter);
  if (event != null) return NotificationLink.toEvent(event);
  return null;
}

Fighter? _earliestFighterMatch(String text, List<Fighter> fighters) {
  Fighter? best;
  var bestIndex = -1;

  for (final fighter in fighters) {
    final name = fighter.name.toLowerCase().trim();
    if (name.isEmpty) continue;

    var index = text.indexOf(name);
    if (index < 0) {
      // Headlines often use just the surname ("Aspinall retains").
      final lastName = name.split(RegExp(r'\s+')).last;
      if (lastName.length >= 4) {
        index = RegExp('\\b${RegExp.escape(lastName)}\\b')
                .firstMatch(text)
                ?.start ??
            -1;
      }
    }

    if (index >= 0 && (bestIndex == -1 || index < bestIndex)) {
      best = fighter;
      bestIndex = index;
    }
  }
  return best;
}

Event? _earliestEventMatch(String text, List<Event> events) {
  Event? best;
  var bestIndex = -1;

  for (final event in events) {
    for (final candidate in [event.name, event.subtitle]) {
      final needle = candidate.toLowerCase().trim();
      if (needle.isEmpty) continue;
      final index = text.indexOf(needle);
      if (index >= 0 && (bestIndex == -1 || index < bestIndex)) {
        best = event;
        bestIndex = index;
      }
    }
  }
  return best;
}
