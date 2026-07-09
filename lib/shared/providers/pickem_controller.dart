import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../models/pick_card.dart';

/// Pick'Em cards keyed by event id, persisted as one JSON blob.
final pickemProvider =
    NotifierProvider<PickemController, Map<String, PickCard>>(
  PickemController.new,
);

class PickemController extends Notifier<Map<String, PickCard>> {
  @override
  Map<String, PickCard> build() {
    final raw = ref.read(storageServiceProvider).pickemData;
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          e.key: PickCard.fromJson(e.value as Map<String, dynamic>),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> _persist() async {
    final blob = jsonEncode({
      for (final e in state.entries) e.key: e.value.toJson(),
    });
    await ref.read(storageServiceProvider).setPickemData(blob);
  }

  PickCard cardFor(String eventId) =>
      state[eventId] ?? PickCard(eventId: eventId);

  Future<void> setPick(String eventId, int boutIndex, FightPick pick) async {
    final card = cardFor(eventId);
    state = {
      ...state,
      eventId: card.copyWith(picks: {...card.picks, boutIndex: pick}),
    };
    await _persist();
  }

  Future<void> setAnySubmission(String eventId, bool value) async {
    final card = cardFor(eventId);
    state = {...state, eventId: card.copyWith(anySubmission: value)};
    await _persist();
  }

  Future<void> submit(String eventId) async {
    final card = cardFor(eventId);
    state = {...state, eventId: card.copyWith(submitted: true)};
    await _persist();
  }
}
