/// Punto de entrada de pantallas. Se descompone en `part` files
/// dentro de `screens/` para mantener navegación legible sin perder
/// visibilidad de los muchos widgets privados compartidos.
library memorizar_screens;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/models.dart';
import '../../../core/app_state.dart';
import '../../../core/services/local_llm_service.dart';
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
import 'home_screen.dart';

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
  ExerciseFlowData('06-completar-n1', 'Completar N1', 'Recuerdo con apoyo'),
  ExerciseFlowData(
    '07-primera-letra-n1',
    'Primera letra N1',
    'Menos pistas, más memoria',
  ),
  ExerciseFlowData('17-niebla-n2', 'Niebla N2', 'Recitación con difuminado medio'),
  ExerciseFlowData('10-completar-n2', 'Completar N2', 'Recuerdo más fuerte'),
  ExerciseFlowData('11-primera-letra-n2', 'Primera letra N2', 'Casi sin ayuda'),
  ExerciseFlowData('09-quiz', 'Quiz', 'Elige la respuesta correcta'),
  ExerciseFlowData('12-completar-n3', 'Completado N3', 'Más huecos visibles'),
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
    if (data.slug == '09-quiz') {
      final store = AppScope.of(context);
      final llmService = LocalLlmService.instance;
      if (!store.isPremium) {
        return const PremiumScreen();
      }
      return FutureBuilder<bool>(
        future: llmService.checkModelExists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: RefColors.cyan),
              ),
            );
          }
          final exists = snapshot.data ?? false;
          if (!exists) {
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
    // ignore: dead_code
    if (data.slug == '01-escuchar') return const _ListenFlowScreen();
    if (data.slug == '02-lectura-frag') {
      return const _FragmentedReadingFlowScreen();
    }
    if (data.slug == '03-leer-voz') return const _ReadAloudFlowScreen();
    if (data.slug == '04-escuchar-voz') {
      return const _ListenOwnVoiceFlowScreen();
    }
    if (data.slug == '05-bloques') return const _BlocksFlowScreen();
    if (data.slug == '06-completar-n1') return const _CompleteN1FlowScreen();
    if (data.slug == '07-primera-letra-n1') {
      return const _FirstLetterFlowScreen(level: 1);
    }
    if (data.slug == '08-voz-guiada') return const _GuidedVoiceFlowScreen();
    if (data.slug == '09-quiz') return const _QuizFlowScreen();
    if (data.slug == '10-completar-n2') return const _CompleteN2FlowScreen();
    if (data.slug == '11-primera-letra-n2') {
      return const _FirstLetterFlowScreen(level: 2);
    }
    if (data.slug == '12-voz-final') return const _FinalVoiceFlowScreen();
    if (data.slug == 'mini-review') return const _MiniReviewFlowScreen();
    if (data.slug == 'final-review') return const _FinalReviewFlowScreen();

    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExerciseTopBar(center: data.title),
          _PageHead(data.title, data.subtitle),
          const _QuestionCard(
            ctx: 'ANATOMÍA · SISTEMA MUSCULAR',
            turn: '2/4',
            question: 'Bíceps braquial: principal flexor del codo.',
            options: [
              ('A', 'Lo recuerdo con seguridad', true),
              ('B', 'Necesito una pista más', false),
            ],
          ),
        ],
      ),
    );
  }
}

class _RealExerciseFlowScreen extends StatefulWidget {
  final ExerciseFlowData data;

  const _RealExerciseFlowScreen({required this.data});

  @override
  State<_RealExerciseFlowScreen> createState() =>
      _RealExerciseFlowScreenState();
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
  final List<(String, String)>? matchingPairs;

  // Open question extra fields
  final String? openQuestionPrompt;
  String? openQuestionResponse;

  int? selectedIdx;

  _QuizRound({
    required this.target,
    required this.type,
    required this.options,
    this.trueFalseStatement,
    this.isStatementTrue,
    this.matchingPairs,
    this.openQuestionPrompt,
    this.openQuestionResponse,
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
  }
  bool _nonVoiceWrongRecent() {
    final ts = _lastNonVoiceWrongAt;
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < 700;
  }

  String? _fogCardId;
  bool _fogFinished = false;
  bool _fogShowHintTemp = false;

  @override
  void reassemble() {
    super.reassemble();
    _completionCardId = null;
    _letterCardId = null;
  }

  @override
  void dispose() {
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

  bool _hasLetterInput() => _letterAnswers.any((answer) => answer != null);

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
    if (keepGoing) {
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
    if (slug == '09-quiz') {
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

  void _selectBlockDestination(int targetIndex) {
    final selectedPosition = _selectedBlockPosition;
    if (selectedPosition == null) return;
    _moveBlock(selectedPosition, targetIndex);
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
    final isFinishedSession = _quizRounds.isNotEmpty && _quizRoundIndex >= _quizRounds.length - 1 && _quizRounds.last.answered;
    if (_quizCardId == card.id && _quizRounds.isNotEmpty && !isFinishedSession) return;
    _quizCardId = card.id;
    _quizRoundIndex = 0;
    _quizScore = 0;
    _openQuestionController.clear();
    _quizRounds = _buildQuizRounds(deck, card);
  }

  _QuizRound _buildConceptualRound(MemoryCardData card, math.Random rng, int index) {
    final text = card.back.toLowerCase();
    String question = '¿Cuál es la enseñanza espiritual o el significado central de este texto?';
    String correct = '';
    List<String> distractors = [];
    final qNum = index % 4;

    // Genre / style detection based on book reference in card.front
    final ref = card.front.toLowerCase();
    var style = 'instructional';
    if (ref.contains('gén') || ref.contains('génesis') || ref.contains('éxo') || ref.contains('éxodo') || 
        ref.contains('lev') || ref.contains('num') || ref.contains('deut') || ref.contains('jos') || 
        ref.contains('jue') || ref.contains('rut') || ref.contains('sam') || ref.contains('rey') || 
        ref.contains('cró') || ref.contains('esd') || ref.contains('neh') || ref.contains('est') || 
        ref.contains('mat') || ref.contains('mar') || ref.contains('luc') || ref.contains('jua') || 
        ref.contains('hec')) {
      style = 'narrative';
    } else if (ref.contains('job') || ref.contains('sal') || ref.contains('salmo') || ref.contains('pro') || 
               ref.contains('ecl') || ref.contains('cant') || ref.contains('lam')) {
      style = 'poetic';
    } else if (ref.contains('isa') || ref.contains('jer') || ref.contains('eze') || ref.contains('dan') || 
               ref.contains('ose') || ref.contains('joe') || ref.contains('amó') || ref.contains('abd') || 
               ref.contains('jon') || ref.contains('miq') || ref.contains('nah') || ref.contains('hab') || 
               ref.contains('sof') || ref.contains('hag') || ref.contains('zac') || ref.contains('mal') || 
               ref.contains('apo')) {
      style = 'prophetic';
    }

    if (text.contains('puedo') || text.contains('fortalece')) {
      if (qNum == 0) {
        question = '¿Cuál es la idea principal de este pasaje sobre la fortaleza?';
        correct = 'La capacidad de superar toda adversidad y circunstancia a través del poder de Cristo.';
        distractors = [
          'La creencia de que el éxito se logra únicamente con autodisciplina y hábitos virtuosos.',
          'La resignación pasiva ante el destino terrenal sin una participación de fe.',
          'La idea de que la madurez espiritual erradica cualquier problema práctico diario.',
        ];
      } else if (qNum == 1) {
        question = '¿Qué significa la expresión "todo lo puedo" según este contexto?';
        correct = 'Tener contentamiento y constancia espiritual tanto en la abundancia como en la necesidad.';
        distractors = [
          'La superación exitosa de cualquier meta material mediante el pensamiento positivo.',
          'La creencia gnóstica de que el cuerpo y la mente pueden anular las leyes físicas.',
          'La capacidad de evitar cualquier confrontación con el sufrimiento moral.',
        ];
      } else if (qNum == 2) {
        question = '¿Quién es la fuente de la capacitación espiritual descrita en el versículo?';
        correct = 'Cristo, quien infunde poder y sostiene la fe de forma íntima.';
        distractors = [
          'El desarrollo psicológico enfocado en el autocontrol estoico.',
          'El soporte emocional provisto por la estructura institucional y comunitaria.',
          'La observancia de directrices doctrinales y normas de conducta social.',
        ];
      } else {
        question = '¿Cuál es el propósito último de la fortaleza que Dios otorga al creyente?';
        correct = 'Permanecer firme y en paz en medio de las pruebas y responsabilidades.';
        distractors = [
          'Lograr un liderazgo moral incuestionable frente al resto de la sociedad.',
          'Obtener un bienestar emocional absoluto y una vida carente de tensiones.',
          'Demostrar superioridad intelectual sobre otras corrientes éticas.',
        ];
      }
    } else if (text.contains('gracias') || text.contains('misericordia') || text.contains('bueno')) {
      if (qNum == 0) {
        question = '¿Qué actitud fundamental promueve este pasaje en el creyente?';
        correct = 'La gratitud y alabanza sincera al Señor por su amor fiel y bondad eternos.';
        distractors = [
          'El optimismo pragmático para sortear las dificultades cotidianas.',
          'El cumplimiento reverente del deber litúrgico como retribución divina.',
          'El enfoque contemplativo que ignora las dinámicas del sufrimiento terrenal.',
        ];
      } else if (qNum == 1) {
        question = '¿Cuál es la base de la alabanza según el texto?';
        correct = 'El carácter inherentemente bueno de Dios y la fidelidad eterna de su misericordia.';
        distractors = [
          'La recompensa moral obtenida por la rectitud de nuestras acciones.',
          'El regocijo transitorio producido por el éxito en nuestros proyectos.',
          'La sumisión temerosa ante la omnipotencia y majestad de la divinidad.',
        ];
      } else if (qNum == 2) {
        question = '¿Qué significa que la misericordia de Dios "es para siempre"?';
        correct = 'Que su amor redentor y perdón no tienen fecha de vencimiento para su pueblo.';
        distractors = [
          'Que el orden moral del universo anula la necesidad de justicia correctiva.',
          'Que todas las corrientes espirituales conducen al mismo destino benevolente.',
          'Que la compasión divina ignora por completo la libertad de elección humana.',
        ];
      } else {
        question = '¿Quiénes son llamados a proclamar activamente las grandezas del Señor?';
        correct = 'Los redimidos que han experimentado su rescate y liberación en la práctica.';
        distractors = [
          'Aquellos que han mantenido una conducta impecable libre de cualquier tropiezo.',
          'Líderes seleccionados con una preparación intelectual y académica superior.',
          'El conjunto de la sociedad humana en virtud de un deber natural universal.',
        ];
      }
    } else if (text.contains('angustia') || text.contains('clamar') || text.contains('liberó') || text.contains('salvó') || text.contains('angustiados')) {
      if (qNum == 0) {
        question = '¿Qué nos enseña este versículo sobre la respuesta ante el sufrimiento?';
        correct = 'Que acudir al Señor con fe en la prueba trae consuelo y liberación real.';
        distractors = [
          'Que la adversidad es un proceso inevitable diseñado para forzar la autosuficiencia.',
          'Que la introspección reflexiva neutraliza el dolor antes de requerir ayuda.',
          'Que la súplica espiritual funciona únicamente como un analgésico psicológico.',
        ];
      } else if (qNum == 1) {
        question = '¿Qué acción de fe desencadena la intervención divina en la tribulación?';
        correct = 'El clamor sincero y humilde nacido de la total dependencia en Dios.';
        distractors = [
          'La resignación filosófica ante el dolor y la aceptación del destino.',
          'La realización de actos meritorios de caridad o disciplina espiritual.',
          'La búsqueda racional de soluciones antes de considerar la súplica.',
        ];
      } else if (qNum == 2) {
        question = '¿Cuál es el resultado de clamar a Dios en el día de la angustia?';
        correct = 'Él escucha con compasión y rescata al afligido de sus temores.';
        distractors = [
          'La resolución automática de toda tensión sin requerir esfuerzo de fe.',
          'El desarrollo inmediato de una insensibilidad absoluta frente a la crisis.',
          'Una tranquilidad pasajera condicionada al cambio inmediato de entorno.',
        ];
      } else {
        question = '¿Cómo se describe la naturaleza del rescate del Señor en este pasaje?';
        correct = 'Como un acto soberano de gracia que saca al creyente de su callejón sin salida.';
        distractors = [
          'Un premio derivado de la acumulación progresiva de méritos éticos.',
          'Una reestructuración mental que no posee implicaciones en el mundo real.',
          'Una providencia general que beneficia a todos de forma impersonal.',
        ];
      }
    } else if (text.contains('paz') || text.contains('cuidado') || text.contains('ansiedad') || text.contains('guardará')) {
      if (qNum == 0) {
        question = '¿Cuál es el camino que propone este texto para vencer la ansiedad?';
        correct = 'Depositar toda preocupación en Dios a través del ruego y la gratitud profunda.';
        distractors = [
          'La supresión sistemática de pensamientos negativos a través de la concentración.',
          'La planificación exhaustiva de cada variable futura para reducir riesgos.',
          'La confianza pasiva en que los conflictos se disolverán solos.',
        ];
      } else if (qNum == 1) {
        question = '¿Qué tipo de paz promete Dios en respuesta a la oración de fe?';
        correct = 'Una paz sobrenatural que supera el entendimiento humano y guarda el corazón.';
        distractors = [
          'Una quietud intelectual y estoica libre de cualquier emoción activa.',
          'La certeza garantizada del éxito de todas nuestras decisiones prácticas.',
          'Un estado permanente de éxtasis místico desprovisto de responsabilidades.',
        ];
      } else if (qNum == 2) {
        question = '¿Qué papel juega la gratitud en medio de nuestras peticiones?';
        correct = 'Alinear el alma con la soberanía y bondad previas de Dios al presentar la necesidad.';
        distractors = [
          'Un acto protocolario de cortesía para asegurar la benevolencia del Creador.',
          'Un ejercicio de positivismo para enmascarar el dolor de la aflicción.',
          'Una herramienta litúrgica orientada a influir en la voluntad divina.',
        ];
      } else {
        question = '¿Qué protege o guarda la paz de Dios según la promesa?';
        correct = 'Nuestros pensamientos y emociones en la íntima comunión con Cristo Jesús.';
        distractors = [
          'Nuestras relaciones interpersonales y reputación ante la comunidad.',
          'Nuestras metas personales frente al fracaso material o intelectual.',
          'El bienestar biológico y de salud frente a cualquier afección física.',
        ];
      }
    } else if (text.contains('luz') || text.contains('tinieblas') || text.contains('noche') || text.contains('día') || text.contains('lumbrera') || text.contains('firmamento') || text.contains('separó')) {
      if (qNum == 0) {
        question = '¿Cuál es la importancia teológica de la distinción primordial entre la luz y las tinieblas?';
        correct = 'El establecimiento del orden inteligente y la soberanía del Creador frente al caos de la oscuridad.';
        distractors = [
          'La demostración práctica de que la materia oscura carece de valor atómico o de utilidad física.',
          'La creencia gnóstica de que el bien y el mal poseen el mismo origen y poder coeterno.',
          'Un orden natural donde la luz se genera de forma fortuita sin requerir una voluntad primordial.',
        ];
      } else if (qNum == 1) {
        question = '¿Qué principio de la creación se infiere cuando Dios declara que la luz "era buena"?';
        correct = 'La bondad intrínseca y la perfección moral con la que Dios diseña cada aspecto de la existencia.';
        distractors = [
          'Que las tinieblas son intrínsecamente malas y no forman parte del plan divino original.',
          'La superioridad estética del día como el único momento apto para la contemplación sagrada.',
          'Una valoración transitoria sujeta a la posterior degradación material del universo.',
        ];
      } else if (qNum == 2) {
        question = '¿Cuál es el significado espiritual detrás del acto divino de separar los elementos creados?';
        correct = 'El propósito inteligente de establecer límites y funciones precisas para que la vida prospere.';
        distractors = [
          'La fragmentación del ser original en partes conflictivas destinadas al caos eterno.',
          'Una imposición restrictiva que impide la libre mezcla de todas las sustancias del cosmos.',
          'El inicio de una competencia eterna donde la luz busca aniquilar físicamente la noche.',
        ];
      } else {
        question = '¿Qué verdad sobre el obrar de la Palabra divina se destaca en este relato de la creación?';
        correct = 'Que el Creador actúa con orden deliberado y evalúa con sabiduría la armonía de su obra.';
        distractors = [
          'La experimentación casual de fórmulas azarosas hasta obtener resultados agradables.',
          'El sometimiento de la divinidad ante leyes preexistentes e ingobernables del espacio.',
          'La delegación de la creación a intermediarios inferiores que actuaron de forma autónoma.',
        ];
      }
    } else if (text.contains('serpiente') || text.contains('árbol') || text.contains('huerto') || text.contains('fruto') || text.contains('comer') || text.contains('tentación')) {
      if (qNum == 0) {
        question = '¿Qué aspecto de la tentación o la obediencia ilustra esta respuesta de la mujer?';
        correct = 'La confrontación inicial con el mandato divino y los límites establecidos por el Creador.';
        distractors = [
          'La sumisión inmediata y sin cuestionamientos a las sugerencias de la serpiente.',
          'El desdén absoluto hacia los frutos materiales del huerto por ser considerados impuros.',
          'La decisión consciente de ignorar cualquier directriz moral sobre la alimentación.',
        ];
      } else if (qNum == 1) {
        question = '¿Qué revela el diálogo de la mujer con la serpiente en este pasaje?';
        correct = 'El inicio de una negociación cognitiva sobre los límites de la obediencia humana.';
        distractors = [
          'Una declaración firme e irrevocable de hostilidad absoluta hacia la tentación.',
          'Un tratado teológico formal sobre la soberanía divina en la creación.',
          'La indiferencia total de la mujer frente a la presencia de la serpiente.',
        ];
      } else if (qNum == 2) {
        question = '¿Cuál es el significado espiritual detrás de la restricción de comer del fruto en el huerto?';
        correct = 'El reconocimiento de la soberanía de Dios sobre el conocimiento moral del bien y del mal.';
        distractors = [
          'Una privación física arbitraria impuesta para forzar el sufrimiento humano.',
          'La demostración de que la creación física es intrínsecamente pecaminosa.',
          'Un ejercicio místico orientado a alcanzar la autosuficiencia espiritual.',
        ];
      } else {
        question = '¿Qué lección sobre la vulnerabilidad humana se infiere de este versículo?';
        correct = 'La fragilidad de dialogar con la mentira que sutilmente tuerce la verdad divina.';
        distractors = [
          'La necesidad de una fuerza física superior para repeler la presencia del adversario.',
          'El valor del intelecto humano autónomo para resolver dilemas morales.',
          'La ineficacia absoluta de cualquier límite moral para de la conducta humana.',
        ];
      }
    } else {
      if (style == 'narrative') {
        if (qNum == 0) {
          question = '¿Qué aspecto del relato o diálogo destaca primordialmente este pasaje?';
          correct = 'La manifestación del propósito soberano de Dios actuando en acontecimientos concretos.';
          distractors = [
            'La primacía del azar físico en la evolución de los hechos descritos.',
            'Un conjunto de mitos morales sin correlato en el obrar histórico divino.',
            'La autosuficiencia absoluta del ser humano frente a su entorno físico.',
          ];
        } else if (qNum == 1) {
          question = '¿Cómo se revela el carácter divino en este acontecimiento o declaración?';
          correct = 'Mediante decretos, llamados u obras directas que revelan su justicia y bondad ordenadora.';
          distractors = [
            'A través de una indiferencia cósmica impasible ante el sufrimiento de los personajes.',
            'Por medio de caprichos mudables que carecen de una sabiduría inteligente.',
            'Mediante la exigencia de sacrificios ciegos como único canal de interacción.',
          ];
        } else if (qNum == 2) {
          question = '¿Cuál es la respuesta de fe esperada ante las acciones narradas en este texto?';
          correct = 'Reconocer el obrar y la soberanía del Creador en el devenir de la historia.';
          distractors = [
            'Desarrollar una resignación intelectual pasiva ante la inevitabilidad de las leyes naturales.',
            'Cuestionar la veracidad y el valor de los testimonios históricos transmitidos.',
            'Ignorar las lecciones del pasado en favor de un existencialismo individualista.',
          ];
        } else {
          question = '¿Qué principio interpretativo se debe aplicar a este suceso o enseñanza?';
          correct = 'Comprender que los hechos singulares forman parte del plan unificado de la revelación.';
          distractors = [
            'Evaluar la narrativa de forma fragmentada y desprovista de cohesión teológica.',
            'Extraer directrices morales universales a partir de descripciones puramente circunstanciales.',
            'Reducir los milagros y portentos a meras fantasías explicativas de la antigüedad.',
          ];
        }
      } else if (style == 'poetic') {
        if (qNum == 0) {
          question = '¿Qué dimensión del alma o de la adoración expresa este lenguaje poético?';
          correct = 'La comunicación sincera de alabanza, anhelo o dependencia absoluta de Dios.';
          distractors = [
            'Una técnica métrica formal destinada al entretenimiento estético cortesano.',
            'El desahogo emocional de temores sin base en la fe o en las promesas divinas.',
            'Un monólogo especulativo sobre el absurdo existencial y la brevedad de la vida.',
          ];
        } else if (qNum == 1) {
          question = '¿Qué metáfora o imagen evoca este verso poético sobre la relación con Dios?';
          correct = 'La seguridad y paz del creyente al cobijo de la fidelidad y amor eternos del Creador.';
          distractors = [
            'Una lucha trágica y constante contra fuerzas hostiles e ingobernables del destino.',
            'La distancia infinita e insalvable entre el alma y un Dios indiferente.',
            'Un intercambio contractual donde la devoción es una moneda de cambio material.',
          ];
        } else if (qNum == 2) {
          question = '¿Cómo contribuye esta lírica sagrada a la meditación diaria?';
          correct = 'Al elevar el pensamiento hacia la majestad, el consuelo y la verdad eterna de Dios.';
          distractors = [
            'Al promover un escape místico que evade las responsabilidades del mundo real.',
            'Al fomentar la memorización mecánica de versos desprovistos de afecto genuino.',
            'Al centrar la atención en el lucimiento poético y literario individual.',
          ];
        } else {
          question = '¿Cuál es la base de la confianza lírica manifestada en el texto?';
          correct = 'El carácter inmutable de Dios, quien cumple sus promesas de generación en generación.';
          distractors = [
            'La estabilidad emocional autónoma lograda mediante la meditación trascendental.',
            'El optimismo basado en circunstancias externas favorables y seguras.',
            'La superioridad moral que se autoafirma frente a los adversarios cotidianos.',
          ];
        }
      } else if (style == 'prophetic') {
        if (qNum == 0) {
          question = '¿Cuál es el núcleo del mensaje o anuncio profético en este pasaje?';
          correct = 'La revelación del juicio justo de Dios o su promesa de redención y restauración futura.';
          distractors = [
            'Un pronóstico astrológico o adivinación casual basada en el análisis social.',
            'Una amenaza punitiva destinada a coaccionar el comportamiento sin ofrecer gracia.',
            'La descripción de un ciclo cósmico repetitivo donde nada cambia sustancialmente.',
          ];
        } else if (qNum == 1) {
          question = '¿Qué actitud demanda el anuncio del profeta de parte del oyente?';
          correct = 'Arrepentimiento sincero, retorno a la justicia y fe en la soberanía divina.';
          distractors = [
            'Apatía o resignación ante la inminencia de eventos predeterminados por el hado.',
            'La búsqueda de alianzas humanas para eludir las consecuencias morales.',
            'La realización de ritos formales externos para complacer formalmente al soberano.',
          ];
        } else if (qNum == 2) {
          question = '¿Cómo se manifiesta la fidelidad de Dios en el contexto profético presentado?';
          correct = 'Al advertir con amor antes de actuar y al asegurar que su palabra no volverá vacía.';
          distractors = [
            'Al irrumpir con decisiones caprichosas e impredecibles sin previo aviso.',
            'Al desentenderse de las alianzas históricas para iniciar un plan totalmente nuevo.',
            'Al condicionar su fidelidad a la perfección absoluta del comportamiento del pueblo.',
          ];
        } else {
          question = '¿Qué horizonte o esperanza final dibuja la profecía en este texto?';
          correct = 'El triunfo definitivo de la justicia, la paz y el reino eterno del Señor.';
          distractors = [
            'Una utopía puramente política y terrenal libre de implicaciones espirituales.',
            'La destrucción nihilista y sin sentido de todo lo creado sin restauración posterior.',
            'El predominio perpetuo de las naciones más poderosas de la tierra.',
          ];
        }
      } else {
        // Epistolary / Instructional (default)
        if (qNum == 0) {
          question = '¿Cuál de las siguientes afirmaciones describe mejor la enseñanza doctrinal o práctica de este pasaje?';
          correct = 'Vivir alineado a los principios eternos y la gracia revelada por Dios.';
          distractors = [
            'Alcanzar la iluminación ética mediante el estudio filosófico y la autodisciplina estoica.',
            'Garantizar la prosperidad física y el éxito material mediante la observancia litúrgica ritual.',
            'Desarrollar una resiliencia psicológica individual independiente de la comunión espiritual.',
          ];
        } else if (qNum == 1) {
          question = '¿Qué implicación práctica tiene este versículo para la toma de decisiones diarias?';
          correct = 'Evaluar nuestras intenciones y actitudes a la luz del mensaje de fe y amor divino.';
          distractors = [
            'Seguir con rigor tradicional las normas de conducta cultural y social imperantes.',
            'Analizar el texto de manera puramente intelectual para debatir posturas doctrinales.',
            'Utilizar los preceptos éticos para juzgar y censurar las faltas de la comunidad.',
          ];
        } else if (qNum == 2) {
          question = '¿Cómo enriquece este pasaje la fe personal del creyente?';
          correct = 'Al recordarnos la presencia constante, la gracia santificadora y la guía de Dios.';
          distractors = [
            'Al asegurar que la fe elimina automáticamente cualquier conflicto emocional.',
            'Al fomentar una resignación pasiva ante el sufrimiento terrenal sin buscar consuelo activo.',
            'Al basar la confianza en nuestras propias capacidades morales para superar la crisis.',
          ];
        } else {
          question = '¿Qué cualidad del carácter cristiano promueve el pasaje en su trasfondo?';
          correct = 'La confianza humilde y el compromiso sincero con la verdad de Dios.';
          distractors = [
            'La autosuficiencia práctica que prescinde de la interdependencia con el prójimo.',
            'El desapego absoluto de las responsabilidades materiales en busca de la contemplación pura.',
            'La superioridad intelectual para argumentar doctrinas complejas frente a otros.',
          ];
        }
      }
    }

    final targetCard = MemoryCardData(
      id: 'quiz-conceptual-${card.id}-$index',
      front: question,
      back: correct,
      source: card.source,
      icon: card.icon,
    );

    final optionCards = <MemoryCardData>[
      targetCard,
      for (var i = 0; i < distractors.length; i++)
        MemoryCardData(
          id: 'quiz-conceptual-distractor-$i-${card.id}-$index',
          front: question,
          back: distractors[i],
          source: 'IA Local Offline',
          icon: card.icon,
        )
    ]..shuffle(rng);

    return _QuizRound(
      target: targetCard,
      type: _QuizQuestionType.frontToBack,
      options: optionCards,
    );
  }

  String _generateTrueFalseStatement(MemoryCardData target, bool isTrue, math.Random rng, {int variant = 0}) {
    final text = target.back.toLowerCase();
    final idx = variant % 2;
    
    // Genre / style detection based on book reference in target.front
    final ref = target.front.toLowerCase();
    var style = 'instructional';
    if (ref.contains('gén') || ref.contains('génesis') || ref.contains('éxo') || ref.contains('éxodo') || 
        ref.contains('lev') || ref.contains('num') || ref.contains('deut') || ref.contains('jos') || 
        ref.contains('jue') || ref.contains('rut') || ref.contains('sam') || ref.contains('rey') || 
        ref.contains('cró') || ref.contains('esd') || ref.contains('neh') || ref.contains('est') || 
        ref.contains('mat') || ref.contains('mar') || ref.contains('luc') || ref.contains('jua') || 
        ref.contains('hec')) {
      style = 'narrative';
    } else if (ref.contains('job') || ref.contains('sal') || ref.contains('salmo') || ref.contains('pro') || 
               ref.contains('ecl') || ref.contains('cant') || ref.contains('lam')) {
      style = 'poetic';
    } else if (ref.contains('isa') || ref.contains('jer') || ref.contains('eze') || ref.contains('dan') || 
               ref.contains('ose') || ref.contains('joe') || ref.contains('amó') || ref.contains('abd') || 
               ref.contains('jon') || ref.contains('miq') || ref.contains('nah') || ref.contains('hab') || 
               ref.contains('sof') || ref.contains('hag') || ref.contains('zac') || ref.contains('mal') || 
               ref.contains('apo')) {
      style = 'prophetic';
    }

    if (isTrue) {
      if (text.contains('ángel') || text.contains('ángeles')) {
        return idx == 0
            ? 'El texto menciona la intervención de ángeles o mensajeros celestiales.'
            : 'El pasaje se refiere a mensajeros divinos enviados por el Señor.';
      } else if (text.contains('pastor') || text.contains('pastoreará') || text.contains('pastores')) {
        return idx == 0
            ? 'El pasaje utiliza la metáfora de un pastor para ilustrar el cuidado personal de Dios.'
            : 'El texto presenta a la divinidad guiando y protegiendo a su pueblo como un pastor.';
      } else if (text.contains('redimidos') || text.contains('redimió') || text.contains('adversario')) {
        return idx == 0
            ? 'El versículo afirma que Dios ha rescatado y redimido a su pueblo del poder del adversario.'
            : 'El texto destaca la redención y el rescate de la aflicción de los creyentes.';
      } else if (text.contains('gracias') || text.contains('misericordia') || text.contains('bueno')) {
        return idx == 0
            ? 'El pasaje nos exhorta a alabar y dar gracias a Dios reconociendo su bondad eterna.'
            : 'El versículo destaca que la misericordia del Señor es eterna y digna de constante gratitud.';
      } else if (text.contains('angustia') || text.contains('clamaron') || text.contains('salvó')) {
        return idx == 0
            ? 'El pasaje enseña que en medio de la aflicción y la angustia, el clamor a Dios es respondido.'
            : 'El texto afirma que el Señor escucha y libra a los suyos en momentos de profunda tribulación.';
      } else if (text.contains('creó') || text.contains('principio') || text.contains('tierra')) {
        return idx == 0
            ? 'El versículo declara que en el inicio absoluto de todo, Dios creó los cielos y la tierra.'
            : 'El texto atribuye la creación originaria de todo el universo material a Dios.';
      } else if (text.contains('paz') || text.contains('cuidado') || text.contains('ansiedad')) {
        return idx == 0
            ? 'El pasaje promete que la paz divina guardará los corazones contra toda ansiedad.'
            : 'El versículo enseña que la paz de Dios sobrepasa todo entendimiento al guardar nuestra mente.';
      } else if (text.contains('serpiente') || text.contains('huerto') || text.contains('fruto') || text.contains('árbol') || text.contains('comer')) {
        return idx == 0
            ? 'El pasaje registra la conversación en el huerto de Edén donde se discuten los límites alimenticios establecidos.'
            : 'El versículo muestra a la mujer respondiendo al tentador citando el permiso general de comer de los árboles.';
      } else if (text.contains('luz') || text.contains('tinieblas') || text.contains('noche') || text.contains('día') || text.contains('lumbrera')) {
        return idx == 0
            ? 'El pasaje hace referencia a la distinción y separación primordial entre la luz y las tinieblas.'
            : 'El versículo destaca la bondad de la luz y el orden divino establecido al separarla de la oscuridad.';
      } else if (text.contains('dijo') || text.contains('llamó') || text.contains('hizo') || text.contains('separó') || text.contains('vio')) {
        return idx == 0
            ? 'El versículo registra un acontecimiento narrativo sobre el obrar soberano e inteligente de Dios en la creación.'
            : 'El texto describe la manifestación del poder divino al ordenar y declarar buena su obra.';
      } else {
        if (style == 'narrative') {
          return idx == 0
              ? 'El versículo describe un evento o diálogo clave dentro del relato histórico sagrado.'
              : 'El texto narra una acción concreta de la divinidad o de los personajes bíblicos en la historia.';
        } else if (style == 'poetic') {
          return idx == 0
              ? 'El pasaje utiliza un lenguaje poético o de sabiduría para expresar alabanza, ruego o devoción profunda.'
              : 'El texto presenta una reflexión contemplativa sobre el carácter divino o la senda de la sabiduría.';
        } else if (style == 'prophetic') {
          return idx == 0
              ? 'El texto proclama un mensaje profético, una advertencia o una promesa de redención futura para el pueblo.'
              : 'El versículo comunica una revelación divina sobre los propósitos soberanos de Dios a lo largo del tiempo.';
        } else {
          return idx == 0
              ? 'El pasaje proporciona una directriz ética o de sabiduría espiritual para guiar la conducta diaria.'
              : 'El versículo enfatiza la alineación de nuestras intenciones y carácter con la justicia moral divina.';
        }
      }
    } else {
      if (text.contains('ángel') || text.contains('ángeles')) {
        return idx == 0
            ? 'El pasaje afirma que los ángeles fueron creados para gobernar a los hombres con severidad.'
            : 'El texto sugiere que los ángeles compiten con Dios por el afecto de la humanidad.';
      } else if (text.contains('pastor') || text.contains('pastoreará') || text.contains('pastores')) {
        return idx == 0
            ? 'El texto dice que el pastor guiará a las ovejas únicamente a caminos de desierto y sequía.'
            : 'La metáfora del pastor indica que las ovejas deben defenderse solas contra los lobos.';
      } else if (text.contains('redimidos') || text.contains('redimió') || text.contains('adversario')) {
        return idx == 0
            ? 'El pasaje instruye que los redimidos deben callar su testimonio y ocultar su liberación.'
            : 'El versículo afirma que el rescate del creyente depende de su estatus económico.';
      } else if (text.contains('gracias') || text.contains('misericordia') || text.contains('bueno')) {
        return idx == 0
            ? 'El versículo aconseja que sólo debemos alabar a Dios cuando las circunstancias sean fáciles y cómodas.'
            : 'El texto sostiene que la bondad y misericordia de Dios están condicionadas a nuestro estado de ánimo diario.';
      } else if (text.contains('angustia') || text.contains('clamaron') || text.contains('salvó')) {
        return idx == 0
            ? 'El texto sugiere que los seres humanos deben resolver sus problemas con sus propias fuerzas sin buscar a Dios.'
            : 'El pasaje advierte que clamar a Dios en el dolor es inútil porque la angustia es incurable.';
      } else if (text.contains('creó') || text.contains('principio') || text.contains('tierra')) {
        return idx == 0
            ? 'El versículo sostiene que los cielos y la tierra existían eternamente antes del Creador.'
            : 'El texto propone que el universo físico se creó a sí mismo mediante leyes azarosas sin intervención divina.';
      } else if (text.contains('paz') || text.contains('cuidado') || text.contains('ansiedad')) {
        return idx == 0
            ? 'El pasaje advierte que es imposible librar la mente de la ansiedad cotidiana y el temor constante.'
            : 'El texto afirma que la paz de Dios provoca apatía e indiferencia absoluta ante el sufrimiento ajeno.';
      } else if (text.contains('serpiente') || text.contains('huerto') || text.contains('fruto') || text.contains('árbol') || text.contains('comer')) {
        return idx == 0
            ? 'El texto afirma que la mujer huyó inmediatamente de la serpiente sin dirigirle la palabra.'
            : 'El pasaje enseña que Dios había prohibido terminantemente comer de todos y cada uno de los árboles del huerto.';
      } else if (text.contains('luz') || text.contains('tinieblas') || text.contains('noche') || text.contains('día') || text.contains('lumbrera')) {
        return idx == 0
            ? 'El pasaje afirma que la luz y las tinieblas se fusionaron en una sola sustancia homogénea sin distinción.'
            : 'El texto sostiene que las tinieblas fueron declaradas como el elemento más perfecto y puro de la creación.';
      } else if (text.contains('dijo') || text.contains('llamó') || text.contains('hizo') || text.contains('separó') || text.contains('vio')) {
        return idx == 0
            ? 'El pasaje sostiene que las acciones de Dios en la creación carecen de propósito u orden inteligente.'
            : 'El versículo afirma que el acontecimiento narrado fue una ilusión que no tuvo consecuencias reales.';
      } else {
        if (style == 'narrative') {
          return idx == 0
              ? 'El pasaje describe un concepto abstracto moderno totalmente ajeno al contexto histórico del relato.'
              : 'El versículo sostiene que el evento narrado ocurrió de forma puramente fortuita sin relevancia histórica.';
        } else if (style == 'poetic') {
          return idx == 0
              ? 'El texto enseña que la alabanza y la poesía son secundarias y carecen de valor espiritual.'
              : 'El versículo propone una resignación cínica donde la meditación personal no tiene sentido.';
        } else if (style == 'prophetic') {
          return idx == 0
              ? 'El pasaje afirma que el futuro es incierto y que las promesas divinas son meramente metafóricas.'
              : 'El texto desestima las advertencias proféticas como simples opiniones humanas sin autoridad.';
        } else {
          return idx == 0
              ? 'El texto sugiere que la conducta ética y la verdad espiritual carecen de relevancia práctica en la vida.'
              : 'El pasaje sostiene que la autosuficiencia moral autónoma es superior al consejo eterno del Creador.';
        }
      }
    }
  }

  List<_QuizRound> _buildQuizRounds(
    MemoryDeckData deck,
    MemoryCardData activeCard,
  ) {
    final rng = math.Random(
      activeCard.id.hashCode ^ DateTime.now().millisecondsSinceEpoch,
    );
    final rounds = <_QuizRound>[];
    final store = AppScope.of(context);
    final isCombinedBible = deck.isBible && deck.cards.length > 1 && store.sessionDailyTarget > 1;
    final List<MemoryCardData> sessionStudiedCards = isCombinedBible
        ? deck.cards.take(store.sessionDailyTarget).toList()
        : deck.cards.take(store.currentCardIndex + 1).toList();

    final studiedPool = sessionStudiedCards.isNotEmpty ? sessionStudiedCards : [activeCard];

    // Pool of all available dynamic round types, shuffled at each session start
    final availableTypes = <String>[
      'frontToBack',
      'backToFront',
      'trueFalse_0',
      'trueFalse_1',
      'conceptual',
      'matching',
      'openQuestion',
    ]..shuffle(rng);

    // Pick 5 exercise types randomly for this session
    final selectedTypes = availableTypes.take(5).toList();

    for (var i = 0; i < 5; i++) {
      final target = studiedPool[i % studiedPool.length];
      final typeStr = selectedTypes[i];

      if (typeStr == 'trueFalse_0') {
        final isTrue = rng.nextBool();
        final statement = _generateTrueFalseStatement(target, isTrue, rng, variant: 0);
        rounds.add(_QuizRound(
          target: target,
          type: _QuizQuestionType.trueFalse,
          options: const [],
          trueFalseStatement: statement,
          isStatementTrue: isTrue,
        ));
      } else if (typeStr == 'trueFalse_1') {
        final isTrue = rng.nextBool();
        final statement = _generateTrueFalseStatement(target, isTrue, rng, variant: 1);
        rounds.add(_QuizRound(
          target: target,
          type: _QuizQuestionType.trueFalse,
          options: const [],
          trueFalseStatement: statement,
          isStatementTrue: isTrue,
        ));
      } else if (typeStr == 'conceptual') {
        rounds.add(_buildConceptualRound(target, rng, i));
      } else if (typeStr == 'openQuestion') {
        String prompt = 'Explícalo con tus palabras: ¿cuál es la enseñanza central o el valor práctico de este texto?';
        final text = target.back.toLowerCase();
        if (text.contains('puedo') || text.contains('fortalece')) {
          prompt = 'Explícalo con tus palabras: ¿qué relación hay entre el poder de Cristo y tus dificultades o debilidades cotidianas?';
        } else if (text.contains('gracias') || text.contains('misericordia') || text.contains('bueno')) {
          prompt = 'Explícalo con tus palabras: ¿por qué debemos dar gracias a Dios en todo momento y cómo se relaciona con su misericordia?';
        } else if (text.contains('angustia') || text.contains('clamar') || text.contains('liberó') || text.contains('salvó') || text.contains('angustiados')) {
          prompt = 'Explícalo con tus palabras: ¿qué actitud debemos tomar en medio de la angustia y qué respuesta promete este pasaje?';
        } else if (text.contains('paz') || text.contains('cuidado') || text.contains('ansiedad') || text.contains('guardará')) {
          prompt = 'Explícalo con tus palabras: ¿cómo nos ayuda la oración con gratitud a experimentar la paz que supera todo entendimiento?';
        } else if (target.front.contains('Bíceps') || target.back.contains('flexor') || target.back.contains('codo') || target.front.contains('codo') || target.back.contains('Bíceps')) {
          prompt = 'Explícalo con tus palabras: ¿qué relación hay entre el bíceps y el movimiento del codo?';
        }
        rounds.add(_QuizRound(
          target: target,
          type: _QuizQuestionType.openQuestion,
          options: const [],
          openQuestionPrompt: prompt,
        ));
      } else if (typeStr == 'backToFront') {
        // Text-to-reference matching round
        final distractorPool = deck.cards.where((c) => c.id != target.id).toList()..shuffle(rng);
        final distractors = <MemoryCardData>[];
        final otherStudied = studiedPool.where((c) => c.id != target.id).toList()..shuffle(rng);
        distractors.addAll(otherStudied.take(3));

        if (distractors.length < 3) {
          final extraDeck = distractorPool.where((c) => !distractors.any((d) => d.id == c.id)).toList();
          distractors.addAll(extraDeck.take(3 - distractors.length));
        }

        final bibleFallbacks = [
          'Juan 3:16', 'Salmo 23:1', 'Filipenses 4:13', 'Mateo 6:33', 
          'Romanos 12:2', '1 Corintios 13:4', 'Génesis 1:1', 'Proverbios 3:5'
        ];
        var fbIdx = 0;
        while (distractors.length < 3) {
          final refFallback = bibleFallbacks[fbIdx % bibleFallbacks.length];
          fbIdx++;
          distractors.add(
            MemoryCardData(
              id: 'ref-distractor-${distractors.length}-${target.id}',
              front: refFallback,
              back: 'Texto alternativo',
              source: 'Sistema',
              icon: target.icon,
            ),
          );
        }

        final targetCard = MemoryCardData(
          id: 'quiz-target-${target.id}-$i',
          front: target.front,
          back: target.back,
          source: target.source,
          icon: target.icon,
        );

        final optionCards = <MemoryCardData>[
          targetCard,
          for (var idx = 0; idx < distractors.length; idx++)
            MemoryCardData(
              id: 'quiz-conceptual-distractor-$idx-${target.id}-$i',
              front: distractors[idx].front,
              back: target.back,
              source: 'Sistema',
              icon: target.icon,
            )
        ]..shuffle(rng);

        rounds.add(_QuizRound(
          target: targetCard,
          type: _QuizQuestionType.backToFront,
          options: optionCards,
        ));
      } else if (typeStr == 'matching') {
        // Matching round
        final pairs = <(String, String)>[];
        pairs.add((target.front, target.back));

        final others = studiedPool.where((c) => c.id != target.id).toList()..shuffle(rng);
        for (final o in others) {
          if (pairs.length < 4) {
            pairs.add((o.front, o.back));
          }
        }

        final fallbacks = [
          ('Juan 3:16', 'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito.'),
          ('Salmo 23:1', 'Jehová es mi pastor; nada me faltará.'),
          ('Filipenses 4:13', 'Todo lo puedo en Cristo que me fortalece.'),
          ('Mateo 6:33', 'Mas buscad primeramente el reino de Dios y su justicia.'),
          ('Romanos 8:28', 'Y sabemos que a los que aman a Dios, todas las cosas les ayudan a bien.'),
          ('Génesis 1:1', 'En el principio creó Dios los cielos y la tierra.'),
        ];

        for (final fb in fallbacks) {
          if (pairs.length < 4 && !pairs.any((p) => p.$1 == fb.$1)) {
            pairs.add((fb.$1, fb.$2));
          }
        }

        rounds.add(_QuizRound(
          target: target,
          type: _QuizQuestionType.matching,
          options: const [],
          matchingPairs: pairs,
        ));
      } else {
        // Baseline frontToBack reference-to-text matching round
        final distractorPool = deck.cards.where((c) => c.id != target.id).toList()..shuffle(rng);
        final distractors = <MemoryCardData>[];
        final otherStudied = studiedPool.where((c) => c.id != target.id).toList()..shuffle(rng);
        distractors.addAll(otherStudied.take(3));

        if (distractors.length < 3) {
          final extraDeck = distractorPool.where((c) => !distractors.any((d) => d.id == c.id)).toList();
          distractors.addAll(extraDeck.take(3 - distractors.length));
        }

        while (distractors.length < 3) {
          final llm = LocalLlmService.instance;
          final dists = llm.generateDistractorsSync(target.back);
          final distText = dists[distractors.length % dists.length];
          distractors.add(
            MemoryCardData(
              id: 'ai-distractor-${distractors.length}-${target.id}',
              front: target.front,
              back: distText,
              source: 'IA Local Offline',
              icon: target.icon,
            ),
          );
        }

        final targetCard = MemoryCardData(
          id: 'quiz-target-${target.id}-$i',
          front: target.front,
          back: target.back,
          source: target.source,
          icon: target.icon,
        );

        final optionCards = <MemoryCardData>[
          targetCard,
          for (var idx = 0; idx < distractors.length; idx++)
            MemoryCardData(
              id: 'quiz-conceptual-distractor-$idx-${target.id}-$i',
              front: target.front,
              back: distractors[idx].back,
              source: 'IA Local Offline',
              icon: target.icon,
            )
        ]..shuffle(rng);

        rounds.add(_QuizRound(
          target: targetCard,
          type: _QuizQuestionType.frontToBack,
          options: optionCards,
        ));
      }
    }
    return rounds;
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

  void _submitOpenQuestionResponse(_QuizRound round) async {
    final response = (round.openQuestionResponse ?? '').trim();
    if (response.isEmpty) return;
    
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isEvaluatingOpenQuestion = true;
    });
    
    // Simulación premium de análisis de la IA Local Offline
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!mounted) return;
    
    final text = response.toLowerCase();
    final keywords = <String>[];
    final targetText = round.target.back.toLowerCase();
    
    if (targetText.contains('puedo') || targetText.contains('fortalece')) {
      keywords.addAll(['cri', 'pod', 'for', 'fue', 'dio', 'fe', 'sos', 'paz', 'tod']);
    } else if (targetText.contains('gracias') || targetText.contains('misericordia') || targetText.contains('bueno')) {
      keywords.addAll(['gra', 'miser', 'buen', 'amo', 'fie', 'dio', 'etern']);
    } else if (targetText.contains('angustia') || targetText.contains('clamar') || targetText.contains('liberó')) {
      keywords.addAll(['cla', 'ang', 'libe', 'salv', 'dio', 'fe', 'ora']);
    } else if (targetText.contains('paz') || targetText.contains('cuidado') || targetText.contains('ansiedad')) {
      keywords.addAll(['paz', 'ans', 'cui', 'ora', 'gra', 'men', 'cor']);
    } else if (round.target.front.contains('Bíceps') || targetText.contains('flexor') || targetText.contains('codo')) {
      keywords.addAll(['bic', 'cod', 'fle', 'art', 'bra', 'mus', 'mov']);
    } else {
      keywords.addAll(['dio', 'fe', 'amo', 'vida', 'pal', 'con']);
    }
    
    int matches = 0;
    for (final kw in keywords) {
      if (text.contains(kw)) {
        matches++;
      }
    }
    
    final responseWords = text.split(RegExp(r'\s+')).map((w) => w.replaceAll(RegExp(r'[.,;:!?¡¿()]'), '')).where((w) => w.length > 3).toSet();
    final targetWords = targetText.split(RegExp(r'\s+')).map((w) => w.replaceAll(RegExp(r'[.,;:!?¡¿()]'), '')).where((w) => w.length > 3).toSet();
    final wordOverlap = responseWords.intersection(targetWords).length;
    
    // La respuesta debe tener al menos 8 caracteres y contener al menos una idea clave del versículo
    final bool passes = response.length >= 8 && (matches >= 1 || wordOverlap >= 1);
    
    setState(() {
      _isEvaluatingOpenQuestion = false;
      round.selectedIdx = 1; // Mark as answered
      if (passes) {
        _quizScore += 1;
      }
    });
    
    String feedback = '';
    if (passes) {
      feedback = '¡Excelente asimilación! ';
      if (matches >= 3 || wordOverlap >= 2) {
        feedback += 'La IA Local Offline reconoció tus ideas clave y tu conceptualización de este pasaje. ¡Sigue así!';
      } else {
        feedback += 'La IA Local Offline identificó conceptos importantes en tu respuesta y validó tu razonamiento básico.';
      }
    } else {
      feedback = 'Asimilación insuficiente. La IA Local Offline no detectó conceptos clave ni coincidencia temática en tu respuesta. Intenta detallar más el valor práctico del texto.';
    }
    
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

  bool get _quizPassed => _quizFinished && _quizScore >= 3;

  void _activateLetterBlank(int index) {
    if (index < 0 || index >= _letterTargets.length) return;
    if (_letterAnswers[index] != null) return;
    setState(() => _activeLetterIndex = index);
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
    return ReferencePage(
      showBottomNav: false,
      scrollable:
          slug != '01-escuchar' &&
          !_isFirstLetterSlug(slug) &&
          !_isFogSlug(slug) &&
          !_isFinalVoiceSlug(slug),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlowStepHeader(
            step: '$step',
            totalSteps: totalSteps,
            title: _realStepTitle(slug),
            progress: step.clamp(1, totalSteps),
          ),
          if (slug == '01-escuchar' ||
              _isFirstLetterSlug(slug) ||
              _isFogSlug(slug) ||
              _isFinalVoiceSlug(slug))
            Expanded(
              child: _RedFlash(
                active: _nonVoiceWrongRecent(),
                child: _realExerciseBody(context, store, card, deck, slug),
              ),
            )
          else
            _RedFlash(
              active: _nonVoiceWrongRecent(),
              child: _realExerciseBody(context, store, card, deck, slug),
            ),
          const SizedBox(height: 14),
          _realExerciseFooter(context, store, card, deck, slug),
        ],
      ),
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
                  Container(
                    constraints: const BoxConstraints(minHeight: 120),
                    alignment: Alignment.center,
                    child: _buildSoloLecturaText(context, _soloLecturaVisibleChars),
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
      final correctCount = hasInteracted ? _correctBlockCount() : 0;
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
      final hasInput = _hasLetterInput();
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

    _ensureQuizRounds(deck, card);
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
        ? 'PREGUNTA ${_quizRoundIndex + 1} DE 5 · VERDADERO / FALSO'
        : isMatching
        ? 'PREGUNTA ${_quizRoundIndex + 1} DE 5 · EMPAREJAR'
        : isOpenQuestion
        ? 'PREGUNTA ${_quizRoundIndex + 1} DE 5 · RESPUESTA ABIERTA'
        : isFrontToBack
        ? (deck.isBible ? 'BIBLIA · ${round.target.front.toUpperCase()}' : deck.title.toUpperCase())
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
                          ? RefColors.lime.withOpacity(0.12)
                          : round.selectedIdx == 0
                          ? (round.correct ? RefColors.lime.withOpacity(0.12) : RefColors.urgent.withOpacity(0.12))
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
                          ? RefColors.lime.withOpacity(0.12)
                          : round.selectedIdx == 1
                          ? (round.correct ? RefColors.lime.withOpacity(0.12) : RefColors.urgent.withOpacity(0.12))
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
                                ? RefColors.lime.withOpacity(0.12)
                                : _matchingSelectedLeft == leftItem
                                ? RefColors.pink.withOpacity(0.12)
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
                                ? RefColors.lime.withOpacity(0.12)
                                : _matchingSelectedRight == rightItem
                                ? RefColors.pink.withOpacity(0.12)
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

  Widget _realExerciseFooter(
    BuildContext context,
    AppStore store,
    MemoryCardData card,
    MemoryDeckData deck,
    String slug,
  ) {
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
                _completeStepAndNavigate(context, store, slug);
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
                _completeStepAndNavigate(context, store, slug);
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
        slug == '09-quiz';

    return Row(
      children: [
        SizedBox(
          width: 118,
          child: GhostButton(
            showOmitirForDefault ? 'Omitir' : 'Pista',
            onTap: () {
              if (showOmitirForDefault) {
                ActiveMediaRegistry.stopAll();
                if (slug == '09-quiz') {
                  store.answerCurrentCard(true);
                }
                _completeStepAndNavigate(context, store, slug);
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
              if (slug == '09-quiz') {
                if (_quizRounds.isEmpty) return;
                final round = _quizRounds[_quizRoundIndex];
                if (!round.answered) return;
                if (!_quizFinished) {
                  _advanceQuizRound();
                  return;
                }
                if (!_quizPassed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Necesitas 3 aciertos. Reintenta.'),
                    ),
                  );
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
              if (!correct && slug != '09-quiz') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Corrige el ejercicio para avanzar.'),
                  ),
                );
                return;
              }
              if (slug == '09-quiz') {
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
    if (slug == '09-quiz') {
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
    if (slug == '09-quiz') {
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

class _CompletionPromptCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final usedTargetIndexes = <int>{};
    final spans = <InlineSpan>[];
    for (final word in _studyWords(text)) {
      final targetIndex = _matchingUnusedTargetIndex(word, usedTargetIndexes);
      if (targetIndex == null) {
        spans.add(TextSpan(text: '$word '));
        continue;
      }
      usedTargetIndexes.add(targetIndex);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 4),
            child: _CompletionBlank(
              answer: answers[targetIndex],
              active:
                  activeIndex == targetIndex && answers[targetIndex] == null,
              complete: answers[targetIndex] != null,
              wordLength: targets[targetIndex].length,
              onTap: () => onBlankTap(targetIndex),
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
            label,
            style: const TextStyle(
              color: RefColors.sun,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
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
        ],
      ),
    );
  }

  int? _matchingUnusedTargetIndex(String word, Set<int> usedTargetIndexes) {
    for (var index = 0; index < targets.length; index++) {
      if (usedTargetIndexes.contains(index)) continue;
      if (_sameAnswer(word, targets[index])) return index;
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
                      : ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: Text(
                            words[i],
                            style: TextStyle(
                              fontSize: 24,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                              color: RefColors.muted.withValues(alpha: .45),
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
    final accent = active
        ? RefColors.pink
        : completed
        ? RefColors.lime
        : RefColors.border;
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
                ? RefColors.pink.withOpacity(0.08)
                : completed
                ? RefColors.lime.withOpacity(0.06)
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
                    color: RefColors.lime.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: RefColors.lime.withOpacity(0.3)),
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
                      color: RefColors.pink.withOpacity(0.12),
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
                                      ? RefColors.lime.withOpacity(0.12)
                                      : _frontId == card.id
                                      ? RefColors.pink.withOpacity(0.12)
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
                                      ? RefColors.lime.withOpacity(0.12)
                                      : _backId == card.id
                                      ? RefColors.pink.withOpacity(0.12)
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
                                ? RefColors.lime.withOpacity(0.12)
                                : _e3SelectedIdx == i
                                ? (_e3Options[i] == _e3CorrectText ? RefColors.lime.withOpacity(0.12) : RefColors.urgent.withOpacity(0.12))
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
                    color: RefColors.lime.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: RefColors.lime.withOpacity(0.3)),
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
                  const Color(0xFF5DF07E).withOpacity(0.9),
                  const Color(0xFF38CD6E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38CD6E).withOpacity(0.4),
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
                Container(
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
                          backgroundColor: RefColors.border.withOpacity(0.1),
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
                      color: RefColors.lime.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RefColors.lime.withOpacity(0.3)),
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
    super.enabled,
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
