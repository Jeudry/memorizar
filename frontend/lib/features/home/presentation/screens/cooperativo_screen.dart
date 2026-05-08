// Generado del refactor de ui_screens.dart.
// CooperativoScreen + Game + Success + helpers.
part of '../ui_screens.dart';

class CooperativoScreen extends StatefulWidget {
  const CooperativoScreen({super.key});

  @override
  State<CooperativoScreen> createState() => _CooperativoScreenState();
}

class _CooperativoScreenState extends State<CooperativoScreen> {
  late final CoopService _coop;
  CoopRoomState? _state;
  StreamSubscription<CoopRoomState>? _sub;
  final _joinCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _coop = CoopService(client: AppScope.of(context).api);
    _sub = _coop.stateStream.listen((s) => setState(() => _state = s));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _coop.dispose();
    _joinCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _coop.createRoom(
        userId: store.currentUser!.id,
        name: store.currentUser!.displayName,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final code = _joinCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _coop.joinRoom(
        code: code,
        userId: store.currentUser!.id,
        name: store.currentUser!.displayName,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return ReferencePage(
      active: AppRoutes.amigos,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoopTopBar(center: state == null ? 'Cooperativo' : '🔒 SALA · ${state.code}'),
          if (state == null) ...[
            const _CoopLobbyHero(),
            const SizedBox(height: 14),
            Glass(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Crear una sala',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Genera un código de 6 letras y compártelo con tus amigos.',
                    style: TextStyle(color: RefColors.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Cta('+ Crear sala', onTap: _busy ? null : _create, disabled: _busy),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Unirse con código',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: HtmlRefColors.glassSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HtmlRefColors.glassBorder),
                    ),
                    child: TextField(
                      controller: _joinCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        color: RefColors.ink,
                        fontSize: 18,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'ABC123',
                        hintStyle: TextStyle(
                          color: RefColors.dim,
                          fontSize: 18,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Cta('Unirme →', onTap: _busy ? null : _join, disabled: _busy),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: RefColors.urgent, fontSize: 12),
              ),
            ],
          ] else ...[
            Glass(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'CÓDIGO DE SALA',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.code,
                    style: const TextStyle(
                      fontSize: 38,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w900,
                      color: RefColors.lime,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${state.memberIds.length} ${state.memberIds.length == 1 ? "miembro" : "miembros"} en la sala',
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final id in state.memberIds)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HtmlRefColors.glassSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HtmlRefColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Fav('?', size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        id,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (id == state.hostId)
                      const RefChip(
                        'HOST',
                        dense: true,
                        color: Color(0x33FF3EA5),
                        textColor: RefColors.pink,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            GhostButton(
              'Salir de la sala',
              onTap: () async {
                await _coop.disconnect();
                if (mounted) setState(() => _state = null);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class CooperativoGameScreen extends StatelessWidget {
  const CooperativoGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CoopTopBar(center: 'EN JUEGO · 3/4', live: true),
          const _CoopTeamRow(),
          const SizedBox(height: 14),
          const RefProgress(.48),
          const SizedBox(height: 14),
          const _CoopQuestionCard(),
          const SizedBox(height: 14),
          const _SharedHint(),
          const SizedBox(height: 14),
          const _CoopOption(letter: 'A', text: 'Filtrar impurezas del aire'),
          const SizedBox(height: 10),
          const _CoopOption(
            letter: 'B',
            text: 'Intercambio de gases con la sangre',
            selected: true,
            voter: 'M',
          ),
          const SizedBox(height: 10),
          const _CoopOption(letter: 'C', text: 'Producir mucosidad protectora'),
          const SizedBox(height: 10),
          const _CoopOption(
            letter: 'D',
            text: 'Regular la temperatura corporal',
          ),
          const SizedBox(height: 14),
          const _CoopGameChat(),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: GhostButton('💬 Pedir ayuda')),
              const SizedBox(width: 8),
              Expanded(
                child: Cta(
                  'Confirmar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.cooperativoLogrado,
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

class CooperativoSuccessScreen extends StatelessWidget {
  const CooperativoSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CoopTopBar(center: 'Sala cerrada'),
          const _CoopCelebrateCard(),
          const SizedBox(height: 14),
          const _CoopScoreCard(),
          const SizedBox(height: 14),
          const _CoopShareCard(),
          const SizedBox(height: 14),
          const _CoopRecapCard(),
          const SizedBox(height: 14),
          const _CoopAchievements(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Salir',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.amigos),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Cta(
                  'Otra ronda →',
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.cooperativo,
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

class _CoopTopBar extends StatelessWidget {
  final String center;
  final bool live;

  const _CoopTopBar({required this.center, this.live = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(),
          Expanded(
            child: Center(
              child: RefChip(
                center,
                dense: true,
                color: live
                    ? RefColors.lime.withValues(alpha: .16)
                    : RefColors.glassStrong,
                textColor: live ? RefColors.lime : RefColors.ink,
              ),
            ),
          ),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _CoopLobbyHero extends StatelessWidget {
  const _CoopLobbyHero();

  @override
  Widget build(BuildContext context) {
    final deck = AppScope.of(context).activeDeck;
    return Glass(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
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
          RefChip(
            'SALA COOPERATIVA · ${deck.subtitle.toUpperCase()}',
            dense: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlyphIcon(deck.icon, size: 27),
              const SizedBox(width: 7),
              Text(
                deck.title.replaceAll(' · ', '\n'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Turnos rotativos · ${deck.cards.length} tarjetas · ~${(deck.cards.length * 2).clamp(6, 20)} min',
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CoopParticipant('M', 'Marco', 'Listo', host: true, ready: true),
              SizedBox(width: 14),
              _CoopParticipant('A', 'Ana (tú)', 'Listo', ready: true),
              SizedBox(width: 14),
              _CoopParticipant(
                'L',
                'Lucía',
                'Cargando...',
                loading: true,
                gradient: RefColors.purple,
              ),
              SizedBox(width: 14),
              _CoopParticipant('+', 'Invitar', '1 libre', empty: true),
            ],
          ),
          const SizedBox(height: 16),
          const _CoopChat(
            messages: [
              ('M', 'Marco:', '¡Empezamos en 1 min! preparen café ☕'),
              ('L', 'Lucía:', 'lista en 30 seg'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoopParticipant extends StatelessWidget {
  final String initials;
  final String name;
  final String status;
  final bool host;
  final bool ready;
  final bool empty;
  final bool loading;
  final Gradient gradient;

  const _CoopParticipant(
    this.initials,
    this.name,
    this.status, {
    this.host = false,
    this.ready = false,
    this.empty = false,
    this.loading = false,
    this.gradient = RefColors.cool,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: empty ? Colors.transparent : null,
        gradient: empty ? null : gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: host ? RefColors.sun : RefColors.border,
          width: host ? 2 : 1,
          style: empty ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: host
            ? [
                BoxShadow(
                  color: RefColors.sun.withValues(alpha: .36),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: empty ? RefColors.dim : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              if (ready)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: RefColors.lime,
                      shape: BoxShape.circle,
                      border: Border.all(color: RefColors.bg, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: RefColors.successInk,
                      size: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            host ? '$name ♕' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: empty ? RefColors.dim : RefColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: loading ? RefColors.sun : RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopChat extends StatelessWidget {
  final List<(String, String, String)> messages;

  const _CoopChat({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: RefColors.inner)),
      ),
      child: Column(
        children: [
          for (final message in messages) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Fav(
                  message.$1,
                  size: 24,
                  gradient: message.$1 == 'L'
                      ? RefColors.purple
                      : RefColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: RefColors.muted,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: '${message.$2} ',
                          style: const TextStyle(
                            color: RefColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(text: message.$3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RefColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Escribe un mensaje...',
                    style: TextStyle(
                      color: RefColors.dim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: RefColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopSettingsCard extends StatelessWidget {
  const _CoopSettingsCard();

  @override
  Widget build(BuildContext context) {
    final deck = AppScope.of(context).activeDeck;
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONFIGURACIÓN DE LA SALA',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _CoopSettingRow('Mazo', deck.title, 'Cambiar'),
          const _CoopSettingRow(
            'Modo',
            'Todos responden · el grupo avanza junto',
            'Sincro',
          ),
          _CoopSettingRow(
            'Tarjetas',
            '${deck.cards.length} tarjetas seleccionadas',
            '${deck.cards.length}',
          ),
        ],
      ),
    );
  }
}

class _CoopSettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;

  const _CoopSettingRow(this.title, this.subtitle, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: RefColors.inner)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          RefChip(value, dense: true),
        ],
      ),
    );
  }
}

class _CoopTeamRow extends StatelessWidget {
  const _CoopTeamRow();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CoopMate('M', 'Marco', '✓ Respondió', done: true),
          SizedBox(width: 8),
          _CoopMate('A', 'Tú', 'Tu turno...', answering: true),
          SizedBox(width: 8),
          _CoopMate('L', 'Lucía', 'Esperando', gradient: RefColors.purple),
        ],
      ),
    );
  }
}

class _CoopMate extends StatelessWidget {
  final String avatar;
  final String name;
  final String status;
  final bool done;
  final bool answering;
  final Gradient gradient;

  const _CoopMate(
    this.avatar,
    this.name,
    this.status, {
    this.done = false,
    this.answering = false,
    this.gradient = RefColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Fav(avatar, size: 30, gradient: gradient),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: done
                      ? RefColors.lime
                      : answering
                      ? RefColors.sun
                      : RefColors.muted,
                  fontSize: 10,
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

class _CoopQuestionCard extends StatelessWidget {
  const _CoopQuestionCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PREGUNTA 6 / 12',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                'Tu turno · Ana',
                style: TextStyle(
                  color: RefColors.sun,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '¿Cuál es la función principal de los alvéolos pulmonares?',
            style: TextStyle(
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w900,
              letterSpacing: -.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedHint extends StatelessWidget {
  const _SharedHint();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.sun.withValues(alpha: .12),
      border: Border.all(color: RefColors.sun.withValues(alpha: .34)),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marco compartió una pista',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                Text(
                  '"Piensa en qué ocurre entre oxígeno y sangre"',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 10,
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

class _CoopOption extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final String? voter;

  const _CoopOption({
    required this.letter,
    required this.text,
    this.selected = false,
    this.voter,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(16),
      color: selected ? RefColors.cyan.withValues(alpha: .14) : RefColors.glass,
      border: Border.all(
        color: selected
            ? RefColors.cyan.withValues(alpha: .52)
            : RefColors.border,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: selected ? RefColors.cyan : RefColors.glassSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? Colors.transparent : RefColors.border,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: selected ? const Color(0xFF003A4A) : RefColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          if (voter != null) Fav(voter!, size: 22),
        ],
      ),
    );
  }
}

class _CoopGameChat extends StatelessWidget {
  const _CoopGameChat();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      radius: 18,
      padding: EdgeInsets.all(14),
      child: _CoopChat(
        messages: [
          ('M', 'Marco:', 'ánimo! la que pensamos ayer'),
          ('L', 'Lucía:', '👍'),
        ],
      ),
    );
  }
}

class _CoopCelebrateCard extends StatelessWidget {
  const _CoopCelebrateCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.fromLTRB(22, 24, 22, 22),
      gradient: RefColors.success,
      border: Border(),
      child: Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 52)),
          SizedBox(height: 6),
          Text(
            '¡Lo lograron juntos!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RefColors.successInk,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '20 tarjetas · 12 min · 85% aciertos',
            style: TextStyle(
              color: RefColors.successInk,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopScoreCard extends StatelessWidget {
  const _CoopScoreCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [RefColors.lime, RefColors.lime, RefColors.glassSoft],
                stops: [0, .85, .85],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: RefColors.bg,
                shape: BoxShape.circle,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '85%',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'ACIERTO',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              children: [
                _CoopScoreRow('Correctas', '17 / 20'),
                _CoopScoreRow('Incorrectas', '3'),
                _CoopScoreRow('Tiempo', '12 min'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopScoreRow extends StatelessWidget {
  final String label;
  final String value;

  const _CoopScoreRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: RefColors.inner)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CoopShareCard extends StatelessWidget {
  const _CoopShareCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Text('📸', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparte el logro del grupo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Imagen o texto · sin cuenta necesaria',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: RefColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Compartir',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopRecapCard extends StatelessWidget {
  const _CoopRecapCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📖 CÓMO LES FUE A LAS TARJETAS',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          _CoopRecapItem(
            '1',
            'Alvéolos · función',
            'Marco · sin errores',
            1,
            '✓ 100%',
          ),
          _CoopRecapItem(
            '2',
            'Bronquios principales',
            'Ana · 1 error',
            .92,
            '✓ 92%',
          ),
          _CoopRecapItem(
            '3',
            'Diafragma · función',
            'Lucía · 2 errores',
            .85,
            '⚡ 85%',
            warn: true,
          ),
          _CoopRecapItem(
            '4',
            'Tráquea · anillos',
            'Marco · sin errores',
            .98,
            '✓ 98%',
          ),
          _CoopRecapItem(
            '5',
            'Intercambio gaseoso',
            'Ana · 3 errores',
            .78,
            '⚡ 78%',
            warn: true,
          ),
        ],
      ),
    );
  }
}

class _CoopRecapItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final double progress;
  final String score;
  final bool warn;

  const _CoopRecapItem(
    this.number,
    this.title,
    this.subtitle,
    this.progress,
    this.score, {
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: RefColors.inner)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RefColors.border),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                RefProgress(
                  progress,
                  gradient: warn
                      ? const LinearGradient(
                          colors: [RefColors.sun, RefColors.urgent],
                        )
                      : RefColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(
            score,
            color: (warn ? RefColors.sun : RefColors.lime).withValues(
              alpha: .14,
            ),
            borderColor: (warn ? RefColors.sun : RefColors.lime).withValues(
              alpha: .38,
            ),
            textColor: warn ? RefColors.sun : RefColors.lime,
          ),
        ],
      ),
    );
  }
}

class _CoopAchievements extends StatelessWidget {
  const _CoopAchievements();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 LOGROS DESBLOQUEADOS HOY',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CoopAchievement(
                  '🤝',
                  'En equipo',
                  '3 sesiones co-op',
                  warm: true,
                ),
                SizedBox(width: 8),
                _CoopAchievement(
                  '💡',
                  'Buena pista',
                  'Ayudaste 2x',
                  warm: true,
                ),
                SizedBox(width: 8),
                _CoopAchievement('🔥', 'Racha 10', '3 días restantes'),
                SizedBox(width: 8),
                _CoopAchievement('🌟', 'Precisión', '90% en 3 sesiones'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopAchievement extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool warm;

  const _CoopAchievement(
    this.icon,
    this.title,
    this.subtitle, {
    this.warm = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: warm ? null : RefColors.glassSoft,
        gradient: warm
            ? LinearGradient(
                colors: [
                  RefColors.sun.withValues(alpha: .18),
                  RefColors.pink.withValues(alpha: .12),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warm ? RefColors.sun.withValues(alpha: .38) : RefColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

