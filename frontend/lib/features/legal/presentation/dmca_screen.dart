import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/ui/widgets.dart';
import '_legal_layout.dart';

class DmcaScreen extends StatelessWidget {
  const DmcaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      child: LegalLayout(
        title: 'DMCA / Copyright',
        intro:
            'Si crees que un mazo, tarjeta o audio en Memorizar reproduce material tuyo sin permiso, puedes pedir su retiro. Atendemos avisos de buena fe en 5 días hábiles o menos.',
        sections: const [
          LegalSection(
            heading: 'Cómo enviar un aviso de retiro',
            body:
                'Mándanos un correo a copyright@memorizar.app con:\n\n'
                '1. Tu nombre completo y datos de contacto (correo, teléfono).\n'
                '2. Identificación de la obra: título, autor, edición, link al original o copia.\n'
                '3. Identificación del contenido en Memorizar: URL del mazo o ID, captura si es posible.\n'
                '4. Declaración: "Tengo de buena fe la creencia de que el uso del material no está autorizado por el titular, su agente o la ley."\n'
                '5. Declaración: "La información en este aviso es exacta. Bajo pena de perjurio declaro que soy el titular o estoy autorizado para actuar en su nombre."\n'
                '6. Tu firma física o electrónica.',
          ),
          LegalSection(
            heading: 'Qué hacemos al recibirlo',
            body:
                '• Retiramos el contenido reportado o le quitamos visibilidad mientras revisamos.\n'
                '• Notificamos al usuario que subió el contenido para que tenga oportunidad de responder.\n'
                '• Si el usuario presenta un counter-notice válido, restauramos el contenido en 10-14 días salvo que el reclamante inicie acción legal.',
          ),
          LegalSection(
            heading: 'Counter-notice',
            body:
                'Si crees que tu contenido fue retirado por error, mándanos a copyright@memorizar.app:\n\n'
                '1. Tu nombre, dirección, correo y teléfono.\n'
                '2. Identificación del contenido retirado y dónde aparecía.\n'
                '3. Declaración bajo pena de perjurio de que crees de buena fe que el retiro fue por error o errónea identificación.\n'
                '4. Consentimiento a la jurisdicción competente.\n'
                '5. Tu firma.',
          ),
          LegalSection(
            heading: 'Reincidencia',
            body:
                'Cuentas que reciban tres avisos válidos de copyright serán suspendidas permanentemente.',
          ),
          LegalSection(
            heading: 'Versiones bíblicas modernas',
            body:
                'Memorizar incluye solo Reina-Valera 1909 (dominio público) en su distribución. Las versiones modernas (RV1960, NBLA, NVI, etc.) se sirven vía API.Bible u otros proveedores con licencia. '
                'Si eres titular de una versión y crees que su uso en Memorizar excede los términos de esa licencia, contáctanos directamente para coordinar.',
          ),
          LegalSection(
            heading: 'Agente DMCA',
            body:
                'Memorizar registra agente DMCA conforme a 17 USC §512(c). El correo copyright@memorizar.app es la vía oficial para todos los avisos. '
                'Avisos enviados por otras vías pueden no recibir respuesta dentro del plazo legal.',
          ),
        ],
      ),
    );
  }
}
