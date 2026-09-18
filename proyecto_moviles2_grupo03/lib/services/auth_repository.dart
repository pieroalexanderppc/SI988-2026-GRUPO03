abstract class AuthRepository {
  Future<String> login(String correo, String password);

  Future<String> registrar(String correo, String password);
}