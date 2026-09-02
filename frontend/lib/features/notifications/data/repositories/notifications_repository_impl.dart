import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../domain/entities/notifications_page.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';
import '../models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote, this._storage, this._ref);

  final NotificationsRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) =>
      runAuthorized(_ref, _storage, call);

  @override
  Future<NotificationsPage> list({int page = 1, bool unreadOnly = false}) =>
      _authorized((token) async {
        return NotificationsPageModel.fromJson(
          await _remote.list(token, page: page, unreadOnly: unreadOnly),
        );
      });

  @override
  Future<int> unreadCount() => _authorized((token) async {
    final json = await _remote.summary(token);
    return json['unread'] as int? ?? 0;
  });

  @override
  Future<void> markRead(String id) =>
      _authorized((token) => _remote.markRead(token, id));

  @override
  Future<int> markAllRead() => _authorized((token) async {
    final json = await _remote.markAllRead(token);
    return json['marked'] as int? ?? 0;
  });
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
