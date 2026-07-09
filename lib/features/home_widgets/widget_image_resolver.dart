import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Resolves a face image reference — either a bundled asset path
/// (`assets/...`) or a remote CDN URL (`https://...`) — into an
/// [ImageProvider] that paints *synchronously* during the offscreen widget
/// capture. Remote images are downloaded once to a disk cache keyed by URL
/// hash (so a photo shared across faces is fetched a single time), then
/// served as [FileImage]. Anything that fails to download resolves to null so
/// callers fall back to the bundled asset — widgets can never break.
class WidgetImageResolver {
  const WidgetImageResolver._();

  static final Map<String, String> _urlToFile = {};

  static bool isRemote(String ref) => ref.startsWith('http');

  /// Downloads any remote refs to disk and warms every ref into the global
  /// image cache so the subsequent offscreen render paints without async gaps.
  static Future<void> warm(Iterable<String> refs) async {
    Directory? cacheDir;
    for (final ref in refs.toSet()) {
      if (ref.isEmpty) continue;
      if (!isRemote(ref)) {
        await _warm(AssetImage(ref));
        continue;
      }
      if (!_urlToFile.containsKey(ref)) {
        cacheDir ??= await _dir();
        final file = File('${cacheDir.path}/${_key(ref)}');
        if (!file.existsSync()) {
          final bytes = await _download(ref);
          if (bytes != null) {
            try {
              await file.writeAsBytes(bytes, flush: true);
            } catch (_) {}
          }
        }
        if (file.existsSync()) _urlToFile[ref] = file.path;
      }
      final path = _urlToFile[ref];
      if (path != null) await _warm(FileImage(File(path)));
    }
  }

  /// Non-null provider ready to paint, or null when a remote ref hasn't been
  /// cached (caller should fall back to a bundled asset / placeholder).
  static ImageProvider? provider(String ref) {
    if (ref.isEmpty) return null;
    if (!isRemote(ref)) return AssetImage(ref);
    final path = _urlToFile[ref];
    return path != null ? FileImage(File(path)) : null;
  }

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/wimg');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static String _key(String url) {
    final ext = url.contains('.')
        ? url.substring(url.lastIndexOf('.')).split(RegExp(r'[?#]')).first
        : '.img';
    return '${sha1.convert(url.codeUnits)}${ext.length <= 5 ? ext : '.img'}';
  }

  static Future<Uint8List?> _download(String url) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.userAgentHeader, 'WalkoutApp');
      final res = await req.close();
      if (res.statusCode != 200) {
        client.close();
        return null;
      }
      final builder = BytesBuilder();
      await for (final chunk in res) {
        builder.add(chunk);
      }
      client.close();
      return builder.takeBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _warm(ImageProvider provider) async {
    final completer = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, __) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (_, __) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await completer.future.timeout(const Duration(seconds: 3), onTimeout: () {});
  }
}
