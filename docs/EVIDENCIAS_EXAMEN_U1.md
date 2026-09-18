# Evidencias del Examen Práctico U1 - Tipo 1

### Ítem 1: Validación de formulario y feedback en UI
- **Archivo**: `proyecto_moviles2_grupo03/lib/screens/login_screen.dart` (Líneas 70-85, validadores y campos) y `proyecto_moviles2_grupo03/lib/utils/validators.dart`
- **Comando Ejecutado**: `flutter analyze`
- **Explicación Técnica**: Se implementó una clase estática `Validators` para delegar la validación y evitar código repetitivo en la UI. En el form se utilizó `AutovalidateMode.onUserInteraction` para proporcionar feedback automático tras la primera interacción, y el botón de enviar observa reactivamente el estado de validez de ambos campos para deshabilitarse e impedir sumisiones inválidas.

### Ítem 2: Bloqueo por intentos (Lockout)
- **Archivo**: `proyecto_moviles2_grupo03/lib/providers/auth_provider.dart` (Líneas 30-74, método `login`)
- **Comando Ejecutado**: `flutter test test/auth/lockout_and_401_test.dart`
- **Explicación Técnica**: Toda la lógica de negocio se centralizó en el `AuthProvider`. Ante cada `AuthFailure`, se incrementa un contador interno. Al llegar al límite, se establece una marca temporal (`lockedUntil`) que impide explícitamente realizar llamadas a `AuthService.signIn` devolviendo el flujo anticipadamente, previniendo abusos del servicio.

### Ítem 3: Cierre de sesión ante HTTP 401
- **Archivo**: `proyecto_moviles2_grupo03/lib/network/auth_interceptor.dart` (Líneas 19-30, método `onError`)
- **Comando Ejecutado**: `flutter test test/auth/lockout_and_401_test.dart`
- **Explicación Técnica**: El interceptor hereda de `Interceptor` (Dio) para inspeccionar respuestas fallidas globalmente. Cuando detecta un 401 y corrobora que la petición inicial estaba autenticada (usaba `Authorization`), ejecuta la limpieza de token a nivel de persistencia y gatilla el callback `onUnauthorized` que desacopla la UI de la capa de red, propagando la orden de deslogueo hasta el estado global.

### Ítem 4: Pruebas unitarias del login (Provider)
- **Archivo**: `proyecto_moviles2_grupo03/test/auth/auth_provider_test.dart`
- **Comando Ejecutado**: `flutter test test/auth/auth_provider_test.dart --reporter expanded`
- **Explicación Técnica**: Las pruebas validan los tres estados puros de autenticación en la ViewModel. Se inyectan dependencias fingidas (`MockAuthService` mediante mocktail e `InMemoryTokenStorage`) logrando un aislamiento total. Se comprueba tanto el cambio del estado emitido (`AuthStatus`) como los efectos secundarios (escrituras de token o contadores de llamadas del servicio).

### Ítem 5: Pruebas unitarias focalizadas (Lockout & Interceptor)
- **Archivo**: `proyecto_moviles2_grupo03/test/auth/lockout_and_401_test.dart`
- **Comando Ejecutado**: `flutter test test/auth/lockout_and_401_test.dart --reporter expanded`
- **Explicación Técnica**: Se usó inyección de fecha `now()` mediante un closure en el provider, lo que hace el paso del tiempo 100% determinista para testear la expiración del bloqueo. Para probar el interceptor sin red, se proporcionó a Dio un `FakeHttpClientAdapter` customizado que inyecta programáticamente una respuesta 401. Esto permite corroborar la intercepción, limpieza de caché y callback en milisegundos sin latencia.
