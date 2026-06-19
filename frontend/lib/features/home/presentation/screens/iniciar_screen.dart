// Generado del refactor de ui_screens.dart.
// IniciarScreen + helpers (option group, round step).
part of '../ui_screens.dart';

class IniciarScreen extends StatefulWidget {
  const IniciarScreen({super.key});

  @override
  State<IniciarScreen> createState() => _IniciarScreenState();
}

/// Which quick-pick chip the user explicitly tapped. Used to disambiguate
/// when the numeric target matches more than one preset (e.g. when the deck
/// only has 1 card both "breve" and "recomendado" map to 1).
enum _DailyQuickPick { breve, recomendado, intenso, none }

class _IniciarScreenState extends State<IniciarScreen> {
  int _difficulty = 1;
  int? _dailyTarget;
  bool _doubleExercises = false;
  bool _hideFiftyPercentPractice = false;
  bool _debugForceQuizFirst = false;
  _DailyQuickPick _quickPick = _DailyQuickPick.recomendado;
  String? _deckId;
  String _selectedIcon = '✝️';
  bool _showIconPicker = false;
  late final TextEditingController _deckTitleController;

  @override
  void initState() {
    super.initState();
    _deckTitleController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deck = AppScope.of(context).activeDeck;
    if (_deckId == deck.id) return;
    _deckId = deck.id;
    _dailyTarget = _recommendedTarget(deck.cards.length);
    _quickPick = _pickForValue(_dailyTarget!, deck.cards.length);
    _selectedIcon = deck.icon;
    _showIconPicker = false;
    _deckTitleController.text = deck.title;
  }

  @override
  void dispose() {
    _deckTitleController.dispose();
    super.dispose();
  }

  /// "Recomendado" sits between breve (1) and intenso (4). Capped at 3 so it
  /// never collides with intenso visually. For 1-card decks recommended just
  /// equals breve and the chip is hidden in render.
  int _recommendedTarget(int total) {
    if (total <= 0) return 0;
    if (total <= 1) return 1;
    return 2;
  }

  /// Pick the chip whose value the current daily target lands on, so the
  /// badge follows the user when they step with +/-. Strict equality only —
  /// values that don't exactly match a preset leave every chip dim.
  _DailyQuickPick _pickForValue(int value, int total) {
    final rec = _recommendedTarget(total);
    if (value == rec && total > 1) return _DailyQuickPick.recomendado;
    if (value == 1) return _DailyQuickPick.breve;
    if (value == 4) return _DailyQuickPick.intenso;
    return _DailyQuickPick.none;
  }

  void _stepTarget(int delta, int total) {
    if (total <= 0) return;
    final current = _dailyTarget ?? _recommendedTarget(total);
    final next = (current + delta).clamp(1, total);
    setState(() {
      _dailyTarget = next;
      _quickPick = _pickForValue(next, total);
    });
  }

  void _setDailyTarget(int value, int total, _DailyQuickPick pick) {
    if (total <= 0) return;
    setState(() {
      _dailyTarget = value.clamp(1, total);
      _quickPick = pick;
    });
  }



  void _renameDeck(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    AppScope.of(context).updateActiveDeck(title: clean);
  }

  void _setDeckIcon(String icon) {
    setState(() => _selectedIcon = icon);
    AppScope.of(context).updateActiveDeck(icon: icon);
  }

  int _difficultyMinutes(int difficulty, int dailyTarget) {
    final perCard = switch (difficulty) {
      0 => 4,
      1 => 5,
      _ => 6,
    };
    if (dailyTarget <= 0) return 0;
    return (dailyTarget * perCard).clamp(perCard, 45);
  }

  void _saveForLater(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión guardada para continuar luego.')),
    );
    Navigator.pushNamed(context, AppRoutes.repasar);
  }

  void _startSession(BuildContext context, MemoryDeckData deck) {
    if (deck.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea tarjetas antes de empezar.')),
      );
      Navigator.pushNamed(context, AppRoutes.especificar);
      return;
    }
    final target =
        (_dailyTarget ?? _recommendedTarget(deck.cards.length)).clamp(
          1,
          deck.cards.length,
        );
    AppScope.of(context).configureSession(
      difficulty: _difficulty,
      dailyTarget: target,
      doubleExercises: _doubleExercises,
      hideFiftyPercentPractice: _hideFiftyPercentPractice,
      debugForceQuizFirst: _debugForceQuizFirst,
    );
    Navigator.pushNamed(context, '${AppRoutes.flow}/progress-tree');
  }

  @override
  Widget build(BuildContext context) {
    final deck = AppScope.of(context).activeDeck;
    final totalCards = deck.cards.length;
    final dailyTarget = (_dailyTarget ?? _recommendedTarget(totalCards)).clamp(
      totalCards == 0 ? 0 : 1,
      totalCards == 0 ? 0 : totalCards,
    );
    final estimatedDays = totalCards == 0
        ? 0
        : (totalCards / dailyTarget).ceil().clamp(1, 30);
    return ReferencePage(
      active: AppRoutes.repasar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Configurar sesión'),
          Glass(
            color: Colors.transparent,
            gradient: const LinearGradient(
              colors: [Color(0x1AFFFFFF), Color(0x4DFFB400)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                RefColors.pink.withValues(alpha: .4),
                                RefColors.violet.withValues(alpha: .2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: HtmlRefColors.glassBorder,
                            ),
                          ),
                          child: Center(child: GlyphIcon(deck.icon, size: 28)),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: GestureDetector(
                            onTap: () => setState(() => _showIconPicker = true),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: RefColors.primary,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .28),
                                ),
                              ),
                              child: const Icon(Icons.add_rounded, size: 17),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: HtmlRefColors.glassSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: HtmlRefColors.glassBorder,
                              ),
                            ),
                            child: TextField(
                              controller: _deckTitleController,
                              onChanged: _renameDeck,
                              onSubmitted: _renameDeck,
                              onEditingComplete: () =>
                                  _renameDeck(_deckTitleController.text),
                              style: const TextStyle(
                                color: RefColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Nombre del mazo',
                                hintStyle: TextStyle(
                                  color: RefColors.muted,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            totalCards == 0
                                ? 'Agrega tarjetas para estimar la sesión'
                                : '${deck.cards.length} tarjetas · dominarás en ~$estimatedDays días',
                            style: const TextStyle(
                              fontSize: 11,
                              color: RefColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_showIconPicker) ...[
                  const SizedBox(height: 12),
                  Glass(
                    radius: 14,
                    padding: const EdgeInsets.all(10),
                    color: HtmlRefColors.glassSoft,
                    border: Border.all(color: HtmlRefColors.glassBorder),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'ICONO DEL MAZO',
                                style: TextStyle(
                                  color: RefColors.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showIconPicker = false),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_rounded, size: 15),
                                  SizedBox(width: 4),
                                  Text(
                                    'Volver',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final choice in const [
                              ('✝️', Icons.add_rounded),
                              ('📜', Icons.article_rounded),
                              ('🧠', Icons.psychology_rounded),
                              ('✨', Icons.auto_awesome_rounded),
                              ('🎯', Icons.track_changes_rounded),
                              ('⚡', Icons.bolt_rounded),
                            ])
                              GestureDetector(
                                onTap: () => _setDeckIcon(choice.$1),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _selectedIcon == choice.$1
                                        ? RefColors.pink.withValues(alpha: .25)
                                        : HtmlRefColors.glassSoft,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedIcon == choice.$1
                                          ? RefColors.pink
                                          : HtmlRefColors.glassBorder,
                                      width: _selectedIcon == choice.$1
                                          ? 1.6
                                          : 1,
                                    ),
                                  ),
                                  child: Icon(choice.$2, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OptionGroup(
            title: 'Dificultad',
            options: [
              (
                Icons.spa_rounded,
                'Fácil',
                '~${_difficultyMinutes(0, dailyTarget)} min · con pistas',
              ),
              (
                Icons.psychology_alt_rounded,
                'Intermedio',
                '~${_difficultyMinutes(1, dailyTarget)} min · balanceado',
              ),
              (
                Icons.timer_rounded,
                'Experto',
                '~${_difficultyMinutes(2, dailyTarget)} min · intenso',
              ),
            ],
            active: _difficulty,
            onSelect: (index) => setState(() => _difficulty = index),
          ),
          const SizedBox(height: 12),
          Glass(
            color: HtmlRefColors.glassBg,
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Center(
                  child: Text(
                    'CANTIDAD A MEMORIZAR',
                    style: TextStyle(
                      fontSize: 10,
                      color: RefColors.cyan,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    totalCards == 0
                        ? 'Sin tarjetas'
                        : 'Finalizaría en $estimatedDays ${estimatedDays == 1 ? "día" : "días"}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: RefColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _RoundStep(
                                '−',
                                onTap: () => _stepTarget(-1, totalCards),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '$dailyTarget',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _RoundStep(
                                '+',
                                onTap: () => _stepTarget(1, totalCards),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          SizedBox(
                            width: 190,
                            child: RefProgress(
                              totalCards == 0
                                  ? 0
                                  : (dailyTarget / totalCards).clamp(.12, 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 138,
                      child: Column(
                        children: [
                          if (totalCards >= 1)
                            GestureDetector(
                              onTap: () => _setDailyTarget(
                                1,
                                totalCards,
                                _DailyQuickPick.breve,
                              ),
                              child: RefChip(
                                '1 · breve',
                                dense: true,
                                color: _quickPick == _DailyQuickPick.breve
                                    ? RefColors.lime
                                    : null,
                                textColor: _quickPick == _DailyQuickPick.breve
                                    ? RefColors.successInk
                                    : RefColors.ink,
                              ),
                            ),
                          if (_recommendedTarget(totalCards) > 1 &&
                              _recommendedTarget(totalCards) <= totalCards &&
                              _recommendedTarget(totalCards) != 1) ...[
                            const SizedBox(height: 7),
                            GestureDetector(
                              onTap: () => _setDailyTarget(
                                _recommendedTarget(totalCards),
                                totalCards,
                                _DailyQuickPick.recomendado,
                              ),
                              child: RefChip(
                                '${_recommendedTarget(totalCards)} · recomendado',
                                dense: true,
                                color: _quickPick == _DailyQuickPick.recomendado
                                    ? RefColors.lime
                                    : null,
                                textColor:
                                    _quickPick == _DailyQuickPick.recomendado
                                    ? RefColors.successInk
                                    : RefColors.ink,
                              ),
                            ),
                          ],
                          if (totalCards >= 4) ...[
                            const SizedBox(height: 7),
                            GestureDetector(
                              onTap: () => _setDailyTarget(
                                4,
                                totalCards,
                                _DailyQuickPick.intenso,
                              ),
                              child: RefChip(
                                '4 · intenso',
                                dense: true,
                                color: _quickPick == _DailyQuickPick.intenso
                                    ? RefColors.lime
                                    : null,
                                textColor: _quickPick == _DailyQuickPick.intenso
                                    ? RefColors.successInk
                                    : RefColors.ink,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _doubleExercises = !_doubleExercises),
            child: Glass(
              color: HtmlRefColors.glassBg,
              border: Border.all(
                color: _doubleExercises
                    ? RefColors.violet
                    : HtmlRefColors.glassBorder,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Text('🔬', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duplicar ejercicios (experimental)',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Cada tarjeta repite su flujo 2 veces. Más repaso.',
                          style: TextStyle(
                              color: RefColors.muted, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _doubleExercises
                          ? RefColors.violet
                          : HtmlRefColors.glassStrong,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Align(
                      alignment: _doubleExercises
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _hideFiftyPercentPractice = !_hideFiftyPercentPractice),
            child: Glass(
              color: HtmlRefColors.glassBg,
              border: Border.all(
                color: _hideFiftyPercentPractice
                    ? RefColors.violet
                    : HtmlRefColors.glassBorder,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Text('🧩', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ocultar 50% en práctica',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          _hideFiftyPercentPractice
                              ? 'Oculta solo la mitad de las palabras.'
                              : 'Oculta todas las palabras (100%).',
                          style: const TextStyle(
                              color: RefColors.muted, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _hideFiftyPercentPractice
                          ? RefColors.violet
                          : HtmlRefColors.glassStrong,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Align(
                      alignment: _hideFiftyPercentPractice
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _debugForceQuizFirst = !_debugForceQuizFirst),
            child: Glass(
              color: HtmlRefColors.glassBg,
              border: Border.all(
                color: _debugForceQuizFirst
                    ? RefColors.violet
                    : HtmlRefColors.glassBorder,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Forzar Quiz al inicio (Debug)',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          _debugForceQuizFirst
                              ? 'El Quiz saldrá como el primer paso de la sesión.'
                              : 'Flujo de pasos estándar de la sesión.',
                          style: const TextStyle(
                              color: RefColors.muted, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _debugForceQuizFirst
                          ? RefColors.violet
                          : HtmlRefColors.glassStrong,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Align(
                      alignment: _debugForceQuizFirst
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 14,
                child: GhostButton(
                  'Guardar para luego',
                  onTap: () => _saveForLater(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 10,
                child: Cta(
                  '▶ Empezar',
                  onTap: () => _startSession(context, deck),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  final String title;
  final List<(IconData, String, String)> options;
  final int active;
  final ValueChanged<int>? onSelect;

  const _OptionGroup({
    required this.title,
    required this.options,
    required this.active,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      color: HtmlRefColors.glassBg,
      border: Border.all(color: HtmlRefColors.glassBorder),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: RefColors.muted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect?.call(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: i == active
                            ? RefColors.pink.withValues(alpha: .15)
                            : HtmlRefColors.glassSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: i == active
                              ? RefColors.pink
                              : HtmlRefColors.glassBorder,
                          width: 1.5,
                        ),
                        boxShadow: i == active
                            ? [
                                BoxShadow(
                                  color: RefColors.pink.withValues(alpha: .12),
                                  blurRadius: 0,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            options[i].$1,
                            size: 25,
                            color: i == active ? RefColors.pink : RefColors.ink,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            options[i].$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            options[i].$3,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: RefColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i != options.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundStep extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _RoundStep(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: HtmlRefColors.glassStrong,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HtmlRefColors.glassBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

