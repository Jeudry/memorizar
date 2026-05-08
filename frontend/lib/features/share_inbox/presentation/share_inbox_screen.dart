import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// Bandeja de mazos que un amigo te compartió. Lista [/v1/social/shares] del
/// receptor, permite importar a la colección local con un solo tap.
class ShareInboxScreen extends StatefulWidget {
  const ShareInboxScreen({super.key});

  @override
  State<ShareInboxScreen> createState() => _ShareInboxScreenState();
}

class _ShareInboxScreenState extends State<ShareInboxScreen> {
  List<Map<String, dynamic>>? _shares;
  bool _loading = false;
  String? _busyShareId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    setState(() => _loading = true);
    try {
      final shares = await store.api.listShares();
      if (!mounted) return;
      // Solo mostramos shares donde YO soy el target (recibidos), no los
      // que yo mismo emití.
      final me = store.currentUser?.id ?? '';
      setState(() {
        _shares = shares
            .where((s) => (s['targetUserId'] as String?) == me)
            .toList();
      });
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importShare(Map<String, dynamic> share) async {
    final store = AppScope.of(context);
    final id = (share['id'] as String?) ?? '';
    setState(() => _busyShareId = id);
    try {
      final raw = (share['payloadJson'] as String?) ?? '';
      if (raw.isEmpty) throw Exception('Payload vacío');
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final cards = (payload['cards'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map((c) => MemoryCardData(
                id: 'shared-${DateTime.now().microsecondsSinceEpoch}-${c['id']}',
                front: (c['front'] as String?) ?? '',
                back: (c['back'] as String?) ?? '',
                source: (c['source'] as String?) ?? 'Compartido',
                icon: (c['icon'] as String?) ?? '🎁',
              ))
          .toList();
      store.createDeckFromCards(
        title: '${(payload['title'] as String?) ?? share['title']} (importado)',
        icon: (payload['icon'] as String?) ?? '🎁',
        cards: cards,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mazo "${(payload['title'] as String?) ?? share['title']}" importado',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyShareId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final shares = _shares ?? const [];
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.repasar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RefTopBar(title: AppStrings.t(context, 'inbox.title')),
          if (!store.isLoggedIn)
            Glass(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline_rounded, color: RefColors.cyan, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'Inicia sesión para ver mazos compartidos contigo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RefColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Cta(
                    'Iniciar sesión',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                  ),
                ],
              ),
            )
          else if (_loading && _shares == null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else if (shares.isEmpty) ...[
            Glass(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined, color: RefColors.cyan, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.t(context, 'inbox.empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            for (final share in shares)
              _ShareRow(
                share: share,
                busy: _busyShareId == share['id'],
                onImport: () => _importShare(share),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  final Map<String, dynamic> share;
  final bool busy;
  final VoidCallback onImport;
  const _ShareRow({
    required this.share,
    required this.busy,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final title = (share['title'] as String?) ?? 'Sin título';
    final summary = (share['summary'] as String?) ?? '';
    final ownerId = (share['ownerUserId'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: RefColors.lime, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'De: $ownerId',
                      style: const TextStyle(
                        color: RefColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              summary,
              style: const TextStyle(
                color: RefColors.ink,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Cta(
            AppStrings.t(context, 'inbox.import'),
            onTap: busy ? null : onImport,
            disabled: busy,
          ),
        ],
      ),
    );
  }
}
