/// Punto de entrada de pantallas. Se descompone en `part` files
/// dentro de `screens/` para mantener navegación legible sin perder
/// visibilidad de los muchos widgets privados compartidos.
library memorizar_screens;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

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
import 'glyph_icon.dart';
import 'home_screen.dart';

// Imports for the extracted shared building blocks.
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

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
part 'screens/recitation_step.dart';


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
  AppRoutes.home: (_) => const HomeScreen(),
  AppRoutes.bgNocturnoMate: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.nocturnoMate),
  AppRoutes.bgVinoAhumado: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.vinoAhumado),
  AppRoutes.bgTintaProfunda: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.tintaProfunda),
  AppRoutes.bgBrasaSuave: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.brasaSuave),
  AppRoutes.bgCarbonAmbar: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.carbonAmbar),
  AppRoutes.bgCiruelaTostada: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.ciruelaTostada),
  AppRoutes.bgPetroleoDorado: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.petroleoDorado),
  AppRoutes.bgNaranjaNocturno: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.naranjaNocturno),
  AppRoutes.bgActualSuave: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.actualSuave),
  AppRoutes.biblia: (_) => const BibliaScreen(),
  AppRoutes.especificar: (_) => const EspecificarScreen(),
  AppRoutes.iniciar: (_) => const IniciarScreen(),
  AppRoutes.repasar: (_) => const RepasarScreen(),
  AppRoutes.comunidad: (_) => const ComunidadScreen(),
  AppRoutes.amigos: (_) => const AmigosScreen(),
  AppRoutes.stats: (_) => const StatsScreen(),
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
  ExerciseFlowData('01-escuchar', 'Escuchar', 'Primero absorbe la idea'),
  ExerciseFlowData('02-lectura-frag', 'Lectura fragmentada', 'Divide y repite'),
  ExerciseFlowData('03-leer-voz', 'Leer en voz', 'Activa memoria auditiva'),
  ExerciseFlowData('04-escuchar-voz', 'Escuchar voz', 'Reconoce sin mirar'),
  ExerciseFlowData('05-bloques', 'Bloques', 'Ordena piezas clave'),
  ExerciseFlowData('06-completar-n1', 'Completar N1', 'Recuerdo con apoyo'),
  ExerciseFlowData(
    '07-primera-letra-n1',
    'Primera letra N1',
    'Menos pistas, más memoria',
  ),
  ExerciseFlowData('08-voz-guiada', 'Voz guiada', 'Responde en voz alta'),
  ExerciseFlowData('09-quiz', 'Quiz', 'Elige la respuesta correcta'),
  ExerciseFlowData('10-completar-n2', 'Completar N2', 'Recuerdo más fuerte'),
  ExerciseFlowData('11-primera-letra-n2', 'Primera letra N2', 'Casi sin ayuda'),
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
  ExerciseFlowData('14-voz-final', 'Voz final', 'Demuestra dominio'),
  ExerciseFlowData('mini-review', 'Mini review', 'Cierre rápido'),
  ExerciseFlowData('final-review', 'Review final', 'Resumen de sesión'),
];

class ExerciseFlowScreen extends StatelessWidget {
  final ExerciseFlowData data;

  const ExerciseFlowScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.slug == '09-quiz' && !AppScope.of(context).isPremium) {
      return const PremiumScreen();
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

enum _QuizQuestionType { frontToBack, backToFront }

class _QuizRound {
  final MemoryCardData target;
  final _QuizQuestionType type;
  final List<MemoryCardData> options;
  int? selectedIdx;

  _QuizRound({required this.target, required this.type, required this.options});

  bool get answered => selectedIdx != null;
  bool get correct =>
      selectedIdx != null && options[selectedIdx!].id == target.id;
}

class _RealExerciseFlowScreenState extends State<_RealExerciseFlowScreen> {
  bool _checked = false;
  int _fragmentVisibleWords = 8;
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

  String? _bankCardId;
  List<String> _bankTargets = [];
  List<String?> _bankAnswers = [];
  List<String> _bankAvailable = [];
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
  int _fogRound = 0;
  bool _fogFinished = false;

  @override
  void dispose() {
    _completionTimer?.cancel();
    _letterTimer?.cancel();
    super.dispose();
  }

  /// Seconds-per-target for timed levels. N3 is faster (less time per hueco).
  static const double _completionSecondsPerTargetN2 = 5.0;
  static const double _completionSecondsPerTargetN3 = 2.8;
  static const double _letterSecondsPerTargetN2 = 5.0;
  static const double _letterSecondsPerTargetN3 = 2.8;

  int _completionTimeFor(int level, int targetCount) {
    if (level <= 1 || targetCount <= 0) return 0;
    final perTarget = level >= 3
        ? _completionSecondsPerTargetN3
        : _completionSecondsPerTargetN2;
    final raw = (targetCount * perTarget).round();
    // Hard floor / ceiling so very short or very long verses stay reasonable.
    return raw.clamp(level >= 3 ? 25 : 35, 180);
  }

  int _letterTimeFor(int level, int targetCount) {
    if (level <= 1 || targetCount <= 0) return 0;
    final perTarget = level >= 3
        ? _letterSecondsPerTargetN3
        : _letterSecondsPerTargetN2;
    final raw = (targetCount * perTarget).round();
    return raw.clamp(level >= 3 ? 25 : 35, 180);
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
    _bankAvailable = [...cleanWords]..shuffle(rng);
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

  void _selectBankWord(String word) {
    if (_bankTargets.isEmpty || _bankComplete()) return;
    if (_bankRemoving.contains(word)) return;
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
    final correct = _sameAnswer(word, _bankTargets[idx]);
    if (correct) {
      setState(() {
        _bankAnswers[idx] = word;
        _bankRemoving.add(word);
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
          final removeAt =
              _bankAvailable.indexWhere((w) => _sameAnswer(w, word));
          if (removeAt >= 0) _bankAvailable.removeAt(removeAt);
          _bankRemoving.remove(word);
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
      store.markExerciseStepCompleted('15-banco-completo');
      Navigator.push(
        context,
        AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
      );
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
    _fogRound = 0;
    _fogFinished = false;
  }

  void _onFogRoundCompleted() {
    setState(() {
      if (_fogRound >= 2) {
        _fogFinished = true;
        HapticFeedback.heavyImpact();
      } else {
        _fogRound += 1;
        HapticFeedback.lightImpact();
      }
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
        return _quizRounds[_quizRoundIndex].answered;
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
    _letterTargets = _firstLetterTargets(text, level: level);
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
    final correct = _sameAnswer(letter, target.substring(0, 1));
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
    if (_quizCardId == card.id && _quizRounds.isNotEmpty) return;
    _quizCardId = card.id;
    _quizRoundIndex = 0;
    _quizScore = 0;
    _quizRounds = _buildQuizRounds(deck, card);
  }

  List<_QuizRound> _buildQuizRounds(
    MemoryDeckData deck,
    MemoryCardData activeCard,
  ) {
    final rng = math.Random(
      activeCard.id.hashCode ^ DateTime.now().millisecondsSinceEpoch,
    );
    final rounds = <_QuizRound>[];
    final allCards = [
      activeCard,
      ...deck.cards.where((c) => c.id != activeCard.id),
    ];
    final usedTargets = <String>{};
    final shuffledPool = [...allCards]..shuffle(rng);
    final targets = <MemoryCardData>[activeCard];
    usedTargets.add(activeCard.id);
    for (final c in shuffledPool) {
      if (targets.length >= 5) break;
      if (usedTargets.contains(c.id)) continue;
      targets.add(c);
      usedTargets.add(c.id);
    }
    while (targets.length < 5) {
      targets.add(activeCard);
    }
    for (var i = 0; i < 5; i++) {
      final target = targets[i];
      final type = i.isEven
          ? _QuizQuestionType.frontToBack
          : _QuizQuestionType.backToFront;
      final distractorPool = allCards.where((c) => c.id != target.id).toList()
        ..shuffle(rng);
      final distractors = distractorPool.take(3).toList();
      while (distractors.length < 3) {
        distractors.add(
          MemoryCardData(
            id: 'placeholder-${distractors.length}-${target.id}',
            front: 'Opción aproximada',
            back: _firstWords(target.back, 4),
            source: 'Placeholder',
            icon: target.icon,
          ),
        );
      }
      final options = [target, ...distractors]..shuffle(rng);
      rounds.add(_QuizRound(target: target, type: type, options: options));
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
  }

  void _advanceQuizRound() {
    if (_quizRoundIndex < _quizRounds.length - 1) {
      setState(() => _quizRoundIndex += 1);
    }
  }

  void _resetQuiz() {
    setState(() {
      _quizCardId = null;
      _quizRounds = [];
      _quizRoundIndex = 0;
      _quizScore = 0;
    });
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
    return ReferencePage(
      showBottomNav: false,
      scrollable:
          slug != '01-escuchar' &&
          slug != '08-voz-guiada' &&
          !_isFinalVoiceSlug(slug), // Allow voice/listen steps to expand
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
              slug == '08-voz-guiada' ||
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

    if (slug == '08-voz-guiada' || _isFinalVoiceSlug(slug)) {
      final hidden = _isFinalVoiceSlug(slug);
      return _RecitationStep(
        targetText: card.back,
        finalMode: hidden,
        colorMode: hidden ? _ListeningColorMode.pink : _ListeningColorMode.blue,
        onCompleted: (passed) {
          store.markExerciseStepCompleted(slug);
          if (hidden) store.answerCurrentCard(passed);
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: hasInteracted
                            ? '$correctCount / ${blocks.length}'
                            : '${blocks.length} bloques',
                        style: const TextStyle(
                          color: RefColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(text: hasInteracted ? ' correctos' : ''),
                    ],
                  ),
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                RefChip(
                  hasInteracted && allCorrect
                      ? 'Correcto'
                      : selectingDestination
                      ? 'Elige destino'
                      : 'Toca un bloque',
                  dense: true,
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
                return ReorderableDragStartListener(
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
          _FirstLetterSentence(
            text: card.back,
            level: level,
            targets: _letterTargets,
            answers: _letterAnswers,
            activeIndex: _activeLetterIndex,
            onBlankTap: _activateLetterBlank,
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
          else if (_letterLost)
            _LostPanel(
              title: '¡Tiempo agotado!',
              subtitle: 'Se acabó el tiempo. Inténtalo de nuevo.',
              onRetry: _retryLetter,
            )
          else ...[
            _KeyboardCard(
              onLetterTap: remainingAttempts == 0 ? null : _selectFirstLetter,
            ),
            if (hasInput && !complete && remainingAttempts == 0) ...[
              const SizedBox(height: 8),
              Text(
                'Sin intentos restantes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: RefColors.urgent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ],
      );
    }

    if (_isWordBankSlug(slug)) {
      _ensureBankState(card.id, card.back);
      final filled = _bankAnswers.where((a) => a != null).length;
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
      final partAvailable = <String>[];
      for (final w in _bankAvailable) {
        final key = clean(w);
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
            firstValue: '$filled/${_bankTargets.length}',
            firstLabel: 'HUECOS',
            secondValue: '$_bankMistakes',
            secondLabel: 'FALLOS',
          ),
          if (isSplit) ...[
            const SizedBox(height: 10),
            _BankPartHeader(
              partIndex: _bankPartIndex,
              partCount: partCount,
            ),
          ],
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
                          key: ValueKey('bank-$word'),
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInBack,
                          scale: _bankRemoving.contains(word) ? 0.0 : 1.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 240),
                            opacity:
                                _bankRemoving.contains(word) ? 0.0 : 1.0,
                            child: GestureDetector(
                              onTap: () => _selectBankWord(word),
                              child: _WordChip(word, active: false),
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
        round: _fogRound,
        finished: _fogFinished,
        onRoundCompleted: _onFogRoundCompleted,
      );
    }

    _ensureQuizRounds(deck, card);
    final round = _quizRounds[_quizRoundIndex];
    final answered = round.answered;
    final isFrontToBack = round.type == _QuizQuestionType.frontToBack;
    final question = isFrontToBack
        ? '¿Qué texto corresponde a ${round.target.front}?'
        : '¿A qué referencia pertenece este texto?';
    final contextLabel = isFrontToBack
        ? (deck.isBible ? round.target.source : deck.title.toUpperCase())
        : '"${_firstWords(round.target.back, 8)}…"';
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
        for (var i = 0; i < round.options.length; i++) ...[
          _ExerciseOption(
            letter: String.fromCharCode(65 + i),
            title: isFrontToBack
                ? round.options[i].back
                : round.options[i].front,
            tip: isFrontToBack
                ? round.options[i].front
                : round.options[i].source,
            selected: round.selectedIdx == i,
            correct: answered && round.options[i].id == round.target.id,
            wrong: round.selectedIdx == i && !round.correct,
            onTap: answered ? () {} : () => _selectQuizOption(i),
          ),
          const SizedBox(height: 10),
        ],
        if (answered)
          _InlineResult(
            correct: round.correct,
            text: round.correct
                ? '¡Correcto!'
                : 'Respuesta correcta: ${isFrontToBack ? round.target.back : round.target.front}',
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
                Navigator.push(
                  context,
                  AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
                );
              },
            ),
          ),
        ],
      );
    }
    if (slug == '01-escuchar' ||
        slug == '03-leer-voz' ||
        slug == '04-escuchar-voz' ||
        slug == '08-voz-guiada' ||
        _isFinalVoiceSlug(slug)) {
      final showSkip =
          slug == '03-leer-voz' ||
          slug == '04-escuchar-voz' ||
          slug == '08-voz-guiada' ||
          _isFinalVoiceSlug(slug);
      final cta = _ActionCta(
        label: _footerLabel(slug, checked: _checked, completed: completed),
        enabled: completed,
        onTap: () => Navigator.push(
          context,
          AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
        ),
      );
      if (!showSkip) return cta;
      return Row(
        children: [
          SizedBox(
            width: 118,
            child: GhostButton(
              'Saltar',
              onTap: () {
                store.markExerciseStepCompleted(slug);
                Navigator.push(
                  context,
                  AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: cta),
        ],
      );
    }
    return Row(
      children: [
        SizedBox(
          width: 118,
          child: GhostButton(
            'Pista',
            onTap: () {
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
                store.markExerciseStepCompleted(slug);
                Navigator.push(
                  context,
                  AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
                );
                return;
              }
              if (!_checked) {
                if (slug == '05-bloques') {
                  if (_blocksAreCorrect()) {
                    store.markExerciseStepCompleted(slug);
                    Navigator.push(
                      context,
                      AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
                    );
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
              store.markExerciseStepCompleted(slug);
              Navigator.push(
                context,
                AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
              );
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
    if (slug == '01-escuchar') {
      return completed ? 'Siguiente →' : 'Escucha completa requerida';
    }
    if (slug == '03-leer-voz') {
      return completed ? 'Siguiente →' : 'Lee en voz alta para continuar';
    }
    if (slug == '04-escuchar-voz') {
      return completed ? 'Siguiente →' : 'Escucha tu lectura para continuar';
    }
    if (slug == '08-voz-guiada') {
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
      if (!round.answered) return 'Elige una opción';
      if (!_quizFinished) return 'Siguiente ronda →';
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

class _BankPartHeader extends StatelessWidget {
  final int partIndex;
  final int partCount;

  const _BankPartHeader({required this.partIndex, required this.partCount});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: Container(
        key: ValueKey('bank-part-$partIndex'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: RefColors.cyan.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RefColors.cyan.withValues(alpha: .55)),
        ),
        child: Row(
          children: [
            const Icon(Icons.view_agenda_rounded,
                color: RefColors.cyan, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Parte ${partIndex + 1} de $partCount',
                style: const TextStyle(
                  color: RefColors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < partCount; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == partIndex ? 18 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= partIndex
                          ? RefColors.cyan
                          : RefColors.cyan.withValues(alpha: .25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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
    final store = AppScope.of(context);
    final source = store.activeDeck.isBible
        ? '${_cardSourceText(context)} · RV1909'
        : _cardSourceText(context);
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
  String? _frontId;
  String? _backId;
  final Set<String> _matched = {};

  @override
  Widget build(BuildContext context) {
    final cards = widget.store.activeDeck.cards.take(4).toList();
    final allMatched = cards.isNotEmpty && _matched.length == cards.length;
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowStepHeader(step: '12', title: 'Mini review', progress: 12),
          const _FlowTitle(
            title: 'Asocia referencia y texto',
            subtitle: 'Toca una referencia y luego el texto que le corresponde',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final card in cards)
                      _PairButton(
                        text: card.front,
                        active: _frontId == card.id,
                        done: _matched.contains(card.id),
                        onTap: () => setState(() => _frontId = card.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    for (final card in cards.reversed)
                      _PairButton(
                        text: _clipText(card.back),
                        active: _backId == card.id,
                        done: _matched.contains(card.id),
                        onTap: () => _selectBack(context, card.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Cta(
            allMatched ? 'Review final →' : 'Saltar review →',
            onTap: () =>
                Navigator.pushNamed(context, '${AppRoutes.flow}/final-review'),
          ),
        ],
      ),
    );
  }

  void _selectBack(BuildContext context, String id) {
    setState(() => _backId = id);
    if (_frontId == null) return;
    if (_frontId == id) {
      setState(() {
        _matched.add(id);
        _frontId = null;
        _backId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pareja correcta.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa pareja no corresponde.')),
      );
    }
  }
}

class _PairButton extends StatelessWidget {
  final String text;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  const _PairButton({
    required this.text,
    required this.active,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = done
        ? RefColors.lime
        : active
        ? RefColors.cyan
        : RefColors.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: done ? null : onTap,
        child: Glass(
          padding: const EdgeInsets.all(12),
          color: accent.withValues(alpha: done || active ? .12 : .04),
          border: Border.all(color: accent.withValues(alpha: .45)),
          child: Text(
            done ? '✓ $text' : text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
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
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowStepHeader(
            step: '12',
            title: 'Review final',
            progress: 12,
          ),
          Glass(
            padding: const EdgeInsets.all(20),
            gradient: LinearGradient(
              colors: [
                RefColors.lime.withValues(alpha: .22),
                RefColors.sun.withValues(alpha: .18),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesión completada',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '${deck.title} · ${store.completedCards} respuestas registradas · ${deck.retention}% retención',
                  style: const TextStyle(color: RefColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final card in deck.cards.take(5))
            _ReviewItem(
              card.icon,
              card.front,
              _clipText(card.back),
              '${card.retention}%',
              urgent: card.retention < 60,
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Repetir',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/01-escuchar',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Cta(
                  'Volver a inicio →',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.home),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListenFlowScreen extends StatelessWidget {
  const _ListenFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlowTopBar(
            chip: 'Ítem 1/5 · ${AppScope.of(context).activeCard.front}',
          ),
          const _FlowStepHeader(
            step: '1',
            title: '🎧 Escuchar',
            progress: 1,
            difficulty: '🌿 Inter',
          ),
          const _FlowTitle(
            title: 'Escucha y sigue',
            subtitle: 'El texto se resalta al ritmo del audio',
          ),
          const _ListenAudioCard(),
          const SizedBox(height: 14),
          const _FlowHintCard(
            icon: '💡',
            text:
                'Escúchalo al menos 3 veces antes de avanzar. Tu cerebro está formando la pista auditiva.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('🔁 Repetir')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente paso →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/02-lectura-frag',
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

class _FragmentedReadingFlowScreen extends StatelessWidget {
  const _FragmentedReadingFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          const _FlowStepHeader(
            step: '2',
            title: '👁 Lectura fragmentada',
            progress: 2,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Lee conforme aparece',
            subtitle: 'Activa tu atención · lo verás de a poco',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: RefProgress(.66),
          ),
          const _FragmentedTextCard(),
          const SizedBox(height: 14),
          const _SpeedSelectorCard(),
          const SizedBox(height: 14),
          const _TapPauseCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('← Repetir')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/03-leer-voz',
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

class _ReadAloudFlowScreen extends StatelessWidget {
  const _ReadAloudFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Zen mode'),
          const _FlowStepHeader(
            step: '3',
            title: '🗣 Dilo sin prisas',
            progress: 3,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Léelo en voz alta',
            subtitle: 'Tu voz refuerza la memoria auditiva',
          ),
          const SizedBox(height: 44),
          const _KaraokeLine(fontSize: 29),
          const SizedBox(height: 48),
          const _PulseMic(),
          const SizedBox(height: 42),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 54),
            child: RefProgress(.74),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              '• TE ESCUCHO',
              style: TextStyle(
                color: RefColors.pink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('Reiniciar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Finalizar grabación →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/04-escuchar-voz',
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

class _ListenOwnVoiceFlowScreen extends StatelessWidget {
  const _ListenOwnVoiceFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '👂 Tu propia voz'),
          const _FlowStepHeader(
            step: '4',
            title: '🎤 Escúchate',
            progress: 4,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Tu grabación',
            subtitle: 'Oír tu propia voz refuerza la memoria auditiva',
          ),
          const _VoiceQuoteCard(),
          const SizedBox(height: 14),
          const _WaveformCard(kind: _WaveKind.original),
          const SizedBox(height: 14),
          const _WaveformCard(kind: _WaveKind.you),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('🔁 Regrabar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/05-bloques',
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

class _BlocksFlowScreen extends StatelessWidget {
  const _BlocksFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '🧩 Reorganizar'),
          const _FlowStepHeader(
            step: '5',
            title: '🧩 Reorganiza los bloques',
            progress: 5,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Reconstruye el texto',
            subtitle: 'Arrastra los bloques al orden correcto',
          ),
          const _BlocksCounterCard(),
          const SizedBox(height: 14),
          const _BlocksListCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('👁 Pista')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Comprobar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/06-completar-n1',
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

class _CompleteN1FlowScreen extends StatelessWidget {
  const _CompleteN1FlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          const _FlowStepHeader(
            step: '6',
            title: '📝 Completar palabra',
            progress: 6,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Completa el versículo · Nivel 1',
            subtitle: 'Toca una palabra del banco y llena el hueco',
          ),
          const _CompleteStatsCard(),
          const SizedBox(height: 14),
          const _CompleteSentenceCard(),
          const SizedBox(height: 14),
          const _WordBankCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('👁 Pista')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Siguiente →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FirstLetterFlowScreen extends StatelessWidget {
  final int level;

  const _FirstLetterFlowScreen({required this.level});

  @override
  Widget build(BuildContext context) {
    final isLevel2 = level == 2;
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          _FlowStepHeader(
            step: isLevel2 ? '11' : '7',
            title: '🔤 Primera letra',
            progress: isLevel2 ? 11 : 7,
            difficulty: isLevel2 ? '🌳' : '🌿',
          ),
          _FlowTitle(
            title: 'Escribe la primera letra · Nivel $level',
            subtitle: isLevel2
                ? 'Casi todo está oculto · cronómetro · intentos limitados'
                : 'De cada hueco escribe únicamente su letra inicial',
          ),
          _CompleteStatsCard(
            level2: isLevel2,
            firstValue: isLevel2 ? '1/5' : '1/3',
          ),
          const SizedBox(height: 14),
          _FirstLetterSentence(level: level),
          const SizedBox(height: 14),
          if (!isLevel2) ...[
            const _FlowHintCard(
              icon: '💡',
              text:
                  'No te preocupes por la exactitud: acentos, mayúsculas o minúsculas no cuentan.',
            ),
            const SizedBox(height: 14),
          ],
          const _KeyboardCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('👁 Pista')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    isLevel2
                        ? '${AppRoutes.flow}/12-voz-final'
                        : '${AppRoutes.flow}/08-voz-guiada',
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

class _GuidedVoiceFlowScreen extends StatelessWidget {
  const _GuidedVoiceFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '🎤 Recitar completo'),
          const _FlowStepHeader(
            step: '8',
            title: '🎤 Voz con palabras ocultas',
            progress: 8,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Recita el versículo completo',
            subtitle: 'Algunas palabras están ocultas · dilas de memoria',
          ),
          const _CompleteStatsCard(
            firstValue: '3/7',
            firstLabel: 'PALABRAS',
            secondValue: '2',
            secondLabel: 'INTENTOS RESTANTES',
          ),
          const SizedBox(height: 14),
          const _VoiceHiddenWordsCard(finalMode: false),
          const SizedBox(height: 14),
          const _ListeningHud(colorMode: _ListeningColorMode.blue),
          const SizedBox(height: 14),
          const _FlowHintCard(
            icon: '💡',
            text:
                'Recita todo literalmente, no solo las ocultas · si pausas más de 5s reiniciamos.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('🔁 Reset')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Terminé →',
                  onTap: () =>
                      Navigator.pushNamed(context, '${AppRoutes.flow}/09-quiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizFlowScreen extends StatelessWidget {
  const _QuizFlowScreen();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final card = store.activeCard;
    final deck = store.activeDeck;
    final options = [
      card,
      ...deck.cards.where((item) => item.id != card.id),
    ].take(4).toList();
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Quiz · 5 preguntas'),
          const _FlowStepHeader(
            step: '9',
            title: '🧠 Entiende el significado',
            progress: 9,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Quiz de comprensión',
            subtitle: '5 preguntas de tipos distintos según el contenido',
          ),
          const _QuizNav(),
          const SizedBox(height: 14),
          _ExerciseQuestionBlock(
            contextLabel: deck.isBible ? card.source : deck.title.toUpperCase(),
            question: deck.isBible
                ? '¿Qué texto pertenece a ${card.front}?'
                : '¿Cuál explicación corresponde a ${card.front}?',
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < options.length; i++) ...[
            _ExerciseOption(
              letter: String.fromCharCode(65 + i),
              title: options[i].back,
              tip: options[i].source,
              selected: i == 0,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 140, child: GhostButton('💡 Explicar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Confirmar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/10-completar-n2',
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

class _CompleteN2FlowScreen extends StatelessWidget {
  const _CompleteN2FlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          const _FlowStepHeader(
            step: '10',
            title: '📝 Completar palabra',
            progress: 10,
            difficulty: '🌳',
          ),
          const _FlowTitle(
            title: 'Completa el versículo · Nivel 2',
            subtitle: 'Más huecos · cronómetro · intentos limitados',
          ),
          const _CompleteStatsCard(
            level2: true,
            firstValue: '1/5',
            secondValue: '2/3',
          ),
          const SizedBox(height: 14),
          const _CompleteSentenceCard(level2: true),
          const SizedBox(height: 14),
          const _WordBankCard(level2: true),
          const SizedBox(height: 14),
          const _WarningCard(
            text:
                'Nivel 2: si fallas 3 veces o se acaba el tiempo, vuelves al paso anterior.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('↩ Vaciar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Comprobar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/11-primera-letra-n2',
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

class _FinalVoiceFlowScreen extends StatelessWidget {
  const _FinalVoiceFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '🏆 EXAMEN FINAL'),
          const _FlowStepHeader(
            step: '12',
            title: '🎤 Recitación final',
            progress: 12,
            difficulty: '🌳',
          ),
          const _FlowTitle(
            title: 'Recita el versículo completo · Examen',
            subtitle: 'Sin ayudas · todas las palabras están ocultas',
          ),
          const _CompleteStatsCard(
            level2: true,
            firstValue: '0/7',
            firstLabel: 'PALABRAS',
            secondValue: '2',
            secondLabel: 'INTENTOS RESTANTES',
            timeValue: '00:30',
          ),
          const SizedBox(height: 14),
          const _VoiceHiddenWordsCard(finalMode: true),
          const SizedBox(height: 14),
          const _ListeningHud(colorMode: _ListeningColorMode.pink),
          const SizedBox(height: 14),
          const _WarningCard(
            text:
                'Examen final: recita todo de memoria sin parar más de 5s. Si fallas 2 veces vuelves al paso anterior.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('🔁 Reset')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Terminé →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniReviewFlowScreen extends StatelessWidget {
  const _MiniReviewFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Mini-repaso'),
          const _MiniReviewHero(),
          const SizedBox(height: 14),
          const _MiniReviewTabs(),
          const SizedBox(height: 16),
          const _FlowTitle(
            title: '🎯 Asocia cada referencia con su texto',
            subtitle:
                'Toca una referencia y luego su texto · arrastrar también funciona',
          ),
          const _MiniReviewCounter(),
          const SizedBox(height: 14),
          const _PairMatchCard(),
          const SizedBox(height: 18),
          const _FlowHintCard(
            icon: '💡',
            text: 'Toca una referencia y luego su texto correspondiente',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 96, child: GhostButton('Saltar')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Siguiente ejercicio →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinalReviewFlowScreen extends StatelessWidget {
  const _FinalReviewFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'FIN DE SESIÓN'),
          const _FinalSuccessHero(),
          const SizedBox(height: 16),
          const _FinalScoreCard(),
          const SizedBox(height: 14),
          const _ShareAchievementCard(),
          const SizedBox(height: 14),
          const _FinalVersesCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 96, child: GhostButton('Repetir')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Volver a inicio →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowTopBar extends StatelessWidget {
  final String chip;

  const _FlowTopBar({required this.chip});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final dynamicChip = chip.contains('Ítem') || chip.contains('Item')
        ? 'Ítem ${store.currentCardIndex + 1}/${store.activeDeck.cards.length} · ${store.activeCard.front}'
        : chip;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(),
          Expanded(child: Center(child: RefChip(dynamicChip, dense: true))),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _FlowStepHeader extends StatelessWidget {
  final String step;
  final String title;
  final int progress;
  final int totalSteps;
  final String? difficulty;

  const _FlowStepHeader({
    required this.step,
    required this.title,
    required this.progress,
    this.totalSteps = 12,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        color: RefColors.glassStrong,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const RefBackButton(),
                const SizedBox(width: 10),
                Text(
                  'PASO $step/$totalSteps',
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${store.activeDeck.cards.length} items · paso $step de $totalSteps · ${store.activeDeck.title}',
                      ),
                    ),
                  ),
                  child: const RefIconButton(icon: Icons.info_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  for (var i = 1; i <= totalSteps; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: i < progress
                              ? RefColors.lime
                              : i == progress
                              ? RefColors.pink
                              : RefColors.glassSoft,
                        ),
                      ),
                    ),
                    if (i < totalSteps) const SizedBox(width: 5),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FlowTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniReviewHero extends StatelessWidget {
  const _MiniReviewHero();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .32),
          RefColors.sun.withValues(alpha: .48),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: RefColors.lime.withValues(alpha: .46)),
      child: const Row(
        children: [
          Text('🎉', style: TextStyle(fontSize: 36)),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completaste 2 ítems',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Antes de seguir, repasa con 3 ejercicios cortos',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniReviewTabs extends StatelessWidget {
  const _MiniReviewTabs();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _MiniReviewTab('EJ 1', 'Asociar', active: true)),
        SizedBox(width: 8),
        Expanded(child: _MiniReviewTab('EJ 2', 'Memoria')),
        SizedBox(width: 8),
        Expanded(child: _MiniReviewTab('EJ 3', 'Quiz rápido', warm: true)),
      ],
    );
  }
}

class _MiniReviewTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final bool warm;

  const _MiniReviewTab(
    this.title,
    this.subtitle, {
    this.active = false,
    this.warm = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? RefColors.pink.withValues(alpha: .16)
            : warm
            ? RefColors.sun.withValues(alpha: .18)
            : RefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? RefColors.pink
              : warm
              ? RefColors.sun.withValues(alpha: .40)
              : RefColors.border,
          width: active ? 1.6 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: active ? RefColors.pink : RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MiniReviewCounter extends StatelessWidget {
  const _MiniReviewCounter();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      radius: 18,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gradient: LinearGradient(
        colors: [Color(0x66372B86), Color(0x66754D44)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      child: Row(
        children: [
          Text(
            '1 / 3',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          Text(
            ' pares',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Spacer(),
          Text(
            'Intentos: 1/2',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PairMatchCard extends StatelessWidget {
  const _PairMatchCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 16),
      color: RefColors.glassStrong,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _PairColumnTitle('REFERENCIAS')),
              SizedBox(width: 10),
              Expanded(child: _PairColumnTitle('TEXTOS')),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PairTile('Sal 23:1', selected: true, correct: true),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _PairTile(
                  '"Jehová es mi pastor;\nnada me faltará."',
                  selected: true,
                  correct: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _PairTile('Juan 3:16', selected: true)),
              SizedBox(width: 10),
              Expanded(
                child: _PairTile('"Fíate de Jehová con\ntodo tu corazón..."'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _PairTile('Prov 3:5')),
              SizedBox(width: 10),
              Expanded(
                child: _PairTile('"De tal manera amó\nDios al mundo..."'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PairColumnTitle extends StatelessWidget {
  final String label;

  const _PairColumnTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: RefColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }
}

class _PairTile extends StatelessWidget {
  final String text;
  final bool selected;
  final bool correct;

  const _PairTile(this.text, {this.selected = false, this.correct = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = correct
        ? RefColors.lime
        : selected
        ? RefColors.pink
        : RefColors.border;
    return Container(
      height: 64,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: correct
            ? RefColors.lime.withValues(alpha: .10)
            : selected
            ? RefColors.pink.withValues(alpha: .12)
            : RefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withValues(alpha: .78),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: correct ? RefColors.lime : RefColors.ink,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (correct)
            const Positioned(
              right: 0,
              top: 0,
              child: Icon(Icons.check_rounded, color: RefColors.lime, size: 16),
            ),
        ],
      ),
    );
  }
}

class _FinalSuccessHero extends StatelessWidget {
  const _FinalSuccessHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF90FA6D), Color(0xFF39D985)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 42)),
          SizedBox(height: 12),
          Text(
            '¡Lo lograste!',
            style: TextStyle(
              color: Color(0xFF06280F),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '5 tarjetas · 18 min · 93% aciertos',
            style: TextStyle(
              color: Color(0xFF06351A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalScoreCard extends StatelessWidget {
  const _FinalScoreCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .32),
          RefColors.sun.withValues(alpha: .42),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      child: Row(
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: RefColors.lime, width: 4),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '93%',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'ACIERTO',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              children: [
                _FinalScoreRow('Correctas', '67 / 72'),
                _FinalScoreRow('Incorrectas', '5'),
                _FinalScoreRow('Tiempo', '18 min', last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _FinalScoreRow(this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ShareAchievementCard extends StatelessWidget {
  const _ShareAchievementCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RefColors.glassStrong,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('📸')),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparte tu logro',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Imagen o texto · sin cuenta necesaria',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: RefColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Compartir',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalVersesCard extends StatelessWidget {
  const _FinalVersesCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
      color: RefColors.glassStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📖 LOS 5 VERSÍCULOS',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 14),
          _FinalVerseRow(
            index: '1',
            title: 'Sal 23:1 · "Jehová es mi pastor..."',
            meta: '12 pasos · sin errores',
            percent: '100%',
            value: 1,
          ),
          _FinalVerseRow(
            index: '2',
            title: 'Sal 23:2 · "En lugares de pastos..."',
            meta: '12 pasos · 1 error',
            percent: '95%',
            value: .95,
          ),
          _FinalVerseRow(
            index: '3',
            title: 'Sal 23:3 · "Confortará mi alma..."',
            meta: '12 pasos · 2 errores',
            percent: '85%',
            value: .85,
            warn: true,
          ),
          _FinalVerseRow(
            index: '4',
            title: 'Sal 23:4 · "Aunque ande en valle..."',
            meta: '12 pasos · sin errores',
            percent: '98%',
            value: .98,
          ),
          _FinalVerseRow(
            index: '5',
            title: 'Sal 23:5 · "Aderezas mesa..."',
            meta: '12 pasos · 1 error',
            percent: '88%',
            value: .88,
            warn: true,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _FinalVerseRow extends StatelessWidget {
  final String index;
  final String title;
  final String meta;
  final String percent;
  final double value;
  final bool warn;
  final bool last;

  const _FinalVerseRow({
    required this.index,
    required this.title,
    required this.meta,
    required this.percent,
    required this.value,
    this.warn = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = warn ? RefColors.sun : RefColors.lime;
    return Container(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      margin: EdgeInsets.only(bottom: last ? 0 : 4),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: RefColors.border),
            ),
            child: Text(
              index,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 5,
                    color: RefColors.glassSoft,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(color: accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: .5)),
            ),
            child: Text(
              '${warn ? '⚡' : '✓'} $percent',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadAloudPracticeCard extends StatefulWidget {
  final String targetText;
  final String source;
  final void Function(String text, String? audioPath) onCompleted;

  const _ReadAloudPracticeCard({
    required this.targetText,
    required this.source,
    required this.onCompleted,
  });

  @override
  State<_ReadAloudPracticeCard> createState() => _ReadAloudPracticeCardState();
}

class _ReadAloudPracticeCardState extends State<_ReadAloudPracticeCard> {
  static const _passScore = .60;
  late final stt.SpeechToText _speech;
  bool _ready = false;
  bool _listening = false;
  bool _completed = false;
  String _recognized = '';
  String _status = 'Toca el micrófono y lee el texto.';
  double _score = 0;
  final _audioRecorder = AudioRecorder();
  String? _recordedPath;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _status = 'No pude escuchar bien. Intenta otra vez.';
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _ready = available;
      _status = available
          ? 'Toca el micrófono y lee el texto.'
          : 'Activa permiso de micrófono para leer en voz.';
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    _audioRecorder.stop().then((_) => _audioRecorder.dispose());
    super.dispose();
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      _finishCapture();
    }
  }

  Future<void> _toggleListening() async {
    if (!_ready) {
      await _initSpeech();
      return;
    }
    if (_listening) {
      // User tapped stop — end both capture streams and finalize.
      await _speech.stop();
      _finishCapture();
      return;
    }
    setState(() {
      _recognized = '';
      _score = 0;
      _completed = false;
      _listening = true;
      _status = 'Escuchando... lee el texto completo.';
    });

    // Start the file recorder FIRST so the first words make it onto disk.
    // The audio session is shared with speech_to_text on iOS — recording in
    // a file via AVAudioRecorder does not collide with SFSpeechRecognizer's
    // engine tap.
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        _recordedPath = path;
      }
    } catch (e) {
      debugPrint('Audio Recorder Error: $e');
    }

    // Tiny breath so AVAudioSession is fully alive before SFSpeech attaches.
    await Future.delayed(const Duration(milliseconds: 120));

    try {
      await _speech.listen(
        localeId: 'es_ES',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 12),
        onResult: _handleResult,
      );
    } catch (e) {
      debugPrint('STT Listen Error: $e');
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords;
    final score = _speechSimilarity(recognized, widget.targetText);
    final passed = score >= _passScore;
    if (!mounted) return;
    setState(() {
      _recognized = recognized;
      _score = score;
      if (passed) {
        _completed = true;
        _status = 'Vas bien — sigue leyendo o toca detener para guardar.';
      }
    });
    // IMPORTANT: do NOT stop on first passed result. Let the user finish.
  }

  bool _finalizing = false;
  Future<void> _finishCapture() async {
    if (_finalizing) return;
    _finalizing = true;
    try {
      final path = await _audioRecorder.stop();
      if (path != null) _recordedPath = path;
      if (!mounted) return;
      setState(() => _listening = false);
      _grade(_recognized);
    } finally {
      _finalizing = false;
    }
  }

  void _grade(String recognized) {
    final score = _speechSimilarity(recognized, widget.targetText);
    final passed = score >= _passScore;
    if (!mounted) return;
    setState(() {
      _score = score;
      _completed = passed;
      _status = passed
          ? '60% o más está fino. Puedes avanzar.'
          : 'Se parece poco todavía. Reintenta leyendo más completo.';
    });
    if (passed) widget.onCompleted(recognized, _recordedPath);
  }


  @override
  Widget build(BuildContext context) {
    final percent = (_score * 100).round();
    final accent = _completed
        ? RefColors.lime
        : _score >= .45
        ? RefColors.sun
        : RefColors.pink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          gradient: LinearGradient(
            colors: [
              RefColors.violet.withValues(alpha: .24),
              RefColors.cyan.withValues(alpha: .10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.source,
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.targetText,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: HtmlRefColors.glassSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HtmlRefColors.glassBorder),
                ),
                child: Text(
                  _recognized.isEmpty
                      ? 'Aquí aparecerá lo que entendió el reconocimiento de voz.'
                      : _recognized,
                  style: TextStyle(
                    color: _recognized.isEmpty ? RefColors.dim : RefColors.ink,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: _listening ? RefColors.primary : null,
                        color: _listening ? null : RefColors.glassStrong,
                        shape: BoxShape.circle,
                        border: Border.all(color: RefColors.border),
                      ),
                      child: Icon(
                        _listening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$percent% parecido',
                          style: TextStyle(
                            color: accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RefProgress(_score.clamp(.02, 1.0)),
                        const SizedBox(height: 7),
                        Text(
                          _status,
                          style: const TextStyle(
                            color: RefColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
}

class _ListenOwnVoicePracticeCard extends StatefulWidget {
  final String originalText;
  final String voiceText;
  final String source;
  final String? audioPath;
  final VoidCallback onCompleted;

  const _ListenOwnVoicePracticeCard({
    required this.originalText,
    required this.voiceText,
    required this.source,
    this.audioPath,
    required this.onCompleted,
  });

  @override
  State<_ListenOwnVoicePracticeCard> createState() =>
      _ListenOwnVoicePracticeCardState();
}

class _ListenOwnVoicePracticeCardState
    extends State<_ListenOwnVoicePracticeCard> {
  late final FlutterTts _tts;
  late final AudioPlayer _audioPlayer;
  int _tab = 1;
  bool _playing = false;
  bool _completed = false;
  int _highlightedCount = 0;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playing = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _audioDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && _audioDuration.inMilliseconds > 0 && _playing) {
        final progress =
            position.inMilliseconds / _audioDuration.inMilliseconds;
        setState(() {
          _highlightedCount = (progress * _currentText.length).toInt().clamp(
            0,
            _currentText.length,
          );
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _highlightedCount = 0;
        if (_tab == 1) _completed = true;
      });
      if (_tab == 1) widget.onCompleted();
    });

    _tts.setStartHandler(() {
      if (mounted) setState(() => _playing = true);
    });

    _tts.setProgressHandler((text, start, end, word) {
      if (mounted) {
        setState(() {
          _highlightedCount = end.clamp(0, _currentText.length);
        });
      }
    });

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _highlightedCount = 0;
        if (_tab == 1 && widget.voiceText.trim().isNotEmpty) {
          _completed = true;
        }
      });
      if (_tab == 1 && widget.voiceText.trim().isNotEmpty) {
        widget.onCompleted();
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _playing = false;
          _highlightedCount = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _currentText {
    if (_tab == 1 && widget.voiceText.trim().isEmpty) {
      return 'Primero completa el paso de leer en voz para guardar tu lectura.';
    }
    return widget.originalText;
  }

  Future<void> _play() async {
    if (_playing) {
      await _tts.stop();
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _playing = false;
          _highlightedCount = 0;
        });
      }
      return;
    }

    if (_tab == 1 && widget.audioPath != null) {
      await _audioPlayer.setPlaybackRate(1);
      await _audioPlayer.play(DeviceFileSource(widget.audioPath!));
      final duration = await _audioPlayer.getDuration();
      if (mounted && duration != null) {
        setState(() => _audioDuration = duration);
      }
    } else {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(_tab == 0 ? 0.44 : 0.48);
      await _tts.setPitch(_tab == 0 ? 1.0 : .92);
      await _tts.speak(_currentText);
    }
  }

  Future<void> _switchTab(int tab) async {
    await _tts.stop();
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _tab = tab;
      _playing = false;
      _highlightedCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasVoice = widget.voiceText.trim().isNotEmpty;
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .25),
          RefColors.sun.withValues(alpha: .16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: HtmlRefColors.glassSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HtmlRefColors.glassBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VoiceTab(
                    'Tuyo',
                    active: _tab == 1,
                    onTap: () => _switchTab(1),
                  ),
                  const SizedBox(width: 4),
                  _VoiceTab(
                    'Original',
                    active: _tab == 0,
                    onTap: () => _switchTab(0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.source,
            style: const TextStyle(
              color: RefColors.pink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(minHeight: 138),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HtmlRefColors.glassSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HtmlRefColors.glassBorder),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: _tab == 1 && !hasVoice
                      ? RefColors.dim
                      : RefColors.ink.withValues(alpha: 0.4),
                  fontSize: 18,
                  height: 1.38,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
                children: [
                  if (_highlightedCount > 0)
                    TextSpan(
                      text: _currentText.substring(0, _highlightedCount),
                      style: const TextStyle(color: RefColors.ink),
                    ),
                  TextSpan(text: _currentText.substring(_highlightedCount)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _PlayerMainButton(paused: _playing, onTap: _play),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _tab == 0
                      ? 'Escucha el original para comparar.'
                      : hasVoice
                      ? (_completed
                            ? 'Ya escuchaste tu lectura. Puedes avanzar.'
                            : 'Reproduce tu lectura para cerrar el paso.')
                      : 'No hay lectura guardada todavía.',
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
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

class _VoiceTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _VoiceTab(this.label, {required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? RefColors.primary : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : RefColors.muted,
          ),
        ),
      ),
    );
  }
}

class _ListenAudioCard extends StatefulWidget {
  final VoidCallback? onCompleted;

  const _ListenAudioCard({this.onCompleted});

  @override
  State<_ListenAudioCard> createState() => _ListenAudioCardState();
}

class _ListenAudioCardState extends State<_ListenAudioCard> {
  late final FlutterTts _tts;
  final ScrollController _textScrollController = ScrollController();
  bool _playing = false;
  bool _completed = false;
  int _wordIndex = 0;
  int _ttsStartWordOffset = 0;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setStartHandler(() {
      if (mounted) setState(() => _playing = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _playing = false;
          _completed = true;
          _wordIndex = 0;
        });
        widget.onCompleted?.call();
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _playing = false);
    });
    _tts.setProgressHandler((text, startOffset, endOffset, word) {
      if (!mounted) return;
      final before = text.substring(0, startOffset.clamp(0, text.length));
      final index = _studyWords(
        before,
      ).length.clamp(0, _studyWords(text).length);
      final absoluteIndex = (_ttsStartWordOffset + index).clamp(
        0,
        _studyWords(_cardStudyText(context)).length,
      );
      setState(() => _wordIndex = absoluteIndex);
      _scrollToProgress(
        absoluteIndex,
        _studyWords(_cardStudyText(context)).length,
      );
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _textScrollController.dispose();
    super.dispose();
  }

  void _scrollToProgress(int index, int total) {
    if (total <= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_textScrollController.hasClients) return;
      final max = _textScrollController.position.maxScrollExtent;
      if (max <= 0) return;
      final target = max * (index / (total - 1)).clamp(0.0, 1.0);
      _textScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _toggle(String text) async {
    if (_playing) {
      await _tts.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.44);
    await _tts.setPitch(1.0);
    await _speakFromCurrent(text);
  }

  Future<void> _restart(String text) async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _wordIndex = 0;
        _playing = false;
        _completed = false;
      });
    }
    await _toggle(text);
  }

  Future<void> _speakFromCurrent(String text) async {
    final words = _studyWords(text);
    final start = _wordIndex.clamp(0, words.length - 1);
    _ttsStartWordOffset = start;
    final remaining = words.skip(start).join(' ');
    await _tts.speak(remaining);
  }

  Future<void> _skipForward(String text) async {
    final words = _studyWords(text);
    final nextIndex = (_wordIndex + 12).clamp(0, words.length - 1);
    await _tts.stop();
    if (mounted) {
      setState(() {
        _wordIndex = nextIndex;
        _playing = false;
      });
    }
    _scrollToProgress(nextIndex, words.length);
    await _toggle(text);
  }

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final source = _cardSourceText(context).toUpperCase();
    final text = _cardStudyText(context);
    final safeIndex = _wordIndex.clamp(0, words.length - 1);
    final lead = words.take(safeIndex).join(' ');
    final current = words[safeIndex];
    final tail = words.skip(safeIndex + 1).join(' ');
    final progress = words.isEmpty ? 0.0 : ((safeIndex + 1) / words.length);
    return Glass(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .34),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Text(
            source,
            style: TextStyle(
              color: RefColors.pink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 34),
          Expanded(
            child: Center(
              child: Scrollbar(
                controller: _textScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _textScrollController,
                  padding: const EdgeInsets.only(right: 10),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (lead.isNotEmpty)
                          TextSpan(
                            text: '$lead ',
                            style: const TextStyle(color: RefColors.lime),
                          ),
                        TextSpan(
                          text: current,
                          style: const TextStyle(
                            color: RefColors.ink,
                            backgroundColor: Color(0x44273CFE),
                          ),
                        ),
                        TextSpan(
                          text: tail.isEmpty ? '' : ' $tail',
                          style: const TextStyle(color: RefColors.muted),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: RefProgress(progress.clamp(.03, 1.0)),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                _playing ? 'Leyendo' : 'Listo',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${safeIndex + 1}/${words.length} palabras',
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: RefColors.inner),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlayerSmallButton(
                Icons.replay_rounded,
                onTap: () => _restart(text),
              ),
              const SizedBox(width: 18),
              _PlayerMainButton(paused: _playing, onTap: () => _toggle(text)),
              const SizedBox(width: 18),
              _PlayerSmallButton(
                Icons.forward_5_rounded,
                onTap: () => _skipForward(text),
              ),
            ],
          ),
          if (_completed) ...[
            const SizedBox(height: 12),
            const StatusChip(
              'ESCUCHA COMPLETA',
              color: Color(0x338DFD63),
              borderColor: Color(0x668DFD63),
              textColor: RefColors.lime,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerSmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PlayerSmallButton(this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: RefColors.glassStrong,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RefColors.border),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

class _PlayerMainButton extends StatelessWidget {
  final bool paused;
  final VoidCallback? onTap;

  const _PlayerMainButton({this.paused = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: RefColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: RefColors.pink.withValues(alpha: .42),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          paused ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 34,
        ),
      ),
    );
  }
}

class _FlowHintCard extends StatelessWidget {
  final String icon;
  final String text;

  const _FlowHintCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FragmentedTextCard extends StatelessWidget {
  const _FragmentedTextCard();

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final visible = words.take(3).join(' ');
    final active = words.length > 3 ? words[3] : '';
    final hidden = words.skip(4).join(' ');
    final activeSplit = active.length < 2 ? active.length : 2;
    return Glass(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: SizedBox(
        height: 150,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$visible '),
                TextSpan(
                  text: active.isEmpty ? '' : active.substring(0, activeSplit),
                  style: const TextStyle(
                    color: RefColors.ink,
                    decoration: TextDecoration.underline,
                    decorationColor: RefColors.pink,
                    decorationThickness: 3,
                  ),
                ),
                TextSpan(
                  text: active.isEmpty
                      ? hidden
                      : '${active.substring(activeSplit)} $hidden',
                  style: const TextStyle(color: RefColors.dim),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 29,
              height: 1.45,
              fontWeight: FontWeight.w900,
              letterSpacing: -.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedSelectorCard extends StatelessWidget {
  const _SpeedSelectorCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text(
            'VELOCIDAD',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: _SpeedPill('Lenta')),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: RefColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Normal',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Expanded(child: _SpeedPill('Rápida')),
        ],
      ),
    );
  }
}

class _SpeedPill extends StatelessWidget {
  final String label;

  const _SpeedPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: RefColors.glassSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RefColors.border),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: RefColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TapPauseCard extends StatelessWidget {
  const _TapPauseCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.cyan.withValues(alpha: .08),
      border: Border.all(color: RefColors.cyan.withValues(alpha: .28)),
      child: Row(
        children: [
          const Text('👆', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Toca la pantalla para pausar · desliza → para saltar al final',
              style: TextStyle(
                color: RefColors.ink,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: RefColors.cyan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '⏸ Pausar',
              style: TextStyle(
                color: Color(0xFF003A4A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KaraokeLine extends StatelessWidget {
  final double fontSize;

  const _KaraokeLine({this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final lead = words.take(3).join(' ');
    final current = words.length > 3 ? words[3] : words.last;
    final tail = words.skip(4).join(' ');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$lead ',
            style: const TextStyle(color: RefColors.lime),
          ),
          TextSpan(
            text: current,
            style: const TextStyle(
              color: RefColors.ink,
              backgroundColor: Color(0x553B173E),
              decoration: TextDecoration.underline,
              decorationColor: RefColors.pink,
              decorationThickness: 3,
            ),
          ),
          TextSpan(
            text: tail.isEmpty ? '' : ' $tail',
            style: const TextStyle(color: RefColors.muted),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.42,
        fontWeight: FontWeight.w900,
        letterSpacing: -.35,
      ),
    );
  }
}

class _PulseMic extends StatelessWidget {
  const _PulseMic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final size in [150.0, 122.0, 98.0])
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: RefColors.pink.withValues(alpha: .35),
                    width: 2,
                  ),
                ),
              ),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: RefColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: RefColors.pink.withValues(alpha: .45),
                    blurRadius: 34,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🎤', style: TextStyle(fontSize: 36)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceQuoteCard extends StatelessWidget {
  const _VoiceQuoteCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .33),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: const _KaraokeLine(fontSize: 22),
    );
  }
}

enum _WaveKind { original, you }

class _WaveformCard extends StatelessWidget {
  final _WaveKind kind;

  const _WaveformCard({required this.kind});

  @override
  Widget build(BuildContext context) {
    final isYou = kind == _WaveKind.you;
    return Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              StatusChip(
                isYou ? 'TÚ' : 'ORIGINAL',
                color: (isYou ? RefColors.pink : RefColors.cyan).withValues(
                  alpha: .18,
                ),
                borderColor: (isYou ? RefColors.pink : RefColors.cyan)
                    .withValues(alpha: .38),
                textColor: isYou ? RefColors.pink : RefColors.cyan,
              ),
              if (isYou) ...[
                const SizedBox(width: 8),
                const StatusChip(
                  '3/5 REP',
                  color: RefColors.glassStrong,
                  textColor: RefColors.pink,
                ),
              ],
              const Spacer(),
              const _SpeedMini('0.5×'),
              const SizedBox(width: 4),
              const _SpeedMini('1×', active: true),
              const SizedBox(width: 4),
              const _SpeedMini('1.5×'),
            ],
          ),
          const SizedBox(height: 14),
          _WaveBars(color: isYou ? RefColors.pink : RefColors.cyan),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                isYou ? '0:01' : '0:00',
                style: const TextStyle(
                  color: RefColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const _PlayerTinyButton(Icons.replay_rounded),
              const SizedBox(width: 10),
              _PlayerRoundButton(paused: isYou),
              const SizedBox(width: 10),
              const _PlayerTinyButton(Icons.replay_rounded, mirror: true),
              const Spacer(),
              const Text(
                '0:04',
                style: TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedMini extends StatelessWidget {
  final String label;
  final bool active;

  const _SpeedMini(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? null : RefColors.glassStrong,
        gradient: active ? RefColors.primary : null,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: active ? Colors.transparent : RefColors.border,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _WaveBars extends StatelessWidget {
  final Color color;

  const _WaveBars({required this.color});

  @override
  Widget build(BuildContext context) {
    const heights = [
      24.0,
      40.0,
      30.0,
      52.0,
      34.0,
      44.0,
      25.0,
      38.0,
      48.0,
      31.0,
      42.0,
      29.0,
    ];
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < heights.length; i++) ...[
            Expanded(
              child: Container(
                height: heights[i],
                decoration: BoxDecoration(
                  color: color.withValues(alpha: i < 6 ? .95 : .55),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < heights.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

class _PlayerTinyButton extends StatelessWidget {
  final IconData icon;
  final bool mirror;

  const _PlayerTinyButton(this.icon, {this.mirror = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: RefColors.glassStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RefColors.border),
      ),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(mirror ? -1.0 : 1.0, 1.0, 1.0),
        child: Icon(icon, size: 19),
      ),
    );
  }
}

class _PlayerRoundButton extends StatelessWidget {
  final bool paused;

  const _PlayerRoundButton({this.paused = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: paused ? 58 : 52,
      height: paused ? 58 : 52,
      decoration: BoxDecoration(
        color: paused ? null : RefColors.glassStrong,
        gradient: paused ? RefColors.primary : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: paused ? Colors.transparent : RefColors.border,
        ),
        boxShadow: paused
            ? [
                BoxShadow(
                  color: RefColors.pink.withValues(alpha: .35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Icon(paused ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }
}

class _BlocksCounterCard extends StatelessWidget {
  const _BlocksCounterCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '2 / 4',
                  style: TextStyle(
                    color: RefColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(text: ' en su lugar'),
              ],
            ),
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Spacer(),
          RefChip('Intento 1/3', dense: true),
        ],
      ),
    );
  }
}

class _BlocksListCard extends StatelessWidget {
  const _BlocksListCard();

  @override
  Widget build(BuildContext context) {
    final blocks = _studyBlocks(context);
    return Glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            _VerseBlock(
              blocks[i],
              correct: i < 2,
              selected: i == 2,
              wrong: i == 3,
            ),
            if (i != blocks.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _VerseBlock extends StatelessWidget {
  final String text;
  final bool correct;
  final bool selected;
  final bool wrong;

  const _VerseBlock(
    this.text, {
    this.correct = false,
    this.selected = false,
    this.wrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = correct
        ? RefColors.lime
        : wrong
        ? RefColors.urgent
        : selected
        ? RefColors.pink
        : RefColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: correct
            ? RefColors.lime.withValues(alpha: .12)
            : wrong
            ? RefColors.urgent.withValues(alpha: .12)
            : selected
            ? Colors.transparent
            : RefColors.glassSoft,
        gradient: selected
            ? LinearGradient(
                colors: [
                  RefColors.pink.withValues(alpha: .2),
                  const Color(0xFF7C3AFF).withValues(alpha: .1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? RefColors.pink : accent.withValues(alpha: .48),
          width: 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: RefColors.pink.withValues(alpha: .3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          if (correct || wrong)
            Icon(
              correct ? Icons.check_rounded : Icons.close_rounded,
              color: correct ? RefColors.lime : RefColors.urgent,
              size: 18,
            ),
        ],
      ),
    );
  }
}

class _BlockMoveTarget extends StatelessWidget {
  final bool visible;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<int> onAccept;

  const _BlockMoveTarget({
    required this.visible,
    required this.active,
    required this.onTap,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => active,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        final shown = visible || highlighted;
        return GestureDetector(
          onTap: active ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: shown ? 34 : 6,
            margin: EdgeInsets.symmetric(vertical: shown ? 6 : 2),
            padding: shown
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: RefColors.cyan.withValues(alpha: highlighted ? .20 : .10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: RefColors.cyan.withValues(
                  alpha: shown ? (highlighted ? .72 : .42) : 0,
                ),
              ),
            ),
            child: shown
                ? Center(
                    child: Text(
                      'Mover aquí',
                      style: TextStyle(
                        color: active
                            ? RefColors.cyan
                            : RefColors.cyan.withValues(alpha: .45),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _LostPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _LostPanel({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      color: RefColors.urgent.withValues(alpha: .12),
      border: Border.all(color: RefColors.urgent.withValues(alpha: .55)),
      child: Column(
        children: [
          const Icon(
            Icons.timer_off_rounded,
            color: RefColors.urgent,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.urgent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onRetry();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [RefColors.pink, RefColors.urgent],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Reintentar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteStatsCard extends StatelessWidget {
  final bool level2;
  final String firstValue;
  final String firstLabel;
  final String secondValue;
  final String secondLabel;
  final String timeValue;

  const _CompleteStatsCard({
    this.level2 = false,
    this.firstValue = '1/3',
    this.firstLabel = 'HUECOS',
    this.secondValue = '2/2',
    this.secondLabel = 'INTENTOS',
    this.timeValue = '00:45',
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 15),
      gradient: LinearGradient(
        colors: const [Color(0x55372B86), Color(0x668B5B21)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FlashStat(firstValue, firstLabel),
          _FlashStat(secondValue, secondLabel),
          if (level2)
            _FlashStat(timeValue, 'TIEMPO', valueColor: RefColors.sun),
        ],
      ),
    );
  }
}

class _CompleteSentenceCard extends StatelessWidget {
  final bool level2;

  const _CompleteSentenceCard({this.level2 = false});

  @override
  Widget build(BuildContext context) {
    final text = _maskedStudyLine(context, visibleWords: level2 ? 1 : 3);
    return Glass(
      padding: EdgeInsets.symmetric(
        horizontal: level2 ? 14 : 18,
        vertical: level2 ? 32 : 34,
      ),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .32),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          height: 1.6,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WordBankCard extends StatelessWidget {
  final bool level2;

  const _WordBankCard({this.level2 = false});

  @override
  Widget build(BuildContext context) {
    final base = _studyWords(_cardStudyText(context)).take(level2 ? 8 : 5);
    final words = [...base, if (level2) 'camino' else 'guía', 'padre'];
    return Glass(
      radius: 18,
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
            children: [for (final word in words) _WordChip(word)],
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool correct;

  const _WordChip(this.label, {this.active = false, this.correct = false});

  @override
  Widget build(BuildContext context) {
    final accent = correct
        ? RefColors.lime
        : active
        ? RefColors.cyan
        : RefColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (active || correct)
            ? accent.withValues(alpha: .14)
            : RefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: .55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (correct) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 15,
              color: RefColors.lime,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FirstLetterSentence extends StatelessWidget {
  final String? text;
  final int level;
  final List<String>? targets;
  final List<String?>? answers;
  final int activeIndex;
  final ValueChanged<int>? onBlankTap;

  const _FirstLetterSentence({
    this.text,
    required this.level,
    this.targets,
    this.answers,
    this.activeIndex = 0,
    this.onBlankTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHarder = level >= 2;
    final sourceText = text ?? _cardStudyText(context);
    final words = _studyWords(sourceText);
    final targetWords =
        targets ?? _firstLetterTargets(sourceText, level: level);
    final answerWords =
        answers ?? List<String?>.filled(targetWords.length, null);
    final visibleWords = switch (level) {
      1 => 3,
      2 => 1,
      _ => 0,
    };
    final usedTargetIndexes = <int>{};
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 32),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .30),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Center(
        child: Wrap(
          spacing: isHarder ? 8 : 10,
          runSpacing: isHarder ? 12 : 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            for (var wordIndex = 0; wordIndex < words.length; wordIndex++)
              if (wordIndex < visibleWords)
                _LetterWord(words[wordIndex])
              else
                _letterWidget(
                  words[wordIndex],
                  usedTargetIndexes,
                  targetWords,
                  answerWords,
                ),
            const Text(
              '.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _letterWidget(
    String word,
    Set<int> usedTargetIndexes,
    List<String> targetWords,
    List<String?> answerWords,
  ) {
    final targetIndex = _matchingUnusedTargetIndex(
      word,
      usedTargetIndexes,
      targetWords,
    );
    if (targetIndex == null) return _LetterWord(word);
    usedTargetIndexes.add(targetIndex);
    return _LetterBlank(
      answer: answerWords[targetIndex],
      active: activeIndex == targetIndex && answerWords[targetIndex] == null,
      wordLength: word.length,
      onTap: () => onBlankTap?.call(targetIndex),
    );
  }

  int? _matchingUnusedTargetIndex(
    String word,
    Set<int> usedTargetIndexes,
    List<String> targetWords,
  ) {
    for (var index = 0; index < targetWords.length; index++) {
      if (usedTargetIndexes.contains(index)) continue;
      if (_sameAnswer(word, targetWords[index])) return index;
    }
    return null;
  }
}

class _LetterWord extends StatelessWidget {
  final String text;

  const _LetterWord(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -.2,
      ),
    );
  }
}

class _LetterBlank extends StatelessWidget {
  final String? answer;
  final bool active;
  final int wordLength;
  final VoidCallback onTap;

  const _LetterBlank({
    required this.answer,
    required this.active,
    required this.wordLength,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final complete = answer != null;
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
          color: active
              ? accent.withValues(alpha: .35)
              : accent.withValues(alpha: complete ? .16 : .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: active ? 1.0 : .5),
            width: active ? 2.4 : 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: .6),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
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

class _KeyboardCard extends StatelessWidget {
  final ValueChanged<String>? onLetterTap;

  const _KeyboardCard({this.onLetterTap});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ñ'],
      ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
    ];
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              children: [
                if (i == 2) const Spacer(flex: 1),
                for (final letter in rows[i]) ...[
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _KeyCap(
                        letter,
                        onTap: onLetterTap == null
                            ? null
                            : () => onLetterTap!(letter),
                      ),
                    ),
                  ),
                ],
                if (i == 2) const Spacer(flex: 1),
              ],
            ),
            if (i < rows.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _KeyCap(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: .06)
              : Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .16),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

enum _ListeningColorMode { blue, pink }

class _VoiceRecitationPracticeCard extends StatefulWidget {
  final String targetText;
  final _ListeningColorMode colorMode;
  final void Function(bool passed) onCompleted;

  const _VoiceRecitationPracticeCard({
    required this.targetText,
    required this.colorMode,
    required this.onCompleted,
  });

  @override
  State<_VoiceRecitationPracticeCard> createState() =>
      _VoiceRecitationPracticeCardState();
}

class _VoiceRecitationPracticeCardState
    extends State<_VoiceRecitationPracticeCard> {
  stt.SpeechToText? _speech;
  bool _ready = false;
  bool _listening = false;
  bool _completed = false;
  String _recognized = '';
  int _currentBlock = 0;
  int? _lastWrongAt;
  int _attemptsRemaining = 5;

  late List<String> _targetBlocks;
  late List<bool> _blockSolved;

  @override
  void initState() {
    super.initState();
    _targetBlocks = _splitIntoBlocks(widget.targetText);
    _blockSolved = List<bool>.filled(_targetBlocks.length, false);
    _initSpeech();
  }

  @override
  void didUpdateWidget(covariant _VoiceRecitationPracticeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetText != widget.targetText) {
      _targetBlocks = _splitIntoBlocks(widget.targetText);
      _blockSolved = List<bool>.filled(_targetBlocks.length, false);
      _currentBlock = 0;
      _recognized = '';
      _attemptsRemaining = 5;
      _completed = false;
    }
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    final available = await _speech!.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    setState(() => _ready = available);
  }

  @override
  void dispose() {
    _speech?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_ready) {
      await _initSpeech();
      return;
    }
    if (_listening) {
      await _speech!.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
    });
    await _speech!.listen(
      localeId: 'es_ES',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 6),
      onResult: (result) => _handleRecognition(result.recognizedWords),
    );
  }

  void _handleRecognition(String text) {
    if (!mounted) return;
    setState(() => _recognized = text);
    if (_currentBlock >= _targetBlocks.length) return;

    final normalizedSpoken = _normalizeSpeechText(text);
    final expectedBlock = _targetBlocks[_currentBlock];
    final normalizedExpected = _normalizeSpeechText(expectedBlock);

    if (_blocksMatch(normalizedSpoken, normalizedExpected)) {
      setState(() {
        _blockSolved[_currentBlock] = true;
        _currentBlock += 1;
        _recognized = '';
      });
      if (_currentBlock >= _targetBlocks.length && !_completed) {
        _completed = true;
        _stopListeningOnComplete();
        widget.onCompleted(true);
      }
    } else if (normalizedSpoken.length >= 3) {
      setState(() {
        _lastWrongAt = DateTime.now().millisecondsSinceEpoch;
        _attemptsRemaining = (_attemptsRemaining - 1).clamp(0, 99);
      });
      if (_attemptsRemaining <= 0 && !_completed) {
        _completed = true;
        _stopListeningOnComplete();
        widget.onCompleted(false);
      }
    }
  }

  void _stopListeningOnComplete() {
    _speech?.cancel();
    if (mounted) setState(() => _listening = false);
  }

  bool _blocksMatch(String spoken, String expected) {
    if (spoken == expected) return true;
    if (spoken.contains(expected) || expected.contains(spoken)) return true;
    final spokenWords = spoken.split(' ').where((w) => w.isNotEmpty).toList();
    final expectedWords = expected
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (spokenWords.isEmpty || expectedWords.isEmpty) return false;
    int matchCount = 0;
    for (final expectedWord in expectedWords) {
      for (final spokenWord in spokenWords) {
        if (_wordsSimilar(spokenWord, expectedWord)) {
          matchCount++;
          break;
        }
      }
    }
    final matchRatio = matchCount / expectedWords.length;
    return matchRatio >= 0.5;
  }

  bool _wordsSimilar(String a, String b) {
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen <= 1) return a == b;
    int distance = 0;
    final minLength = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < minLength; i++) {
      if (a[i] != b[i]) distance++;
    }
    distance += (maxLen - minLength);
    final similarity = 1 - (distance / maxLen);
    return similarity >= 0.5;
  }

  List<String> _splitIntoBlocks(String text) {
    final words = _studyWords(text);
    if (words.length <= 6) return words;
    final blockSize = (words.length / 3).round().clamp(2, 5);
    final blocks = <String>[];
    for (var i = 0; i < words.length; i += blockSize) {
      final end = (i + blockSize).clamp(0, words.length);
      blocks.add(words.sublist(i, end).join(' '));
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final isBlue = widget.colorMode == _ListeningColorMode.blue;
    final accent = _completed
        ? RefColors.lime
        : isBlue
        ? RefColors.cyan
        : RefColors.pink;
    final wrongRecent =
        _lastWrongAt != null &&
        DateTime.now().millisecondsSinceEpoch - _lastWrongAt! < 1200;
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _targetBlocks.length; i++)
                _RecitationBlock(
                  text: _targetBlocks[i],
                  solved: _blockSolved[i],
                  active: i == _currentBlock && !_completed,
                  accent: accent,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: _listening ? .55 : .18),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: .85)),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .35),
                        blurRadius: _listening ? 28 : 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: RefColors.ink,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: wrongRecent
                        ? RefColors.urgent.withValues(alpha: .18)
                        : HtmlRefColors.glassSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: wrongRecent
                          ? RefColors.urgent
                          : HtmlRefColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    _recognized.isEmpty
                        ? (_listening ? 'Escuchando…' : 'Toca el mic y recita')
                        : _recognized,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _recognized.isEmpty
                          ? RefColors.dim
                          : RefColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: .6)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_attemptsRemaining',
                      style: TextStyle(
                        color: _attemptsRemaining <= 1
                            ? RefColors.urgent
                            : accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'intentos',
                      style: TextStyle(
                        color: accent.withValues(alpha: .85),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'restantes',
                      style: TextStyle(
                        color: accent.withValues(alpha: .85),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecitationBlock extends StatelessWidget {
  final String text;
  final bool solved;
  final bool active;
  final Color accent;

  const _RecitationBlock({
    required this.text,
    required this.solved,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = solved
        ? RefColors.lime
        : active
        ? accent
        : RefColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: blockColor.withValues(alpha: solved || active ? .16 : .06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: blockColor.withValues(alpha: .6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (solved) ...[
            const Icon(Icons.check_rounded, color: RefColors.lime, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            solved ? text : '_' * text.length.clamp(3, 20),
            style: TextStyle(
              color: solved ? RefColors.lime : RefColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningHud extends StatelessWidget {
  final _ListeningColorMode colorMode;

  const _ListeningHud({required this.colorMode});

  @override
  Widget build(BuildContext context) {
    final isBlue = colorMode == _ListeningColorMode.blue;
    final accent = isBlue ? RefColors.cyan : RefColors.pink;
    final icon = isBlue ? '🎧' : '🎤';
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .18),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: .45)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Empieza a recitar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '● ESCUCHANDO...',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceHiddenWordsCard extends StatelessWidget {
  final bool finalMode;

  const _VoiceHiddenWordsCard({required this.finalMode});

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    if (finalMode) {
      return _buildAllHidden(words);
    }
    final rng = math.Random(DateTime.now().millisecondsSinceEpoch ~/ 60000);
    final hiddenRatio = 0.35;
    final hiddenCount = (words.length * hiddenRatio).round().clamp(
      1,
      words.length - 1,
    );
    final indices = List.generate(words.length, (i) => i);
    indices.shuffle(rng);
    final hiddenIndices = indices.take(hiddenCount).toSet();
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .30),
          RefColors.sun.withValues(alpha: .28),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < words.length; i++)
                    if (hiddenIndices.contains(i))
                      _HiddenWord(
                        wordLength: words[i].length,
                        active: false,
                        pink: false,
                      )
                    else
                      _LetterWord(words[i]),
                  const Text(
                    '.',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllHidden(List<String> words) {
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .30),
          RefColors.sun.withValues(alpha: .28),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < words.length; i++)
                    _HiddenWord(
                      wordLength: words[i].length,
                      active: i == 0,
                      pink: true,
                    ),
                  const Text(
                    '.',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HiddenWord extends StatelessWidget {
  final int wordLength;
  final bool active;
  final bool pink;
  final bool solved;
  final bool skipped;
  final bool wrongFlash;
  final String? word;

  const _HiddenWord({
    required this.wordLength,
    this.active = false,
    this.pink = false,
    this.solved = false,
    this.skipped = false,
    this.wrongFlash = false,
    this.word,
  });

  @override
  Widget build(BuildContext context) {
    final accent = wrongFlash
        ? RefColors.urgent
        : skipped
        ? RefColors.sun
        : solved
        ? RefColors.lime
        : active
        ? (pink ? RefColors.pink : RefColors.cyan)
        : RefColors.border;
    final filledColor = skipped ? RefColors.sun : RefColors.lime;
    final length = wordLength.clamp(1, 14);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(minWidth: (length * 10.0).clamp(28, 160)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: wrongFlash ? .28 : (solved || active ? .16 : .08),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: wrongFlash ? 1 : .62),
          width: wrongFlash ? 2 : 1.5,
        ),
      ),
      child: solved && word != null
          ? TweenAnimationBuilder<double>(
              key: ValueKey('solved-$word-$skipped'),
              tween: Tween(begin: 0.55, end: 1.0),
              duration: const Duration(milliseconds: 360),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                word!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: filledColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Text(
              '_' * length,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RefColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _QuizNav extends StatelessWidget {
  const _QuizNav();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++) ...[
            Expanded(child: _QuizChip('Q$i', active: i == 2)),
            if (i < 5) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _QuizChip extends StatelessWidget {
  final String label;
  final bool active;

  const _QuizChip(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                colors: [
                  RefColors.cyan.withValues(alpha: .92),
                  const Color(0xFF347DFF).withValues(alpha: .92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : RefColors.glassStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? RefColors.cyan : RefColors.border,
          width: active ? 1.6 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : RefColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String text;

  const _WarningCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.pink.withValues(alpha: .10),
      border: Border.all(color: RefColors.pink.withValues(alpha: .36)),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _Stat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GlyphIcon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: RefColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTopBar extends StatelessWidget {
  final String center;

  const _ExerciseTopBar({required this.center});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Inside the exercise flow the back arrow jumps to the progress
          // tree (the user's "session map"), not the previous step. Use
          // pushReplacement so we don't pile new entries on the stack.
          RefBackButton(
            onTap: () => Navigator.pushReplacementNamed(
              context,
              '${AppRoutes.flow}/progress-tree',
            ),
          ),
          Expanded(child: Center(child: RefChip(center, dense: true))),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String ctx;
  final String? turn;
  final String question;
  final List<(String, String, bool)> options;

  const _QuestionCard({
    required this.ctx,
    this.turn,
    required this.question,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Glass(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ctx,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RefColors.muted,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (turn != null)
                    Text(
                      turn!,
                      style: const TextStyle(
                        color: RefColors.sun,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                question,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final opt in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Glass(
              radius: 16,
              padding: const EdgeInsets.all(12),
              color: opt.$3
                  ? RefColors.pink.withValues(alpha: .14)
                  : RefColors.glass,
              border: Border.all(
                color: opt.$3
                    ? RefColors.pink.withValues(alpha: .45)
                    : RefColors.border,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: opt.$3 ? RefColors.primary : null,
                      color: opt.$3 ? null : RefColors.glassStrong,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        opt.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      opt.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

