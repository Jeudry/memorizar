import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/db/app_database.dart' hide Item;
import 'package:memorizar/features/decks/data/models/item.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';

class ItemEditScreen extends ConsumerStatefulWidget {
  const ItemEditScreen({super.key, required this.deckId, required this.itemId});
  final String deckId;
  final String itemId;

  @override
  ConsumerState<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends ConsumerState<ItemEditScreen> {
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  late final TextEditingController _bookController;
  late final TextEditingController _chapterController;
  late final TextEditingController _verseController;

  bool _isBibleDeck = false;
  Item? _item;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController();
    _backController = TextEditingController();
    _bookController = TextEditingController();
    _chapterController = TextEditingController();
    _verseController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItem();
    });
  }

  void _loadItem() {
    final itemsAsync = ref.read(itemsForDeckProvider(widget.deckId));
    final deckAsync = ref.read(deckByIdProvider(widget.deckId));
    final items = itemsAsync.valueOrNull ?? [];
    final deck = deckAsync.valueOrNull;

    Item item;
    try {
      item = items.firstWhere((i) => i.id == widget.itemId);
    } catch (_) {
      return;
    }

    setState(() {
      _item = item;
      _frontController.text = item.front;
      _backController.text = item.back;
      _bookController.text = item.book ?? '';
      _chapterController.text = item.chapter?.toString() ?? '';
      _verseController.text = item.verse?.toString() ?? '';
      _isBibleDeck = deck?.type == DeckType.bible;
    });
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _bookController.dispose();
    _chapterController.dispose();
    _verseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Editar tarjeta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmDelete,
          ),
          TextButton(
            onPressed: _save,
            child: Text(
              'Guardar',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(label: 'Frente'),
              const SizedBox(height: 8),
              TextField(
                controller: _frontController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Pregunta o término',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                  enabledBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                  focusedBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              _FieldLabel(label: 'Respuesta'),
              const SizedBox(height: 8),
              TextField(
                controller: _backController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Respuesta o definición',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                  enabledBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                  focusedBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                ),
              ),
              if (_isBibleDeck) ...[
                const SizedBox(height: 20),
                Text(
                  'Referencia bíblica',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _bookController,
                        decoration: InputDecoration(
                          labelText: 'Libro',
                          hintText: 'Génesis',
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          border: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                          enabledBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                          focusedBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _chapterController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cap.',
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          border: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                          enabledBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                          focusedBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _verseController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Vers.',
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          border: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                          enabledBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                          focusedBorder: OutlineInputPart.borderRadius(BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              _SrsInfo(item: _item!),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_frontController.text.trim().isEmpty || _backController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Frente y respuesta son obligatorios')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final chapter = int.tryParse(_chapterController.text);
    final verse = int.tryParse(_verseController.text);

    await db.upsertItem(ItemsCompanion(
      id: Value(widget.itemId),
      deckId: Value(widget.deckId),
      front: Value(_frontController.text.trim()),
      back: Value(_backController.text.trim()),
      book: _bookController.text.trim().isEmpty ? const Value.absent() : Value(_bookController.text.trim()),
      chapter: chapter != null ? Value(chapter) : const Value.absent(),
      verse: verse != null ? Value(verse) : const Value.absent(),
    ));

    if (mounted) context.pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar tarjeta?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.deleteItem(widget.itemId);
      if (mounted) context.pop();
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _SrsInfo extends StatelessWidget {
  const _SrsInfo({required this.item});
  final Item item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información SRS', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _SrsChip(label: 'Ease', value: item.easeFactor.toStringAsFixed(2)),
              const SizedBox(width: 8),
              _SrsChip(label: 'Intervalo', value: '${item.interval}d'),
              const SizedBox(width: 8),
              _SrsChip(label: 'Reps', value: '${item.repetitions}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.isDue
                ? 'Vence: ahora'
                : 'Próximo repaso: ${_formatDate(item.nextReviewAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _SrsChip extends StatelessWidget {
  const _SrsChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.indigo),
      ),
    );
  }
}

class OutlineInputPart {
  static InputBorder borderRadius(BorderRadius radius) {
    return OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );
  }
}
