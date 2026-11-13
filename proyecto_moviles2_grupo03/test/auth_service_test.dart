import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/services/auth_service.dart';

void main() {
  group('H29 - AuthService & Validación de Correo Institucional', () {
    test('Rechaza correos nulos o vacíos', () {
      expect(AuthService.esCorreoAutorizado(null), isFalse);
      expect(AuthService.esCorreoAutorizado(''), isFalse);
      expect(AuthService.esCorreoAutorizado('   '), isFalse);
    });

    test('Autoriza correos institucionales de alumnos (@virtual.upt.pe)', () {
      expect(
        AuthService.esCorreoAutorizado('2020067890@virtual.upt.pe'),
        isTrue,
      );
      expect(
        AuthService.esCorreoAutorizado('juan.perez@virtual.upt.pe'),
        isTrue,
      );
    });

    test('Autoriza correos institucionales de docentes/administrativos (@upt.pe)', () {
      expect(
        AuthService.esCorreoAutorizado('jdocente@upt.pe'),
        isTrue,
      );
      expect(
        AuthService.esCorreoAutorizado('decanato.faing@upt.pe'),
        isTrue,
      );
    });

    test('Autoriza la cuenta de administración para testing (elvismv.2016@gmail.com)', () {
      expect(
        AuthService.esCorreoAutorizado('elvismv.2016@gmail.com'),
        isTrue,
      );
    });

    test('Maneja mayúsculas y espacios en blanco adecuadamente', () {
      expect(
        AuthService.esCorreoAutorizado('  ELVISMV.2016@GMAIL.COM  '),
        isTrue,
      );
      expect(
        AuthService.esCorreoAutorizado(' 2021001234@VIRTUAL.UPT.PE '),
        isTrue,
      );
      expect(
        AuthService.esCorreoAutorizado('Docente@UPT.PE'),
        isTrue,
      );
    });

    test('Rechaza correos de otros dominios públicos o no autorizados', () {
      expect(
        AuthService.esCorreoAutorizado('usuario@gmail.com'),
        isFalse,
      );
      expect(
        AuthService.esCorreoAutorizado('estudiante@hotmail.com'),
        isFalse,
      );
      expect(
        AuthService.esCorreoAutorizado('otro@yahoo.es'),
        isFalse,
      );
      expect(
        AuthService.esCorreoAutorizado('cuenta@outlook.com'),
        isFalse,
      );
    });

    test('Rechaza dominios impostores o que contengan el dominio como prefijo', () {
      expect(
        AuthService.esCorreoAutorizado('atacante@virtual.upt.pe.malicious.com'),
        isFalse,
      );
      expect(
        AuthService.esCorreoAutorizado('fake@notupt.pe'),
        isFalse,
      );
      expect(
        AuthService.esCorreoAutorizado('test@upt.pe.co'),
        isFalse,
      );
    });

    test('CorreoNoAutorizadoException genera mensaje y almacena el email', () {
      final exc = CorreoNoAutorizadoException(email: 'intruso@gmail.com');
      expect(exc.email, 'intruso@gmail.com');
      expect(exc.mensaje, contains('@virtual.upt.pe'));
      expect(exc.toString(), contains('Acceso restringido'));
    });
  });
}
