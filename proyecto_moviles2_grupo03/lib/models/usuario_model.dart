import 'dart:convert';

/// Modelo que representa al Usuario / Estudiante autenticado en la aplicación.
/// Cumple con las especificaciones de serialización segura del Examen Tipo 2:
/// - Identificadores procesados y almacenados estrictamente como texto (String).
/// - Valores monetarios o saldos guardados en céntimos enteros (int) evitando tipo double.
/// - Tolerancia total a nulos, campos omitidos y descarte de claves no mapeadas.
class UsuarioModel {
  /// Identificador único del usuario (estrictamente texto para evitar pérdida de precisión).
  final String id;

  /// Nombre completo del estudiante.
  final String nombre;

  /// Correo electrónico institucional.
  final String email;

  /// Código de estudiante (ej. 2020068763).
  final String codigo;

  /// Token o identificador de sesión activa para persistencia y auto-login.
  final String token;

  /// Saldo económico o monto de matrícula guardado estrictamente en CÉNTIMOS ENTEROS (int).
  /// Se evita el uso de tipo double para impedir problemas de precisión flotante IEEE-754.
  final int saldoCentimos;

  /// Estado académico o de cuenta del usuario (ej. 'ACTIVO', 'MATRICULADO').
  final String estado;

  /// Carrera profesional (campo opcional con valor por defecto seguro).
  final String carrera;

  /// Ciclo académico (campo opcional con valor por defecto seguro).
  final String ciclo;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.codigo,
    required this.token,
    required this.saldoCentimos,
    this.estado = 'ACTIVO',
    this.carrera = 'Ingeniería de Sistemas',
    this.ciclo = 'IX Ciclo',
  });

  /// Saldo formateado en Soles (S/) para renderizado seguro en la interfaz.
  String get saldoFormateado {
    final soles = saldoCentimos ~/ 100;
    final centimos = (saldoCentimos % 100).abs().toString().padLeft(2, '0');
    return 'S/ $soles.$centimos';
  }

  /// Deserializador seguro tolerante a fallos (Puntos 2 y 3).
  /// - Procesa claves ausentes o nulas asignando valores por defecto seguros.
  /// - Ignora silenciosamente claves adicionales no contempladas en el modelo.
  /// - Transforma identificadores a texto exacto sin conversión por int/Long.
  /// - Guarda montos en céntimos enteros descartando tipo double.
  factory UsuarioModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UsuarioModel(
        id: '0',
        nombre: 'Estudiante Invitado',
        email: 'invitado@upt.pe',
        codigo: '0000000000',
        token: '',
        saldoCentimos: 0,
        estado: 'INACTIVO',
        carrera: 'General',
        ciclo: 'I',
      );
    }

    return UsuarioModel(
      // Parseo seguro de ID: strictly String sin pérdida de precisión
      id: _parseSafeId(json['id'] ?? json['identificador'] ?? json['userId']),
      
      // Manejo tolerante de campos con defaults seguros
      nombre: (json['nombre'] ?? json['name'] ?? 'Elvis Mamani Valdivia').toString(),
      email: (json['email'] ?? json['correo'] ?? 'elvmamani@upt.pe').toString(),
      codigo: (json['codigo'] ?? json['code'] ?? '2020068763').toString(),
      token: (json['token'] ?? json['auth_token'] ?? '').toString(),
      
      // Parseo seguro de valores monetarios en céntimos enteros (evita double)
      saldoCentimos: _parseMontoCentimos(
        json['saldoCentimos'] ?? json['saldo'] ?? json['monto'] ?? json['balance'],
      ),
      
      // Campos opcionales tolerantes a null
      estado: (json['estado'] ?? json['status'] ?? 'ACTIVO').toString(),
      carrera: (json['carrera'] ?? json['career'] ?? 'Ingeniería de Sistemas').toString(),
      ciclo: (json['ciclo'] ?? json['semester'] ?? 'IX Ciclo').toString(),
    );
  }

  /// Parseo seguro desde cadena en texto crudo (JSON String literal).
  /// Soporta preservar identificadores numéricos de 19+ dígitos sin truncamiento.
  factory UsuarioModel.fromRawJson(String rawJson) {
    // Si la cadena contiene un ID numérico extenso, podemos capturarlo directamente
    final idRegex = RegExp(r'"id"\s*:\s*(\d+)');
    final match = idRegex.firstMatch(rawJson);
    String? rawExtractedId;
    if (match != null) {
      rawExtractedId = match.group(1);
    }

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final model = UsuarioModel.fromJson(decoded);

    if (rawExtractedId != null && rawExtractedId.isNotEmpty) {
      return model.copyWith(id: rawExtractedId);
    }
    return model;
  }

  /// Conversor a Map JSON para persistencia o transporte.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'codigo': codigo,
      'token': token,
      'saldoCentimos': saldoCentimos,
      'estado': estado,
      'carrera': carrera,
      'ciclo': ciclo,
    };
  }

  /// Serialización a texto JSON.
  String toRawJson() => jsonEncode(toJson());

  /// Helper de copia inmutable.
  UsuarioModel copyWith({
    String? id,
    String? nombre,
    String? email,
    String? codigo,
    String? token,
    int? saldoCentimos,
    String? estado,
    String? carrera,
    String? ciclo,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      codigo: codigo ?? this.codigo,
      token: token ?? this.token,
      saldoCentimos: saldoCentimos ?? this.saldoCentimos,
      estado: estado ?? this.estado,
      carrera: carrera ?? this.carrera,
      ciclo: ciclo ?? this.ciclo,
    );
  }

  /// Conversión segura de identificador a String exacto.
  static String _parseSafeId(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value.trim();
    // Si viene numérico, convertimos a texto exacto sin operar matemáticamente
    return value.toString();
  }

  /// Conversión de valores monetarios a céntimos enteros (int).
  /// Procesa tanto números enteros, strings monetarios "150.50" o números.
  static int _parseMontoCentimos(dynamic value) {
    if (value == null) return 0;
    if (value is int) {
      // Si ya viene en céntimos directamente
      return value;
    }
    if (value is num) {
      // Convierte a través de string para evitar artefactos binarios de punto flotante
      final s = value.toString();
      return _stringMonetarioACentimos(s);
    }
    if (value is String) {
      return _stringMonetarioACentimos(value);
    }
    return 0;
  }

  /// Convierte texto monetario "150.75" o "150" a céntimos (15075) sin recurrir a double.
  static int _stringMonetarioACentimos(String str) {
    final clean = str.replaceAll(RegExp(r'[^\d.]'), '');
    if (clean.isEmpty) return 0;
    if (clean.contains('.')) {
      final parts = clean.split('.');
      final enteros = int.tryParse(parts[0]) ?? 0;
      final decimals = parts.length > 1 ? parts[1] : '0';
      final decimalsPadded = (decimals + '00').substring(0, 2);
      final centimos = int.tryParse(decimalsPadded) ?? 0;
      return enteros * 100 + centimos;
    } else {
      final enteros = int.tryParse(clean) ?? 0;
      return enteros * 100;
    }
  }
}
