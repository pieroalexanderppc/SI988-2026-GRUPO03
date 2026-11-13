# [H29] Inicio de Sesión Seguro con Google Sign-In (OAuth 2.0 / Correo Institucional)

## Descripción
**Como** estudiante universitario usuario de Pondera,  
**Quiero** iniciar sesión y registrarme en la aplicación utilizando mi cuenta de Google (Gmail o correo institucional @upt.pe),  
**Para** acceder de forma inmediata y segura con un solo toque, sin necesidad de recordar ni escribir contraseñas en el dispositivo móvil y aprovechando la seguridad de doble factor (2FA) de Google.

---

## Contexto y Justificación
Actualmente la aplicación cuenta con registro y login tradicional por correo y contraseña (H05). Aunque incluye verificación de correo, ingresar contraseñas complejas en teclados virtuales móviles genera fricción y riesgo de contraseñas débiles o reutilizadas.
La integración de Google Sign-In mediante OAuth 2.0 y OpenID Connect delega la seguridad en la infraestructura de Google, garantiza la verificación del correo en tiempo real (`emailVerified: true`), sincroniza el nombre y foto de perfil oficial del estudiante y permite restringir el acceso a dominios universitarios autorizados (@upt.pe).

---

## Criterios de Aceptación (Gherkin)

### Escenario 1: Inicio de sesión exitoso con Google
- **Dado** que el estudiante se encuentra en la pantalla de bienvenida (`WelcomeScreen`) o de autenticación (`AuthScreen`),
- **Cuando** presiona el botón **"Continuar con Google"**,
- **Entonces** se despliega el selector nativo de cuentas de Google de Android / Google Play Services,
- **Y** al seleccionar su cuenta válida, se autentica en Firebase Auth mediante `GoogleAuthProvider`, redirigiendo inmediatamente a la pantalla principal (`HomeScreen`).

### Escenario 2: Creación automática de perfil en Firestore
- **Dado** que es la primera vez que el estudiante inicia sesión con su cuenta de Google,
- **Cuando** se completa el flujo de autenticación,
- **Entonces** se crea automáticamente su documento de usuario en la colección `usuarios` de Firestore vinculando su `uid`, correo institucional, nombre completo y URL de foto de perfil.

### Escenario 3: Manejo de cancelación o error de red
- **Dado** que el selector nativo de Google está visible en pantalla,
- **Cuando** el usuario presiona "Atrás" o cancela la selección,
- **Entonces** la aplicación no se bloquea ni genera excepciones no controladas, retornando limpiamente a la pantalla de login con un mensaje informativo o permaneciendo en el estado previo.

### Escenario 4: Validación de dominio institucional universitario y cuenta de prueba
- **Dado** que se configura la restricción de dominio universitario,
- **Cuando** un usuario intenta acceder con un correo que no pertenece al dominio permitido (`@virtual.upt.pe` o `@upt.pe`) y no es la cuenta de prueba autorizada (`elvismv.2016@gmail.com`),
- **Entonces** la aplicación revoca la sesión temporal en Firebase, muestra un diálogo de advertencia informando que debe utilizar su correo institucional `@virtual.upt.pe` y no almacena datos no autorizados.

---

## Tareas Técnicas
- [x] Configuración de dependencias: Agregar `google_sign_in: ^6.2.1` en `proyecto_moviles2_grupo03/pubspec.yaml`.
- [x] Implementación de `AuthService`: Servicio de autenticación OAuth 2.0 (`iniciarSesionConGoogle()`, `cerrarSesion()`) y validación estricta de dominios (`@virtual.upt.pe`, `@upt.pe`) y whitelist admin (`elvismv.2016@gmail.com`).
- [x] Componente UI `BotonGoogle`: Botón con especificaciones oficiales de Google y vector exacto multi-color, adaptable a modo claro/oscuro.
- [x] Integración en `WelcomeScreen` y `AuthScreen`: Botón Google, separador visual y diálogo de error explicativo para correos no institucionales.
- [x] Actualización de `PerfilAjustesScreen`: Carga de avatar desde `photoURL`, badge de "Google Institucional UPT" / "Google Admin (Testing)" y cierre de sesión sincronizado.
- [x] Pruebas Unitarias Automatizadas: Suite de 8 tests en `test/auth_service_test.dart` validando dominios permitidos, correos admin, sanitización y rechazo de dominios impostores.
- [ ] *(Paso manual en consola)* Habilitar el proveedor **Google** en Firebase Console y registrar la huella SHA-1 del keystore si se requiere ejecución en dispositivo físico.

