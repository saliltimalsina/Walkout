import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkout/features/home_widgets/application/living_state.dart';
import 'package:walkout/features/home_widgets/face_registry.dart';
import 'package:walkout/features/home_widgets/faces/living_face.dart';
import 'package:walkout/shared/data/app_dataset.dart';
import 'package:walkout/shared/models/models.dart';

/// Renders every widget face to a PNG in test/_faces so the design can be
/// reviewed and iterated without the device. Uses the real bundled dataset
/// (real fighters + portraits).
void main() {
  late AppDataset data;

  setUpAll(() async {
    final b = TestWidgetsFlutterBinding.ensureInitialized();
    b.window.physicalSizeTestValue = const Size(2000, 2000);
    b.window.devicePixelRatioTestValue = 1.0;
    for (final family in const ['Anton', 'Inter']) {
      final loader = FontLoader(family)
        ..addFont(File(
          family == 'Anton'
              ? 'assets/fonts/Anton-Regular.ttf'
              : 'assets/fonts/Inter-Variable.ttf',
        ).readAsBytes().then((x) => ByteData.view(x.buffer)));
      await loader.load();
    }
    data = await AppDataset.load();
  });

  Future<void> warm(Iterable<String?> paths) async {
    for (final p in paths) {
      if (p == null || p.isEmpty) continue;
      final c = Completer<void>();
      final s = AssetImage(p).resolve(ImageConfiguration.empty);
      late final ImageStreamListener l;
      l = ImageStreamListener((_, __) {
        if (!c.isCompleted) c.complete();
        s.removeListener(l);
      }, onError: (_, __) {
        if (!c.isCompleted) c.complete();
        s.removeListener(l);
      });
      s.addListener(l);
      await c.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    }
  }

  Future<void> capture(String name, Widget child, Size size) async {
    final boundary = RenderRepaintBoundary();
    final owner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
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
        child: SizedBox.fromSize(size: size, child: child),
      ),
    ).attachToRenderTree(buildOwner);
    for (var i = 0; i < 6; i++) {
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
    File('test/_faces/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  test('render all widget faces', () async {
    final byId = data.fighterById;
    // A booked event featuring two roster fighters with portraits.
    final booked = data.events.firstWhere(
      (e) =>
          e.status != EventStatus.past &&
          e.mainEvent != null &&
          byId[e.mainEvent!.redCornerId]?.imageUrl.isNotEmpty == true &&
          byId[e.mainEvent!.blueCornerId]?.imageUrl.isNotEmpty == true,
    );
    final bout = booked.mainEvent!;
    final red = byId[bout.redCornerId]!;
    final blue = byId[bout.blueCornerId]!;
    final champ = data.fighters.firstWhere(
        (f) => f.isChampion && f.imageUrl.isNotEmpty,
        orElse: () => red);

    await warm([red.imageUrl, blue.imageUrl, champ.imageUrl]);

    const size = Size(329, 158);
    final wkNow = booked.date.subtract(const Duration(days: 4));

    await capture(
        'living_corner',
        LivingFace(
          snapshot: LivingSnapshot(
              state: LivingState.corner, fighter: champ, event: booked),
          now: DateTime(2026),
        ),
        size);
    await capture(
        'living_booked',
        LivingFace(
          snapshot: LivingSnapshot(
              state: LivingState.booked,
              fighter: red,
              opponent: blue,
              event: booked),
          now: DateTime(2026),
        ),
        size);
    await capture(
        'living_fightweek',
        LivingFace(
          snapshot: LivingSnapshot(
              state: LivingState.fightWeek,
              fighter: red,
              opponent: blue,
              event: booked,
              phase: FightWeekPhase.openWorkouts),
          now: wkNow,
        ),
        size);
    await capture(
        'living_fightnight',
        LivingFace(
          snapshot: LivingSnapshot(
              state: LivingState.fightNight,
              fighter: red,
              opponent: blue,
              event: booked,
              phase: FightWeekPhase.mainCard),
          now: booked.date,
        ),
        size);
    await capture(
        'living_result',
        LivingFace(
          snapshot: LivingSnapshot(
            state: LivingState.result,
            fighter: red,
            opponent: blue,
            event: booked,
            bout: bout.copyWith(
                winnerId: red.id, method: 'Submission', finishRound: 'R3'),
            won: true,
          ),
          now: booked.date.add(const Duration(hours: 8)),
        ),
        size);
    await capture(
        'living_aftermath',
        LivingFace(
          snapshot: LivingSnapshot(
              state: LivingState.aftermath,
              fighter: red,
              opponent: blue,
              event: booked,
              won: true),
          now: booked.date.add(const Duration(hours: 36)),
        ),
        size);
    // The full concept board, resolved like production (red corner favorited
    // so the personal faces show a real subject).
    final specs = FaceRegistry.build(
      dataset: data,
      favorites: {red.id},
      now: DateTime(2026, 7, 9),
    );
    for (final spec in specs) {
      await warm(spec.assets);
      await capture(spec.key, spec.face, spec.size);
    }

    expect(
        Directory('test/_faces').listSync().length, greaterThanOrEqualTo(20));
  });
}
