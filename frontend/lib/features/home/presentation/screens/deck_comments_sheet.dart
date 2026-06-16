import 'package:flutter/material.dart';

import '../../../../core/app_state.dart';
import '../../../../core/theme/ref_colors.dart';

/// Abre una hoja con el hilo de comentarios de un mazo comunitario: lista los
/// existentes (autor + texto) y permite agregar uno. Reporta el nuevo conteo
/// de comentarios vía [onCountChanged] (al cargar y al comentar).
Future<void> showDeckCommentsSheet(
  BuildContext context, {
  required String shareId,
  required String deckTitle,
  required int initialCount,
  required void Function(int count) onCountChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A1430),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CommentsSheet(
      shareId: shareId,
      deckTitle: deckTitle,
      initialCount: initialCount,
      onCountChanged: onCountChanged,
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  final String shareId;
  final String deckTitle;
  final int initialCount;
  final void Function(int count) onCountChanged;

  const _CommentsSheet({
    required this.shareId,
    required this.deckTitle,
    required this.initialCount,
    required this.onCountChanged,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>>? _comments;
  bool _loading = true;
  bool _sending = false;
  late int _count = widget.initialCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = AppScope.of(context);
    try {
      final list = await store.api.listDeckComments(widget.shareId);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _count = list.length;
        _loading = false;
      });
      widget.onCountChanged(_count);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final store = AppScope.of(context);
    try {
      final created = await store.api.addDeckComment(widget.shareId, body);
      if (!mounted) return;
      setState(() {
        _comments = [created, ...?_comments];
        _count = (_comments ?? const []).length;
        _ctrl.clear();
        _sending = false;
      });
      widget.onCountChanged(_count);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo comentar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = _comments ?? const [];
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Comentarios · "${widget.deckTitle}"',
            style: const TextStyle(
              color: RefColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : comments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Sé el primero en comentar este mazo.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: RefColors.muted, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: comments.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) => _CommentRow(comments[i]),
                      ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 280,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      null,
                  style: const TextStyle(color: RefColors.ink, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario…',
                    hintStyle:
                        const TextStyle(color: RefColors.dim, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0x22FFFFFF),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : _send,
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: RefColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final Map<String, dynamic> comment;
  const _CommentRow(this.comment);

  @override
  Widget build(BuildContext context) {
    final author = (comment['authorName'] as String?)?.trim();
    final username = (comment['authorUsername'] as String?) ?? '';
    final name = (author != null && author.isNotEmpty)
        ? author
        : (username.isNotEmpty ? '@$username' : 'Anónimo');
    final body = (comment['body'] as String?) ?? '';
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: RefColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: const TextStyle(
              color: RefColors.ink,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
