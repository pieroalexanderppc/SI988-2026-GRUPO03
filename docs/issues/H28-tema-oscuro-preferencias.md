# [H28] Selector Dinámico de Tema (Modo Claro / Oscuro) y Pantalla de Perfil de Usuario

## Descripción
**Como** estudiante universitario usuario de Pondera,  
**Quiero** contar con un menú de perfil y configuración que me permita alternar dinámicamente entre el Tema Claro, Tema Oscuro o Tema del Sistema,  
**Para** adaptar la apariencia visual de la aplicación según mis preferencias de estudio diurno o nocturno y gestionar los datos de mi cuenta académica.

---

## Contexto y Justificación
La aplicación ya cuenta con definiciones de estilos para `lightTheme` y `darkTheme` en `lib/theme/app_theme.dart`. Sin embargo, `main.dart` fuerza estáticamente `ThemeMode.system` sin ofrecer al usuario ninguna opción en la interfaz para elegir su tema favorito ni persistir su elección.
Asimismo, el usuario carece de una pantalla dedicada para consultar el estado de su cuenta (correo institucional, estado de verificación, fecha de ingreso) y acceder a las opciones de configuración general.

---

## Criterios de Aceptación (Gherkin)

### Escenario 1: Acceso a la pantalla de Perfil y Ajustes
- **Dado** que el usuario se encuentra en la pantalla principal (`HomeScreen`),
- **Cuando** presiona el nuevo ícono de perfil/configuración en el `AppBar`,
- **Entonces** se abre la pantalla `PerfilAjustesScreen` mostrando sus datos de cuenta y opciones de personalización.

### Escenario 2: Alternar tema en tiempo real
- **Dado** que el usuario está en la pantalla de Perfil y Ajustes,
- **Cuando** selecciona entre las opciones:
  - ☀️ **Modo Claro**
  - 🌙 **Modo Oscuro**
  - ⚙️ **Automático (Sistema)**
- **Entonces** toda la aplicación cambia su paleta de colores de forma reactiva e instantánea, respetando los contrastes de Material 3 y los colores de estado de notas.

### Escenario 3: Resumen de información de usuario y sesión
- **Dado** que el usuario ha iniciado sesión con Firebase Auth,
- **Cuando** revisa la sección de cuenta,
- **Entonces** visualiza su avatar con sus iniciales, su correo institucional, un badge de "Correo Verificado", y opciones claras para cerrar sesión de manera segura.

---

## Tareas Técnicas
- [ ] Crear `ThemeProvider` en `lib/providers/theme_provider.dart` que gestione el estado de `ThemeMode` reactivamente con `ChangeNotifier`.
- [ ] Envolver `MaterialApp` en `main.dart` con `MultiProvider` para proveer `ThemeProvider` a todo el árbol de widgets.
- [ ] Crear la pantalla `PerfilAjustesScreen` con `SegmentedButton` o lista de selección para cambiar el tema en tiempo real.
- [ ] Agregar el botón de acceso directo con avatar o ícono de ajustes en el `AppBarNivel` del `HomeScreen`.
- [ ] Validar que todos los widgets y diálogos mantengan legibilidad óptima tanto en modo claro como en modo oscuro.
