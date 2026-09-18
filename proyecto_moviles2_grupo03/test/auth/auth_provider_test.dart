import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:proyecto_moviles2_grupo03/providers/auth_provider.dart';
import 'package:proyecto_moviles2_grupo03/services/auth_service.dart';
import 'package:proyecto_moviles2_grupo03/services/token_storage.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late InMemoryTokenStorage tokenStorage;
  late AuthProvider authProvider;

  setUp(() {
    mockAuthService = MockAuthService();
    tokenStorage = InMemoryTokenStorage();
    authProvider = AuthProvider(mockAuthService, tokenStorage);
  });

  group('AuthProvider Tests', () {
    test('(a) Estado inicial: sin sesión', () async {
      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.token, isNull);
      expect(await tokenStorage.readToken(), isNull);
      verifyNever(() => mockAuthService.signIn(any(), any()));
    });

    test('(b) Autenticación exitosa', () async {
      when(() => mockAuthService.signIn('test@test.com', '123456'))
          .thenAnswer((_) async => 'fake_token');

      await authProvider.login('test@test.com', '123456');

      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.token, 'fake_token');
      expect(await tokenStorage.readToken(), 'fake_token');
    });

    test('(c) Autenticación rechazada', () async {
      when(() => mockAuthService.signIn('test@test.com', 'wrong'))
          .thenThrow(AuthFailure('Credenciales incorrectas'));

      await authProvider.login('test@test.com', 'wrong');

      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.errorMessage, 'Credenciales incorrectas');
      expect(authProvider.token, isNull);
      expect(await tokenStorage.readToken(), isNull);
      verify(() => mockAuthService.signIn('test@test.com', 'wrong')).called(1);
    });
  });
}
