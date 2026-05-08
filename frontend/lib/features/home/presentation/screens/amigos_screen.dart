// Generado del refactor de ui_screens.dart.
// AmigosScreen + helpers.
part of '../ui_screens.dart';

class AmigosScreen extends StatefulWidget {
  const AmigosScreen({super.key});

  @override
  State<AmigosScreen> createState() => _AmigosScreenState();
}

class _AmigosScreenState extends State<AmigosScreen> {
  FriendsResult? _data;
  List<RemoteUser> _suggestions = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final friends = await store.api.listFriends();
      final suggestions = await store.api.suggestions();
      if (!mounted) return;
      setState(() {
        _data = friends;
        _suggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendRequest(RemoteUser to) async {
    final store = AppScope.of(context);
    try {
      await store.api.requestFriend(to.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitación enviada a ${to.displayName}')),
      );
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pude enviar la invitación: $e')),
      );
    }
  }

  Future<void> _accept(Friendship f) async {
    final store = AppScope.of(context);
    try {
      await store.api.acceptFriend(f.id);
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pude aceptar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      return ReferencePage(
        active: AppRoutes.amigos,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RefTopBar(title: 'Amigos'),
            const _InviteHero(),
            Glass(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: RefColors.cyan,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Inicia sesión para conectar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Necesitas una cuenta para encontrar y mandar invitaciones a amigos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Cta(
                    'Iniciar sesión',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final friends = _data?.friends ?? const [];
    final pending = _data?.pendingRequests ?? const [];
    return ReferencePage(
      active: AppRoutes.amigos,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Amigos'),
          const _InviteHero(),
          _FriendSearch(onInvite: _sendRequest),
          if (_error != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RefColors.urgent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: RefColors.urgent.withValues(alpha: .55),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: RefColors.urgent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(
                        color: RefColors.urgent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _refresh,
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: RefColors.urgent,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_loading && _data == null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          if (pending.isNotEmpty) ...[
            const SectionHead('Invitaciones pendientes'),
            for (final f in pending)
              _PendingFriendRow(
                friendship: f,
                meId: store.currentUser?.id ?? '',
                onAccept: () => _accept(f),
              ),
          ],
          if (friends.isNotEmpty) ...[
            const SectionHead('Tus amigos'),
            for (final f in friends)
              _FriendshipRow(friendship: f, meId: store.currentUser?.id ?? ''),
          ] else if (_data != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Todavía no tienes amigos. Mira las sugerencias de abajo.',
              style: TextStyle(color: RefColors.muted, fontSize: 12),
            ),
          ],
          if (_suggestions.isNotEmpty) ...[
            const SectionHead('Sugerencias'),
            for (final s in _suggestions)
              _SuggestionRow(user: s, onInvite: () => _sendRequest(s)),
          ],
        ],
      ),
    );
  }
}

class _PendingFriendRow extends StatelessWidget {
  final Friendship friendship;
  final String meId;
  final VoidCallback onAccept;
  const _PendingFriendRow({
    required this.friendship,
    required this.meId,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming = friendship.addresseeId == meId;
    final otherId = isIncoming ? friendship.requesterId : friendship.addresseeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Row(
        children: [
          const Fav('?'),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncoming ? 'Te quiere agregar' : 'Solicitud enviada',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  otherId,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isIncoming)
            GestureDetector(
              onTap: onAccept,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: RefColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            const Text(
              'Pendiente',
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

class _FriendshipRow extends StatelessWidget {
  final Friendship friendship;
  final String meId;
  const _FriendshipRow({required this.friendship, required this.meId});

  @override
  Widget build(BuildContext context) {
    final otherId = friendship.requesterId == meId
        ? friendship.addresseeId
        : friendship.requesterId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Row(
        children: [
          const Fav('A'),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              otherId,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: RefColors.muted,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final RemoteUser user;
  final VoidCallback onInvite;
  const _SuggestionRow({required this.user, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Row(
        children: [
          Fav(user.initial),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName.isEmpty ? user.email : user.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                if (user.email.isNotEmpty)
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onInvite,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: HtmlRefColors.glassStrong,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RefColors.pink.withValues(alpha: .55)),
              ),
              child: const Text(
                '+ Invitar',
                style: TextStyle(
                  color: RefColors.pink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteHero extends StatelessWidget {
  const _InviteHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.all(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF55C8FF), Color(0xFF7757FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: Colors.transparent),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -44,
              top: -60,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: .22),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const GlyphIcon('🤝', size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crecen juntos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Invita amigos y multipliquen su progreso',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xE6FFFFFF),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '+ Invitar',
                    style: TextStyle(
                      color: Color(0xFF063079),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
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

/// Caja de búsqueda de personas. Hace search debounced (350ms) contra el
/// backend `/v1/social/search`, muestra resultados inline con botón Invitar.
class _FriendSearch extends StatefulWidget {
  final ValueChanged<RemoteUser>? onInvite;
  const _FriendSearch({this.onInvite});

  @override
  State<_FriendSearch> createState() => _FriendSearchState();
}

class _FriendSearchState extends State<_FriendSearch> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<RemoteUser> _results = const [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    setState(() => _searching = true);
    try {
      final results = await store.api.searchPeople(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      // Silencioso — el usuario puede reintentar tipeando.
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Glass(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            gradient: LinearGradient(
              colors: [
                RefColors.violet.withValues(alpha: .14),
                RefColors.sun.withValues(alpha: .16),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 19, color: RefColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: RefColors.ink,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Buscar por nombre o correo…',
                      hintStyle: TextStyle(
                        color: RefColors.dim,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (_searching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      setState(() => _results = const []);
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: RefColors.muted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final u in _results)
              _SearchHitRow(
                user: u,
                onInvite: widget.onInvite == null ? null : () => widget.onInvite!(u),
              ),
          ] else if (_controller.text.trim().length >= 2 && !_searching) ...[
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Sin resultados.',
                style: TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchHitRow extends StatelessWidget {
  final RemoteUser user;
  final VoidCallback? onInvite;
  const _SearchHitRow({required this.user, this.onInvite});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Row(
        children: [
          Fav(user.initial, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName.isEmpty ? user.email : user.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (user.email.isNotEmpty)
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (onInvite != null)
            GestureDetector(
              onTap: onInvite,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: HtmlRefColors.glassStrong,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: RefColors.pink.withValues(alpha: .55),
                  ),
                ),
                child: const Text(
                  '+ Invitar',
                  style: TextStyle(
                    color: RefColors.pink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingInvite extends StatelessWidget {
  const _PendingInvite();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: const Color(0x18FFB400),
        border: Border.all(color: const Color(0x4DFFB400)),
        child: Row(
          children: [
            const _FriendAvatar('N', gradient: RefColors.primary, size: 36),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nora te invita a ser amiga',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Os conocéis por Sofía',
                    style: TextStyle(fontSize: 10, color: RefColors.muted),
                  ),
                ],
              ),
            ),
            const _MiniButton('Aceptar', primary: true),
            const SizedBox(width: 6),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: HtmlRefColors.glassSoft,
                shape: BoxShape.circle,
                border: Border.all(color: HtmlRefColors.glassBorder),
              ),
              child: const Icon(Icons.close_rounded, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final String initial;
  final String name;
  final String status;
  final List<String> badges;
  final String primaryAction;
  final Gradient gradient;
  final bool online;
  final bool live;

  const _FriendCard({
    required this.initial,
    required this.name,
    required this.status,
    required this.badges,
    required this.primaryAction,
    required this.gradient,
    this.online = false,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.all(14),
        color: const Color(0x12FFFFFF),
        border: Border.all(color: const Color(0x2EFFFFFF)),
        child: Row(
          children: [
            _FriendAvatar(
              initial,
              gradient: gradient,
              size: 46,
              online: online,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      color: live ? RefColors.lime : RefColors.muted,
                      fontWeight: live ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final badge in badges) _FriendBadge(badge),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MiniButton(primaryAction, primary: true),
                const SizedBox(height: 5),
                const _MiniButton('Mensaje'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  final String initial;
  final Gradient gradient;
  final double size;
  final bool online;

  const _FriendAvatar(
    this.initial, {
    required this.gradient,
    this.size = 46,
    this.online = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(size * .32),
            border: Border.all(color: HtmlRefColors.glassBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: size * .34,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (online)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: RefColors.lime,
                shape: BoxShape.circle,
                border: Border.all(color: RefColors.bg, width: 2),
                boxShadow: const [
                  BoxShadow(color: RefColors.lime, blurRadius: 7),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String text;
  final bool primary;

  const _MiniButton(this.text, {this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: primary ? RefColors.limeGrad : null,
        color: primary ? null : HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: primary ? Colors.transparent : HtmlRefColors.glassBorder,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: primary ? RefColors.successInk : RefColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FriendBadge extends StatelessWidget {
  final String text;

  const _FriendBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

