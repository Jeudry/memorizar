// AUTO-GENERATED extraction from ui_screens.dart (refactor PR-D).
// Tightly-coupled exercise-flow widgets — kept in this library to
// preserve cross-class private visibility.
part of '../ui_screens.dart';

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

