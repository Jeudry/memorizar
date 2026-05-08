import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/ui/widgets.dart';
import '_legal_layout.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      child: LegalLayout(
        title: 'Privacidad',
        intro:
            'Memorizar guarda solo lo necesario para que la app funcione. Este es un resumen claro, sin letra chica, de qué datos toca y por qué.',
        sections: const [
          LegalSection(
            heading: 'Qué guardamos',
            body:
                '• Tu mazos, tarjetas y progreso de estudio: necesarios para que la app sirva.\n'
                '• Tu correo electrónico (si decides registrarte): solo para recuperar acceso y para sincronizar.\n'
                '• Audios que grabes: solo en tu dispositivo a menos que actives respaldo en la nube.\n'
                '• Métricas mínimas de uso (sesiones iniciadas, errores): de forma anónima, para arreglar bugs.',
          ),
          LegalSection(
            heading: 'Qué NO guardamos',
            body:
                '• Tu ubicación.\n'
                '• Tus contactos (a menos que invites a un amigo y nos pidas mandarle el link, una sola vez).\n'
                '• Datos de pago en nuestros servidores: si compras premium, eso pasa por la tienda (App Store / Play) y nunca tocamos tu tarjeta.',
          ),
          LegalSection(
            heading: 'Modo offline',
            body:
                'Si no inicias sesión, todos tus mazos viven solo en tu dispositivo. Si reinstalas la app sin haber iniciado sesión antes, ese contenido se pierde.',
          ),
          LegalSection(
            heading: 'Visibilidad de tu contenido',
            body:
                'Tus mazos son privados por defecto. Solo aparecen en otros dispositivos si:\n'
                '• Los marcas como compartidos con un amigo específico.\n'
                '• Los marcas como públicos para la comunidad.\n\n'
                'En ambos casos te pedimos confirmación explícita y aceptación de que tienes derechos sobre el contenido.',
          ),
          LegalSection(
            heading: 'Versiones de la Biblia',
            body:
                'Cuando estudias con una versión obtenida vía API (RV1960, NBLA, etc.), tu app pide los versículos al servidor del titular. Esa petición incluye qué libro/capítulo/verso pediste, pero no quién eres ni desde dónde — proxy nuestro elimina esos datos antes de reenviar.',
          ),
          LegalSection(
            heading: 'Borrar tu cuenta',
            body:
                'Puedes borrar toda tu información en cualquier momento desde Ajustes → Borrar cuenta. La acción elimina mazos, audios sincronizados, registros de progreso y tu correo de nuestros servidores en máximo 30 días. Lo bíblico bajo licencia que se te haya servido vía API no se "guarda en ti", solo dejamos de servírtelo.',
          ),
          LegalSection(
            heading: 'Menores de edad',
            body:
                'Memorizar no está dirigido a menores de 13 años. Si descubrimos una cuenta de un menor sin consentimiento parental, la cerraremos.',
          ),
          LegalSection(
            heading: 'Contacto',
            body: 'Para temas de privacidad: privacy@memorizar.app',
          ),
        ],
      ),
    );
  }
}
