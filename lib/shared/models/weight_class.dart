/// Standard MMA weight divisions.
enum WeightClass {
  flyweight('Flyweight', 125, 'FLW'),
  bantamweight('Bantamweight', 135, 'BW'),
  featherweight('Featherweight', 145, 'FW'),
  lightweight('Lightweight', 155, 'LW'),
  welterweight('Welterweight', 170, 'WW'),
  middleweight('Middleweight', 185, 'MW'),
  lightHeavyweight('Light Heavyweight', 205, 'LHW'),
  heavyweight('Heavyweight', 265, 'HW'),
  womenStrawweight("Women's Strawweight", 115, 'WSW'),
  womenFlyweight("Women's Flyweight", 125, 'WFW'),
  womenBantamweight("Women's Bantamweight", 135, 'WBW');

  const WeightClass(this.label, this.limitLbs, this.abbr);

  final String label;
  final int limitLbs;
  final String abbr;

  bool get isWomens => name.startsWith('women');

  static WeightClass fromName(String value) => WeightClass.values.firstWhere(
        (w) => w.name == value,
        orElse: () => WeightClass.lightweight,
      );
}
