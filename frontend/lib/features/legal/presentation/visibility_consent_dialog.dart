import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// Sheet para cambiar la visibilidad de un mazo. Si la nueva visibilidad
/// expone el mazo a otros (friends / public), exige una casilla de
/// consentimiento explícita y enlaza a las normas de comunidad.
Future<void> showVisibilityConsentSheet(
  BuildContext context, {
  required String deckId,
  required String deckTitle,
  required DeckVisibility current,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _VisibilitySheet(
      deckId: deckId,
      deckTitle: deckTitle,
      initial: current,
    ),
  );
}

class _VisibilitySheet extends StatefulWidget {
  final String deckId;
  final String deckTitle;
  final DeckVisibility initial;
  const _VisibilitySheet({
    required this.deckId,
    required this.deckTitle,
    required this.initial,
  });

  @override
  State<_VisibilitySheet> createState() => _VisibilitySheetState();
}

class _VisibilitySheetState extends State<_VisibilitySheet> {
  late DeckVisibility _selected = widget.initial;
  bool _rightsAck = false;
  bool _saving = false;

  bool get _needsAck => _selected != DeckVisibility.private;
  bool get _canSave => (!_needsAck || _rightsAck) && !_saving;

  /// Publica el mazo en el catálogo comunitario del backend. Sin esto, el
  /// flag local de visibilidad no haría visible el mazo a nadie.
  Future<void> _publishToCommunity(AppStore store) async {
    final deck = store.decks.firstWhere(
      (d) => d.id == widget.deckId,
      orElse: () => throw StateError('Mazo no encontrado.'),
    );
    if (deck.cards.isEmpty) {
      throw StateError('El mazo no tiene tarjetas; agrega al menos una antes de publicarlo.');
    }
    final payload = jsonEncode({
      'title': deck.title,
      'icon': deck.icon,
      'cards': [
        for (final card in deck.cards)
          {
            'id': card.id,
            'front': card.front,
            'back': card.back,
            'source': card.source,
            'icon': card.icon,
          },
      ],
    });
    await store.api.shareDeck(
      deckId: deck.id,
      title: deck.title.trim(),
      summary: '${deck.cards.length} tarjetas',
      payloadJson: payload,
      isPublic: true,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final store = AppScope.of(context);

    if (_selected == DeckVisibility.public && !store.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para publicar en la comunidad.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_selected == DeckVisibility.public) {
        await _publishToCommunity(store);
      }
      if (!mounted) return;
      final ok = store.setDeckVisibility(
        widget.deckId,
        visibility: _selected,
        rightsAcknowledged: _rightsAck || _selected == DeckVisibility.private,
      );
      if (!ok) return;
      Navigator.of(context).pop();
      final label = switch (_selected) {
        DeckVisibility.private => 'Mazo ahora privado',
        DeckVisibility.friends => 'Mazo compartido con tus amigos',
        DeckVisibility.public => 'Mazo publicado en la comunidad 🌍',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + viewInsets.bottom),
      child: Glass(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Visibilidad de "${widget.deckTitle}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _VisRow(
              icon: Icons.lock_outline_rounded,
              title: 'Privado',
              subtitle: 'Solo tú lo ves. Default.',
              selected: _selected == DeckVisibility.private,
              onTap: () => setState(() {
                _selected = DeckVisibility.private;
                _rightsAck = false;
              }),
            ),
            _VisRow(
              icon: Icons.people_outline_rounded,
              title: 'Amigos',
              subtitle: 'Visible para los amigos que conectes a tu cuenta.',
              selected: _selected == DeckVisibility.friends,
              onTap: () => setState(() => _selected = DeckVisibility.friends),
            ),
            _VisRow(
              icon: Icons.public_rounded,
              title: 'Comunidad',
              subtitle:
                  'Cualquiera puede encontrarlo y copiarlo a su cuenta.',
              selected: _selected == DeckVisibility.public,
              onTap: () => setState(() => _selected = DeckVisibility.public),
            ),
            if (_needsAck) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RefColors.urgent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: RefColors.urgent.withValues(alpha: .55),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _rightsAck = !_rightsAck),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _rightsAck
                                  ? RefColors.lime
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                width: 1.6,
                                color: _rightsAck
                                    ? RefColors.lime
                                    : RefColors.muted,
                              ),
                            ),
                            child: _rightsAck
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: RefColors.successInk,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tengo derechos para compartir este contenido',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No puedes compartir versiones modernas de la Biblia bajo copyright (RV1960, NBLA, NVI, etc.) a través de mazos públicos. Para esas versiones, usa el modo de versión vía API.',
                      style: TextStyle(
                        color: RefColors.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.legalCommunity,
                      ),
                      child: const Text(
                        'Ver normas de comunidad →',
                        style: TextStyle(
                          color: RefColors.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          decorationColor: RefColors.cyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    'Cancelar',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Cta(
                    _saving ? 'Publicando…' : 'Guardar',
                    onTap: _canSave ? _save : null,
                    disabled: !_canSave,
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

class _VisRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _VisRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: selected
              ? RefColors.pink.withValues(alpha: .18)
              : HtmlRefColors.glassSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? RefColors.pink.withValues(alpha: .6)
                : HtmlRefColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? RefColors.pink : RefColors.muted,
            ),
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
                    subtitle,
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
      ),
    );
  }
}
