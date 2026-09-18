import 'package:dio/dio.dart';
import 'auth_interceptor.dart';
import '../services/token_storage.dart';

class ApiClient {
  final Dio dio;

  ApiClient(TokenStorage tokenStorage, {required void Function() onUnauthorized}) 
      : dio = Dio() {
    dio.interceptors.add(
      AuthInterceptor(tokenStorage, onUnauthorized: onUnauthorized),
    );
  }

  // Ejemplo de endpoint de Firestore REST para forzar el 401
  Future<void> simulate401Request() async {
    // Si se pasa un token inválido, Firebase retornará 401
    await dio.get(
      'https://firestore.googleapis.com/v1/projects/proyecto-fake/databases/(default)/documents/test',
      options: Options(headers: {'Authorization': 'Bearer INVALID_TOKEN'}),
    );
  }
}
