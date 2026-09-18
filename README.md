# PROYECTO-G03-SOLUCIONESMOVILES-II

## Examen Práctico U1 – Tipo 1

**Rama utilizada**: `exam/u1-tipo1-login-seguro`

### Lista de cambios por ítem:

* **Fase 1 (Pre-requisitos)**: Se creó una estructura base de autenticación con un login mínimo, ya que el proyecto no contaba con esta funcionalidad.
  * *Nuevos*: 
    * `proyecto_moviles2_grupo03/lib/services/auth_service.dart`
    * `proyecto_moviles2_grupo03/lib/services/token_storage.dart`
    * `proyecto_moviles2_grupo03/lib/network/api_client.dart`
  * *Modificado*:
    * `proyecto_moviles2_grupo03/pubspec.yaml`
    * `proyecto_moviles2_grupo03/lib/main.dart`

* **Ítem 1 (Validación de formulario y feedback en UI)**: Creación de validadores puros para el formulario de login. Deshabilitado reactivo del botón.
  * *Nuevos*: 
    * `proyecto_moviles2_grupo03/lib/utils/validators.dart`
    * `proyecto_moviles2_grupo03/lib/screens/login_screen.dart`

* **Ítem 2 (Bloqueo por intentos)**: Lógica de estado y bloqueo (lockout) temporal por fallos, administrada dentro del provider de autenticación.
  * *Nuevo*: 
    * `proyecto_moviles2_grupo03/lib/providers/auth_provider.dart`

* **Ítem 3 (Cierre de sesión ante HTTP 401)**: Interceptor global de Dio para limpiar la sesión en caso de respuesta 401 del backend, y botón para forzar error.
  * *Nuevo*:
    * `proyecto_moviles2_grupo03/lib/network/auth_interceptor.dart`

* **Ítem 4 (Pruebas unitarias del login)**: Cobertura del estado inicial, éxito y rechazo del Provider, usando Mocktail.
  * *Nuevo*: 
    * `proyecto_moviles2_grupo03/test/auth/auth_provider_test.dart`

* **Ítem 5 (Pruebas unitarias focalizadas)**: Pruebas especializadas sobre el flujo de lockout y el interceptor de peticiones sin depender de Firebase.
  * *Nuevo*: 
    * `proyecto_moviles2_grupo03/test/auth/lockout_and_401_test.dart`

* **Ajustes de Integración**: Se actualizó el test inicial para ser compatible con la inyección de dependencias.
  * *Modificado*:
    * `proyecto_moviles2_grupo03/test/widget_test.dart`

### Comandos para correr los tests:
Ubicarse dentro de la carpeta `proyecto_moviles2_grupo03/` y ejecutar:

Para el Ítem 4 (Provider):
```bash
flutter test test/auth/auth_provider_test.dart --reporter expanded
```

Para el Ítem 5 (Lockout & 401):
```bash
flutter test test/auth/lockout_and_401_test.dart --reporter expanded
```

Para ejecutar toda la suite de pruebas del proyecto:
```bash
flutter test
```