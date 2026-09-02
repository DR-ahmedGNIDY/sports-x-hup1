import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../domain/entities/invitation.dart';
import '../../domain/entities/invitations_page.dart';
import '../../domain/entities/invitations_summary.dart';
import '../../domain/repositories/invitations_repository.dart';
import '../datasources/invitations_remote_data_source.dart';
import '../models/invitation_model.dart';

class InvitationsRepositoryImpl implements InvitationsRepository {
  InvitationsRepositoryImpl(this._remote, this._storage, this._ref);

  final InvitationsRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) =>
      runAuthorized(_ref, _storage, call);

  @override
  Future<Invitation> invitePlayer({
    String? playerId,
    String? playerCode,
    String? message,
  }) => _authorized((token) async {
    final json = await _remote.invitePlayer(
      token,
      playerId: playerId,
      playerCode: playerCode,
      message: message,
    );
    return InvitationModel.fromJson(json);
  });

  @override
  Future<Invitation> requestToJoinClub({
    String? clubId,
    String? clubCode,
    String? message,
  }) => _authorized((token) async {
    final json = await _remote.requestToJoinClub(
      token,
      clubId: clubId,
      clubCode: clubCode,
      message: message,
    );
    return InvitationModel.fromJson(json);
  });

  @override
  Future<InvitationsPage> listReceived({
    int page = 1,
    InvitationStatus? status,
  }) => _authorized((token) async {
    final json = await _remote.listReceived(
      token,
      page: page,
      status: status?.wireValue,
    );
    return InvitationsPageModel.fromJson(json);
  });

  @override
  Future<InvitationsPage> listSent({
    int page = 1,
    InvitationStatus? status,
  }) => _authorized((token) async {
    final json = await _remote.listSent(
      token,
      page: page,
      status: status?.wireValue,
    );
    return InvitationsPageModel.fromJson(json);
  });

  @override
  Future<InvitationsSummary> getSummary() => _authorized((token) async {
    return InvitationsSummaryModel.fromJson(await _remote.getSummary(token));
  });

  @override
  Future<Invitation> accept(String id) => _authorized((token) async {
    return InvitationModel.fromJson(await _remote.accept(token, id));
  });

  @override
  Future<Invitation> reject(String id) => _authorized((token) async {
    return InvitationModel.fromJson(await _remote.reject(token, id));
  });

  @override
  Future<Invitation> cancel(String id) => _authorized((token) async {
    return InvitationModel.fromJson(await _remote.cancel(token, id));
  });
}

final invitationsRepositoryProvider = Provider<InvitationsRepository>(
  (ref) => InvitationsRepositoryImpl(
    ref.watch(invitationsRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
