import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Renders an arbitrary widget to a PNG file offscreen, reliably.
///
/// `home_widget`'s built-in `renderFlutterWidget` captures the repaint
/// boundary after a single flush and trips `!debugNeedsPaint` on trees with
/// images/gradients. This runs a self-contained render pipeline and pumps
/// until layout+paint are actually clean before `toImage`, so it works for
/// arbitrarily complex faces.
class WidgetCapture {
  const WidgetCapture._();

  /// Renders [child] at [logicalSize] × [pixelRatio] and writes a PNG to the
  /// app documents dir as `$key.png`. Returns the absolute file path.
  static Future<String> toPngFile({
    required Widget child,
    required String key,
    required Size logicalSize,
    double pixelRatio = 3.0,
  }) async {
    final repaintBoundary = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    final renderView = RenderView(
      view: ui.PlatformDispatcher.instance.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints:
            BoxConstraints.tight(logicalSize),
        physicalConstraints:
            BoxConstraints.tight(logicalSize * pixelRatio),
        devicePixelRatio: pixelRatio,
      ),
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.fromSize(size: logicalSize, child: child),
      ),
    ).attachToRenderTree(buildOwner);

    // Pump until the tree settles (images/gradients marked clean).
    for (var i = 0; i < 8; i++) {
      buildOwner
        ..buildScope(rootElement)
        ..finalizeTree();
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
      if (!repaintBoundary.debugNeedsPaint) break;
      // Give async image decodes a beat to land in the cache.
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('widget capture produced no bytes');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$key.png');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  }
}
