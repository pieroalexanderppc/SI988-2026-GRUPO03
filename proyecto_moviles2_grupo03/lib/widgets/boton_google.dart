import 'package:flutter/material.dart';

/// Botón estilizado para inicio de sesión con Google (H29).
class BotonGoogle extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool cargando;
  final String texto;

  const BotonGoogle({
    super.key,
    required this.onPressed,
    this.cargando = false,
    this.texto = 'Continuar con Google',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esOscuro = theme.brightness == Brightness.dark;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: esOscuro
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
        backgroundColor: esOscuro
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.white,
        foregroundColor: esOscuro ? Colors.white : Colors.black87,
      ),
      onPressed: cargando ? null : onPressed,
      child: cargando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _GoogleLogoIcon(),
                const SizedBox(width: 12),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: esOscuro ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Logo oficial de Google dibujado con CustomPainter para nitidez vectorial sin assets externos.
class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GooglePainter(),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    const red = Color(0xFFEA4335);
    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);

    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()..style = PaintingStyle.fill;

    // Sector azul
    paint.color = blue;
    canvas.drawArc(rect, -0.6, 1.2, true, paint);

    // Sector verde
    paint.color = green;
    canvas.drawArc(rect, 0.6, 1.3, true, paint);

    // Sector amarillo
    paint.color = yellow;
    canvas.drawArc(rect, 1.9, 1.3, true, paint);

    // Sector rojo
    paint.color = red;
    canvas.drawArc(rect, 3.2, 1.3, true, paint);

    // Centro blanco
    paint.color = Colors.white;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.32, paint);

    // Barra horizontal
    paint.color = blue;
    final barRect = Rect.fromLTWH(w * 0.45, h * 0.38, w * 0.55, h * 0.24);
    canvas.drawRect(barRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
