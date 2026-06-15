part of '../ui_screens.dart';

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
