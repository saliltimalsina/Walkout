import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import 'mock_data.dart';

/// Read access to in-app notifications. Keeps a mutable in-memory copy so the
/// "mark as read" action reflects immediately during a session.
class NotificationRepository {
  NotificationRepository() : _items = [...MockData.notifications];

  final List<NotificationItem> _items;

  Future<List<NotificationItem>> getAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }

  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
  }

  Future<void> markRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(read: true);
    }
  }

  int get unreadCount => _items.where((n) => !n.read).length;
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository());
