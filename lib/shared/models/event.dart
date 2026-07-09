import 'package:freezed_annotation/freezed_annotation.dart';

import 'bout.dart';

part 'event.freezed.dart';
part 'event.g.dart';

enum EventStatus { upcoming, live, past }

@freezed
abstract class Event with _$Event {
  const Event._();

  const factory Event({
    required String id,
    required String name,
    @Default('') String subtitle, // e.g. "Jones vs Aspinall"
    required DateTime date,
    @Default('') String venue,
    @Default('') String location,
    @Default('') String posterUrl,

    /// Full-bleed cover/hero image (bundled asset path) for the home hero.
    @Default('') String heroImage,

    /// Headline label, e.g. "UFC Fight Night" or "UFC 328".
    @Default('') String eventType,

    @Default(EventStatus.upcoming) EventStatus status,
    @Default(<Bout>[]) List<Bout> mainCard,
    @Default(<Bout>[]) List<Bout> prelims,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Bout? get mainEvent =>
      mainCard.where((b) => b.isMainEvent).firstOrNull ?? mainCard.firstOrNull;

  int get totalBouts => mainCard.length + prelims.length;
}
