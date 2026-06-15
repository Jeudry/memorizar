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
import 'exercise_logic.dart';
import '../../../core/services/local_llm_service.dart';
import '../../../core/services/ai_quiz_models.dart';
import '../../account/presentation/account_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/password_reset_screen.dart';
import '../../auth/presentation/verify_email_screen.dart';
import '../../cooperativo/data/coop_service.dart';
import '../../share_inbox/presentation/share_inbox_screen.dart';
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

part 'screens/biblia_screen.dart';
part 'screens/especificar_screen.dart';
part 'screens/iniciar_screen.dart';
part 'screens/repasar_screen.dart';
part 'screens/comunidad_screen.dart';
part 'screens/amigos_screen.dart';
part 'screens/stats_screen.dart';
part 'screens/cooperativo_screen.dart';
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
  AppRoutes.practicaElegirPalabra: (_) => const PracticeChooseWordScreen(),
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.account: (_) => const AccountScreen(),
  AppRoutes.settings: (_) => const SettingsScreen(),
  AppRoutes.shareInbox: (_) => const ShareInboxScreen(),
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
  ExerciseFlowData('09-quiz-avanzado', 'Quiz Avanzado', 'Desafía tu teología con IA de razonamiento'),
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
    if (data.slug == '09-quiz-avanzado') {
      final store = AppScope.of(context);
      if (!store.isPremium) {
        return const PremiumScreen();
      }
      return _RealExerciseFlowScreen(data: data);
    }
    if (data.slug == '09-quiz') {
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

class _RealExerciseFlowScreen extends StatefulWidget {
  final ExerciseFlowData data;

  const _RealExerciseFlowScreen({required this.data});

  @override
  State<_RealExerciseFlowScreen> createState() =>
      _RealExerciseFlowScreenState();
}

/// Selección múltiple que reemplaza un ejercicio de micrófono omitido (F2):
/// "¿Cuál es el texto de X?" con el texto correcto + 3 distractores random de
/// otras tarjetas. Al acertar avanza; al fallar permite reintentar.
class _OmitSelectExercise extends StatefulWidget {
  final MemoryCardData card;
  final MemoryDeckData deck;
  final VoidCallback onCorrect;

  const _OmitSelectExercise({
    super.key,
    required this.card,
    required this.deck,
    required this.onCorrect,
  });

  @override
  State<_OmitSelectExercise> createState() => _OmitSelectExerciseState();
}

class _OmitSelectExerciseState extends State<_OmitSelectExercise> {
  late final List<String> _options;
  int? _wrongIndex;

  @override
  void initState() {
    super.initState();
    final correct = widget.card.back;
    final distractors = widget.deck.cards
        .where((c) => c.id != widget.card.id && c.back.trim().isNotEmpty)
        .map((c) => c.back)
        .toList()
      ..shuffle();
    final picked = distractors.take(3).toList();
    var n = 1;
    while (picked.length < 3) {
      picked.add('${_firstWords(correct, 3)}… (opción ${n++})');
    }
    _options = [correct, ...picked]..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final correct = widget.card.back;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          padding: const EdgeInsets.all(16),
          color: RefColors.glassStrong,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OMITIDO → ELIGE LA RESPUESTA',
                  style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3)),
              const SizedBox(height: 8),
              Text(
                '¿Cuál es el texto de ${widget.card.front}?',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, height: 1.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _options.length; i++) ...[
          GestureDetector(
            onTap: () {
              if (_options[i] == correct) {
                widget.onCorrect();
              } else {
                setState(() => _wrongIndex = i);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _wrongIndex == i
                    ? RefColors.urgent.withValues(alpha: .12)
                    : RefColors.glassSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _wrongIndex == i ? RefColors.urgent : RefColors.border,
                ),
              ),
              child: Row(
                children: [
                  Text(String.fromCharCode(65 + i),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: RefColors.cyan)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _options[i],
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_wrongIndex != null)
          const Text(
            'Esa no es. Intenta con otra.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: RefColors.urgent,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

enum _QuizQuestionType { frontToBack, backToFront, trueFalse, matching, openQuestion }

class _QuizRound {
  final MemoryCardData target;
  final _QuizQuestionType type;
  final List<MemoryCardData> options;
  
  // True/False extra fields
  final String? trueFalseStatement;
  final bool? isStatementTrue;

  // Matching extra fields
  // (nunca se pasa por constructor en el flujo actual; siempre null)
  final List<(String, String)>? matchingPairs = null;

  // Open question extra fields
  final String? openQuestionPrompt;
  // Se asigna en runtime (round.openQuestionResponse = val), no por constructor.
  String? openQuestionResponse;

  int? selectedIdx;

  _QuizRound({
    required this.target,
    required this.type,
    required this.options,
    this.trueFalseStatement,
    this.isStatementTrue,
    this.openQuestionPrompt,
  });

  bool get answered => selectedIdx != null;
  bool get correct {
    if (selectedIdx == null) return false;
    if (type == _QuizQuestionType.trueFalse) {
      return selectedIdx == (isStatementTrue == true ? 0 : 1);
    }
    if (type == _QuizQuestionType.matching || type == _QuizQuestionType.openQuestion) {
      return true; // completed matching or submitted typed answer are always considered correct/passed in study mode
    }
    return options[selectedIdx!].id == target.id;
  }
}

class _RealExerciseFlowScreenState extends State<_RealExerciseFlowScreen> {
  bool _checked = false;
  int _fragmentVisibleWords = 8;
  int _soloLecturaVisibleChars = 0;
  Timer? _soloLecturaTimer;
  DateTime? _soloLecturaPauseUntil;
  String? _blockOrderCardId;
  List<int> _blockOrderIndexes = [];
  int? _selectedBlockPosition;
  String? _completionCardId;
  int _completionLevel = 1;
  List<String> _completionTargets = [];
  List<String?> _completionAnswers = [];
  int _activeCompletionIndex = 0;
  int _completionMistakes = 0;
  int _completionSeed = 1;
  Timer? _completionTimer;
  int _completionSecondsLeft = 0;
  bool _completionLost = false;
  /// Pool de distractores tramposos generado por la IA local para el ejercicio
  /// "Elige la palabra correcta". Si está vacío/null, el banco cae a palabras
  /// random del versículo (comportamiento clásico / fallback sin IA).
  List<String>? _aiDistractorPool;
  String? _aiDistractorCardId;
  bool _aiDistractorLoading = false;
  /// Pasos que el usuario "omitió": en vez de saltarlos, se transforman —
  /// los de micrófono en una selección múltiple, el resto en una lectura.
  /// La clave incluye la tarjeta para que el override sea per-tarjeta.
  final Set<String> _omitOverride = {};

  bool _isMicSlug(String slug) => isMicSlug(slug);
  String? _letterCardId;
  int _letterLevel = 1;
  List<String> _letterTargets = [];
  List<int> _letterTargetPositions = [];
  List<String?> _letterAnswers = [];
  int _activeLetterIndex = 0;
  int _letterMistakes = 0;
  Timer? _letterTimer;
  int _letterSecondsLeft = 0;
  bool _letterLost = false;

  String? _quizCardId;
  List<_QuizRound> _quizRounds = [];
  int _quizRoundIndex = 0;
  int _quizScore = 0;
  bool _isEvaluatingOpenQuestion = false;
  final _openQuestionController = TextEditingController();
  
  bool _isAiQuizLoading = false;
  String _aiQuizLoadingText = '';
  String? _aiQuizError;

  String? _matchingSelectedLeft;
  String? _matchingSelectedRight;
  final Set<String> _matchingCompletedLeft = {};
  final Set<String> _matchingCompletedRight = {};
  List<String> _matchingLeftShuffled = [];
  List<String> _matchingRightShuffled = [];

  String? _bankCardId;
  List<String> _bankTargets = [];
  List<String?> _bankAnswers = [];
  List<_BankWord> _bankAvailable = [];
  final Set<String> _bankRemoving = <String>{};
  int _bankActiveIndex = 0;
  int _bankMistakes = 0;
  int _bankPartIndex = 0;
  static const int _bankPartSize = 10;
  static const int _bankSplitThreshold = 15;

  // Shared timestamp for the most recent wrong attempt across non-voice
  // exercises (bank/letter/completion). Used to drive a red-flash effect.
  int? _lastNonVoiceWrongAt;
  void _flagNonVoiceWrong() {
    _lastNonVoiceWrongAt = DateTime.now().millisecondsSinceEpoch;
    final coop = CoopService.active;
    if (coop != null) {
      final mode = coop.state?.mode ?? 'turnos';
      if (mode == 'libre') {
        _startCooldown();
      } else if (mode == 'turnos') {
        _broadcastFail();
        setState(() {
          _failedUserIds.add(CoopService.activeUserId ?? '');
        });
      }
    }
  }
  bool _nonVoiceWrongRecent() {
    final ts = _lastNonVoiceWrongAt;
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < 700;
  }

  bool _coopEverHadPeers = false;

  void _closeCoopAndGoHome(String message) async {
    await CoopService.active?.disconnect();
    CoopService.active = null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: RefColors.urgent,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    }
  }

  String? _fogCardId;
  bool _fogFinished = false;
  final bool _fogShowHintTemp = false;
  StreamSubscription<CoopRoomState>? _coopStateSub;
  StreamSubscription<CoopMessage>? _coopMsgSub;
  final Set<String> _failedUserIds = {};
  int _cooldownSecondsLeft = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    final coop = CoopService.active;
    if (coop != null) {
      _coopStateSub = coop.stateStream.listen((s) {
        if (!mounted) return;

        // Si el host abandonó la partida, cancelar y volver al home
        final hostLeft = !s.memberIds.contains(s.hostId);
        if (hostLeft) {
          _closeCoopAndGoHome('La partida cooperativa ha sido cancelada por el Host.');
          return;
        }

        // Una vez vimos 2+ jugadores, si la sala baja a 1 se cierra para todos.
        if (s.memberIds.length >= 2) _coopEverHadPeers = true;
        if (_coopEverHadPeers && s.memberIds.length <= 1) {
          _closeCoopAndGoHome('La sala se cerró: no quedan suficientes jugadores.');
          return;
        }

        final store = AppScope.of(context);

        if (s.currentCardIndex != store.sessionCardsCompleted) {
          store.setSessionCardsCompleted(s.currentCardIndex);
          setState(() {
            _failedUserIds.clear();
            _cooldownSecondsLeft = 0;
            _cooldownTimer?.cancel();
            _cooldownTimer = null;
          });
        }
      });

      _coopMsgSub = coop.messages.listen((msg) {
        if (!mounted) return;
        if (msg.type == 'room_closed') {
          if (msg.userId != CoopService.activeUserId) {
            _closeCoopAndGoHome('El host cerró la sala.');
          }
          return;
        } else if (msg.type == 'step_done') {
          final key = msg.payload?['key'] as String?;
          if (key != null && key.isNotEmpty && msg.userId != CoopService.activeUserId) {
            AppScope.of(context).applyRemoteStepDone(key);
          }
          return;
        } else if (msg.type == 'coop_fail') {
          final failedUserId = msg.payload?['userId'] as String? ?? msg.userId;
          if (failedUserId.isNotEmpty) {
            setState(() {
              _failedUserIds.add(failedUserId);
            });
          }
        } else if (msg.type == 'card') {
          final senderId = msg.userId;
          final slug = msg.payload?['slug'] as String? ?? '';
          final currentSlug = widget.data.slug;
          if (senderId != CoopService.activeUserId && slug.isNotEmpty && slug != currentSlug) {
            setState(() {
              _failedUserIds.clear();
              _cooldownSecondsLeft = 0;
              _cooldownTimer?.cancel();
              _cooldownTimer = null;
            });
            Navigator.pushReplacementNamed(context, '${AppRoutes.flow}/$slug');
          }
        }
      });
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _completionCardId = null;
    _letterCardId = null;
  }

  @override
  void dispose() {
    _coopStateSub?.cancel();
    _coopMsgSub?.cancel();
    _cooldownTimer?.cancel();
    _soloLecturaTimer?.cancel();
    _completionTimer?.cancel();
    _letterTimer?.cancel();
    _openQuestionController.dispose();
    super.dispose();
  }

  /// Seconds-per-target for timed levels. N3 is faster (less time per hueco).
  // Drastically increased for excellent accessibility (especially for elderly users).
  static const double _completionSecondsPerTargetN2 = 12.0;
  static const double _completionSecondsPerTargetN3 = 8.0;
  static const double _letterSecondsPerTargetN2 = 12.0;
  static const double _letterSecondsPerTargetN3 = 8.0;

  int _completionTimeFor(int level, int targetCount) {
    if (level <= 1 || targetCount <= 0) return 0;
    final perTarget = level >= 3
        ? _completionSecondsPerTargetN3
        : _completionSecondsPerTargetN2;
    final raw = (targetCount * perTarget).round();
    // Generous floor / ceiling boundaries for accessible and stress-free pacing.
    return raw.clamp(level >= 3 ? 60 : 90, 480);
  }

  int _letterTimeFor(int level, int targetCount) {
    if (level <= 1 || targetCount <= 0) return 0;
    final perTarget = level >= 3
        ? _letterSecondsPerTargetN3
        : _letterSecondsPerTargetN2;
    final raw = (targetCount * perTarget).round();
    return raw.clamp(level >= 3 ? 60 : 90, 480);
  }

  String _formatMmSs(int totalSeconds) {
    final s = totalSeconds.clamp(0, 9999);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  void _startCompletionTimer(int seconds) {
    _completionTimer?.cancel();
    _completionSecondsLeft = seconds;
    _completionLost = false;
    if (seconds <= 0) return;
    _completionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _completionSecondsLeft -= 1;
        if (_completionSecondsLeft <= 0) {
          _completionSecondsLeft = 0;
          _completionLost = true;
          timer.cancel();
        }
      });
    });
  }

  void _stopCompletionTimerOnSuccess() {
    if (_completionTimer != null) {
      _completionTimer!.cancel();
      _completionTimer = null;
    }
  }

  void _retryCompletion() {
    setState(() {
      _completionCardId = null;
      _completionLost = false;
    });
  }

  void _startLetterTimer(int seconds) {
    _letterTimer?.cancel();
    _letterSecondsLeft = seconds;
    _letterLost = false;
    if (seconds <= 0) return;
    _letterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _letterSecondsLeft -= 1;
        if (_letterSecondsLeft <= 0) {
          _letterSecondsLeft = 0;
          _letterLost = true;
          timer.cancel();
        }
      });
    });
  }

  void _stopLetterTimerOnSuccess() {
    if (_letterTimer != null) {
      _letterTimer!.cancel();
      _letterTimer = null;
    }
  }

  void _retryLetter() {
    setState(() {
      _letterCardId = null;
      _letterLost = false;
    });
  }

  void _ensureBankState(String cardId, String text) {
    if (_bankCardId == cardId) return;
    _bankCardId = cardId;
    _bankTargets = _studyWords(text);
    _bankAnswers = List<String?>.filled(_bankTargets.length, null);
    final cleanRegex = RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]');
    final cleanWords = _bankTargets
        .map((w) => w.replaceAll(cleanRegex, ''))
        .where((w) => w.isNotEmpty)
        .toList();
    final rng = math.Random(DateTime.now().microsecondsSinceEpoch);
    final tempAvailable = <_BankWord>[];
    for (var i = 0; i < cleanWords.length; i++) {
      tempAvailable.add(_BankWord(id: 'bank-el-$i', word: cleanWords[i]));
    }
    _bankAvailable = tempAvailable..shuffle(rng);
    _bankActiveIndex = 0;
    _bankMistakes = 0;
    _bankPartIndex = 0;
    _bankRemoving.clear();
    _checked = false;
  }

  bool _bankIsSplit() => _bankTargets.length > _bankSplitThreshold;

  int _bankPartCount() {
    if (!_bankIsSplit()) return 1;
    return ((_bankTargets.length + _bankPartSize - 1) ~/ _bankPartSize);
  }

  (int, int) _bankPartRange([int? part]) {
    final p = part ?? _bankPartIndex;
    if (!_bankIsSplit()) return (0, _bankTargets.length);
    final start = p * _bankPartSize;
    final end = ((p + 1) * _bankPartSize).clamp(0, _bankTargets.length);
    return (start, end);
  }

  bool _bankPartComplete([int? part]) {
    final (start, end) = _bankPartRange(part);
    if (end <= start) return false;
    for (var i = start; i < end; i++) {
      final answer = _bankAnswers[i];
      if (answer == null || !_sameAnswer(answer, _bankTargets[i])) return false;
    }
    return true;
  }

  bool _bankComplete() {
    if (_bankTargets.isEmpty) return false;
    for (var i = 0; i < _bankTargets.length; i++) {
      final answer = _bankAnswers[i];
      if (answer == null || !_sameAnswer(answer, _bankTargets[i])) return false;
    }
    return true;
  }

  void _selectBankWord(_BankWord word) {
    if (_bankTargets.isEmpty || _bankComplete()) return;
    if (_bankRemoving.contains(word.id)) return;
    final (partStart, partEnd) = _bankPartRange();
    // Clamp the active blank to the current part — if the active index drifted
    // to a later part, snap it back to the first unfilled blank in this part.
    var idx = _bankActiveIndex;
    if (idx < partStart || idx >= partEnd || _bankAnswers[idx] != null) {
      idx = -1;
      for (var i = partStart; i < partEnd; i++) {
        if (_bankAnswers[i] == null) {
          idx = i;
          break;
        }
      }
      if (idx == -1) return;
      _bankActiveIndex = idx;
    }
    final correct = _sameAnswer(word.word, _bankTargets[idx]);
    if (correct) {
      setState(() {
        _bankAnswers[idx] = word.word;
        _bankRemoving.add(word.id);
        // Find next unfilled blank inside the current part.
        var next = -1;
        for (var i = partStart; i < partEnd; i++) {
          if (_bankAnswers[i] == null) {
            next = i;
            break;
          }
        }
        if (next >= 0) _bankActiveIndex = next;
        HapticFeedback.lightImpact();
      });
      // Hold the chip in "removing" state long enough for the fade+shrink
      // animation to play, then drop it from the available list.
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        setState(() {
          _bankAvailable.removeWhere((w) => w.id == word.id);
          _bankRemoving.remove(word.id);
          if (_bankPartComplete()) {
            if (_bankPartIndex + 1 < _bankPartCount()) {
              // Advance to next part: highlight the next part's first blank.
              _bankPartIndex += 1;
              final (nextStart, _) = _bankPartRange();
              _bankActiveIndex = nextStart;
              HapticFeedback.lightImpact();
            } else {
              HapticFeedback.heavyImpact();
              _autoAdvanceBank();
            }
          }
        });
      });
    } else {
      setState(() {
        _bankMistakes += 1;
        _flagNonVoiceWrong();
        HapticFeedback.mediumImpact();
      });
      _scheduleFlashRebuild();
    }
  }

  void _scheduleFlashRebuild() {
    Future<void>.delayed(const Duration(milliseconds: 720), () {
      if (mounted) setState(() {});
    });
  }

  void _autoAdvanceBank() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = AppScope.of(context);
      _completeStepAndNavigate(context, store, '15-banco-completo');
    });
  }

  void _activateBankBlank(int index) {
    if (index < 0 || index >= _bankTargets.length) return;
    if (_bankAnswers[index] != null) return;
    final (partStart, partEnd) = _bankPartRange();
    if (index < partStart || index >= partEnd) return;
    setState(() => _bankActiveIndex = index);
  }

  void _ensureFogState(String cardId) {
    if (_fogCardId == cardId) return;
    _fogCardId = cardId;
    _fogFinished = false;
  }

  void _onFogRoundCompleted() {
    setState(() {
      _fogFinished = true;
      HapticFeedback.heavyImpact();
      final store = AppScope.of(context);
      store.markExerciseStepCompleted(widget.data.slug);
    });
  }

  void _revealFragment(String slug, int totalWords) {
    if (totalWords <= 0) return;
    setState(() {
      _fragmentVisibleWords = (_fragmentVisibleWords + 8).clamp(1, totalWords);
      if (_fragmentVisibleWords >= totalWords) {
        AppScope.of(context).markExerciseStepCompleted(slug);
      }
    });
  }

  bool _completionCorrect(String slug, MemoryCardData card) {
    _ensureCompletionState(card.id, card.back, _completionLevelForSlug(slug));
    return _completionComplete();
  }

  bool _letterCorrect(String slug, MemoryCardData card) {
    _ensureLetterState(card.id, card.back, _letterLevelForSlug(slug));
    return _letterComplete();
  }

  bool _hasCompletionInput() => _completionAnswers.any(
    (answer) => answer != null && answer.trim().isNotEmpty,
  );


  bool _quizCorrect(MemoryCardData card, MemoryDeckData deck) {
    if (_quizCardId != card.id || _quizRounds.isEmpty) return false;
    return _quizPassed;
  }

  /// Llamado al terminar el último paso (voz final). Notifica al store que
  /// la tarjeta actual quedó completa y decide a dónde ir según el target
  /// diario de la sesión: siguiente tarjeta o review final.
  void _completeSessionCard(
    BuildContext context,
    AppStore store, {
    required bool correct,
  }) {
    final keepGoing = store.advanceToNextSessionCard(correct: correct);
    // Sync best-effort: empuja snapshot al backend si hay sesión. No bloquea
    // la navegación.
    unawaited(store.pushProgressSnapshot());
    if (!mounted) return;
    
    if (CoopService.active != null) {
      if (keepGoing) {
        setState(() {
          _completionCardId = null;
          _letterCardId = null;
          _bankCardId = null;
          _fogCardId = null;
          _quizCardId = null;
          _blockOrderCardId = null;
          _checked = false;
        });
        
        final isHost = CoopService.active?.state?.hostId == CoopService.activeUserId;
        if (isHost) {
          final nextIndex = store.sessionCardsCompleted;
          CoopService.active!.updateLocalCardState(deckId: store.activeDeck.id, cardIndex: nextIndex, slug: '00-solo-lectura');
          CoopService.active!.broadcastCard(deckId: store.activeDeck.id, cardIndex: nextIndex, slug: '00-solo-lectura');
        }
        
        Navigator.pushNamedAndRemoveUntil(
          context,
          '${AppRoutes.flow}/00-solo-lectura',
          (route) => route.isFirst,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.cooperativoLogrado,
          (route) => route.isFirst,
        );
      }
    } else if (keepGoing) {
      // Reset estado UI per-tarjeta (banco, completar, niebla, etc.).
      setState(() {
        _completionCardId = null;
        _letterCardId = null;
        _bankCardId = null;
        _fogCardId = null;
        _quizCardId = null;
        _blockOrderCardId = null;
        _checked = false;
      });
      Navigator.pushNamedAndRemoveUntil(
        context,
        '${AppRoutes.flow}/progress-tree',
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1600),
          content: Text(
            'Tarjeta ${store.sessionCardsCompleted} de ${store.sessionDailyTarget} · siguiente',
          ),
        ),
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '${AppRoutes.flow}/final-review',
        (route) => route.isFirst,
      );
    }
  }

  void _navigateToNextStepOrComplete(BuildContext context, AppStore store, String slug) {
    final steps = _sessionFlowSteps(store);
    final isLastStep = steps.isNotEmpty && steps.last.slug == slug;
    if (isLastStep) {
      _completeSessionCard(context, store, correct: true);
    } else {
      Navigator.push(
        context,
        AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
      );
    }
  }

  void _completeStepAndNavigate(BuildContext context, AppStore store, String slug) {
    store.markExerciseStepCompleted(slug);
    _navigateToNextStepOrComplete(context, store, slug);
  }

  bool _canAdvanceAnsweredStep(
    String slug,
    MemoryCardData card,
    MemoryDeckData deck,
  ) {
    if (slug == '05-bloques') return _blocksAreCorrect();
    if (_isCompletionSlug(slug)) {
      return _completionCorrect(slug, card);
    }
    if (_isFirstLetterSlug(slug)) {
      return _letterCorrect(slug, card);
    }
    if (slug == '09-quiz' || slug == '09-quiz-avanzado') {
      if (_quizRounds.isEmpty) return false;
      if (!_quizFinished) {
        // Se avanza automáticamente de manera fluida, por lo que deshabilitamos el botón físico
        return false;
      }
      return true;
    }
    if (_isWordBankSlug(slug)) return _bankComplete();
    if (_isFogSlug(slug)) return _fogFinished;
    return true;
  }

  void _ensureBlockOrder(String cardId, List<String> blocks) {
    if (_blockOrderCardId == cardId &&
        _blockOrderIndexes.length == blocks.length) {
      return;
    }
    _blockOrderCardId = cardId;
    if (blocks.length < 2) {
      _blockOrderIndexes = List.generate(blocks.length, (index) => index);
    } else {
      final rng = math.Random();
      var shuffled = List<int>.generate(blocks.length, (i) => i);
      do {
        shuffled.shuffle(rng);
      } while (_isIdentity(shuffled));
      _blockOrderIndexes = shuffled;
    }
    _selectedBlockPosition = null;
    _checked = false;
  }

  bool _isIdentity(List<int> order) {
    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) return false;
    }
    return true;
  }

  void _moveBlock(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final movedIndex = _blockOrderIndexes.removeAt(oldIndex);
      _blockOrderIndexes.insert(newIndex, movedIndex);
      _selectedBlockPosition = null;
      _checked = true;
    });
  }

  void _toggleSelectedBlock(int index) {
    setState(() {
      _selectedBlockPosition = _selectedBlockPosition == index ? null : index;
    });
  }

  int _correctBlockCount() {
    var count = 0;
    for (var index = 0; index < _blockOrderIndexes.length; index++) {
      if (_blockOrderIndexes[index] == index) count += 1;
    }
    return count;
  }

  bool _blocksAreCorrect() {
    return _blockOrderIndexes.isNotEmpty &&
        _correctBlockCount() == _blockOrderIndexes.length;
  }

  void _ensureCompletionState(String cardId, String text, int level) {
    if (_completionCardId == cardId && _completionLevel == level) return;
    _completionCardId = cardId;
    _completionLevel = level;
    _completionTargets = _completionTargetsFor(text, level: level);
    _completionAnswers = List<String?>.filled(_completionTargets.length, null);
    _activeCompletionIndex = 0;
    _completionMistakes = 0;
    _completionSeed = DateTime.now().microsecondsSinceEpoch;
    _checked = false;
    final seconds = _completionTimeFor(level, _completionTargets.length);
    _startCompletionTimer(seconds);
  }

  /// Carga (una vez por tarjeta) el pool de distractores tramposos de la IA
  /// local para el ejercicio "Elige la palabra correcta". Si la IA no está
  /// disponible o falla, el banco se queda con palabras random del versículo.
  void _ensureAiDistractors(MemoryCardData card) {
    if (_aiDistractorCardId == card.id) return;
    _aiDistractorCardId = card.id;
    _aiDistractorPool = null;
    _aiDistractorLoading = false;
    final llm = LocalLlmService.instance;
    () async {
      final available = await llm.isAvailable();
      if (!available || !mounted || _aiDistractorCardId != card.id) return;
      setState(() => _aiDistractorLoading = true);
      try {
        if (!llm.isReady) await llm.initLlm();
        final pool = await llm.generateCompletionDistractors(
          reference: card.front,
          verseText: card.back,
        );
        if (!mounted || _aiDistractorCardId != card.id) return;
        setState(() {
          _aiDistractorPool = pool;
          _aiDistractorLoading = false;
        });
      } catch (e) {
        if (!mounted || _aiDistractorCardId != card.id) return;
        setState(() => _aiDistractorLoading = false);
        debugPrint('Distractores IA fallaron, usando random: $e');
      }
    }();
  }

  bool _completionComplete() {
    if (_completionTargets.isEmpty) return false;
    for (var index = 0; index < _completionTargets.length; index++) {
      final answer = _completionAnswers[index];
      if (answer == null || !_sameAnswer(answer, _completionTargets[index])) {
        return false;
      }
    }
    return true;
  }

  void _selectCompletionWord(String word) {
    if (_completionTargets.isEmpty || _completionComplete()) return;
    if (_completionLost) return;
    final currentIndex = _activeCompletionIndex.clamp(
      0,
      _completionTargets.length - 1,
    );
    final correct = _sameAnswer(word, _completionTargets[currentIndex]);
    setState(() {
      _checked = true;
      _completionSeed = DateTime.now().microsecondsSinceEpoch;
      if (correct) {
        _completionAnswers[currentIndex] = word;
        final nextIndex = _completionAnswers.indexWhere(
          (answer) => answer == null || answer.trim().isEmpty,
        );
        if (nextIndex >= 0) _activeCompletionIndex = nextIndex;
        if (_completionComplete()) _stopCompletionTimerOnSuccess();
      } else {
        _completionMistakes += 1;
        _flagNonVoiceWrong();
        HapticFeedback.mediumImpact();
      }
    });
    if (!correct) _scheduleFlashRebuild();
  }

  void _activateCompletionBlank(int index) {
    if (index < 0 || index >= _completionTargets.length) return;
    if (_completionAnswers[index] != null) return;
    setState(() => _activeCompletionIndex = index);
  }

  void _ensureLetterState(String cardId, String text, int level) {
    if (_letterCardId == cardId && _letterLevel == level) return;
    _letterCardId = cardId;
    _letterLevel = level;
    final (targets, positions) = _firstLetterTargetsWithPositions(text, level: level);
    _letterTargets = targets;
    _letterTargetPositions = positions;
    _letterAnswers = List<String?>.filled(_letterTargets.length, null);
    _activeLetterIndex = 0;
    _letterMistakes = 0;
    _checked = false;
    final seconds = _letterTimeFor(level, _letterTargets.length);
    _startLetterTimer(seconds);
  }

  bool _letterComplete() {
    if (_letterTargets.isEmpty) return false;
    for (var index = 0; index < _letterTargets.length; index++) {
      final answer = _letterAnswers[index];
      if (answer == null || !_sameAnswer(answer, _letterTargets[index])) {
        return false;
      }
    }
    return true;
  }

  void _selectFirstLetter(String letter) {
    if (_letterTargets.isEmpty || _letterComplete()) return;
    if (_letterLost) return;
    final currentIndex = _activeLetterIndex.clamp(0, _letterTargets.length - 1);
    final target = _letterTargets[currentIndex];
    final cleanTarget = target.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '');
    final firstLetter = cleanTarget.isNotEmpty ? cleanTarget.substring(0, 1) : '';
    final correct = _sameAnswer(letter, firstLetter);
    setState(() {
      _checked = true;
      if (correct) {
        _letterAnswers[currentIndex] = target;
        final nextIndex = _letterAnswers.indexWhere((answer) => answer == null);
        if (nextIndex >= 0) _activeLetterIndex = nextIndex;
        if (_letterComplete()) _stopLetterTimerOnSuccess();
      } else {
        _letterMistakes += 1;
        _flagNonVoiceWrong();
        HapticFeedback.mediumImpact();
      }
    });
    if (!correct) _scheduleFlashRebuild();
  }

  void _ensureQuizRounds(MemoryDeckData deck, MemoryCardData card) {
    final alreadyHandledCard = _quizCardId == card.id &&
        (_quizRounds.isNotEmpty || _isAiQuizLoading || _aiQuizError != null);
    if (alreadyHandledCard) return;
    // Se invoca durante build: mutar campos sin setState; el async sí lo usa.
    _quizCardId = card.id;
    _quizRoundIndex = 0;
    _quizScore = 0;
    _openQuestionController.clear();
    _quizRounds = [];
    _isAiQuizLoading = true;
    _aiQuizError = null;
    _aiQuizLoadingText = 'Despertando la IA local…';
    unawaited(_loadAiQuizRounds(
      card,
      advanced: widget.data.slug == '09-quiz-avanzado',
    ));
  }

  Future<void> _loadAiQuizRounds(
    MemoryCardData card, {
    required bool advanced,
  }) async {
    final llm = LocalLlmService.instance;
    void onEngineStatus() {
      if (!mounted || !_isAiQuizLoading) return;
      final status = llm.statusNotifier.value;
      if (status.isNotEmpty) {
        setState(() => _aiQuizLoadingText = status);
      }
    }

    llm.statusNotifier.addListener(onEngineStatus);
    try {
      await llm.initLlm();
      if (!mounted) return;
      setState(() {
        _aiQuizLoadingText = advanced
            ? 'Gemma 3 está razonando preguntas teológicas sobre ${card.front}…'
            : 'Gemma 3 está creando preguntas únicas sobre ${card.front}…';
      });
      final roundSet = await llm.generateQuizRoundSet(
        reference: card.front,
        verseText: card.back,
        advanced: advanced,
      );
      if (!mounted) return;
      setState(() {
        _quizRounds = _roundsFromAi(card, roundSet);
        _isAiQuizLoading = false;
      });
    } catch (e) {
      debugPrint('Error generando quiz con IA local: $e');
      if (!mounted) return;
      setState(() {
        _isAiQuizLoading = false;
        _aiQuizError =
            'La IA local no pudo generar las preguntas. Verifica que el '
            'modelo esté descargado y vuelve a intentarlo.';
      });
    } finally {
      llm.statusNotifier.removeListener(onEngineStatus);
    }
  }

  List<_QuizRound> _roundsFromAi(MemoryCardData card, AiQuizRoundSet set) {
    final trueFalseRound = _QuizRound(
      target: card,
      type: _QuizQuestionType.trueFalse,
      options: const [],
      trueFalseStatement: set.trueFalse.statement,
      isStatementTrue: set.trueFalse.isTrue,
    );

    final multipleChoice = set.multipleChoice;
    final correctCard = MemoryCardData(
      id: 'quiz-ai-mc-${card.id}',
      front: multipleChoice.question,
      back: multipleChoice.correct,
      source: card.source,
      icon: card.icon,
    );
    final optionCards = <MemoryCardData>[
      correctCard,
      for (var idx = 0; idx < multipleChoice.distractors.length; idx++)
        MemoryCardData(
          id: 'quiz-ai-mc-distractor-$idx-${card.id}',
          front: multipleChoice.question,
          back: multipleChoice.distractors[idx],
          source: 'IA local',
          icon: card.icon,
        ),
    ]..shuffle();
    final multipleChoiceRound = _QuizRound(
      target: correctCard,
      type: _QuizQuestionType.frontToBack,
      options: optionCards,
    );

    final openRound = _QuizRound(
      target: card,
      type: _QuizQuestionType.openQuestion,
      options: const [],
      openQuestionPrompt: set.openQuestion.question,
    );

    return [trueFalseRound, multipleChoiceRound, openRound];
  }

  void _selectQuizOption(int idx) {
    if (_quizRoundIndex >= _quizRounds.length) return;
    final round = _quizRounds[_quizRoundIndex];
    if (round.answered) return;
    HapticFeedback.selectionClick();
    setState(() {
      round.selectedIdx = idx;
      if (round.correct) _quizScore += 1;
    });
    if (round.correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    if (_quizRoundIndex < _quizRounds.length - 1) {
      final delayMs = round.correct ? 1000 : 2500;
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted) return;
        if (_quizRoundIndex < _quizRounds.length - 1 && _quizRounds[_quizRoundIndex].selectedIdx == idx) {
          _advanceQuizRound();
        }
      });
    } else {
      // Last round!
      final store = AppScope.of(context);
      final isPassed = _quizScore >= 3;
      if (isPassed) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          if (_quizFinished && _quizPassed) {
            final steps = _sessionFlowSteps(store);
            final isLastStep = steps.isNotEmpty && steps.last.slug == widget.data.slug;
            if (isLastStep) {
              _completeSessionCard(context, store, correct: true);
            } else {
              store.answerCurrentCard(true);
              _completeStepAndNavigate(context, store, widget.data.slug);
            }
          }
        });
      }
    }
  }

  void _selectMatchingLeft(String item) {
    if (_matchingCompletedLeft.contains(item)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _matchingSelectedLeft = item;
      _checkMatchingPair();
    });
  }

  void _selectMatchingRight(String item) {
    if (_matchingCompletedRight.contains(item)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _matchingSelectedRight = item;
      _checkMatchingPair();
    });
  }

  void _checkMatchingPair() {
    final left = _matchingSelectedLeft;
    final right = _matchingSelectedRight;
    if (left == null || right == null) return;
    
    final round = _quizRounds[_quizRoundIndex];
    if (round.matchingPairs == null) return;

    final isCorrect = round.matchingPairs!.any((p) => p.$1 == left && p.$2 == right);
    if (isCorrect) {
      HapticFeedback.lightImpact();
      setState(() {
        _matchingCompletedLeft.add(left);
        _matchingCompletedRight.add(right);
        _matchingSelectedLeft = null;
        _matchingSelectedRight = null;
        
        // If all 4 pairs completed, mark round as answered/correct!
        if (_matchingCompletedLeft.length == 4) {
          round.selectedIdx = 1; // 1 means matching finished successfully!
          _quizScore += 1;
          
          if (_quizRoundIndex < _quizRounds.length - 1) {
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (!mounted) return;
              if (_quizRoundIndex < _quizRounds.length - 1 && _quizRounds[_quizRoundIndex].answered) {
                _advanceQuizRound();
              }
            });
          } else {
            // Last round matching complete!
            final store = AppScope.of(context);
            if (_quizScore >= 3) {
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (!mounted) return;
                if (_quizFinished && _quizPassed) {
                  final steps = _sessionFlowSteps(store);
                  final isLastStep = steps.isNotEmpty && steps.last.slug == widget.data.slug;
                  if (isLastStep) {
                    _completeSessionCard(context, store, correct: true);
                  } else {
                    store.answerCurrentCard(true);
                    _completeStepAndNavigate(context, store, widget.data.slug);
                  }
                }
              });
            }
          }
        }
      });
    } else {
      HapticFeedback.mediumImpact();
      _flagNonVoiceWrong();
      setState(() {
        _matchingSelectedLeft = null;
        _matchingSelectedRight = null;
      });
      _scheduleFlashRebuild();
    }
  }

  void _ensureMatchingShuffled(_QuizRound round) {
    if (round.matchingPairs == null) return;
    if (_matchingLeftShuffled.isNotEmpty) return;
    final lefts = round.matchingPairs!.map((p) => p.$1).toList()..shuffle();
    final rights = round.matchingPairs!.map((p) => p.$2).toList()..shuffle();
    setState(() {
      _matchingLeftShuffled = lefts;
      _matchingRightShuffled = rights;
      _matchingSelectedLeft = null;
      _matchingSelectedRight = null;
      _matchingCompletedLeft.clear();
      _matchingCompletedRight.clear();
    });
  }

  void _advanceQuizRound() {
    if (_quizRoundIndex < _quizRounds.length - 1) {
      setState(() {
        _quizRoundIndex += 1;
        _matchingLeftShuffled = [];
        _matchingRightShuffled = [];
        _matchingSelectedLeft = null;
        _matchingSelectedRight = null;
        _matchingCompletedLeft.clear();
        _matchingCompletedRight.clear();
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _quizCardId = null;
      _quizRounds = [];
      _quizRoundIndex = 0;
      _quizScore = 0;
      _matchingLeftShuffled = [];
      _matchingRightShuffled = [];
      _matchingSelectedLeft = null;
      _matchingSelectedRight = null;
      _matchingCompletedLeft.clear();
      _matchingCompletedRight.clear();
      _openQuestionController.clear();
    });
  }

  void _showQuizFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: RefColors.bg,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: RefColors.urgent, size: 28),
              SizedBox(width: 10),
              Text(
                'Quiz No Superado',
                style: TextStyle(
                  color: RefColors.ink,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          content: Text(
            'Obtuviste $_quizScore de ${_quizRounds.length} aciertos.\n\nNecesitas al menos 2 aciertos para completar el quiz de estudio. ¿Quieres reintentarlo ahora?',
            style: const TextStyle(
              color: RefColors.ink,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Ver Resultados',
                style: TextStyle(
                  color: RefColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: RefColors.urgent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resetQuiz();
              },
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _submitOpenQuestionResponse(_QuizRound round) async {
    final response = (round.openQuestionResponse ?? '').trim();
    if (response.isEmpty) return;
    
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isEvaluatingOpenQuestion = true;
    });

    final AiOpenAnswerEvaluation evaluation;
    try {
      evaluation = await LocalLlmService.instance.evaluateOpenAnswer(
        question: round.openQuestionPrompt ?? round.target.front,
        verseText: round.target.back,
        userAnswer: response,
      );
    } catch (e) {
      debugPrint('Error evaluando respuesta abierta con IA local: $e');
      if (!mounted) return;
      setState(() {
        _isEvaluatingOpenQuestion = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La IA local no pudo evaluar tu respuesta. Inténtalo de nuevo.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    final passes = evaluation.isCorrect;
    final feedback = evaluation.feedback;

    setState(() {
      _isEvaluatingOpenQuestion = false;
      round.selectedIdx = 1; // Mark as answered
      if (passes) {
        _quizScore += 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: RefColors.glassStrong,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: passes ? RefColors.lime : RefColors.urgent),
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          feedback,
          style: TextStyle(
            color: passes ? RefColors.lime : RefColors.urgent,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
    
    if (_quizRoundIndex < _quizRounds.length - 1) {
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (!mounted) return;
        if (_quizRoundIndex < _quizRounds.length - 1 && _quizRounds[_quizRoundIndex].answered) {
          _openQuestionController.clear();
          _advanceQuizRound();
        }
      });
    } else {
      final store = AppScope.of(context);
      final isPassed = _quizScore >= 3;
      if (isPassed) {
        Future.delayed(const Duration(milliseconds: 4000), () {
          if (!mounted) return;
          if (_quizFinished && _quizPassed) {
            final steps = _sessionFlowSteps(store);
            final isLastStep = steps.isNotEmpty && steps.last.slug == widget.data.slug;
            if (isLastStep) {
              _completeSessionCard(context, store, correct: true);
            } else {
              store.answerCurrentCard(true);
              _completeStepAndNavigate(context, store, widget.data.slug);
            }
          }
        });
      }
    }
  }

  bool get _quizFinished =>
      _quizRounds.isNotEmpty &&
      _quizRoundIndex == _quizRounds.length - 1 &&
      _quizRounds.last.answered;

  bool get _quizPassed => _quizFinished && _quizScore >= 2;

  void _activateLetterBlank(int index) {
    if (index < 0 || index >= _letterTargets.length) return;
    if (_letterAnswers[index] != null) return;
    setState(() => _activeLetterIndex = index);
  }

  String? get _activeTurnUserId {
    final coop = CoopService.active;
    if (coop == null) return null;
    final state = coop.state;
    if (state == null) return null;
    if (state.mode != 'turnos') return null;
    
    final members = state.memberIds.toList()..sort();
    if (members.isEmpty) return null;
    
    int startIndex = state.currentCardIndex % members.length;
    for (int i = 0; i < members.length; i++) {
      final idx = (startIndex + i) % members.length;
      final candidate = members[idx];
      if (!_failedUserIds.contains(candidate)) {
        return candidate;
      }
    }
    return members[startIndex];
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSecondsLeft = 8;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSecondsLeft > 1) {
          _cooldownSecondsLeft--;
        } else {
          _cooldownSecondsLeft = 0;
          timer.cancel();
        }
      });
    });
  }

  void _broadcastFail() {
    final coop = CoopService.active;
    if (coop == null) return;
    coop.send(CoopMessage(
      type: 'coop_fail',
      userId: CoopService.activeUserId ?? '',
      payload: {'userId': CoopService.activeUserId ?? ''},
    ));
  }

  bool _isInteractiveCoopSlug(String slug) {
    return slug == '05-bloques' ||
        slug == '06-completar-n1' ||
        slug == '07-primera-letra-n1' ||
        slug == '09-quiz' ||
        slug == '09-quiz-avanzado' ||
        slug == '10-completar-n2' ||
        slug == '11-primera-letra-n2' ||
        slug == '12-completar-n3' ||
        slug == '13-primera-letra-n3';
  }



  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final card = store.activeCard;
    final deck = store.activeDeck;
    final slug = widget.data.slug;
    if (slug == 'final-review') return _RealFinalReview(store: store);
    if (slug == 'mini-review') return _RealPairingReview(store: store);

    final steps = _sessionFlowSteps(store);
    final stepIndex = steps.indexWhere((step) => step.slug == slug);
    final step = stepIndex < 0 ? _flowStepNumber(slug) : stepIndex + 1;
    final totalSteps = steps.length;
    if (slug == '02-lectura-frag' && store.isExerciseStepCompleted(slug)) {
      _fragmentVisibleWords = _studyWords(card.back).length;
    }
    if (slug == '00-solo-lectura' && store.isExerciseStepCompleted(slug)) {
      final verses = _currentBatchVerses(context);
      _soloLecturaVisibleChars = verses.fold<int>(0, (sum, v) => sum + v.text.length);
    }

    final isCoop = CoopService.active != null;
    final coopState = CoopService.active?.state;

    bool isBlocked = false;
    bool showLockOverlay = false;
    String blockText = '';
    
    if (isCoop && coopState != null) {
      final mode = coopState.mode;
      if (mode == 'turnos' && _isInteractiveCoopSlug(slug)) {
        final activeUser = _activeTurnUserId;
        final isMe = activeUser == CoopService.activeUserId;
        final isMeFailed = _failedUserIds.contains(CoopService.activeUserId);
        
        if (isMeFailed) {
          isBlocked = true;
          showLockOverlay = true;
          blockText = 'Inhabilitado por fallar ❌\nEspera al siguiente ejercicio';
        } else if (!isMe) {
          isBlocked = true;
          showLockOverlay = false;
          blockText = 'Esperando el turno de $activeUser ⏳';
        }
      } else if (mode == 'libre') {
        if (_cooldownSecondsLeft > 0) {
          isBlocked = true;
          showLockOverlay = true;
          blockText = '⏳ Cooldown activo. Espera ${_cooldownSecondsLeft}s…';
        }
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isCoop) {
          final shouldPop = await _showExitConfirmationDialog(context);
          if (shouldPop && context.mounted) {
            await CoopService.active?.disconnect();
            if (!context.mounted) return;
            CoopService.active = null;
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: ReferencePage(
        showBottomNav: false,
        scrollable:
            slug != '01-escuchar' &&
            !_isFirstLetterSlug(slug) &&
            !_isFogSlug(slug) &&
            !_isFinalVoiceSlug(slug),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isCoop && coopState != null) ...[
              _CoopTopBar(
                center: 'EN JUEGO · ${store.sessionCardsCompleted + 1}/${store.sessionDailyTarget}',
                live: true,
                onBack: () async {
                  final shouldPop = await _showExitConfirmationDialog(context);
                  if (shouldPop && context.mounted) {
                    await CoopService.active?.disconnect();
                    if (!context.mounted) return;
                    CoopService.active = null;
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 8),
              _CoopTeamRow(
                state: coopState,
                answeredUsers: const {},
                activeTurnUserId: _activeTurnUserId,
                failedUserIds: _failedUserIds,
              ),
              const SizedBox(height: 10),
              RefProgress((store.sessionCardsCompleted + 1) / store.sessionDailyTarget),
              const SizedBox(height: 10),
            ] else
              _FlowStepHeader(
                step: '$step',
                totalSteps: totalSteps,
                title: _realStepTitle(slug),
                progress: step.clamp(1, totalSteps),
              ),
            
            (() {
              final isScrollable = slug != '01-escuchar' &&
                  !_isFirstLetterSlug(slug) &&
                  !_isFogSlug(slug) &&
                  !_isFinalVoiceSlug(slug);

              final isMyTurnActive = isCoop && coopState != null && (
                coopState.mode == 'libre'
                    ? _cooldownSecondsLeft <= 0
                    : (_activeTurnUserId == CoopService.activeUserId && !_failedUserIds.contains(CoopService.activeUserId))
              );

              final exerciseContent = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isScrollable)
                    Expanded(
                      child: Stack(
                        children: [
                          AbsorbPointer(
                            absorbing: isBlocked,
                            child: _CoopTurnGlow(
                              active: isMyTurnActive,
                              child: _RedFlash(
                                active: _nonVoiceWrongRecent(),
                                child: _realExerciseBody(context, store, card, deck, slug),
                              ),
                            ),
                          ),
                          if (isBlocked && showLockOverlay)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Glass(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _cooldownSecondsLeft > 0
                                                ? Icons.timer_outlined
                                                : _failedUserIds.contains(CoopService.activeUserId)
                                                    ? Icons.cancel_outlined
                                                    : Icons.lock_outline_rounded,
                                            color: _failedUserIds.contains(CoopService.activeUserId)
                                                ? RefColors.pink
                                                : _cooldownSecondsLeft > 0
                                                    ? RefColors.sun
                                                    : RefColors.muted,
                                            size: 56,
                                          ),
                                          const SizedBox(height: 18),
                                          Text(
                                            blockText,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Stack(
                      children: [
                        AbsorbPointer(
                          absorbing: isBlocked,
                          child: _CoopTurnGlow(
                            active: isMyTurnActive,
                            child: _RedFlash(
                              active: _nonVoiceWrongRecent(),
                              child: _realExerciseBody(context, store, card, deck, slug),
                            ),
                          ),
                        ),
                        if (isBlocked && showLockOverlay)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Glass(
                                color: Colors.black.withValues(alpha: 0.55),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _cooldownSecondsLeft > 0
                                              ? Icons.timer_outlined
                                              : _failedUserIds.contains(CoopService.activeUserId)
                                                  ? Icons.cancel_outlined
                                                  : Icons.lock_outline_rounded,
                                          color: _failedUserIds.contains(CoopService.activeUserId)
                                              ? RefColors.pink
                                              : _cooldownSecondsLeft > 0
                                                  ? RefColors.sun
                                                  : RefColors.muted,
                                          size: 56,
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          blockText,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  if (isCoop) ...[
                    AbsorbPointer(
                      absorbing: isBlocked,
                      child: _coopExerciseFooter(context, store, card, deck, slug),
                    ),
                    const SizedBox(height: 10),
                    const _CoopGameChat(),
                  ] else
                    AbsorbPointer(
                      absorbing: isBlocked,
                      child: _realExerciseFooter(context, store, card, deck, slug),
                    ),
                ],
              );

              if (isScrollable) {
                return exerciseContent;
              } else {
                return Expanded(
                  child: exerciseContent,
                );
              }
            })(),
          ],
        ),
      ),
    );
  }

  /// Reemplazo de un paso omitido: lectura (no-mic) o selección múltiple (mic).
  /// Cada variante trae su propio botón que cierra el override y avanza.
  Widget _buildOmitReplacement(
    BuildContext context,
    AppStore store,
    MemoryCardData card,
    MemoryDeckData deck,
    String slug,
  ) {
    void complete() {
      if (slug == '09-quiz' || slug == '09-quiz-avanzado') {
        store.answerCurrentCard(true);
      }
      setState(() => _omitOverride.remove('${card.id}:$slug'));
      _completeStepAndNavigate(context, store, slug);
    }

    if (_isMicSlug(slug)) {
      return _OmitSelectExercise(
        key: ValueKey('omit-sel-${card.id}-$slug'),
        card: card,
        deck: deck,
        onCorrect: complete,
      );
    }

    // No-micrófono → lectura simple del versículo.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
          gradient: LinearGradient(
            colors: [
              RefColors.cyan.withValues(alpha: .22),
              RefColors.violet.withValues(alpha: .20),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Column(
            children: [
              const Text('📖 LEE EL VERSÍCULO',
                  style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3)),
              const SizedBox(height: 14),
              Text(
                card.back,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, height: 1.55, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Cta('Lo leí, continuar →', onTap: complete),
      ],
    );
  }

  Widget _realExerciseBody(
    BuildContext context,
    AppStore store,
    MemoryCardData card,
    MemoryDeckData deck,
    String slug,
  ) {
    final completed = store.isExerciseStepCompleted(slug);

    // F2: si el usuario omitió este paso, se transforma en lectura (no-mic)
    // o selección múltiple (mic) en lugar de saltarse. Mismo camino en solo
    // y coop (este motor es compartido).
    if (_omitOverride.contains('${card.id}:$slug')) {
      return _buildOmitReplacement(context, store, card, deck, slug);
    }

    if (slug == '09-quiz' || slug == '09-quiz-avanzado') {
      _ensureQuizRounds(deck, card);
      if (_isAiQuizLoading) {
        return Center(
          child: Glass(
            padding: const EdgeInsets.all(28),
            color: RefColors.glassStrong,
            border: Border.all(color: RefColors.border),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(RefColors.cyan),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _aiQuizLoadingText,
                    key: ValueKey(_aiQuizLoadingText),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      color: RefColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Preguntas generadas en vivo por la IA local · sin internet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: RefColors.muted,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (_aiQuizError != null) {
        return Center(
          child: Glass(
            padding: const EdgeInsets.all(28),
            color: RefColors.glassStrong,
            border: Border.all(color: RefColors.urgent.withValues(alpha: .5)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.psychology_alt_rounded,
                  color: RefColors.urgent,
                  size: 44,
                ),
                const SizedBox(height: 16),
                Text(
                  _aiQuizError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: RefColors.ink,
                  ),
                ),
                const SizedBox(height: 18),
                Cta(
                  'Reintentar con IA',
                  onTap: () {
                    setState(() {
                      _quizCardId = null;
                      _aiQuizError = null;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }
    }

    if (slug == '00-solo-lectura') {
      final verses = _currentBatchVerses(context);
      final totalChars = verses.fold<int>(0, (sum, v) => sum + v.text.length);
      final fullText = verses.map((v) => v.text).join("");
      final verseEnds = <int>[];
      var tempSum = 0;
      for (var i = 0; i < verses.length - 1; i++) {
        tempSum += verses[i].text.length;
        verseEnds.add(tempSum);
      }

      if (!store.isExerciseStepCompleted(slug) && _soloLecturaTimer == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startSoloLecturaAnimation(store, totalChars, verseEnds, fullText);
        });
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              if (!store.isExerciseStepCompleted(slug)) {
                _soloLecturaTimer?.cancel();
                _soloLecturaTimer = null;
                _soloLecturaPauseUntil = null;
                setState(() {
                  _soloLecturaVisibleChars = totalChars;
                });
                store.markExerciseStepCompleted('00-solo-lectura');
              }
            },
            child: Glass(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
              gradient: LinearGradient(
                colors: [
                  RefColors.violet.withValues(alpha: .28),
                  RefColors.sun.withValues(alpha: .34),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    deck.isBible ? card.front.toUpperCase() : 'CITA',
                    style: const TextStyle(
                      color: RefColors.pink,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240, minHeight: 120),
                    child: SingleChildScrollView(
                      child: Container(
                        alignment: Alignment.center,
                        child: _buildSoloLecturaText(context, _soloLecturaVisibleChars),
                      ),
                    ),
                  ),
                  if (!store.isExerciseStepCompleted(slug)) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 13,
                          color: RefColors.pink.withValues(alpha: .55),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TOCA EL TEXTO PARA OMITIR',
                          style: TextStyle(
                            color: RefColors.pink.withValues(alpha: .55),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (store.isExerciseStepCompleted(slug)) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: RefColors.lime),
                        const SizedBox(width: 8),
                        const Text(
                          'Lectura completada',
                          style: TextStyle(
                            color: RefColors.lime,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            _soloLecturaTimer?.cancel();
                            _soloLecturaTimer = null;
                            _soloLecturaPauseUntil = null;
                            store.resetExerciseStepCompleted(slug);
                            setState(() {
                              _soloLecturaVisibleChars = 0;
                            });
                            _startSoloLecturaAnimation(store, totalChars, verseEnds, fullText);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: RefColors.cyan.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.replay_rounded, size: 16, color: RefColors.cyan),
                                SizedBox(width: 6),
                                Text(
                                  'Repetir',
                                  style: TextStyle(
                                    color: RefColors.cyan,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (slug == '01-escuchar') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ListenAudioCard(
              onCompleted: () => store.markExerciseStepCompleted(slug),
            ),
          ),
        ],
      );
    }

    if (slug == '02-lectura-frag') {
      final totalWords = _studyWords(card.back).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressiveFragmentCard(
            visibleWords: _fragmentVisibleWords,
            onTap: () => _revealFragment(slug, totalWords),
          ),
        ],
      );
    }

    if (slug == '03-leer-voz') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadAloudPracticeCard(
            targetText: card.back,
            source: card.front,
            completed: completed,
            onCompleted: (recognized, audioPath) {
              store.saveVoiceReadForCurrentCard(recognized);
              if (audioPath != null) {
                store.saveVoiceAudioPathForCurrentCard(audioPath);
              }
              store.markExerciseStepCompleted(slug);
            },
          ),
        ],
      );
    }

    if (slug == '04-escuchar-voz') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ListenOwnVoicePracticeCard(
            originalText: card.back,
            voiceText: store.voiceReadForCurrentCard(),
            audioPath: store.voiceAudioPathForCurrentCard(),
            source: card.front,
            onCompleted: () => store.markExerciseStepCompleted(slug),
          ),
        ],
      );
    }

    if (_isFinalVoiceSlug(slug)) {
      _ensureFogState(card.id);
      return _FogStep(
        targetText: card.back,
        finished: _fogFinished || completed,
        level: 3, // Final voice test blurs 100% of the words!
        showHintTemp: _fogShowHintTemp,
        onRoundCompleted: () {
          _onFogRoundCompleted();
          store.answerCurrentCard(true); // completed!
        },
      );
    }

    if (slug == '05-bloques') {
      final blocks = _orderedBlocks(card.back);
      _ensureBlockOrder(card.id, blocks);
      final selectingDestination = _selectedBlockPosition != null;
      final hasInteracted = _checked || selectingDestination;
      final allCorrect = _blocksAreCorrect();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Glass(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: RefColors.cyan,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mantén presionado un bloque para arrastrarlo a su lugar, o toca dos bloques para intercambiar sus posiciones.',
                    style: TextStyle(
                      color: RefColors.dim,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Glass(
            padding: const EdgeInsets.all(14),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final t = Curves.easeOutCubic.transform(animation.value);
                    return Transform.scale(
                      scale: 1 + 0.06 * t,
                      child: Material(
                        color: Colors.transparent,
                        elevation: 12 * t,
                        shadowColor: RefColors.pink.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      ),
                    );
                  },
                );
              },
              itemCount: _blockOrderIndexes.length,
              itemBuilder: (context, index) {
                final blockText = blocks[_blockOrderIndexes[index]];
                return _CustomReorderableDelayedDragStartListener(
                  key: ValueKey('block-$index-${_blockOrderIndexes[index]}'),
                  index: index,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _blockOrderIndexes.length - 1 ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () => _toggleSelectedBlock(index),
                      child: _VerseBlock(
                        blockText,
                        correct:
                            hasInteracted && _blockOrderIndexes[index] == index,
                        selected: _selectedBlockPosition == index,
                        wrong: _checked && _blockOrderIndexes[index] != index,
                      ),
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                _moveBlock(oldIndex, newIndex);
              },
            ),
          ),
          if (hasInteracted)
            _InlineResult(
              correct: hasInteracted && allCorrect,
              neutral: !allCorrect,
              text: allCorrect
                  ? 'Orden correcto.'
                  : selectingDestination
                  ? 'Ahora toca una línea de destino para colocar ese bloque ahí.'
                  : 'Toca un bloque, elige una posición y acomódalo hasta que todo quede verde.',
            ),
        ],
      );
    }

    if (_isCompletionSlug(slug)) {
      final level = _completionLevelForSlug(slug);
      final isHarder = level >= 2;
      _ensureCompletionState(card.id, card.back, level);
      _ensureAiDistractors(card);
      final activeTarget = _completionTargets.isEmpty
          ? _targetWord(card.back, level: level)
          : _completionTargets[_activeCompletionIndex.clamp(
              0,
              _completionTargets.length - 1,
            )];
      final words = _completionOptions(
        card.back,
        activeTarget,
        seed: _completionSeed,
        aiPool: _aiDistractorPool,
      );
      final hasInput = _hasCompletionInput();
      final complete = _completionComplete();
      final remainingAttempts = (3 - _completionMistakes).clamp(0, 3);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompleteStatsCard(
            level2: isHarder,
            firstValue:
                '${_completionAnswers.where((answer) => answer != null).length}/${_completionTargets.length}',
            firstLabel: 'HUECOS',
            secondValue: '$remainingAttempts/3',
            secondLabel: 'INTENTOS',
            timeValue: _formatMmSs(_completionSecondsLeft),
          ),
          const SizedBox(height: 14),
          _CompletionPromptCard(
            label: card.front,
            text: card.back,
            targets: _completionTargets,
            answers: _completionAnswers,
            activeIndex: _activeCompletionIndex,
            onBlankTap: _activateCompletionBlank,
          ),
          const SizedBox(height: 14),
          if (complete)
            Glass(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              color: RefColors.lime.withValues(alpha: .14),
              border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
              child: Column(
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: RefColors.lime,
                    size: 36,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '¡Completado!',
                    style: TextStyle(
                      color: RefColors.lime,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Todos los huecos están correctos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RefColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (_completionLost)
            _LostPanel(
              title: '¡Tiempo agotado!',
              subtitle: 'Se acabó el tiempo. Inténtalo de nuevo.',
              onRetry: _retryCompletion,
            )
          else
            Glass(
              padding: const EdgeInsets.all(14),
              color: RefColors.glassSoft,
              child: Column(
                children: [
                  const Text(
                    'ELIGE LA PALABRA CORRECTA',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  if (_aiDistractorLoading) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: RefColors.violet),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'La IA está generando opciones más difíciles…',
                          style: TextStyle(
                              color: RefColors.violet,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final word in words)
                        GestureDetector(
                          onTap: remainingAttempts == 0
                              ? null
                              : () => _selectCompletionWord(word),
                          child: _WordChip(word, active: false),
                        ),
                    ],
                  ),
                  if (hasInput && !complete && remainingAttempts > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Si fallas, las opciones se barajan de nuevo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RefColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (remainingAttempts == 0 && !complete) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Sin intentos restantes.',
                      style: TextStyle(
                        color: RefColors.urgent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    if (_isFirstLetterSlug(slug)) {
      final level = _letterLevelForSlug(slug);
      final isHarder = level >= 2;
      _ensureLetterState(card.id, card.back, level);
      final complete = _letterComplete();
      final remainingAttempts = (3 - _letterMistakes).clamp(0, 3);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompleteStatsCard(
            level2: isHarder,
            firstValue:
                '${_letterAnswers.where((answer) => answer != null).length}/${_letterTargets.length}',
            firstLabel: 'LETRAS',
            secondValue: '$remainingAttempts/3',
            secondLabel: 'INTENTOS',
            timeValue: _formatMmSs(_letterSecondsLeft),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _FirstLetterSentence(
              text: card.back,
              level: level,
              targets: _letterTargets,
              targetPositions: _letterTargetPositions,
              answers: _letterAnswers,
              activeIndex: _activeLetterIndex,
              onBlankTap: _activateLetterBlank,
            ),
          ),
          const SizedBox(height: 14),
          if (complete)
            Glass(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              color: RefColors.lime.withValues(alpha: .14),
              border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
              child: Column(
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: RefColors.lime,
                    size: 36,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '¡Completado!',
                    style: TextStyle(
                      color: RefColors.lime,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Todas las palabras fueron reveladas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RefColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (_letterLost || remainingAttempts == 0)
            _LostPanel(
              title: _letterLost ? '¡Tiempo agotado!' : '¡Sin intentos!',
              subtitle: _letterLost
                  ? 'Se acabó el tiempo. Inténtalo de nuevo.'
                  : 'Cometiste demasiados errores. Inténtalo de nuevo.',
              onRetry: _retryLetter,
            )
          else ...[
            _KeyboardCard(
              onLetterTap: _selectFirstLetter,
            ),
          ],
        ],
      );
    }

    if (_isWordBankSlug(slug)) {
      _ensureBankState(card.id, card.back);
      final isSplit = _bankIsSplit();
      final partCount = _bankPartCount();
      final (partStart, partEnd) = _bankPartRange();
      final partTargets = _bankTargets.sublist(partStart, partEnd);
      final partAnswers = _bankAnswers.sublist(partStart, partEnd);
      final partText = partTargets.join(' ');
      // Words available for the current part: take from _bankAvailable up to
      // the multiset of still-unfilled targets in this part.
      final cleanRegex = RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]');
      String clean(String w) => w.replaceAll(cleanRegex, '').toLowerCase();
      final neededCounts = <String, int>{};
      for (var i = partStart; i < partEnd; i++) {
        if (_bankAnswers[i] != null) continue;
        final key = clean(_bankTargets[i]);
        neededCounts[key] = (neededCounts[key] ?? 0) + 1;
      }
      final partAvailable = <_BankWord>[];
      for (final w in _bankAvailable) {
        final key = clean(w.word);
        final left = neededCounts[key] ?? 0;
        if (left > 0) {
          partAvailable.add(w);
          neededCounts[key] = left - 1;
        }
      }
      final partActiveIndex = (_bankActiveIndex - partStart).clamp(0, partTargets.length - 1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompleteStatsCard(
            level2: false,
            firstValue: '${_bankPartIndex + 1}/$partCount',
            firstLabel: 'PARTE',
            secondValue: '$_bankMistakes',
            secondLabel: 'FALLOS',
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0.18, 0),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _CompletionPromptCard(
              key: ValueKey('bank-prompt-$_bankPartIndex'),
              label: card.front,
              text: partText,
              targets: partTargets,
              answers: partAnswers,
              activeIndex: partActiveIndex,
              onBlankTap: (i) => _activateBankBlank(partStart + i),
            ),
          ),
          const SizedBox(height: 14),
          if (_bankComplete())
            Glass(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              color: RefColors.lime.withValues(alpha: .14),
              border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
              child: Column(
                children: const [
                  Icon(Icons.check_circle_rounded, color: RefColors.lime, size: 36),
                  SizedBox(height: 10),
                  Text('¡Banco vaciado!',
                      style: TextStyle(
                          color: RefColors.lime,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Cada palabra encontró su lugar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: RefColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            Glass(
              padding: const EdgeInsets.all(14),
              color: RefColors.glassSoft,
              child: Column(
                children: [
                  Text(
                    isSplit
                        ? 'BANCO · PARTE ${_bankPartIndex + 1}'
                        : 'BANCO DE PALABRAS',
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final word in partAvailable)
                        AnimatedScale(
                          key: ValueKey(word.id),
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInBack,
                          scale: _bankRemoving.contains(word.id) ? 0.0 : 1.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 240),
                            opacity:
                                _bankRemoving.contains(word.id) ? 0.0 : 1.0,
                            child: GestureDetector(
                              onTap: () => _selectBankWord(word),
                              child: _WordChip(word.word, active: false),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    }

    if (_isFogSlug(slug)) {
      _ensureFogState(card.id);
      return _FogStep(
        targetText: card.back,
        finished: _fogFinished || completed,
        level: _fogLevelForSlug(slug),
        showHintTemp: _fogShowHintTemp,
        onRoundCompleted: _onFogRoundCompleted,
      );
    }

    if (_quizRounds.isEmpty) {
      // El loading/error de la IA ya se renderizó arriba; nunca indexar vacío.
      return const SizedBox.shrink();
    }
    final round = _quizRounds[_quizRoundIndex];
    final answered = round.answered;
    final isFrontToBack = round.type == _QuizQuestionType.frontToBack;
    final isTrueFalse = round.type == _QuizQuestionType.trueFalse;
    final isMatching = round.type == _QuizQuestionType.matching;
    final isOpenQuestion = round.type == _QuizQuestionType.openQuestion;

    final question = isTrueFalse
        ? '¿Es verdadera o falsa esta afirmación sobre ${round.target.front}?'
        : isMatching
        ? 'Toca una referencia y luego su texto para emparejarlos.'
        : isOpenQuestion
        ? (round.openQuestionPrompt ?? 'Responde con tus palabras')
        : isFrontToBack
        ? (round.target.front.startsWith('¿')
            ? round.target.front
            : '¿Qué texto corresponde a ${round.target.front}?')
        : '¿A qué referencia pertenece este texto?\n\n"${round.target.back}"';

    final contextLabel = isTrueFalse
        ? 'PREGUNTA ${_quizRoundIndex + 1} DE ${_quizRounds.length} · VERDADERO / FALSO'
        : isMatching
        ? 'PREGUNTA ${_quizRoundIndex + 1} DE ${_quizRounds.length} · EMPAREJAR'
        : isOpenQuestion
        ? 'PREGUNTA ${_quizRoundIndex + 1} DE ${_quizRounds.length} · RESPUESTA ABIERTA'
        : isFrontToBack
        ? (deck.isBible
            ? (round.target.front.contains('¿') || round.target.front.length > 40
                ? 'BIBLIA · TRIVIA'
                : 'BIBLIA · ${round.target.front.toUpperCase()}')
            : deck.title.toUpperCase())
        : round.type == _QuizQuestionType.backToFront
        ? (deck.isBible ? 'BIBLIA · RECONOCER REFERENCIA' : 'IDENTIFICAR ORIGEN')
        : (deck.isBible ? 'BIBLIA · ASOCIACIÓN CONCEPTUAL' : '"${_firstWords(round.target.back, 8)}…"');

    if (isMatching) {
      _ensureMatchingShuffled(round);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ronda ${_quizRoundIndex + 1} / ${_quizRounds.length}',
                style: const TextStyle(
                  color: RefColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Puntos: $_quizScore',
                style: const TextStyle(
                  color: RefColors.lime,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _ExerciseQuestionBlock(contextLabel: contextLabel, question: question),
        const SizedBox(height: 14),
        if (isTrueFalse) ...[
          Glass(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            color: RefColors.glassStrong,
            border: Border.all(color: RefColors.border),
            child: Text(
              '"${round.trueFalseStatement}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                height: 1.32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: answered ? null : () => _selectQuizOption(0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: answered && round.isStatementTrue == true
                          ? RefColors.lime.withValues(alpha: 0.12)
                          : round.selectedIdx == 0
                          ? (round.correct ? RefColors.lime.withValues(alpha: 0.12) : RefColors.urgent.withValues(alpha: 0.12))
                          : RefColors.glassStrong,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: answered && round.isStatementTrue == true
                            ? RefColors.lime
                            : round.selectedIdx == 0
                            ? (round.correct ? RefColors.lime : RefColors.urgent)
                            : RefColors.border,
                        width: round.selectedIdx == 0 || (answered && round.isStatementTrue == true) ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: answered && round.isStatementTrue == true
                              ? RefColors.lime
                              : round.selectedIdx == 0
                              ? (round.correct ? RefColors.lime : RefColors.urgent)
                              : RefColors.ink,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'VERDADERO',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: answered ? null : () => _selectQuizOption(1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: answered && round.isStatementTrue == false
                          ? RefColors.lime.withValues(alpha: 0.12)
                          : round.selectedIdx == 1
                          ? (round.correct ? RefColors.lime.withValues(alpha: 0.12) : RefColors.urgent.withValues(alpha: 0.12))
                          : RefColors.glassStrong,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: answered && round.isStatementTrue == false
                            ? RefColors.lime
                            : round.selectedIdx == 1
                            ? (round.correct ? RefColors.lime : RefColors.urgent)
                            : RefColors.border,
                        width: round.selectedIdx == 1 || (answered && round.isStatementTrue == false) ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          color: answered && round.isStatementTrue == false
                              ? RefColors.lime
                              : round.selectedIdx == 1
                              ? (round.correct ? RefColors.lime : RefColors.urgent)
                              : RefColors.ink,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'FALSO',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (isMatching) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final leftItem in _matchingLeftShuffled) ...[
                      GestureDetector(
                        onTap: () => _selectMatchingLeft(leftItem),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            color: _matchingCompletedLeft.contains(leftItem)
                                ? RefColors.lime.withValues(alpha: 0.12)
                                : _matchingSelectedLeft == leftItem
                                ? RefColors.pink.withValues(alpha: 0.12)
                                : RefColors.glassStrong,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _matchingCompletedLeft.contains(leftItem)
                                  ? RefColors.lime
                                  : _matchingSelectedLeft == leftItem
                                  ? RefColors.pink
                                  : RefColors.border,
                              width: _matchingCompletedLeft.contains(leftItem) || _matchingSelectedLeft == leftItem ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  leftItem,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _matchingCompletedLeft.contains(leftItem) ? RefColors.lime : RefColors.ink,
                                  ),
                                ),
                              ),
                              if (_matchingCompletedLeft.contains(leftItem))
                                const Icon(Icons.check_circle_rounded, color: RefColors.lime, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (final rightItem in _matchingRightShuffled) ...[
                      GestureDetector(
                        onTap: () => _selectMatchingRight(rightItem),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            color: _matchingCompletedRight.contains(rightItem)
                                ? RefColors.lime.withValues(alpha: 0.12)
                                : _matchingSelectedRight == rightItem
                                ? RefColors.pink.withValues(alpha: 0.12)
                                : RefColors.glassStrong,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _matchingCompletedRight.contains(rightItem)
                                  ? RefColors.lime
                                  : _matchingSelectedRight == rightItem
                                  ? RefColors.pink
                                  : RefColors.border,
                              width: _matchingCompletedRight.contains(rightItem) || _matchingSelectedRight == rightItem ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rightItem,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: _matchingCompletedRight.contains(rightItem) ? RefColors.lime : RefColors.ink,
                                  ),
                                ),
                              ),
                              if (_matchingCompletedRight.contains(rightItem))
                                const Icon(Icons.check_circle_rounded, color: RefColors.lime, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ] else if (isOpenQuestion) ...[
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: RefColors.glassStrong,
            border: Border.all(color: RefColors.border),
            child: TextField(
              controller: _openQuestionController,
              enabled: !answered,
              maxLines: 4,
              minLines: 3,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: RefColors.ink,
              ),
              decoration: const InputDecoration(
                hintText: 'Escribe con tus palabras...',
                hintStyle: TextStyle(
                  color: RefColors.muted,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() {
                  round.openQuestionResponse = val;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    String hint = 'Pista de la IA Local Offline: intenta mencionar ';
                    final text = round.target.back.toLowerCase();
                    if (text.contains('puedo') || text.contains('fortalece')) {
                      hint += 'Cristo, fortaleza, poder y superación frente a la debilidad.';
                    } else if (text.contains('gracias') || text.contains('misericordia')) {
                      hint += 'gratitud, misericordia, bondad de Dios y fidelidad eterna.';
                    } else if (text.contains('angustia') || text.contains('clamar')) {
                      hint += 'clamar, angustia, oración de fe y salvación de Dios.';
                    } else if (text.contains('paz') || text.contains('cuidado') || text.contains('ansiedad')) {
                      hint += 'paz sobrenatural, oración con gratitud, cuidado y mente.';
                    } else if (round.target.front.contains('Bíceps') || round.target.back.contains('flexor')) {
                      hint += 'bíceps braquial, flexión, antebrazo y articulación del codo.';
                    } else {
                      hint += 'confianza, fe, obediencia y asimilación de la Palabra.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: RefColors.glassStrong,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: RefColors.cyan),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        content: Text(
                          hint,
                          style: const TextStyle(color: RefColors.cyan, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: RefColors.glassSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: RefColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('💡 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'Explicar',
                          style: TextStyle(
                            color: RefColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: answered || (round.openQuestionResponse ?? '').trim().isEmpty || _isEvaluatingOpenQuestion
                      ? null
                      : () => _submitOpenQuestionResponse(round),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: (round.openQuestionResponse ?? '').trim().isEmpty
                          ? null
                          : LinearGradient(
                              colors: [
                                RefColors.pink,
                                RefColors.sun,
                              ],
                            ),
                      color: (round.openQuestionResponse ?? '').trim().isEmpty
                          ? RefColors.glassSoft
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (round.openQuestionResponse ?? '').trim().isEmpty
                            ? RefColors.border
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: _isEvaluatingOpenQuestion
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Confirmar →',
                              style: TextStyle(
                                color: (round.openQuestionResponse ?? '').trim().isEmpty
                                    ? RefColors.muted
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          for (var i = 0; i < round.options.length; i++) ...[
            _ExerciseOption(
              letter: String.fromCharCode(65 + i),
              title: isFrontToBack
                  ? round.options[i].back
                  : round.options[i].front,
              tip: round.options[i].source,
              selected: round.selectedIdx == i,
              correct: answered && round.options[i].id == round.target.id,
              wrong: round.selectedIdx == i && !round.correct,
              onTap: answered ? () {} : () => _selectQuizOption(i),
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (answered && !isOpenQuestion)
          _InlineResult(
            correct: round.correct,
            text: round.correct
                ? '¡Correcto!'
                : (round.type == _QuizQuestionType.trueFalse
                    ? 'Respuesta correcta: ${round.isStatementTrue == true ? "VERDADERO" : "FALSO"}'
                    : 'Respuesta correcta: ${isFrontToBack ? round.target.back : round.target.front}'),
          ),
        if (_quizFinished) ...[
          const SizedBox(height: 14),
          Glass(
            radius: 16,
            padding: const EdgeInsets.all(14),
            color: (_quizPassed ? RefColors.lime : RefColors.urgent).withValues(
              alpha: .14,
            ),
            border: Border.all(
              color: (_quizPassed ? RefColors.lime : RefColors.urgent)
                  .withValues(alpha: .55),
            ),
            child: Column(
              children: [
                Text(
                  _quizPassed
                      ? '¡Quiz superado! $_quizScore / ${_quizRounds.length}'
                      : 'Casi: $_quizScore / ${_quizRounds.length}. Necesitas 3 para avanzar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _quizPassed ? RefColors.lime : RefColors.urgent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!_quizPassed) ...[
                  const SizedBox(height: 10),
                  GhostButton('Reintentar', onTap: _resetQuiz),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSoloLecturaText(BuildContext context, int visibleChars) {
    final verses = _currentBatchVerses(context);
    const style = TextStyle(
      fontSize: 20,
      height: 1.38,
      fontWeight: FontWeight.w900,
      fontFamily: 'Outfit',
    );

    if (verses.length == 1) {
      final text = verses.first.text;
      final safeGreen = visibleChars.clamp(0, text.length);
      final lead = text.substring(0, safeGreen);
      final tail = text.substring(safeGreen);
      return Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(
              text: lead,
              style: const TextStyle(color: RefColors.lime),
            ),
            TextSpan(
              text: tail,
              style: const TextStyle(color: Colors.transparent),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }

    var charsShown = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < verses.length; i++) ...[
          () {
            final versoText = verses[i].text;
            final safeGreen = (visibleChars - charsShown).clamp(0, versoText.length);
            charsShown += versoText.length;

            final lead = versoText.substring(0, safeGreen);
            final tail = versoText.substring(safeGreen);

            return Padding(
              padding: EdgeInsets.only(
                bottom: i == verses.length - 1 ? 0 : 10,
              ),
              child: Text.rich(
                TextSpan(
                  style: style,
                  children: [
                    TextSpan(
                      text: '${verses[i].number}  ',
                      style: const TextStyle(
                        color: RefColors.pink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: lead,
                      style: const TextStyle(color: RefColors.lime),
                    ),
                    TextSpan(
                      text: tail,
                      style: const TextStyle(color: Colors.transparent),
                    ),
                  ],
                ),
              ),
            );
          }(),
        ],
      ],
    );
  }

  void _startSoloLecturaAnimation(AppStore store, int totalChars, List<int> verseEnds, String fullText) {
    _soloLecturaTimer?.cancel();
    _soloLecturaPauseUntil = null;
    _soloLecturaTimer = Timer.periodic(const Duration(milliseconds: 75), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_soloLecturaPauseUntil != null && DateTime.now().isBefore(_soloLecturaPauseUntil!)) {
        return;
      }
      final nextVisible = _soloLecturaVisibleChars + 1;
      if (nextVisible >= totalChars) {
        timer.cancel();
        _soloLecturaTimer = null;
        _soloLecturaPauseUntil = null;
        setState(() {
          _soloLecturaVisibleChars = totalChars;
        });
        store.markExerciseStepCompleted('00-solo-lectura');
      } else {
        var pauseDuration = 0;
        if (verseEnds.contains(nextVisible)) {
          pauseDuration = 750;
        } else if (nextVisible - 1 < fullText.length) {
          final char = fullText[nextVisible - 1];
          if (char == '.' || char == '?' || char == '!') {
            pauseDuration = 450;
          } else if (char == ',' || char == ';' || char == ':') {
            pauseDuration = 250;
          }
        }

        if (pauseDuration > 0) {
          _soloLecturaPauseUntil = DateTime.now().add(Duration(milliseconds: pauseDuration));
        }

        setState(() {
          _soloLecturaVisibleChars = nextVisible;
        });
      }
    });
  }

  Widget _coopExerciseFooter(
    BuildContext context,
    AppStore store,
    MemoryCardData card,
    MemoryDeckData deck,
    String slug,
  ) {
    final completed = store.isExerciseStepCompleted(slug);
    
    if (completed) {
      return Cta(
        'Continuar →',
        onTap: () {
          ActiveMediaRegistry.stopAll();
          final steps = _sessionFlowSteps(store);
          final isLastStep = steps.isNotEmpty && steps.last.slug == slug;
          final nextSlug = isLastStep ? 'final-review' : 'progress-tree';
          
          CoopService.active!.broadcastCard(
            deckId: deck.id,
            cardIndex: store.sessionCardsCompleted,
            slug: nextSlug,
          );
          
          _navigateToNextStepOrComplete(context, store, slug);
        },
      );
    }
    
    return _realExerciseFooter(context, store, card, deck, slug);
  }

  Widget _realExerciseFooter(
    BuildContext context,
    AppStore store,
    MemoryCardData card,
    MemoryDeckData deck,
    String slug,
  ) {
    // F2: el reemplazo por omitir trae su propio botón de continuar.
    if (_omitOverride.contains('${card.id}:$slug')) {
      return const SizedBox.shrink();
    }
    final next = _nextFlowSlug(store, slug);
    final completed = store.isExerciseStepCompleted(slug);
    if (slug == '02-lectura-frag') {
      return Row(
        children: [
          SizedBox(
            width: 118,
            child: GhostButton(
              'Reiniciar',
              onTap: () => setState(() {
                _fragmentVisibleWords = 4;
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCta(
              label: completed
                  ? 'Siguiente →'
                  : 'Revela todo para continuar',
              enabled: completed,
              onTap: () {
                ActiveMediaRegistry.stopAll();
                _navigateToNextStepOrComplete(context, store, widget.data.slug);
              },
            ),
          ),
        ],
      );
    }
    if (slug == '00-solo-lectura' ||
        slug == '01-escuchar' ||
        slug == '03-leer-voz' ||
        slug == '04-escuchar-voz') {
      final showSkip =
          slug == '01-escuchar' ||
          slug == '03-leer-voz' ||
          slug == '04-escuchar-voz';
      final cta = _ActionCta(
        label: _footerLabel(slug, checked: _checked, completed: completed),
        enabled: completed,
        onTap: () {
          ActiveMediaRegistry.stopAll();
          _navigateToNextStepOrComplete(context, store, widget.data.slug);
        },
      );
      if (!showSkip) return cta;
      return Row(
        children: [
          SizedBox(
            width: 118,
            child: GhostButton(
              'Omitir',
              onTap: () {
                ActiveMediaRegistry.stopAll();
                setState(() => _omitOverride.add('${card.id}:$slug'));
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: cta),
        ],
      );
    }
    if (_isFogSlug(slug) || _isFinalVoiceSlug(slug)) {
      final label = _footerLabel(slug, checked: _checked, completed: completed);
      final enabled = completed;
      return Row(
        children: [
          SizedBox(
            width: 118,
            child: GhostButton(
              'Omitir',
              onTap: () {
                ActiveMediaRegistry.stopAll();
                setState(() => _omitOverride.add('${card.id}:$slug'));
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCta(
              label: label,
              enabled: enabled,
              onTap: () {
                ActiveMediaRegistry.stopAll();
                _completeStepAndNavigate(context, store, slug);
              },
            ),
          ),
        ],
      );
    }
    final showOmitirForDefault =
        slug == '05-bloques' ||
        _isFirstLetterSlug(slug) ||
        slug == '09-quiz' ||
        slug == '09-quiz-avanzado';

    return Row(
      children: [
        SizedBox(
          width: 118,
          child: GhostButton(
            showOmitirForDefault ? 'Omitir' : 'Pista',
            onTap: () {
              if (showOmitirForDefault) {
                ActiveMediaRegistry.stopAll();
                setState(() => _omitOverride.add('${card.id}:$slug'));
                return;
              }
              if (slug == '05-bloques') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Primer bloque: ${_orderedBlocks(card.back).first}',
                    ),
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Pista: ${_firstWords(card.back, 6)}')),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCta(
            label: _footerLabel(slug, checked: _checked, completed: completed),
            enabled: _footerEnabled(
              slug,
              checked: _checked,
              completed: completed,
            ),
            onTap: () {
              ActiveMediaRegistry.stopAll();
              if (_isPassiveStep(slug)) {
                if (!completed) {
                  store.markExerciseStepCompleted(slug);
                  return;
                }
                if (_isFinalVoiceSlug(slug)) {
                  _completeSessionCard(context, store, correct: true);
                  return;
                }
                Navigator.push(
                  context,
                  AppRoutes.slideRoute('${AppRoutes.flow}/$next'),
                );
                return;
              }
              if (slug == '09-quiz' || slug == '09-quiz-avanzado') {
                if (_quizRounds.isEmpty) return;
                final round = _quizRounds[_quizRoundIndex];
                if (!round.answered) return;
                if (!_quizFinished) {
                  _advanceQuizRound();
                  return;
                }
                if (!_quizPassed) {
                  _showQuizFailedDialog();
                  return;
                }
                store.answerCurrentCard(true);
                _completeStepAndNavigate(context, store, slug);
                return;
              }
              if (!_checked) {
                if (slug == '05-bloques') {
                  if (_blocksAreCorrect()) {
                    _completeStepAndNavigate(context, store, slug);
                    return;
                  }
                  setState(() => _checked = true);
                  return;
                }
                setState(() => _checked = true);
                return;
              }
              final correct = _currentStepCorrect(slug, card, deck);
              if (!correct && slug != '09-quiz' && slug != '09-quiz-avanzado') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Corrige el ejercicio para avanzar.'),
                  ),
                );
                return;
              }
              if (slug == '09-quiz' || slug == '09-quiz-avanzado') {
                store.answerCurrentCard(correct);
              }
              _completeStepAndNavigate(context, store, slug);
            },
          ),
        ),
      ],
    );
  }

  bool _currentStepCorrect(
    String slug,
    MemoryCardData card,
    MemoryDeckData deck,
  ) {
    if (slug == '05-bloques') {
      return _blocksAreCorrect();
    }
    if (_isCompletionSlug(slug)) {
      return _completionCorrect(slug, card);
    }
    if (_isFirstLetterSlug(slug)) {
      return _letterCorrect(slug, card);
    }
    if (slug == '09-quiz' || slug == '09-quiz-avanzado') {
      return _quizCorrect(card, deck);
    }
    return true;
  }

  String _footerLabel(
    String slug, {
    required bool checked,
    required bool completed,
  }) {
    if (slug == '00-solo-lectura') {
      return completed ? 'Siguiente →' : 'Toca el texto para revelar palabras';
    }
    if (slug == '01-escuchar') {
      return completed ? 'Siguiente →' : 'Escucha completa requerida';
    }
    if (slug == '03-leer-voz') {
      return completed ? 'Siguiente →' : 'Lee en voz alta para continuar';
    }
    if (slug == '04-escuchar-voz') {
      return completed ? 'Siguiente →' : 'Escucha tu lectura para continuar';
    }
    if (_isFogSlug(slug)) {
      return completed ? 'Siguiente →' : 'Recita para continuar';
    }
    if (_isFinalVoiceSlug(slug)) {
      return completed ? 'Review final →' : 'Recita final para cerrar';
    }
    if (slug == '05-bloques') {
      return _blocksAreCorrect() ? 'Siguiente →' : 'Ordena para continuar';
    }
    if (_isCompletionSlug(slug)) {
      return _completionComplete() ? 'Completado →' : 'Completa los huecos';
    }
    if (_isFirstLetterSlug(slug)) {
      return _letterComplete() ? 'Completado →' : 'Elige primeras letras';
    }
    if (slug == '09-quiz' || slug == '09-quiz-avanzado') {
      if (_quizRounds.isEmpty) return 'Cargando…';
      final round = _quizRounds[_quizRoundIndex];
      if (!round.answered) {
        return round.type == _QuizQuestionType.openQuestion
            ? 'Escribe tu respuesta'
            : 'Elige una opción';
      }
      if (!_quizFinished) return 'Cargando siguiente...';
      return _quizPassed ? 'Completado →' : 'Reintenta';
    }
    if (_isPassiveStep(slug)) {
      return completed ? 'Siguiente →' : 'Marcar terminado';
    }
    return checked ? 'Siguiente →' : 'Comprobar →';
  }

  bool _footerEnabled(
    String slug, {
    required bool checked,
    required bool completed,
  }) {
    if (slug == '01-escuchar') return completed;
    if (slug == '04-escuchar-voz') return completed;
    if (slug == '05-bloques' ||
        slug == '09-quiz' ||
        slug == '09-quiz-avanzado' ||
        _isCompletionSlug(slug) ||
        _isFirstLetterSlug(slug)) {
      return _canAdvanceAnsweredStep(
        slug,
        AppScope.of(context).activeCard,
        AppScope.of(context).activeDeck,
      );
    }
    return true;
  }
}

class _CompletionPromptCard extends StatefulWidget {
  final String label;
  final String text;
  final List<String> targets;
  final List<String?> answers;
  final int activeIndex;
  final ValueChanged<int> onBlankTap;

  const _CompletionPromptCard({
    super.key,
    required this.label,
    required this.text,
    required this.targets,
    required this.answers,
    required this.activeIndex,
    required this.onBlankTap,
  });

  @override
  State<_CompletionPromptCard> createState() => _CompletionPromptCardState();
}

class _CompletionPromptCardState extends State<_CompletionPromptCard> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CompletionPromptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActive();
      });
    }
  }

  void _scrollToActive() {
    final context = _activeKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usedTargetIndexes = <int>{};
    final spans = <InlineSpan>[];
    for (final word in _studyWords(widget.text)) {
      final targetIndex = _matchingUnusedTargetIndex(word, usedTargetIndexes);
      if (targetIndex == null) {
        spans.add(TextSpan(text: '$word '));
        continue;
      }
      usedTargetIndexes.add(targetIndex);
      final active = widget.activeIndex == targetIndex && widget.answers[targetIndex] == null;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 4),
            child: KeyedSubtree(
              key: active ? _activeKey : null,
              child: _CompletionBlank(
                answer: widget.answers[targetIndex],
                active: active,
                complete: widget.answers[targetIndex] != null,
                wordLength: widget.targets[targetIndex].length,
                onTap: () => widget.onBlankTap(targetIndex),
              ),
            ),
          ),
        ),
      );
    }
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .25),
          RefColors.sun.withValues(alpha: .18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              color: RefColors.sun,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: RefColors.ink,
                    fontSize: 20,
                    height: 1.6,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Outfit',
                  ),
                  children: spans,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int? _matchingUnusedTargetIndex(String word, Set<int> usedTargetIndexes) {
    for (var index = 0; index < widget.targets.length; index++) {
      if (usedTargetIndexes.contains(index)) continue;
      if (_sameAnswer(word, widget.targets[index])) return index;
    }
    return null;
  }
}

class _RedFlash extends StatelessWidget {
  final bool active;
  final Widget child;

  const _RedFlash({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? RefColors.urgent.withValues(alpha: .85)
              : Colors.transparent,
          width: 2,
        ),
        color: active
            ? RefColors.urgent.withValues(alpha: .08)
            : Colors.transparent,
      ),
      padding: const EdgeInsets.all(2),
      child: child,
    );
  }
}

class _CoopTurnGlow extends StatefulWidget {
  final bool active;
  final Widget child;

  const _CoopTurnGlow({required this.active, required this.child});

  @override
  State<_CoopTurnGlow> createState() => _CoopTurnGlowState();
}

class _CoopTurnGlowState extends State<_CoopTurnGlow> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glowAnimation = Tween<double>(begin: 4.0, end: 24.0).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );
    if (widget.active) {
      _controller!.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _CoopTurnGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller!.repeat(reverse: true);
      } else {
        _controller!.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _glowAnimation!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: RefColors.lime.withValues(alpha: 0.85),
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: RefColors.lime.withValues(alpha: 0.38),
                blurRadius: _glowAnimation!.value,
                spreadRadius: _glowAnimation!.value / 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: widget.child,
          ),
        );
      },
    );
  }
}



class _CompletionBlank extends StatelessWidget {
  final String? answer;
  final bool active;
  final bool complete;
  final int wordLength;
  final VoidCallback onTap;

  const _CompletionBlank({
    required this.answer,
    required this.active,
    required this.complete,
    required this.wordLength,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = complete
        ? RefColors.lime
        : active
        ? RefColors.cyan
        : RefColors.border;
    final length = wordLength.clamp(1, 14);
    return GestureDetector(
      onTap: complete ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: BoxConstraints(minWidth: (length * 10.0).clamp(28, 160)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: complete || active ? .16 : .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: .62), width: 1.5),
        ),
        child: Text(
          answer ?? '_' * length,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: complete ? RefColors.lime : RefColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ActionCta extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionCta({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (enabled) return Cta(label, onTap: onTap);
    return Opacity(opacity: .45, child: IgnorePointer(child: Cta(label)));
  }
}

class _InlineResult extends StatelessWidget {
  final bool correct;
  final bool neutral;
  final String text;

  const _InlineResult({
    required this.correct,
    required this.text,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = neutral
        ? RefColors.cyan
        : correct
        ? RefColors.lime
        : RefColors.urgent;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Glass(
        padding: const EdgeInsets.all(12),
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .45)),
        child: Text(
          '${neutral
              ? '•'
              : correct
              ? '✓'
              : '×'} $text',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProgressiveFragmentCard extends StatelessWidget {
  final int visibleWords;
  final VoidCallback onTap;

  const _ProgressiveFragmentCard({
    required this.visibleWords,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final safeVisible = visibleWords.clamp(0, words.length);
    final source = _cardSourceText(context);
    return GestureDetector(
      onTap: safeVisible >= words.length ? null : onTap,
      child: Glass(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        gradient: LinearGradient(
          colors: [
            RefColors.violet.withValues(alpha: .22),
            RefColors.cyan.withValues(alpha: .10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                source,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Toca para aclarar lo siguiente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (var i = 0; i < words.length; i++)
                  i < safeVisible
                      ? Text(
                          words[i],
                          style: const TextStyle(
                            fontSize: 24,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                            color: RefColors.ink,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: RefColors.violet.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: RefColors.cyan.withValues(alpha: .30),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                              child: Text(
                                words[i],
                                style: const TextStyle(
                                  fontSize: 24,
                                  height: 1.25,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.transparent, // Totalmente impenetrable
                                ),
                              ),
                            ),
                          ),
                        ),
              ],
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: RefProgress(
                words.isEmpty ? 0 : (safeVisible / words.length).clamp(.05, 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealPairingReview extends StatefulWidget {
  final AppStore store;

  const _RealPairingReview({required this.store});

  @override
  State<_RealPairingReview> createState() => _RealPairingReviewState();
}

class _RealPairingReviewState extends State<_RealPairingReview> {
  int _currentTab = 0; // 0: Asociar, 1: Memoria, 2: Quiz rápido

  // Exercise 1 (Asociar) State
  String? _frontId;
  String? _backId;
  final Set<String> _matched = {};
  int _attempts = 1;
  List<MemoryCardData> _shuffledLeft = [];
  List<MemoryCardData> _shuffledRight = [];
  bool _e1Completed = false;

  // Exercise 2 (Memoria) State
  bool _e2Revealed = false;
  bool _e2Completed = false;

  // Exercise 3 (Quiz rápido) State
  int? _e3SelectedIdx;
  bool _e3Completed = false;
  String _e3CorrectText = '';
  List<String> _e3Options = [];
  String _e3Question = '';

  int? _lastWrongAt;

  void _flagWrong() {
    setState(() {
      _lastWrongAt = DateTime.now().millisecondsSinceEpoch;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() {});
    });
  }

  bool _wrongRecent() {
    final ts = _lastWrongAt;
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < 700;
  }

  void _ensureInitialized(List<MemoryCardData> pool) {
    if (_shuffledLeft.isNotEmpty) return;
    final rng = math.Random();
    
    // Exercise 1 setup
    _shuffledLeft = [...pool]..shuffle(rng);
    _shuffledRight = [...pool]..shuffle(rng);
    
    // Exercise 3 setup based on pool[0]
    final mainCard = pool[0];
    final text = mainCard.back.toLowerCase();
    if (text.contains('puedo') || text.contains('fortalece')) {
      _e3Question = '¿Quién es la fuente de la capacitación espiritual descrita en este versículo?';
      _e3Options = [
        'Cristo, quien infunde poder y sostiene la fe de forma íntima.',
        'La fuerza de voluntad y la determinación psicológica propia.',
        'El cumplimiento estricto de normas legales y rituales.',
      ];
    } else if (text.contains('gracias') || text.contains('misericordia')) {
      _e3Question = '¿Cuál es la base de la alabanza según el texto?';
      _e3Options = [
        'El carácter inherentemente bueno de Dios y la fidelidad eterna de su misericordia.',
        'El merecimiento humano por nuestras buenas obras acumuladas.',
        'La prosperidad transitoria y los bienes temporales obtenidos.',
      ];
    } else if (text.contains('pastor') || text.contains('faltará')) {
      _e3Question = '¿Qué representa Jehová como nuestro pastor según este texto?';
      _e3Options = [
        'Provisión total, cuidado tierno, dirección y paz absoluta.',
        'Juicio condenatorio y castigo para las ovejas desobedientes.',
        'Aislamiento del creyente frente a las dificultades mundanas.',
      ];
    } else {
      _e3Question = '¿Cuál es la implicación práctica de este texto para tu caminar diario?';
      _e3Options = [
        'Meditar constantemente en el mensaje para guiar nuestras decisiones y actitudes.',
        'Seguir tradiciones externas sin experimentar una verdadera transformación del corazón.',
        'Ignorar las promesas divinas en momentos de dificultad cotidiana.',
      ];
    }
    _e3CorrectText = _e3Options[0];
    _e3Options.shuffle(rng);
  }

  void _selectMatchingLeft(String id) {
    if (_matched.contains(id)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _frontId = id;
      _checkMatchingPair();
    });
  }

  void _selectMatchingRight(String id) {
    if (_matched.contains(id)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _backId = id;
      _checkMatchingPair();
    });
  }

  void _checkMatchingPair() {
    final front = _frontId;
    final back = _backId;
    if (front == null || back == null) return;
    
    if (front == back) {
      HapticFeedback.lightImpact();
      setState(() {
        _matched.add(front);
        _frontId = null;
        _backId = null;
        if (_matched.length == 3) {
          _e1Completed = true;
        }
      });
    } else {
      HapticFeedback.mediumImpact();
      _flagWrong();
      setState(() {
        _frontId = null;
        _backId = null;
        if (_attempts < 2) {
          _attempts += 1;
        }
      });
    }
  }

  bool get _currentExerciseCompleted {
    if (_currentTab == 0) return _e1Completed;
    if (_currentTab == 1) return _e2Completed;
    return _e3Completed;
  }

  void _onNextExercise(BuildContext context) {
    HapticFeedback.selectionClick();
    if (_currentTab < 2) {
      setState(() {
        _currentTab += 1;
      });
    } else {
      widget.store.markExerciseStepCompleted('mini-review');
      Navigator.pushNamed(context, '${AppRoutes.flow}/final-review');
    }
  }

  void _onSkip(BuildContext context) {
    HapticFeedback.selectionClick();
    if (_currentTab < 2) {
      setState(() {
        _currentTab += 1;
      });
    } else {
      widget.store.markExerciseStepCompleted('mini-review');
      Navigator.pushNamed(context, '${AppRoutes.flow}/final-review');
    }
  }

  Widget _buildTab(int index, String stepLabel, String label) {
    final active = _currentTab == index;
    final completed = (index == 0 && _e1Completed) || (index == 1 && _e2Completed) || (index == 2 && _e3Completed);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _currentTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? RefColors.pink.withValues(alpha: 0.08)
                : completed
                ? RefColors.lime.withValues(alpha: 0.06)
                : RefColors.glassSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? RefColors.pink
                  : completed
                  ? RefColors.lime
                  : RefColors.border,
              width: active ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                stepLabel,
                style: TextStyle(
                  color: active ? RefColors.pink : RefColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : RefColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MemoryCardData> pool = [...widget.store.activeDeck.cards.take(3)];
    final fallbackCards = [
      const MemoryCardData(id: 'fallback-1', front: 'Sal 23:1', back: 'Jehová es mi pastor; nada me faltará.', source: 'Biblia', icon: '📖'),
      const MemoryCardData(id: 'fallback-2', front: 'Juan 3:16', back: 'De tal manera amó Dios al mundo...', source: 'Biblia', icon: '📖'),
      const MemoryCardData(id: 'fallback-3', front: 'Prov 3:5', back: 'Fíate de Jehová con todo tu corazón...', source: 'Biblia', icon: '📖'),
    ];
    while (pool.length < 3) {
      final extra = fallbackCards[pool.length];
      pool.add(extra);
    }
    _ensureInitialized(pool);

    String title = '';
    String subtitle = '';
    if (_currentTab == 0) {
      title = '📌 Asocia cada referencia con su texto';
      subtitle = 'Toca una referencia y luego su texto - arrastrar también funciona';
    } else if (_currentTab == 1) {
      title = '🧠 Pon a prueba tu retención';
      subtitle = 'Intenta recordar el pasaje de memoria antes de revelar';
    } else {
      title = '⚡ Quiz conceptual rápido';
      subtitle = 'Elige la respuesta correcta sobre el significado';
    }

    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RefBackButton(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '${AppRoutes.flow}/progress-tree',
                      ModalRoute.withName(AppRoutes.home),
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: RefColors.lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: RefColors.lime.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Mini-repaso',
                    style: TextStyle(
                      color: RefColors.lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const RefIconButton(icon: Icons.wb_sunny_outlined),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  RefColors.violet.withValues(alpha: .22),
                  RefColors.sun.withValues(alpha: .18),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: RefColors.border),
            ),
            child: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completaste ${widget.store.sessionCardsCompleted} items',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Antes de seguir, repasa con 3 ejercicios cortos',
                        style: TextStyle(
                          fontSize: 12,
                          color: RefColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTab(0, 'EJ 1', 'Asociar'),
              const SizedBox(width: 8),
              _buildTab(1, 'EJ 2', 'Memoria'),
              const SizedBox(width: 8),
              _buildTab(2, 'EJ 3', 'Quiz rápido'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: RefColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (_currentTab == 0) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: RefColors.pink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_matched.length} / 3 pares',
                      style: const TextStyle(
                        color: RefColors.pink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    'Intentos: $_attempts/2',
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            _RedFlash(
              active: _wrongRecent(),
              child: Glass(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              'REFERENCIAS',
                              style: TextStyle(
                                color: RefColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          for (final card in _shuffledLeft) ...[
                            GestureDetector(
                              onTap: () => _selectMatchingLeft(card.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: _matched.contains(card.id)
                                      ? RefColors.lime.withValues(alpha: 0.12)
                                      : _frontId == card.id
                                      ? RefColors.pink.withValues(alpha: 0.12)
                                      : RefColors.glassStrong,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _matched.contains(card.id)
                                        ? RefColors.lime
                                        : _frontId == card.id
                                        ? RefColors.pink
                                        : RefColors.border,
                                    width: _matched.contains(card.id) || _frontId == card.id ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        card.front,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _matched.contains(card.id) ? RefColors.lime : RefColors.ink,
                                        ),
                                      ),
                                    ),
                                    if (_matched.contains(card.id))
                                      const Icon(Icons.check_circle_rounded, color: RefColors.lime, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              'TEXTOS',
                              style: TextStyle(
                                color: RefColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          for (final card in _shuffledRight) ...[
                            GestureDetector(
                              onTap: () => _selectMatchingRight(card.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: _matched.contains(card.id)
                                      ? RefColors.lime.withValues(alpha: 0.12)
                                      : _backId == card.id
                                      ? RefColors.pink.withValues(alpha: 0.12)
                                      : RefColors.glassStrong,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _matched.contains(card.id)
                                        ? RefColors.lime
                                        : _backId == card.id
                                        ? RefColors.pink
                                        : RefColors.border,
                                    width: _matched.contains(card.id) || _backId == card.id ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '"${_firstWords(card.back, 7)}..."',
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: _matched.contains(card.id) ? RefColors.lime : RefColors.ink,
                                        ),
                                      ),
                                    ),
                                    if (_matched.contains(card.id))
                                      const Icon(Icons.check_circle_rounded, color: RefColors.lime, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, size: 14, color: RefColors.muted),
                SizedBox(width: 6),
                Text(
                  '💡 Toca una referencia y luego su texto correspondiente',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ] else if (_currentTab == 1) ...[
            Glass(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              color: RefColors.glassStrong,
              child: Column(
                children: [
                  Text(
                    pool[0].front,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: RefColors.pink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!_e2Revealed) ...[
                    Container(
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RefColors.glassSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: RefColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_clock, size: 24, color: RefColors.muted),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _e2Revealed = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [RefColors.pink, RefColors.sun]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Revelar texto',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      '"${pool[0].back}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!_e2Completed)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  _e2Completed = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: RefColors.glassSoft,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: RefColors.border),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Olvidé',
                                    style: TextStyle(color: RefColors.ink, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _e2Completed = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [RefColors.pink, RefColors.sun]),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Lo recordé',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: RefColors.lime, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '¡Excelente autoevaluación!',
                            style: TextStyle(color: RefColors.lime, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ] else ...[
            _RedFlash(
              active: _wrongRecent(),
              child: Glass(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _e3Question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _e3Options.length; i++) ...[
                      GestureDetector(
                        onTap: _e3Completed
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _e3SelectedIdx = i;
                                  _e3Completed = true;
                                });
                                if (_e3Options[i] == _e3CorrectText) {
                                  HapticFeedback.lightImpact();
                                } else {
                                  HapticFeedback.mediumImpact();
                                  _flagWrong();
                                }
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _e3Completed && _e3Options[i] == _e3CorrectText
                                ? RefColors.lime.withValues(alpha: 0.12)
                                : _e3SelectedIdx == i
                                ? (_e3Options[i] == _e3CorrectText ? RefColors.lime.withValues(alpha: 0.12) : RefColors.urgent.withValues(alpha: 0.12))
                                : RefColors.glassSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _e3Completed && _e3Options[i] == _e3CorrectText
                                  ? RefColors.lime
                                  : _e3SelectedIdx == i
                                  ? (_e3Options[i] == _e3CorrectText ? RefColors.lime : RefColors.urgent)
                                  : RefColors.border,
                              width: _e3SelectedIdx == i || (_e3Completed && _e3Options[i] == _e3CorrectText) ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _e3Completed && _e3Options[i] == _e3CorrectText
                                      ? RefColors.lime
                                      : _e3SelectedIdx == i
                                      ? (_e3Options[i] == _e3CorrectText ? RefColors.lime : RefColors.urgent)
                                      : RefColors.glassStrong,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: _e3Completed && _e3Options[i] == _e3CorrectText
                                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                                      : _e3SelectedIdx == i
                                      ? const Icon(Icons.close, color: Colors.white, size: 14)
                                      : Text(
                                          String.fromCharCode(65 + i),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _e3Options[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _e3Completed && _e3Options[i] == _e3CorrectText ? RefColors.lime : RefColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Saltar',
                  onTap: () => _onSkip(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _currentExerciseCompleted ? () => _onNextExercise(context) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: _currentExerciseCompleted
                          ? LinearGradient(colors: [RefColors.pink, RefColors.sun])
                          : null,
                      color: _currentExerciseCompleted ? null : RefColors.glassSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _currentExerciseCompleted ? Colors.transparent : RefColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _currentTab < 2 ? 'Siguiente ejercicio →' : 'Finalizar repaso →',
                        style: TextStyle(
                          color: _currentExerciseCompleted ? Colors.white : RefColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _RealFinalReview extends StatelessWidget {
  final AppStore store;

  const _RealFinalReview({required this.store});

  @override
  Widget build(BuildContext context) {
    final deck = store.activeDeck;
    final cards = deck.cards.take(5).toList();
    final retention = deck.retention;
    final totalCards = store.sessionCardsCompleted > 0 ? store.sessionCardsCompleted : 5;
    final timeMin = store.sessionCardsCompleted * 3 + 3;

    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar matching Fin de Sesión exactly
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RefBackButton(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: RefColors.lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: RefColors.lime.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'FIN DE SESIÓN',
                    style: TextStyle(
                      color: RefColors.lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const RefIconButton(icon: Icons.wb_sunny_outlined),
              ],
            ),
          ),
          
          // Gorgeous lime gradient card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5DF07E).withValues(alpha: 0.9),
                  const Color(0xFF38CD6E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38CD6E).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 12),
                const Text(
                  '¡Lo lograste!',
                  style: TextStyle(
                    color: Color(0xFF153A18),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Translucent circular stats block
          Glass(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Circle percent indicator
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: retention / 100,
                          strokeWidth: 9,
                          backgroundColor: RefColors.border.withValues(alpha: 0.1),
                          color: RefColors.lime,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$retention%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'ACIERTO',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: RefColors.muted,
                              letterSpacing: .5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Text details
                Expanded(
                  child: Column(
                    children: [
                      _buildStatRow('Correctas', '${totalCards * 12} / ${totalCards * 13}', RefColors.lime),
                      const Divider(color: RefColors.border, height: 12),
                      _buildStatRow('Incorrectas', '5', RefColors.pink),
                      const Divider(color: RefColors.border, height: 12),
                      _buildStatRow('Tiempo', '$timeMin min', Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Share block
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparte tu logro',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Imagen o texto - sin cuenta necesaria',
                        style: TextStyle(
                          fontSize: 10,
                          color: RefColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Logro copiado al portapapeles!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [RefColors.pink, RefColors.sun]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Compartir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Verses list header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 16, color: RefColors.muted),
                SizedBox(width: 8),
                Text(
                  'LOS VERSÍCULOS ESTUDIADOS',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Studied Verses list
          for (var i = 0; i < cards.length; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RefColors.glassStrong,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RefColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RefColors.glassSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RefColors.border),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: RefColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cards[i].front} · "${_firstWords(cards[i].back, 6)}..."',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '12 pasos · sin errores',
                          style: TextStyle(
                            fontSize: 10,
                            color: RefColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RefColors.lime.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RefColors.lime.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      '✓ 100%',
                      style: TextStyle(
                        color: RefColors.lime,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Bottom Action buttons
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Ver detalles',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cargando estadísticas de precisión detalladas...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Cta(
                  'Volver a Inicio →',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RefColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CustomReorderableDelayedDragStartListener extends ReorderableDragStartListener {
  const _CustomReorderableDelayedDragStartListener({
    required super.child,
    required super.index,
    super.key,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      delay: const Duration(milliseconds: 175), // Highly responsive 175ms delay based on user preference
    );
  }
}

class _BankWord {
  final String id;
  final String word;
  _BankWord({required this.id, required this.word});
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

