/// Display metadata for the widget gallery, keyed by [FaceSpec.key]. Names
/// mirror the Android manifest `android:label`s so the in-app gallery matches
/// the launcher widget picker exactly.
library;

enum GalleryCategory {
  fighter('Fighter'),
  events('Event Day'),
  feeds('Feeds');

  const GalleryCategory(this.label);
  final String label;
}

typedef GalleryEntry = ({String name, String blurb, GalleryCategory category});

abstract final class GalleryCatalog {
  const GalleryCatalog._();

  /// The Living Widget — the hero, handled outside the face registry.
  static const livingName = 'The Living Widget';
  static const livingBlurb =
      'One widget that transforms with the calendar — quiet corner presence, '
      'fight-week countdown, weigh-ins, fight night, then the result.';

  static const entries = <String, GalleryEntry>{
    'fight_clock': (
      name: 'Fight Clock',
      blurb: 'Countdown poster to the next main event.',
      category: GalleryCategory.events,
    ),
    'corner': (
      name: 'Your Corner',
      blurb: 'The fighters you follow, at a glance.',
      category: GalleryCategory.fighter,
    ),
    'octagon_count': (
      name: 'Octagon Countdown',
      blurb: 'Days until the next card, ringed in the octagon.',
      category: GalleryCategory.events,
    ),
    'faceoff': (
      name: 'Face-Off',
      blurb: 'The next big matchup, head to head.',
      category: GalleryCategory.fighter,
    ),
    'last5': (
      name: 'Last 5 Fights',
      blurb: 'Recent form — wins and losses on one strip.',
      category: GalleryCategory.fighter,
    ),
    'tape': (
      name: 'Tale of the Tape',
      blurb: 'Side-by-side stats for the next matchup.',
      category: GalleryCategory.fighter,
    ),
    'belts': (
      name: 'Belt Collection',
      blurb: 'A champion and their hardware.',
      category: GalleryCategory.fighter,
    ),
    'momentum': (
      name: 'Fight Momentum',
      blurb: 'Win streaks, tracked live.',
      category: GalleryCategory.fighter,
    ),
    'ladder': (
      name: 'Division Ladder',
      blurb: 'Champion and top contenders of a division.',
      category: GalleryCategory.feeds,
    ),
    'ticket': (
      name: 'Walkout Card',
      blurb: 'Your ticket stub for the next event.',
      category: GalleryCategory.events,
    ),
    'hype': (
      name: 'Hype Pulse',
      blurb: 'The buzz building toward fight night.',
      category: GalleryCategory.events,
    ),
    'finish_dna': (
      name: 'Finish DNA',
      blurb: 'How a fighter wins — KO, sub or decision.',
      category: GalleryCategory.fighter,
    ),
    'radar': (
      name: 'Octagon Radar',
      blurb: 'A fighter\'s skill profile on the radar.',
      category: GalleryCategory.fighter,
    ),
    'journey': (
      name: 'Career Journey',
      blurb: 'A career arc, fight by fight.',
      category: GalleryCategory.fighter,
    ),
    'prediction': (
      name: 'Prediction',
      blurb: 'Your Pick\'Em call on the next main event.',
      category: GalleryCategory.events,
    ),
    'news': (
      name: 'Latest News',
      blurb: 'Top stories, straight to your home screen.',
      category: GalleryCategory.feeds,
    ),
    'upcoming': (
      name: 'Upcoming Events',
      blurb: 'The next cards, soonest first.',
      category: GalleryCategory.events,
    ),
    'fightweek': (
      name: 'Fight Week',
      blurb: 'Weigh-ins, prelims and main card times.',
      category: GalleryCategory.events,
    ),
    'slate': (
      name: 'Weekend Slate',
      blurb: 'The full fight-week itinerary, poster style — press conference '
          'to main card.',
      category: GalleryCategory.events,
    ),
  };

  static GalleryEntry entryFor(String key) =>
      entries[key] ??
      (
        name: key,
        blurb: '',
        category: GalleryCategory.events,
      );
}
