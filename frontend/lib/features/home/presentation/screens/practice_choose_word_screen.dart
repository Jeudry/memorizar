import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/app_state.dart';
import '../../../../core/theme/ref_colors.dart';
import '../../../../core/ui/widgets.dart';
import '../exercise_logic.dart';

/// Práctica de "Elige la palabra correcta" sobre una tarjeta, embebida como un
/// paso del flujo de estudio (bloque Preparar).
///
/// A diferencia de los ejercicios con nivel de la sesión (intentos, cronómetro
/// y distractores de IA), esta versión es de práctica:
///  - sin niveles ni límite de intentos (fallar no penaliza, solo no avanza);
///  - 100% de las palabras ocultas;
///  - hay que completarlo DOS veces para terminar.
///
/// No incluye scaffold ni top bar propios: devuelve solo el contenido para que
/// lo envuelva el chrome del flujo. Al terminar (botón "Listo") invoca
/// [onFinished], que el flujo usa para marcar el paso y avanzar.
class ChooseWordPracticeBody extends StatefulWidget {
  final String cardId;
  final String targetText;
  final String reference;
  final VoidCallback onFinished;

  const ChooseWordPracticeBody({
    super.key,
    required this.cardId,
    required this.targetText,
    required this.reference,
    required this.onFinished,
  });

  @override
  State<ChooseWordPracticeBody> createState() => _ChooseWordPracticeBodyState();
}

class _ChooseWordPracticeBodyState extends State<ChooseWordPracticeBody> {
  static const int _passesRequired = 1;

  String? _cardId;
  List<String> _words = [];
  List<int> _blankPositions = [];
  Map<int, String> _filled = {};
  List<String> _options = [];
  int _pass = 0;
  bool _finished = false;
  int? _wrongFlashPos; // resalta en rojo brevemente al fallar

  String _norm(String w) =>
      w.toLowerCase().replaceAll(RegExp(r'[^0-9a-záéíóúüñ]'), '');

  List<String> _splitWords(String text) {
    final clean = text
        .replaceAll(RegExp(r'[“”"]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return const ['Jehová', 'es', 'mi', 'pastor'];
    return clean.split(' ');
  }

  void _ensure(String cardId, String targetText, BuildContext context) {
    if (_cardId == cardId) return;
    _cardId = cardId;
    _words = _splitWords(targetText);
    final hideFifty = AppScope.of(context).hideFiftyPercentPractice;
    final allWordPositions = [
      for (var i = 0; i < _words.length; i++)
        if (_norm(_words[i]).isNotEmpty) i,
    ];
    if (hideFifty) {
      if (allWordPositions.isEmpty) {
        _blankPositions = [];
      } else {
        final list = [...allWordPositions]..shuffle(math.Random());
        final count = (allWordPositions.length / 2).round().clamp(1, allWordPositions.length);
        _blankPositions = list.take(count).toList()..sort();
      }
    } else {
      _blankPositions = allWordPositions;
    }
    _startPass(0, targetText);
  }

  void _startPass(int pass, String text) {
    _pass = pass;
    _filled = {};
    _finished = false;
    _wrongFlashPos = null;
    _updateOptionsForActiveBlank(text);
  }

  void _updateOptionsForActiveBlank(String text) {
    final pos = _activeBlank;
    if (pos == null) {
      _options = [];
      return;
    }
    final target = _words[pos];
    _options = completionOptions(text, target);
  }

  int? get _activeBlank {
    for (final pos in _blankPositions) {
      if (!_filled.containsKey(pos)) return pos;
    }
    return null;
  }

  void _tap(String word, String text) {
    final pos = _activeBlank;
    if (pos == null || _finished) return;
    if (_norm(word) == _norm(_words[pos])) {
      setState(() {
        _filled[pos] = _words[pos];
        _wrongFlashPos = null;
      });
      final next = _activeBlank;
      if (next == null) {
        // Pasada completa.
        if (_pass + 1 < _passesRequired) {
          setState(() => _startPass(_pass + 1, text));
        } else {
          setState(() => _finished = true);
        }
      } else {
        setState(() {
          _updateOptionsForActiveBlank(text);
        });
      }
    } else {
      // Práctica: sin penalización, solo feedback visual breve.
      setState(() => _wrongFlashPos = pos);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _wrongFlashPos == pos) {
          setState(() => _wrongFlashPos = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensure(widget.cardId, widget.targetText, context);
    final activeBlank = _activeBlank;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PracticeHeader(
          pass: _pass,
          passesRequired: _passesRequired,
          filled: _filled.length,
          total: _blankPositions.length,
          reference: widget.reference,
        ),
        const SizedBox(height: 12),
        // El versículo con huecos.
        Glass(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
          gradient: LinearGradient(
            colors: [
              RefColors.violet.withValues(alpha: .26),
              RefColors.cyan.withValues(alpha: .20),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _words.length; i++)
                _WordSlot(
                  word: _words[i],
                  isBlank: _blankPositions.contains(i),
                  filled: _filled[i],
                  isActive: i == activeBlank,
                  isWrong: i == _wrongFlashPos,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_finished)
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                const Text(
                  '¡Lo completaste!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Practicaste sin presión. Tu memoria lo agradece.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: RefColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        'Otra vez',
                        onTap: () => setState(() {
                          _cardId = null; // fuerza re-init
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Cta(
                        'Listo',
                        onTap: widget.onFinished,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final word in _options)
                      GestureDetector(
                        onTap: () => _tap(word, widget.targetText),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: RefColors.glassStrong,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: RefColors.border),
                          ),
                          child: Text(
                            word,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w900),
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
}

class _PracticeHeader extends StatelessWidget {
  final int pass;
  final int passesRequired;
  final int filled;
  final int total;
  final String reference;

  const _PracticeHeader({
    required this.pass,
    required this.passesRequired,
    required this.filled,
    required this.total,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(14),
      color: RefColors.glassStrong,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sin niveles · sin intentos · complétalo $passesRequired veces',
                  style:
                      const TextStyle(color: RefColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: RefColors.violet.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: RefColors.violet.withValues(alpha: .5)),
            ),
            child: Text(
              'Vuelta ${pass + 1}/$passesRequired · $filled/$total',
              style: const TextStyle(
                color: RefColors.violet,
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

class _WordSlot extends StatelessWidget {
  final String word;
  final bool isBlank;
  final String? filled;
  final bool isActive;
  final bool isWrong;

  const _WordSlot({
    required this.word,
    required this.isBlank,
    required this.filled,
    required this.isActive,
    required this.isWrong,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBlank) {
      return Text(
        word,
        style: const TextStyle(
            fontSize: 18, height: 1.5, fontWeight: FontWeight.w800),
      );
    }
    final done = filled != null;
    final Color accent = isWrong
        ? RefColors.urgent
        : done
            ? RefColors.lime
            : isActive
                ? RefColors.cyan
                : RefColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: done ? .16 : .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent, width: isActive ? 1.8 : 1),
      ),
      child: Text(
        done ? filled! : '_____',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: done ? RefColors.ink : accent,
        ),
      ),
    );
  }
}
