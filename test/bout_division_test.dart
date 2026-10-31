import 'package:flutter_test/flutter_test.dart';
import 'package:walkout/shared/models/bout.dart';
import 'package:walkout/shared/models/weight_class.dart';

void main() {
  test('division strips scraped suffixes', () {
    const cases = {
      'Lightweight Bout': 'Lightweight',
      "Women's Strawweight Title": "Women's Strawweight",
      'Heavyweight Interim Title Bout Pres. by CRYPTO.COM': 'Heavyweight',
      'Middleweight': 'Middleweight',
    };
    cases.forEach((raw, want) {
      expect(Bout(id: 'x', weightLabel: raw).division, want);
    });
  });

  test('division falls back to the weight class', () {
    const b = Bout(id: 'x', weightClass: WeightClass.flyweight);
    expect(b.division, WeightClass.flyweight.label);
  });
}
