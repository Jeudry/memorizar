import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/ui/widgets.dart';
import '_legal_layout.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      child: LegalLayout(
        title: 'Comunidad',
        intro:
            'Memorizar es una comunidad para memorizar Escritura y otros contenidos juntos. Estas normas existen para que sea un espacio seguro y útil.',
        sections: const [
          LegalSection(
            heading: 'Qué SÍ aporta',
            body:
                '• Mazos bien curados: referencias correctas, sin errores de transcripción.\n'
                '• Estudios temáticos, devocionales, vocabulario, fórmulas, fechas históricas.\n'
                '• Comentarios constructivos sobre mazos de otros.\n'
                '• Reportar contenido que claramente viole estas normas.',
          ),
          LegalSection(
            heading: 'Qué NO está permitido',
            body:
                '• Distribuir versiones de la Biblia bajo copyright copiándolas a un mazo público (RV1960, NBLA, NVI, etc.). Usa el modo de versión vía API.\n'
                '• Acoso, amenazas, discurso de odio, o ataques personales.\n'
                '• Contenido sexual explícito o gráfico.\n'
                '• Contenido que dañe o ponga en riesgo a menores.\n'
                '• Spam, links maliciosos, esquemas de monetización ajenos a la app.\n'
                '• Suplantación de identidad de líderes religiosos, marcas o personas reales.\n'
                '• Doctrinas que inciten violencia o discriminación.',
          ),
          LegalSection(
            heading: 'Sobre desacuerdos doctrinales',
            body:
                'Diferentes tradiciones cristianas tienen interpretaciones distintas. Comentarios y mazos pueden reflejar una postura específica sin que eso signifique que se "ataque" a otra. La diferencia teológica no es motivo de retiro. Sí lo es el insulto, la calumnia o la deshumanización del que piensa distinto.',
          ),
          LegalSection(
            heading: 'Cómo reportar',
            body:
                'Cualquier mazo público tiene un botón "Reportar" (ícono de bandera). Selecciona la razón que mejor describe el problema y, opcionalmente, agrega una nota. El equipo de moderación revisa todo reporte en máximo 72 horas.',
          ),
          LegalSection(
            heading: 'Qué pasa cuando reportas',
            body:
                '1. El mazo queda con visibilidad reducida mientras se revisa.\n'
                '2. Moderación decide: mantener, ajustar (ej. reclasificar como privado) o retirar.\n'
                '3. Tanto el reportante como el creador reciben notificación de la decisión.\n'
                '4. Reportar de mala fe (spam de reportes) puede limitar tu cuenta.',
          ),
          LegalSection(
            heading: 'Sanciones',
            body:
                'Para cuentas que violan estas normas, las sanciones escalan:\n'
                '• Primera vez: aviso + retiro del contenido.\n'
                '• Segunda vez: suspensión de creación pública por 30 días.\n'
                '• Tercera vez: suspensión permanente de la cuenta.\n\n'
                'Casos graves (contenido ilegal, amenazas, daño a menores) saltan directo a suspensión permanente y, si aplica, reporte a autoridades.',
          ),
          LegalSection(
            heading: 'Apelaciones',
            body:
                'Si crees que tu contenido o cuenta fue sancionado por error, escríbenos a moderation@memorizar.app con la URL del contenido y tu explicación. Revisamos apelaciones en 5 días hábiles.',
          ),
        ],
      ),
    );
  }
}
