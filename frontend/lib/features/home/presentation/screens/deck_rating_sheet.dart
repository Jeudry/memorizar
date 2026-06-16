import 'package:flutter/material.dart';

import '../../../../core/app_state.dart';
import '../../../../core/theme/ref_colors.dart';

/// Resultado de valorar un mazo: nuevo promedio, conteo y las estrellas que
/// dejó el usuario.
class DeckRatingResult {
  final double avg;
  final int count;
  final int myStars;
  const DeckRatingResult(this.avg, this.count, this.myStars);
}

/// Fila compacta de estrellas para mostrar la valoración de un mazo en una
/// card. Resalta si el usuario ya valoró; invita a valorar si nadie lo hizo.
class RatingStarsRow extends StatelessWidget {
  final double avg;
  final int count;
  final int myRating;

  const RatingStarsRow({
    super.key,
    required this.avg,
    required this.count,
    required this.myRating,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star_border_rounded, size: 13, color: RefColors.muted),
          SizedBox(width: 3),
          Text(
            'Sé el primero en valorar',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    final rounded = avg.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rounded ? Icons.star_rounded : Icons.star_border_rounded,
            size: 13,
            color: RefColors.sun,
          ),
        const SizedBox(width: 5),
        Text(
          '${avg.toStringAsFixed(1)} · $count',
          style: const TextStyle(
            color: RefColors.sun,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (myRating > 0) ...[
          const SizedBox(width: 6),
          const Text(
            'Tu valoración ✓',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

/// Abre una hoja para valorar un mazo: estrellas tocables (1-5) + reseña
/// opcional. Devuelve el resultado, o null si se cancela / falla.
Future<DeckRatingResult?> showDeckRatingSheet(
  BuildContext context, {
  required String shareId,
  required String deckTitle,
  required int currentStars,
}) {
  return showModalBottomSheet<DeckRatingResult>(
    context: context,
    backgroundColor: const Color(0xFF1A1430),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _RatingSheet(
      shareId: shareId,
      deckTitle: deckTitle,
      currentStars: currentStars,
    ),
  );
}

class _RatingSheet extends StatefulWidget {
  final String shareId;
  final String deckTitle;
  final int currentStars;

  const _RatingSheet({
    required this.shareId,
    required this.deckTitle,
    required this.currentStars,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  late int _stars = widget.currentStars;
  final _reviewCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars < 1 || _busy) return;
    setState(() => _busy = true);
    final store = AppScope.of(context);
    try {
      final res = await store.api.rateDeck(
        widget.shareId,
        _stars,
        review: _reviewCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        DeckRatingResult(
          ((res['ratingAvg'] as num?) ?? 0).toDouble(),
          (res['ratingCount'] as int?) ?? 0,
          _stars,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo valorar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Valorar "${widget.deckTitle}"',
            style: const TextStyle(
              color: RefColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _stars = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i <= _stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 40,
                      color: i <= _stars ? RefColors.sun : RefColors.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewCtrl,
            maxLines: 3,
            maxLength: 280,
            style: const TextStyle(color: RefColors.ink, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Escribe una reseña (opcional)…',
              hintStyle: const TextStyle(color: RefColors.dim, fontSize: 12),
              filled: true,
              fillColor: const Color(0x22FFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _stars >= 1 && !_busy ? _submit : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: _stars >= 1 ? RefColors.primary : null,
                color: _stars >= 1 ? null : RefColors.glassSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _stars >= 1
                            ? 'Guardar valoración'
                            : 'Toca una estrella',
                        style: TextStyle(
                          color: _stars >= 1 ? Colors.white : RefColors.muted,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
