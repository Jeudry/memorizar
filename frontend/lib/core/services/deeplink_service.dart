import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../app_state.dart';
import '../api/memorizar_client.dart';
import '../router/app_routes.dart';
import '../theme/ref_colors.dart';
import '../ui/widgets.dart';

/// Servicio que escucha deeplinks `memorizar://deck/{shareId}` y abre un
/// preview con botón "Importar". Activado desde main.dart con el
/// `BuildContext` del `MaterialApp` para poder navegar.
class DeeplinkService {
  final AppLinks _links = AppLinks();
  StreamSubscription<Uri>? _sub;
  GlobalKey<NavigatorState>? _navKey;
  AppStore? _store;

  /// Llamar una vez después de runApp. Procesa el link inicial (si la app
  /// se abrió desde uno) y empieza a escuchar futuros.
  Future<void> attach({
    required GlobalKey<NavigatorState> navKey,
    required AppStore store,
  }) async {
    _navKey = navKey;
    _store = store;
    try {
      final initial = await _links.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {}
    _sub = _links.uriLinkStream.listen(
      _handle,
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handle(Uri uri) {
    // Esquemas soportados:
    //   memorizar://deck/{id}
    //   memorizar://coop/{code}
    //   https://memorizar.app/deck/{id}    (universal link futuro)
    final isDeck = uri.host == 'deck' || uri.pathSegments.firstOrNull == 'deck';
    final isCoop = uri.host == 'coop' || uri.pathSegments.firstOrNull == 'coop';
    if (!isDeck && !isCoop) return;
    final id = uri.host == 'deck' || uri.host == 'coop'
        ? uri.pathSegments.firstOrNull
        : uri.pathSegments.length > 1
            ? uri.pathSegments[1]
            : null;
    if (id == null || id.isEmpty) return;
    if (isCoop) {
      _openCoopRoom(id.toUpperCase());
      return;
    }
    _showPreview(id);
  }

  /// Deja el código pendiente en el store y abre el lobby cooperativo, que
  /// lo consume y se une automáticamente a la sala.
  void _openCoopRoom(String code) {
    final navState = _navKey?.currentState;
    final store = _store;
    if (navState == null || store == null) return;
    store.pendingCoopJoinCode = code;
    navState.pushNamed(AppRoutes.cooperativo);
  }

  Future<void> _showPreview(String shareId) async {
    final navState = _navKey?.currentState;
    final store = _store;
    if (navState == null || store == null) return;
    final ctx = navState.context;
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DeeplinkPreviewSheet(
        shareId: shareId,
        store: store,
        client: store.api,
      ),
    );
  }
}

class _DeeplinkPreviewSheet extends StatefulWidget {
  final String shareId;
  final AppStore store;
  final MemorizarClient client;
  const _DeeplinkPreviewSheet({
    required this.shareId,
    required this.store,
    required this.client,
  });

  @override
  State<_DeeplinkPreviewSheet> createState() => _DeeplinkPreviewSheetState();
}

class _DeeplinkPreviewSheetState extends State<_DeeplinkPreviewSheet> {
  Map<String, dynamic>? _share;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final r = await http.get(
        Uri.parse('${widget.client.baseUrl}/v1/public/shares/${widget.shareId}'),
      );
      if (r.statusCode != 200) {
        throw Exception('HTTP ${r.statusCode}');
      }
      setState(() => _share = jsonDecode(r.body) as Map<String, dynamic>);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _import() {
    final share = _share;
    if (share == null) return;
    try {
      final raw = (share['payloadJson'] as String?) ?? '';
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final cards = (payload['cards'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map((c) => MemoryCardData(
                id: 'link-${DateTime.now().microsecondsSinceEpoch}-${c['id']}',
                front: (c['front'] as String?) ?? '',
                back: (c['back'] as String?) ?? '',
                source: (c['source'] as String?) ?? 'Link',
                icon: (c['icon'] as String?) ?? '🔗',
              ))
          .toList();
      widget.store.createDeckFromCards(
        title: '${payload['title'] ?? share['title']} (link)',
        icon: (payload['icon'] as String?) ?? '🔗',
        cards: cards,
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mazo importado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + viewInsets.bottom),
      child: Glass(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.link_rounded, color: RefColors.lime, size: 22),
                SizedBox(width: 8),
                Text(
                  'Mazo compartido',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Text(
                'No pudimos cargar el mazo: $_error',
                style: const TextStyle(color: RefColors.urgent, fontSize: 12),
              )
            else if (_share != null) ...[
              Text(
                (_share!['title'] as String?) ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (_share!['summary'] as String?) ?? '',
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Cta('Importar a mis mazos', onTap: _import),
              const SizedBox(height: 8),
              GhostButton(
                'Cerrar',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
