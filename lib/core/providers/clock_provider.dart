import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A shared coarse clock for time-derived UI (LIVE pills, "Xd away" labels).
/// Ticks every 30s so visible widgets re-derive state without each owning a
/// timer; precision UI (the 1s countdown) keeps its own timer.
final clockProvider = StreamProvider<DateTime>(
  (ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 30),
    (_) => DateTime.now(),
  ),
);
