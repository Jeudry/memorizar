import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/ui/widgets.dart';
import '_legal_layout.dart';

/// Términos y condiciones de uso. Texto base — abogado debe revisarlo antes de
/// publicación. Mantenemos este contenido en el binario para que esté siempre
/// disponible sin red.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      child: LegalLayout(
        title: 'Términos de Uso',
        sections: const [
          LegalSection(
            heading: '1. Aceptación',
            body:
                'Al usar Memorizar aceptas estos términos. Si no estás de acuerdo, no uses la app.',
          ),
          LegalSection(
            heading: '2. Tu cuenta',
            body:
                'Eres responsable de mantener segura la información de acceso a tu cuenta. '
                'No compartas credenciales con terceros. Memorizar no puede recuperar contraseñas perdidas si pierdes acceso al método de autenticación.',
          ),
          LegalSection(
            heading: '3. Contenido que tú creas o pegas',
            body:
                'Cuando pegas, escribes o subes contenido a Memorizar (textos, mazos, audios), declaras que:\n'
                '• Eres dueño del contenido o tienes permiso explícito del titular para usarlo y, si corresponde, para compartirlo.\n'
                '• El contenido no infringe derechos de autor, marcas registradas, privacidad ni dignidad de terceros.\n'
                '• Memorizar puede almacenar ese contenido únicamente para que TÚ lo uses dentro de tu cuenta.\n\n'
                'Tú conservas la propiedad de tu contenido. Memorizar no reclama derechos sobre él.',
          ),
          LegalSection(
            heading: '4. Contenido compartido públicamente',
            body:
                'Si decides hacer público un mazo o compartirlo con amigos:\n'
                '• Garantizas tener los derechos necesarios para esa redistribución.\n'
                '• Aceptas que Memorizar puede mostrar ese contenido a otros usuarios y, si lo retiras, copias en caché en sus dispositivos pueden persistir un tiempo razonable.\n'
                '• Memorizar puede retirar contenido reportado o que viole estos términos en cualquier momento, sin aviso previo.',
          ),
          LegalSection(
            heading: '5. Versiones bíblicas',
            body:
                'La Reina-Valera 1909 viene incluida bajo dominio público.\n'
                'Las versiones modernas (RV1960, NBLA, NVI, etc.) se obtienen vía API de terceros con licencia. '
                'Memorizar muestra esas versiones únicamente bajo los términos de esos titulares y no permite descargar/cachear permanentemente su contenido.',
          ),
          LegalSection(
            heading: '6. Uso prohibido',
            body:
                'Está prohibido usar Memorizar para:\n'
                '• Distribuir contenido protegido sin licencia.\n'
                '• Acoso, discurso de odio, contenido sexual, contenido que dañe a menores.\n'
                '• Spam, fraude, suplantación de identidad.\n'
                '• Ingeniería inversa o ataques al servicio.\n\n'
                'El incumplimiento puede resultar en suspensión inmediata de la cuenta.',
          ),
          LegalSection(
            heading: '7. Sin garantías',
            body:
                'Memorizar se ofrece "tal como está". No garantizamos disponibilidad continua, exactitud de los textos bíblicos provistos por terceros, ni que la app cumpla expectativas específicas. El uso es bajo tu propio riesgo.',
          ),
          LegalSection(
            heading: '8. Cambios',
            body:
                'Podemos actualizar estos términos. Si el cambio es material te avisaremos en la app. Continuar usando Memorizar después del cambio significa que aceptas la nueva versión.',
          ),
          LegalSection(
            heading: '9. Contacto',
            body:
                'Para preguntas sobre estos términos: legal@memorizar.app\n'
                'Para reclamos de copyright, ver la sección DMCA / Copyright en este menú.',
          ),
        ],
      ),
    );
  }
}
