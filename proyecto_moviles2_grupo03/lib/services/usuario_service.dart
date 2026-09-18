import 'dart:convert';
import '../models/usuario_model.dart';

/// Estados posibles durante el ciclo de vida de lectura y deserialización.
enum EstadoCarga { inicial, cargando, exitoso, fallido }

/// Representa el resultado y estado final tras procesar un payload JSON.
class ResultadoCargaUsuario {
  final EstadoCarga estado;
  final UsuarioModel? usuario;
  final String? mensajeError;
  final bool datosListosParaRenderizar;
  final int reintentosDisparados;

  const ResultadoCargaUsuario({
    required this.estado,
    this.usuario,
    this.mensajeError,
    this.datosListosParaRenderizar = false,
    this.reintentosDisparados = 0,
  });
}

/// Servicio encargado del procesamiento seguro y control de flujo de lectura de usuario.
class UsuarioService {
  /// Procesa y deserializa un payload JSON entrante garantizando control de estado.
  /// (Punto 4 del Examen Práctico Tipo 2)
  ResultadoCargaUsuario procesarPayload(dynamic rawPayload) {
    if (rawPayload == null) {
      return const ResultadoCargaUsuario(
        estado: EstadoCarga.fallido,
        mensajeError: 'Payload inaceptable: el cuerpo recibido es nulo.',
        datosListosParaRenderizar: false,
        reintentosDisparados: 0,
      );
    }

    try {
      Map<String, dynamic> jsonMap;
      if (rawPayload is String) {
        final clean = rawPayload.trim();
        if (!clean.startsWith('{') || !clean.endsWith('}')) {
          return const ResultadoCargaUsuario(
            estado: EstadoCarga.fallido,
            mensajeError: 'Payload inaceptable: la cadena no corresponde a un objeto JSON válido.',
            datosListosParaRenderizar: false,
            reintentosDisparados: 0,
          );
        }
        jsonMap = jsonDecode(clean) as Map<String, dynamic>;
      } else if (rawPayload is Map<String, dynamic>) {
        jsonMap = rawPayload;
      } else {
        return const ResultadoCargaUsuario(
          estado: EstadoCarga.fallido,
          mensajeError: 'Payload inaceptable: tipo de dato entrante incompatible.',
          datosListosParaRenderizar: false,
          reintentosDisparados: 0,
        );
      }

      // Si el servidor envía una respuesta de error explícita
      if (jsonMap.containsKey('error') && jsonMap['error'] == true) {
        return ResultadoCargaUsuario(
          estado: EstadoCarga.fallido,
          mensajeError: jsonMap['mensaje']?.toString() ?? 'Error explícito en respuesta del servidor.',
          datosListosParaRenderizar: false,
          reintentosDisparados: 0,
        );
      }

      // Si el objeto está vacío y no contiene atributos mínimos
      if (jsonMap.isEmpty) {
        return const ResultadoCargaUsuario(
          estado: EstadoCarga.fallido,
          mensajeError: 'Payload inaceptable: objeto JSON sin datos de entidad.',
          datosListosParaRenderizar: false,
          reintentosDisparados: 0,
        );
      }

      // Hidratación segura de la entidad
      final usuario = UsuarioModel.fromJson(jsonMap);

      return ResultadoCargaUsuario(
        estado: EstadoCarga.exitoso,
        usuario: usuario,
        datosListosParaRenderizar: true,
        reintentosDisparados: 0,
      );
    } catch (e) {
      // Manejo de carga fallida: posiciona en estado error sin bucles de reintento
      return ResultadoCargaUsuario(
        estado: EstadoCarga.fallido,
        mensajeError: 'Excepción en deserialización: $e',
        datosListosParaRenderizar: false,
        reintentosDisparados: 0,
      );
    }
  }
}
