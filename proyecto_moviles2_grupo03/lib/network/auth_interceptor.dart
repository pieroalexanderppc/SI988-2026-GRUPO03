import 'package:dio/dio.dart';
import '../services/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final void Function() onUnauthorized;

  AuthInterceptor(this._tokenStorage, {required this.onUnauthorized});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si la petición tenía Authorization y devolvió 401
    if (err.response?.statusCode == 401 && err.requestOptions.headers.containsKey('Authorization')) {
      // 1. Limpiar token
      await _tokenStorage.clear();
      // 2. Invocar callback de desautorización
      onUnauthorized();
      
      // 3. Marcar para no reintentar y propagar error original
      err.requestOptions.extra['noRetry'] = true;
    }
    return super.onError(err, handler);
  }
}
