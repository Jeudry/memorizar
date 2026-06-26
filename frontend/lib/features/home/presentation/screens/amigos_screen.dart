// Generado del refactor de ui_screens.dart.
// AmigosScreen + helpers.
part of '../ui_screens.dart';

class AmigosScreen extends StatefulWidget {
  const AmigosScreen({super.key});

  static void showAddFriendModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddFriendModal(),
    );
  }

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitación enviada a ${to.displayName}')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
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
          
          // Sala Cooperativa Card
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.cooperativo),
              child: Glass(
                radius: 18,
                padding: const EdgeInsets.all(14),
                gradient: LinearGradient(
                  colors: [
                    RefColors.cyan.withValues(alpha: .2),
                    RefColors.pink.withValues(alpha: .2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: RefColors.cyan.withValues(alpha: .2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.people_alt_rounded, color: RefColors.cyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Abrir Sala Cooperativa',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Estudien juntos en tiempo real con o sin tarjetas.',
                            style: TextStyle(
                              fontSize: 11,
                              color: RefColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: RefColors.muted),
                  ],
                ),
              ),
            ),
          ),

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
              _FriendshipRow(friend: f),
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
  final RemoteUser friend;
  const _FriendshipRow({required this.friend});

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
          Fav(friend.initial),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName.isEmpty
                      ? '@${friend.username}'
                      : friend.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (friend.username.isNotEmpty)
                  Text(
                    '@${friend.username}',
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
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
                  user.displayName.isEmpty
                      ? '@${user.username}'
                      : user.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                if (user.username.isNotEmpty)
                  Text(
                    '@${user.username}',
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
        radius: 16,
        padding: const EdgeInsets.all(12),
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
                width: 120,
                height: 120,
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const GlyphIcon('🤝', size: 19),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crecen juntos',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Invita amigos y multipliquen su progreso',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xE6FFFFFF),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    final store = AppScope.of(context);
                    if (store.isLoggedIn) {
                      AmigosScreen.showAddFriendModal(context);
                    } else {
                      Navigator.pushNamed(context, AppRoutes.login);
                    }
                  },
                  child: Container(
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
                  user.displayName.isEmpty
                      ? '@${user.username}'
                      : user.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (user.username.isNotEmpty)
                  Text(
                    '@${user.username}',
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

class AddFriendModal extends StatefulWidget {
  const AddFriendModal({super.key});

  @override
  State<AddFriendModal> createState() => _AddFriendModalState();
}

class _AddFriendModalState extends State<AddFriendModal> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<RemoteUser> _results = const [];
  bool _searching = false;
  String? _message;

  List<RemoteUser> _myFriends = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMyFriends());
  }

  Future<void> _fetchMyFriends() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    try {
      final res = await store.api.listFriends();
      if (mounted) {
        setState(() {
          _myFriends = res.friends;
        });
      }
    } catch (_) {}
  }

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
    } catch (_) {}
    finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendRequest(RemoteUser to) async {
    final store = AppScope.of(context);
    try {
      await store.api.requestFriend(to.id);
      if (!mounted) return;
      setState(() {
        _message = '¡Invitación enviada a ${to.displayName.isNotEmpty ? to.displayName : to.email}!';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _message = null);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final userId = store.currentUser?.id ?? '';
    
    // Enlace de invitación dinámico
    final inviteLink = kIsWeb 
        ? '${Uri.base.scheme}://${Uri.base.host}${Uri.base.port != 80 && Uri.base.port != 443 ? ":${Uri.base.port}" : ""}/?ref=$userId'
        : 'http://localhost:61337/?ref=$userId';

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0C1B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Agregar amigos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            // Sección Enlace de Invitación
            const Text(
              'Comparte tu enlace de invitación',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RefColors.pink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Cualquiera que se registre o inicie sesión con este enlace se agregará automáticamente como tu amigo.',
              style: TextStyle(
                fontSize: 12,
                color: RefColors.muted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            
            // Cuadro del enlace
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteLink,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RefColors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Enlace de invitación copiado!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copiar', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Sección Tus Amigos (Si tiene amigos)
            if (_myFriends.isNotEmpty) ...[
              const Text(
                'Tus amigos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: RefColors.lime,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _myFriends.length,
                  itemBuilder: (context, idx) {
                    final f = _myFriends[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Fav(f.initial, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.displayName.isEmpty ? f.email : f.displayName,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (f.displayName.isNotEmpty && f.email.isNotEmpty)
                                  Text(
                                    f.email,
                                    style: const TextStyle(color: RefColors.muted, fontSize: 10, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RefColors.lime.withValues(alpha: .2),
                              foregroundColor: RefColors.lime,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              final code = CoopService.active?.state?.code ?? '';
                              final linkWithRoom = '$inviteLink&room=$code';
                              Clipboard.setData(ClipboardData(text: linkWithRoom));
                              
                              setState(() {
                                _message = '¡Enlace copiado para invitar a ${f.displayName.isNotEmpty ? f.displayName : f.email}! 🚀';
                              });
                              Future.delayed(const Duration(seconds: 3), () {
                                if (mounted) setState(() => _message = null);
                              });
                            },
                            child: const Text('Invitar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Línea divisoria
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('O', style: TextStyle(color: RefColors.muted, fontSize: 12)),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              ],
            ),
            const SizedBox(height: 20),
            
            // Sección Búsqueda
            const Text(
              'Buscar por nombre o correo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RefColors.cyan,
              ),
            ),
            const SizedBox(height: 8),
            
            // Input de búsqueda
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white54, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: _onChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Ingresa nombre o email...',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                        isDense: true,
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
                      child: const Icon(Icons.close, color: Colors.white54, size: 18),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Mensaje de éxito si aplica
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  _message!,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Resultados
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, idx) {
                    final u = _results[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Fav(u.initial, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.displayName.isEmpty ? u.email : u.displayName,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                if (u.email.isNotEmpty)
                                  Text(
                                    u.email,
                                    style: const TextStyle(color: RefColors.muted, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              foregroundColor: RefColors.pink,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: RefColors.pink.withValues(alpha: 0.3)),
                              ),
                            ),
                            onPressed: () => _sendRequest(u),
                            child: const Text('+ Invitar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else if (_controller.text.trim().length >= 2 && !_searching) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sin resultados.',
                  style: TextStyle(color: RefColors.muted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

