import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_x_hub/core/storage/session_storage.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSecureStorage secureStorage;
  late SessionStorage sessionStorage;

  setUp(() {
    secureStorage = _MockSecureStorage();
    sessionStorage = SessionStorage(secureStorage);
  });

  test('saveTokens writes both tokens to secure storage', () async {
    when(
      () => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')),
    ).thenAnswer((_) async {});

    await sessionStorage.saveTokens(
      accessToken: 'access-123',
      refreshToken: 'refresh-456',
    );

    verify(
      () => secureStorage.write(key: 'sxh_access_token', value: 'access-123'),
    ).called(1);
    verify(
      () => secureStorage.write(key: 'sxh_refresh_token', value: 'refresh-456'),
    ).called(1);
  });

  test('accessToken/refreshToken read from secure storage', () async {
    when(() => secureStorage.read(key: 'sxh_access_token'))
        .thenAnswer((_) async => 'stored-access');
    when(() => secureStorage.read(key: 'sxh_refresh_token'))
        .thenAnswer((_) async => 'stored-refresh');

    expect(await sessionStorage.accessToken, 'stored-access');
    expect(await sessionStorage.refreshToken, 'stored-refresh');
  });

  test('clear deletes both tokens from secure storage', () async {
    when(() => secureStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    await sessionStorage.clear();

    verify(() => secureStorage.delete(key: 'sxh_access_token')).called(1);
    verify(() => secureStorage.delete(key: 'sxh_refresh_token')).called(1);
  });

  group('migrateFromSharedPreferences', () {
    test('moves legacy plaintext tokens into secure storage and removes them', () async {
      SharedPreferences.setMockInitialValues({
        'sxh_access_token': 'legacy-access',
        'sxh_refresh_token': 'legacy-refresh',
      });
      final prefs = await SharedPreferences.getInstance();
      when(
        () => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      await sessionStorage.migrateFromSharedPreferences(prefs);

      verify(
        () => secureStorage.write(key: 'sxh_access_token', value: 'legacy-access'),
      ).called(1);
      verify(
        () => secureStorage.write(key: 'sxh_refresh_token', value: 'legacy-refresh'),
      ).called(1);
      expect(prefs.getString('sxh_access_token'), isNull);
      expect(prefs.getString('sxh_refresh_token'), isNull);
    });

    test('is a no-op when no legacy tokens are present', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await sessionStorage.migrateFromSharedPreferences(prefs);

      verifyNever(
        () => secureStorage.write(key: any(named: 'key'), value: any(named: 'value')),
      );
    });
  });
}
