import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:memorizar/core/db/app_database.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/data/models/item.dart' as model;
import 'package:memorizar/features/decks/presentation/providers/decks_provider.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, required this.deckId, this.item});
  final String deckId;
  final model.Item? item;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  late final TextEditingController _bookController;
  late final TextEditingController _chapterController;
  late final TextEditingController _verseController;

  bool _isBibleDeck = false;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.item?.front ?? '');
    _backController = TextEditingController(text: widget.item?.back ?? '');
    _bookController = TextEditingController(text: widget.item?.book ?? '');
    _chapterController = TextEditingController(text: widget.item?.chapter?.toString() ?? '');
    _verseController = TextEditingController(text: widget.item?.verse?.toString() ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deck = ref.read(deckByIdProvider(widget.deckId)).valueOrNull;
      if (deck != null) {
        setState(() => _isBibleDeck = deck.type == DeckType.bible);
      }
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
        title: Text(_isEditing ? 'Editar tarjeta' : 'Nueva tarjeta'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Guardar', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
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
                decoration: _inputDecoration(cs, 'Pregunta o término'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              _FieldLabel(label: 'Respuesta'),
              const SizedBox(height: 8),
              TextField(
                controller: _backController,
                maxLines: 4,
                decoration: _inputDecoration(cs, 'Respuesta o definición'),
                textCapitalization: TextCapitalization.sentences,
              ),
              if (_isBibleDeck || _bookController.text.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Referencia bíblica', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _bookController,
                        decoration: _inputDecoration(cs, 'Libro'),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _chapterController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(cs, 'Cap.'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _verseController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(cs, 'Vers.'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme cs, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.indigo, width: 1.5),
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

    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);
      final id = widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final chapter = int.tryParse(_chapterController.text);
      final verse = int.tryParse(_verseController.text);

      await db.upsertItem(ItemsCompanion.insert(
        id: id,
        deckId: widget.deckId,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        book: _bookController.text.trim().isEmpty ? const Value.absent() : Value(_bookController.text.trim()),
        chapter: chapter != null ? Value(chapter) : const Value.absent(),
        verse: verse != null ? Value(verse) : const Value.absent(),
      ));

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleSmall);
  }
}
