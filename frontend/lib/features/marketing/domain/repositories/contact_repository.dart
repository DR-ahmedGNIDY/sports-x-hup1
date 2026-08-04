/// Throws [AppException] (core/errors) on failure.
abstract class ContactRepository {
  Future<void> submit({required String name, required String email, required String message});
}
