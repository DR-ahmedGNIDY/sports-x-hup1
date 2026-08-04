import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/repositories/contact_repository_impl.dart';

class ContactFormState {
  const ContactFormState({this.submitting = false, this.success = false, this.errorMessage});

  final bool submitting;
  final bool success;
  final String? errorMessage;

  ContactFormState copyWith({bool? submitting, bool? success, String? errorMessage}) =>
      ContactFormState(
        submitting: submitting ?? this.submitting,
        success: success ?? false,
        errorMessage: errorMessage,
      );
}

class ContactController extends Notifier<ContactFormState> {
  @override
  ContactFormState build() => const ContactFormState();

  Future<void> submit({required String name, required String email, required String message}) async {
    state = state.copyWith(submitting: true);
    try {
      await ref.read(contactRepositoryProvider).submit(name: name, email: email, message: message);
      state = const ContactFormState(success: true);
    } on AppException catch (e) {
      state = ContactFormState(errorMessage: e.message);
    }
  }
}

final contactControllerProvider = NotifierProvider<ContactController, ContactFormState>(
  ContactController.new,
);
