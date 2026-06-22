/// Punto de entrada de pantallas. Se descompone en `part` files
/// dentro de `screens/` para mantener navegación legible sin perder
/// visibilidad de los muchos widgets privados compartidos.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'package:file_selector/file_selector.dart';
import '../../../core/api/models.dart';
import '../../../core/app_state.dart';
import '../../../core/import/csv_import.dart';
import 'screens/coop_recap_share.dart';
import 'screens/practice_choose_word_screen.dart';
import 'screens/deck_csv_export.dart';
import 'screens/deck_rating_sheet.dart';
import 'screens/deck_comments_sheet.dart';
import 'exercise_logic.dart';
import '../../../core/services/local_llm_service.dart';
import '../../../core/srs_forecast.dart';
import '../../../core/services/ai_quiz_models.dart';
import '../../account/presentation/account_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/password_reset_screen.dart';
import '../../auth/presentation/verify_email_screen.dart';
import '../../cooperativo/data/coop_service.dart';
import '../../share_inbox/presentation/share_inbox_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../legal/presentation/community_guidelines_screen.dart';
import '../../legal/presentation/dmca_screen.dart';
import '../../legal/presentation/legal_menu_screen.dart';
import '../../legal/presentation/privacy_policy_screen.dart';
import '../../legal/presentation/terms_of_service_screen.dart';
import '../../legal/presentation/visibility_consent_dialog.dart';
import '../../moderation/presentation/moderation_queue_screen.dart';
import '../../moderation/presentation/report_dialog.dart';
import '../../settings/presentation/settings_screen.dart';
import 'glyph_icon.dart';
import '../../plans/presentation/plans_screen.dart';

// Imports for the extracted shared building blocks.
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';
import '../../../core/ui/main_tab_shell.dart';
import '../../../core/services/whisper_service.dart';
import 'screens/intruder_words_step.dart';

part 'screens/biblia_screen.dart';
part 'screens/especificar_screen.dart';
part 'screens/iniciar_screen.dart';
part 'screens/repasar_screen.dart';
part 'screens/comunidad_screen.dart';
part 'screens/amigos_screen.dart';
part 'screens/stats_screen.dart';
part 'screens/cooperativo_screen.dart';
part 'screens/real_exercise_flow.dart';
part 'screens/review_screens.dart';
part 'screens/flashcards_screen.dart';
part 'screens/ejercicios_screen.dart';
part 'screens/progress_tree_screen.dart';
part 'screens/fog_step.dart';
part 'screens/exercise_flow_screens.dart';
part 'screens/exercise_review_widgets.dart';
part 'screens/exercise_voice_widgets.dart';
part 'screens/exercise_step_widgets.dart';


// Bible book data — used by BibliaScreen below. Kept here until the bible
// feature is extracted to its own folder.
class _BibleBook {
  final String name;
  final int chapters;

  const _BibleBook(this.name, this.chapters);
}

const _oldTestamentBooks = [
  _BibleBook('Gén', 50),
  _BibleBook('Éxo', 40),
  _BibleBook('Lev', 27),
  _BibleBook('Núm', 36),
  _BibleBook('Deut', 34),
  _BibleBook('Jos', 24),
  _BibleBook('Jue', 21),
  _BibleBook('Rut', 4),
  _BibleBook('1Sam', 31),
  _BibleBook('2Sam', 24),
  _BibleBook('1Re', 22),
  _BibleBook('2Re', 25),
  _BibleBook('1Cr', 29),
  _BibleBook('2Cr', 36),
  _BibleBook('Esd', 10),
  _BibleBook('Neh', 13),
  _BibleBook('Est', 10),
  _BibleBook('Job', 42),
  _BibleBook('Salmos', 150),
  _BibleBook('Prov', 31),
  _BibleBook('Ecl', 12),
  _BibleBook('Cant', 8),
  _BibleBook('Isa', 66),
  _BibleBook('Jer', 52),
  _BibleBook('Lam', 5),
  _BibleBook('Eze', 48),
  _BibleBook('Dan', 12),
  _BibleBook('Ose', 14),
  _BibleBook('Joel', 3),
  _BibleBook('Amós', 9),
  _BibleBook('Abd', 1),
  _BibleBook('Jon', 4),
  _BibleBook('Miq', 7),
  _BibleBook('Nah', 3),
  _BibleBook('Hab', 3),
  _BibleBook('Sof', 3),
  _BibleBook('Hag', 2),
  _BibleBook('Zac', 14),
  _BibleBook('Mal', 4),
];

const _newTestamentBooks = [
  _BibleBook('Mat', 28),
  _BibleBook('Mar', 16),
  _BibleBook('Luc', 24),
  _BibleBook('Juan', 21),
  _BibleBook('Hech', 28),
  _BibleBook('Rom', 16),
  _BibleBook('1Cor', 16),
  _BibleBook('2Cor', 13),
  _BibleBook('Gál', 6),
  _BibleBook('Ef', 6),
  _BibleBook('Fil', 4),
  _BibleBook('Col', 4),
  _BibleBook('1Tes', 5),
  _BibleBook('2Tes', 3),
  _BibleBook('1Tim', 6),
  _BibleBook('2Tim', 4),
  _BibleBook('Tit', 3),
  _BibleBook('Flm', 1),
  _BibleBook('Heb', 13),
  _BibleBook('Stg', 5),
  _BibleBook('1Pe', 5),
  _BibleBook('2Pe', 3),
  _BibleBook('1Jn', 5),
  _BibleBook('2Jn', 1),
  _BibleBook('3Jn', 1),
  _BibleBook('Jud', 1),
  _BibleBook('Apoc', 22),
];

int _chapterCountFor(String book) {
  for (final item in [..._oldTestamentBooks, ..._newTestamentBooks]) {
    if (item.name == book) return item.chapters;
  }
  return 1;
}

/// Master route → builder map. Kept in this file (rather than core/router/)
/// because it references every feature screen, all of which still live here.
/// Once each feature lives in its own folder this can move.
Map<String, WidgetBuilder> buildAppRoutes() => {
  AppRoutes.home: (_) => const MainTabShell(initialRoute: AppRoutes.home),
  AppRoutes.bgNocturnoMate: (_) =>
      const MainTabShell(initialRoute: AppRoutes.bgNocturnoMate),
  AppRoutes.bgVinoAhumado: (_) =>
      const MainTabShell(initialRoute: AppRoutes.bgVinoAhumado),
  AppRoutes.bgTintaProfunda: (_) =>
      const MainTabShell(initialRoute: AppRoutes.bgTintaProfunda),
  AppRoutes.bgBrasaSuave: (_) =>
      const MainTabShell(initialRoute: AppRoutes.bgBrasaSuave),
  AppRoutes.bgCarbonAmbar: (_) =>
      const MainTabShell(initialRoute: AppRoutes.bgCarbonAmbar),
  AppRoutes.bgCiruelaTostada: (_) =>
      const MainTabShell(initialRoute: AppRoutes.bgCiruelaTostada),
  AppRoutes.bgPetroleoDorado: (_) =>
      const MainTabShell(initialRoute: AppRoutes.bgPetroleoDorado),
  AppRoutes.bgNaranjaNocturno: (_) =>
      const MainTabShell(initialRoute: AppRoutes.bgNaranjaNocturno),
  AppRoutes.bgActualSuave: (_) =>
      const MainTabShell(initialRoute: AppRoutes.bgActualSuave),
  AppRoutes.biblia: (_) => const BibliaScreen(),
  AppRoutes.especificar: (_) => const EspecificarScreen(),
  AppRoutes.iniciar: (_) => const IniciarScreen(),
  AppRoutes.repasar: (_) => const MainTabShell(initialRoute: AppRoutes.repasar),
  AppRoutes.comunidad: (_) => const MainTabShell(initialRoute: AppRoutes.comunidad),
  AppRoutes.amigos: (_) => const MainTabShell(initialRoute: AppRoutes.amigos),
  AppRoutes.stats: (_) => const MainTabShell(initialRoute: AppRoutes.stats),
  AppRoutes.cooperativo: (_) => const CooperativoScreen(),
  AppRoutes.cooperativoJuego: (_) => const CooperativoGameScreen(),
  AppRoutes.cooperativoLogrado: (_) => const CooperativoSuccessScreen(),
  AppRoutes.ejercicios: (_) => ExerciseFlowScreen(data: flowScreens.first),
  AppRoutes.flashcards: (_) => const FlashcardsScreen(),
  AppRoutes.premium: (_) => const PremiumScreen(),
  AppRoutes.planes: (_) => const PlansScreen(),
  '${AppRoutes.flow}/progress-tree': (_) => const _ProgressTreeScreen(),
  for (final screen in flowScreens)
    '${AppRoutes.flow}/${screen.slug}': (_) => ExerciseFlowScreen(data: screen),
  AppRoutes.legalMenu: (_) => const LegalMenuScreen(),
  AppRoutes.legalTerms: (_) => const TermsOfServiceScreen(),
  AppRoutes.legalPrivacy: (_) => const PrivacyPolicyScreen(),
  AppRoutes.legalDmca: (_) => const DmcaScreen(),
  AppRoutes.legalCommunity: (_) => const CommunityGuidelinesScreen(),
  AppRoutes.moderationQueue: (_) => const ModerationQueueScreen(),
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.account: (_) => const AccountScreen(),
  AppRoutes.settings: (_) => const SettingsScreen(),
  AppRoutes.shareInbox: (_) => const ShareInboxScreen(),
  AppRoutes.notificaciones: (_) => const NotificationsScreen(),
  AppRoutes.verifyEmail: (_) => const VerifyEmailScreen(),
  AppRoutes.passwordReset: (_) => const PasswordResetScreen(),
};

class ExerciseFlowData {
  final String slug;
  final String title;
  final String subtitle;

  const ExerciseFlowData(this.slug, this.title, this.subtitle);
}

const flowScreens = [
  ExerciseFlowData('00-solo-lectura', 'Solo lectura', 'Lee el texto con atención'),
  ExerciseFlowData('01-escuchar', 'Escuchar', 'Primero absorbe la idea'),
  ExerciseFlowData('02-lectura-frag', 'Lectura fragmentada', 'Divide y repite'),
  ExerciseFlowData('02-niebla-n1', 'Niebla N1', 'Recita mientras se nubla un poco'),
  ExerciseFlowData('03-leer-voz', 'Leer en voz', 'Activa memoria auditiva'),
  ExerciseFlowData('04-escuchar-voz', 'Escuchar voz', 'Reconoce sin mirar'),
  ExerciseFlowData('05-bloques', 'Bloques', 'Ordena piezas clave'),
  ExerciseFlowData(
    _chooseWordPracticeSlug,
    'Elige la palabra Práctica',
    'Elige la palabra, sin presión',
  ),
  ExerciseFlowData('06-completar-n1', 'Elige la palabra · N1', 'Recuerdo con apoyo'),
  ExerciseFlowData(
    '07-primera-letra-n1',
    'Primera letra N1',
    'Menos pistas, más memoria',
  ),
  ExerciseFlowData('17-niebla-n2', 'Niebla N2', 'Recitación con difuminado medio'),
  ExerciseFlowData('10-completar-n2', 'Elige la palabra · N2', 'Recuerdo más fuerte'),
  ExerciseFlowData('11-primera-letra-n2', 'Primera letra N2', 'Casi sin ayuda'),
  ExerciseFlowData('09-quiz', 'Quiz', 'Elige la respuesta correcta'),
  ExerciseFlowData('18-palabras-intrusas', 'Palabras intrusas', 'Identifica alteraciones de la IA'),
  // El flujo real usa las variantes por nivel (-n1/-n2/-n3); sin estas entradas
  // sus rutas no se registran y al tocarlas en el árbol de progreso "no pasa
  // nada" (generateRoute no encuentra el builder y devuelve null).
  ExerciseFlowData('18-palabras-intrusas-n1', 'Palabras intrusas N1', 'Identifica alteraciones de la IA'),
  ExerciseFlowData('18-palabras-intrusas-n2', 'Palabras intrusas N2', 'Identifica alteraciones de la IA'),
  ExerciseFlowData('18-palabras-intrusas-n3', 'Palabras intrusas N3', 'Identifica alteraciones de la IA'),
  ExerciseFlowData('12-completar-n3', 'Elige la palabra · N3', 'Más huecos visibles'),
  ExerciseFlowData(
    '13-primera-letra-n3',
    'Iniciales N3',
    'Todas las pistas ocultas',
  ),
  ExerciseFlowData(
    '15-banco-completo',
    'Banco completo',
    'Vacía el banco eligiendo bien',
  ),
  ExerciseFlowData(
    '16-niebla',
    'Niebla',
    'Recita mientras se nubla más',
  ),
  ExerciseFlowData(
    '16-niebla-n3',
    'Niebla N3',
    'Recitación con difuminado denso',
  ),
  ExerciseFlowData('14-voz-final', 'Voz final', 'Demuestra dominio'),
  ExerciseFlowData('mini-review', 'Mini review', 'Cierre rápido'),
  ExerciseFlowData('final-review', 'Review final', 'Resumen de sesión'),
];

class ExerciseFlowScreen extends StatelessWidget {
  final ExerciseFlowData data;

  const ExerciseFlowScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.slug == '09-quiz' || data.slug.startsWith('18-palabras-intrusas')) {
      final store = AppScope.of(context);
      final llmService = LocalLlmService.instance;
      if (!store.isPremium) {
        return const PremiumScreen();
      }
      return FutureBuilder<bool>(
        future: llmService.isAvailable(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: RefColors.cyan),
              ),
            );
          }
          final available = snapshot.data ?? false;
          if (!available) {
            return const PremiumScreen();
          }
          if (!llmService.isReady) {
            llmService.initLlm().catchError((e) => debugPrint('Error auto-init LLM: $e'));
          }
          return _RealExerciseFlowScreen(data: data);
        },
      );
    }
    return _RealExerciseFlowScreen(data: data);
  }
}

Future<bool> _showExitConfirmationDialog(BuildContext context) async {
  final isHost = CoopService.activeUserId == CoopService.active?.state?.hostId;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0F0C1B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isHost ? '¿Cancelar partida?' : '¿Salir de la sala?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
      content: Text(
        isHost 
            ? 'Como eres el HOST, al salir cerrarás la sala y se cancelará la partida para todos los participantes.'
            : '¿Estás seguro de que quieres abandonar la partida en curso?',
        style: const TextStyle(color: RefColors.dim, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar', style: TextStyle(color: RefColors.muted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: RefColors.urgent),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Salir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  return result ?? false;
}

