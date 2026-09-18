import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:proyecto_moviles2_grupo03/providers/auth_provider.dart';
import 'package:proyecto_moviles2_grupo03/services/auth_service.dart';
import 'package:proyecto_moviles2_grupo03/services/token_storage.dart';
import 'package:proyecto_moviles2_grupo03/network/auth_interceptor.dart';
import 'dart:convert';
import 'dart:typed_data';

class MockAuthService extends Mock implements AuthService {}

// Fake adapter para Dio
class FakeHttpClientAdapter implements HttpClientAdapter {
  int requestCount = 0;
  
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requestCount++;
    return ResponseBody.fromString(
      jsonEncode({'error': 'Unauthorized'}),
      401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('Lockout and 401 Tests', () {
    test('(a) Bloqueo tras 3 intentos', () async {
      final mockAuthService = MockAuthService();
      final tokenStorage = InMemoryTokenStorage();
      
      // Controlar el tiempo
      DateTime currentTime = DateTime(2023, 1, 1, 10, 0, 0);
      final authProvider = AuthProvider(
        mockAuthService, 
        tokenStorage,
        now: () => currentTime,
      );

      when(() => mockAuthService.signIn(any(), any()))
          .thenThrow(AuthFailure('Error'));

      // 3 intentos fallidos
      await authProvider.login('test@test.com', 'wrong');
      await authProvider.login('test@test.com', 'wrong');
      await authProvider.login('test@test.com', 'wrong');

      expect(authProvider.status, AuthStatus.locked);
      expect(authProvider.errorMessage, isNotEmpty);

      clearInteractions(mockAuthService);

      // Intento 4 (bloqueado)
      await authProvider.login('test@test.com', 'wrong');

      // Comprobar que no se llamó al servicio
      verifyNever(() => mockAuthService.signIn(any(), any()));
      expect(authProvider.status, AuthStatus.locked);
    });

    test('(b) HTTP 401 interceptor', () async {
      final tokenStorage = InMemoryTokenStorage();
      await tokenStorage.writeToken('valid_token');

      bool unauthorizedCalled = false;
      final interceptor = AuthInterceptor(
        tokenStorage,
        onUnauthorized: () {
          unauthorizedCalled = true;
        },
      );

      final dio = Dio();
      final fakeAdapter = FakeHttpClientAdapter();
      dio.httpClientAdapter = fakeAdapter;
      dio.interceptors.add(interceptor);

      try {
        await dio.get('https://api.test.com/data');
        fail('Should have thrown DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
      }

      // Verificaciones
      expect(await tokenStorage.readToken(), isNull);
      expect(unauthorizedCalled, isTrue);
      expect(fakeAdapter.requestCount, 1); // Exactamente 1, sin reintentos
    });
  });
}
