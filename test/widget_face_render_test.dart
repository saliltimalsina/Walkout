import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkout/features/home_widgets/application/living_state.dart';
import 'package:walkout/features/home_widgets/faces/living_face.dart';
import 'package:walkout/shared/models/models.dart';

/// Renders each Living Widget state to a PNG in test/_faces so the design can
/// be reviewed without fighting the device / time-travel calibration.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final family in ['Anton', 'Inter']) {
      final loader = FontLoader(family);
      final path = family == 'Anton'
          ? 'assets/fonts/Anton-Regular.ttf'
          : 'assets/fonts/Inter-Variable.ttf';
      loader.addFont(File(path).readAsBytes().then(
            (b) => ByteData.view(b.buffer),
          ));
      await loader.load();
    }
  });

  Future<void> render(String name, LivingSnapshot snap, DateTime now) async {
    final boundary = RenderRepaintBoundary();
    final owner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    const size = Size(329, 158);
    final view = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(child: boundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size * 3),
        devicePixelRatio: 3,
      ),
    );
    owner.rootNode = view;
    view.prepareInitialFrame();
    final el = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.fromSize(
          size: size,
          child: LivingFace(snapshot: snap, now: now),
        ),
      ),
    ).attachToRenderTree(buildOwner);
    for (var i = 0; i < 5; i++) {
      buildOwner
        ..buildScope(el)
        ..finalizeTree();
      owner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
    }
    final img = await boundary.toImage(pixelRatio: 3);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('test/_faces').createSync(recursive: true);
    File('test/_faces/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  test('render living faces', () async {
    final now = DateTime(2026, 8, 12, 14); // 4 days before an Aug 16 card
    const wc = WeightClass.lightweight;
    const jones = Fighter(
      id: 'a', name: 'Islam Makhachev', weightClass: wc,
      record: FightRecord(wins: 26, losses: 1), isChampion: true,
    );
    const opp = Fighter(
      id: 'b', name: 'Ian Machado Garry', weightClass: wc,
      record: FightRecord(wins: 17, losses: 1), rankingPosition: 3,
    );
    final event = Event(
      id: 'e', name: 'UFC 330', eventType: 'UFC 330',
      subtitle: 'Makhachev vs Garry', date: DateTime(2026, 8, 16, 22),
      mainCard: const [
        Bout(id: 'x', redCornerId: 'a', blueCornerId: 'b',
            redName: 'Makhachev', blueName: 'Garry',
            weightClass: wc, isTitleFight: true),
      ],
    );

    await render(
      'fightweek',
      LivingSnapshot(
        state: LivingState.fightWeek,
        fighter: jones,
        opponent: opp,
        event: event,
        phase: FightWeekPhase.openWorkouts,
      ),
      now,
    );
    await render(
      'weighin',
      LivingSnapshot(
        state: LivingState.weighInDay,
        fighter: jones,
        opponent: opp,
        event: event,
        phase: FightWeekPhase.weighIns,
      ),
      DateTime(2026, 8, 15, 10),
    );
    expect(File('test/_faces/fightweek.png').existsSync(), isTrue);
  });
}
