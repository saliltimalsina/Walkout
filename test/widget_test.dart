import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkout/core/theme/app_theme.dart';
import 'package:walkout/shared/widgets/rank_badge.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('RankBadge', () {
    testWidgets('shows "C" for champions', (tester) async {
      await tester.pumpWidget(_wrap(const RankBadge(isChampion: true)));
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('shows "#n" for ranked fighters', (tester) async {
      await tester.pumpWidget(_wrap(const RankBadge(position: 3)));
      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('shows "NR" when unranked', (tester) async {
      await tester.pumpWidget(_wrap(const RankBadge()));
      expect(find.text('NR'), findsOneWidget);
    });
  });
}
