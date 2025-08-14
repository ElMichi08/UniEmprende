import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class WhatsAppService {
  /// Contactar emprendedor por WhatsApp
  static Future<void> contactarEmprendedor({
    required String numeroTelefono,
    required String nombreEmprendimiento,
    required String nombreProducto,
    BuildContext? context,
  }) async {
    try {
      // Limpiar el número de teléfono
      String numeroLimpio = numeroTelefono.replaceAll(RegExp(r'[^\d]'), '');

      // Agregar código de país si no tiene
      if (!numeroLimpio.startsWith('593')) {
        if (numeroLimpio.startsWith('0')) {
          numeroLimpio = '593${numeroLimpio.substring(1)}';
        } else {
          numeroLimpio = '593$numeroLimpio';
        }
      }

      final mensaje =
          '''¡Hola $nombreEmprendimiento! 

Vi tu producto "$nombreProducto" en la app Latacunga Emprende y estoy interesado(a). 

¿Podrías darme más información?

Saludos! 🙂''';

      // Intentar diferentes métodos
      bool exito = false;

      // Método 1: WhatsApp directo
      try {
        final whatsappUrl =
            'whatsapp://send?phone=$numeroLimpio&text=${Uri.encodeComponent(mensaje)}';
        final whatsappUri = Uri.parse(whatsappUrl);

        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          exito = true;
        }
      } catch (e) {
        print('Método WhatsApp directo falló: $e');
      }

      // Método 2: URL web de WhatsApp
      if (!exito) {
        try {
          final mensajeCodificado = Uri.encodeComponent(mensaje);
          final webUrl = 'https://wa.me/$numeroLimpio?text=$mensajeCodificado';
          final webUri = Uri.parse(webUrl);

          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
            exito = true;
          }
        } catch (e) {
          print('Método web de WhatsApp falló: $e');
        }
      }

      // Método 3: Abrir en navegador
      if (!exito) {
        try {
          final mensajeCodificado = Uri.encodeComponent(mensaje);
          final browserUrl =
              'https://wa.me/$numeroLimpio?text=$mensajeCodificado';
          final browserUri = Uri.parse(browserUrl);

          await launchUrl(browserUri, mode: LaunchMode.inAppWebView);
          exito = true;
        } catch (e) {
          print('Método navegador falló: $e');
        }
      }

      if (exito && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abriendo WhatsApp...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      print('Error al contactar por WhatsApp: $e');

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: WhatsApp no está instalado o no se puede abrir.\nNúmero: $numeroTelefono',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
