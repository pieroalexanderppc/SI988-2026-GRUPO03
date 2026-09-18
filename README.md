# SI-988 Soluciones Móviles II - Examen Práctico Unidad 1

## Información del Estudiante y Examen
* **Estudiante:** Elvis Mamani Valdivia
* **Código:** `2020068763`
* **Correo Institucional:** `elvmamani@upt.pe`
* **Docente:** Dr. Oscar Juan Jimenez Flores
* **Universidad:** Universidad Privada de Tacna (UPT)
* **Tipo de Examen Asignado:** **Tipo 2: "Leer JSON sin romper la app móvil"**
* **Rama de Trabajo:** `feat/examen-tipo2-elvis-mamani`

---

 Resumen Ejecutivo de la Solución

El objetivo principal de este desarrollo es garantizar que la aplicación móvil sea **altamente tolerante a fallos**, permitiendo consumir, mapear y persistir información proveniente de payloads JSON inconsistentes, corruptos o con cambios de estructura imprevistos sin provocar cierres inesperados (*crashes*) ni pérdidas de precisión en datos sensibles.

---

## Detalle de Implementación por Puntos

### 🔹 Punto 1: Persistencia Local y Auto-Login (4 puntos)
* **Objetivo:** Almacenar de forma segura la sesión del usuario para restaurarla automáticamente al reiniciar la app o matar el proceso.
* **Mecanismo de Persistencia:** Se utilizó la librería oficial `shared_preferences: ^2.3.5`, interactuando con el almacenamiento nativo de la plataforma (XML en Android / `localStorage` en Web).
* **Flujo de Autenticación y Auto-Login:**
  1. **Inicio de Sesión:** El usuario ingresa credenciales en `LoginScreen`. Al autenticar, `AuthService.login()` almacena el token de sesión (`auth_token`) y el payload del usuario (`user_data`).
  2. **Verificación en el Arranque (`main.dart`):** Antes de renderizar la interfaz, la app consulta `AuthService.verificarSesion()`.
  3. **Auto-Login Transparente:** Si existe un token persistido válido, la app navega directamente a `HomeScreen` mostrando los datos del alumno (Elvis Mamani Valdivia, Código 2020068763, Saldo y datos académicos) sin pedir credenciales nuevamente.
  4. **Cierre de Sesión:** El botón de cierre en `HomeScreen` invoca `AuthService.logout()`, limpiando las llaves en `SharedPreferences` y retornando a `LoginScreen`.
* **Archivos clave:**
  * `lib/services/auth_service.dart`
  * `lib/screens/login_screen.dart`
  * `lib/screens/home_screen.dart`
  * `lib/main.dart`
  * `test/auth_service_test.dart` (3 pruebas unitarias completas)

---

### 🔹 Punto 2: Parseo Seguro de Identificadores y Montos Monetarios (4 puntos)
* **Objetivo:** Evitar truncamiento de IDs extensos y errores de precisión en cálculos monetarios.
* **Manejo Seguro de Identificadores (`id`):**
  * **Problema tradicional:** Si una API envía un ID numérico de 19 dígitos (ej. `9876543210123456789`), parsearlo como entero en ciertos entornos o flotante provoca pérdida de precisión por redondeo.
  * **Solución técnica:** El modelo `UsuarioModel` utiliza `_parseSafeId` y `UsuarioModel.fromRawJson`, convirtiendo y preservando el identificador estrictamente como `String` inmutable sin aplicar operaciones matemáticas ni truncamientos.
* **Manejo Seguro de Montos Monetarios (Sin tipo `double`):**
  * **Problema tradicional:** El tipo `double` en Dart se rige por el estándar IEEE-754 de coma flotante, generando inexactitudes conocidas en finanzas (ej. `0.1 + 0.2 = 0.30000000000000004`).
  * **Solución técnica:** Se implementaron dos mecanismos complementarios:
    1. `saldoCentimos: int`: Almacenamiento en céntimos enteros (ej. `S/ 150.50` se procesa y persiste como `15050` céntimos).
    2. `saldoExacto: String`: Preservación textual exacta del importe recibido de la API para visualización directa.
* **Archivos clave:**
  * `lib/models/usuario_model.dart`
  * `test/punto2_parseo_seguro_test.dart` (3 pruebas unitarias verificando IDs de 19 dígitos y ausencia de `double`)

---

### 🔹 Punto 3: Tolerancia a Valores Nulos y Claves Desconocidas (4 puntos)
* **Objetivo:** Inmunidad ante JSON mal formateados, campos opcionales nulos o claves nuevas no mapeadas.
* **Solución técnica:**
  * El constructor factory `UsuarioModel.fromJson` aplica operadores de coalescencia nula (`??`) asignando *fallbacks* coherentes a los datos de Elvis Mamani Valdivia en caso de ausencia o nulidad.
  * Claves no previstas en el payload (campos adicionales inyectados por la API) son ignoradas silenciosamente sin generar errores de tipo `NoSuchMethodError` o excepciones de deserialización.

---

## 🧪 Pruebas Unitarias Automatizadas

El proyecto cuenta con una suite completa de pruebas unitarias implementadas con `flutter_test`.

###  Cobertura de Pruebas:
1. `test/auth_service_test.dart`:
   * ✅ Retorno `false` cuando no existe token previo.
   * ✅ Persistencia correcta de token y datos de usuario en `SharedPreferences`.
   * ✅ Limpieza íntegra de almacenamiento al invocar `logout()`.
2. `test/punto2_parseo_seguro_test.dart`:
   * ✅ Parseo de identificador numérico a `String` sin pérdida de dígitos.
   * ✅ Integridad de ID de 19 dígitos (`9876543210123456789`).
   * ✅ Parseo monetario a enteros en céntimos (`int`) sin usar tipo `double`.
3. `test/calculadora_promedio_test.dart` y `test/widget_test.dart`:
   * ✅ Pruebas de lógica de cálculo ponderado y componentes visuales del proyecto base.

### Comando para ejecutar las pruebas:
```bash
cd proyecto_moviles2_grupo03
flutter test
```
**Resultado de ejecución:**
```
00:01 +12: All tests passed!
```

---

##  Estructura del Código Fuente Afectado

```
proyecto_moviles2_grupo03/
├── lib/
│   ├── models/
│   │   └── usuario_model.dart       # Entidad segura: strictly String ID, saldo en céntimos enteros, tolerancia a nulos
│   ├── services/
│   │   └── auth_service.dart        # Lógica de SharedPreferences, token y persistencia de sesión
│   ├── screens/
│   │   ├── login_screen.dart        # Pantalla de Login institucional
│   │   └── home_screen.dart         # Pantalla principal con banner de Elvis Mamani y botón Cerrar Sesión
│   └── main.dart                    # Entrypoint con chequeo asíncrono de Auto-Login
└── test/
    ├── auth_service_test.dart       # Tests de persistencia local y auto-login (Punto 1)
    └── punto2_parseo_seguro_test.dart # Tests de parseo seguro de IDs y montos monetarios (Punto 2)
```

---

| **¿Por qué no usar `double` para el saldo monetario?** | *«Porque `double` utiliza el estándar IEEE-754 de coma flotante, susceptible a errores de aproximación binaria en centavos. Para evitarlo, mapeamos el saldo en céntimos enteros (`int`) y conservamos el texto exacto (`String`).»* |
| **¿Qué ocurre si el backend envía un ID de 19 dígitos o claves inesperadas?** | *«El modelo parsea el ID estrictamente como `String` para evitar desbordamientos de enteros de 64 bits o notación científica. Además, cualquier clave ajena es descartada sin romper el ciclo de vida de la aplicación.»* |
