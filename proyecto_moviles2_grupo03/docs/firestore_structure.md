# Estructura de Base de Datos en Firestore

La base de datos en Firestore sigue una arquitectura de subcolecciones anidadas para reflejar fielmente la jerarquía académica del usuario.

## Jerarquía

```
usuarios/{uid}
  └── ciclos/{cicloId}
        └── cursos/{cursoId}
              └── unidades/{unidadId}
                    └── tiposEvaluacion/{tipoId}
                          └── notas/{notaId}
```

## Modelos y sus Atributos Principales

### Ciclo
- **Colección:** `usuarios/{uid}/ciclos`
- **Atributos:**
  - `nombre` (String) - Ej: '2026-I'

### Curso
- **Colección:** `usuarios/{uid}/ciclos/{cicloId}/cursos`
- **Atributos:**
  - `nombre` (String) - Ej: 'Soluciones Móviles II'
  - `color` (String, Opcional) - Ej: '#FF0000'

### Unidad
- **Colección:** `usuarios/{uid}/ciclos/{cicloId}/cursos/{cursoId}/unidades`
- **Atributos:**
  - `nombre` (String) - Ej: 'Unidad 1'
  - `peso` (Double) - Porcentaje que vale de la nota final, Ej: 50.0

### TipoEvaluacion
- **Colección:** `usuarios/{uid}/ciclos/{cicloId}/cursos/{cursoId}/unidades/{unidadId}/tiposEvaluacion`
- **Atributos:**
  - `nombre` (String) - Ej: 'Práctica', 'Laboratorio'
  - `peso` (Double) - Porcentaje que vale dentro de la unidad, Ej: 30.0

### Nota
- **Colección:** `usuarios/{uid}/ciclos/{cicloId}/cursos/{cursoId}/unidades/{unidadId}/tiposEvaluacion/{tipoId}/notas`
- **Atributos:**
  - `nombre` (String) - Ej: 'Práctica 1'
  - `valor` (Double) - Nota obtenida, Ej: 18.5
  - `peso` (Double) - Peso específico de esta nota, Ej: 100.0 (o fraccionado si hay varias)
  - `fecha` (String ISO8601, Opcional)
