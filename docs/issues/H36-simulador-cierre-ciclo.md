# Issue H36: Simulador Multiescenario de Cierre de Ciclo ("¿Qué pasa si...?") y Metas de Tercio Superior

- **Título en GitHub:** `feat(h36): Simulador multiescenario de cierre de ciclo con sliders hápticos, presets y meta de tercio superior`
- **Labels:** `enhancement`, `simulation`, `academic`, `H36`, `sprint-3`
- **Responsable:** Elvis Mamani Valdivia (`@elvisMamaniValdivia`)
- **Rama:** `feat/h36-simulador-cierre-ciclo`

---

## 📖 Descripción / User Story
> **Como** estudiante de la Universidad Privada de Tacna que se encuentra a mitad o en la recta final del ciclo académico,  
> **quiero** proyectar de forma interactiva y multiescenario las notas finales de todas mis materias matriculadas mediante controles deslizantes y presets inteligentes,  
> **para** prever mi promedio ponderado semestral, medir el impacto en mi Promedio Ponderado Acumulado (PPA) histórico y evaluar si alcanzo o mantengo la condición de Tercio Superior universitario.

---

## 🎯 Criterios de Aceptación (Gherkin)

### CA1: Proyección simultánea de todos los cursos ponderados por créditos
- **Dado** un ciclo académico activo con múltiples cursos matriculados,
- **Cuando** el usuario ingresa a la pantalla `SimuladorCicloScreen`,
- **Entonces** se muestran todas las asignaturas cargadas con su crédito respectivo y su nota inicial (obtenida de lo evaluado hasta el momento o 11.0 por defecto), calculando dinámicamente el promedio ponderado del ciclo en tiempo real.

### CA2: Controles deslizantes (Sliders) interactivos con feedback háptico
- **Dado** que el usuario desea ajustar la nota estimada de una asignatura específica,
- **Cuando** desliza el control de 0.0 a 20.0 (en pasos de 0.5) o presiona los botones de ajuste fino (+ / -),
- **Entonces** el sistema emite feedback háptico discreto (`HapticFeedback.selectionClick()`), actualiza la etiqueta numérica de la materia y recalcula instantáneamente todas las métricas globales.

### CA3: Presets automáticos de simulación rápida
- **Dado** el panel de simulación abierta,
- **Cuando** el estudiante selecciona uno de los presets:
  - *Mínimo Aprobatorio (10.5)*: todas las notas se fijan en 10.5.
  - *Escenario Realista*: se preservan las notas obtenidas hasta la fecha o el rendimiento medio.
  - *Meta Distinción (16.0)*: las materias se elevan a 16.0 o más para aspirar a cuadros de mérito.
- **Entonces** todas las notas simuladas se reconfiguran en un solo toque con respuesta háptica media (`HapticFeedback.mediumImpact()`).

### CA4: Cálculo de impacto en PPA histórico y verificación de Tercio Superior
- **Dado** que el estudiante cuenta con un historial académico acumulado previo,
- **Cuando** se simulan las calificaciones del ciclo actual,
- **Entonces** el sistema proyecta el nuevo PPA histórico ponderado por los créditos totales acumulados, indica cuántos puntos suma o resta el ciclo (`+X.X pts`), y evalúa la condición de Tercio Superior (umbral institucional $\ge 15.0$ en la UPT).

---

## 🛠️ Tareas Técnicas Implementadas
1. Implementación del motor matemático en `CalculadoraSimulacionCicloService` (`lib/services/calculadora_simulacion_ciclo_service.dart`).
2. Creación de la pantalla interactiva `SimuladorCicloScreen` en `lib/screens/simulador_ciclo_screen.dart`.
3. Integración del acceso directo al simulador en `CursosScreen` (`lib/screens/cursos_screen.dart`).
4. Pruebas unitarias exhaustivas en `test/simulador_ciclo_test.dart` cubriendo promedios ponderados, los 3 presets automáticos, impacto en PPA histórico y umbral de Tercio Superior.
