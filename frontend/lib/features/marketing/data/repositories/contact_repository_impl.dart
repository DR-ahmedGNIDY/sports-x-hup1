import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/contact_repository.dart';
import '../datasources/contact_remote_data_source.dart';

class ContactRepositoryImpl implements ContactRepository {
  ContactRepositoryImpl(this._remote);

  final ContactRemoteDataSource _remote;

  @override
  Future<void> submit({required String name, required String email, required String message}) =>
      _remote.submit(name: name, email: email, message: message);
}

final contactRepositoryProvider = Provider<ContactRepository>(
  (ref) => ContactRepositoryImpl(ref.watch(contactRemoteDataSourceProvider)),
);
