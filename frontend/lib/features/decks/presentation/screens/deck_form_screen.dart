import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:memorizar/core/db/app_database.dart';
import 'package:memorizar/core/db/database_provider.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/deck.dart' as model;

class DeckFormScreen extends ConsumerStatefulWidget {
  const DeckFormScreen({super.key, this.deck, this.deckId});
  final model.Deck? deck;
  final String? deckId;

  @override
  ConsumerState<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends ConsumerState<DeckFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _emojiController;

  model.DeckType _selectedType = model.DeckType.general;
  int _accentIndex = 0;
  bool _saving = false;

  bool get _isEditing => widget.deck != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _emojiController = TextEditingController();

    if (widget.deck != null) {
      _nameController.text = widget.deck!.name;
      _descController.text = widget.deck!.description;
      _emojiController.text = widget.deck!.emoji ?? '';
      _selectedType = widget.deck!.type;
      _accentIndex = widget.deck!.accentColorIndex;
    } else if (widget.deckId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeck());
    }
  }

  Future<void> _loadDeck() async {
    final db = ref.read(databaseProvider);
    final dbDecks = await db.getAllDecks();
    final dbDeck = dbDecks.where((d) => d.id == widget.deckId).firstOrNull;
    if (dbDeck == null || !mounted) return;

    final typeStr = dbDeck.type;
    setState(() {
      _nameController.text = dbDeck.name;
      _descController.text = dbDeck.description;
      _emojiController.text = dbDeck.emoji ?? '';
      _selectedType = typeStr == 'bible'
          ? model.DeckType.bible
          : typeStr == 'language'
              ? model.DeckType.language
              : model.DeckType.general;
      _accentIndex = dbDeck.accentColorIndex;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emojiController.dispose();
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
        title: Text(_isEditing ? 'Editar deck' : 'Nuevo deck'),
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
              // Emoji picker
              Center(
                child: GestureDetector(
                  onTap: _pickEmoji,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.deckAccents[_accentIndex].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.deckAccents[_accentIndex].withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _emojiController.text.isEmpty
                            ? '📚'
                            : _emojiController.text,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Toca para cambiar emoji',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(height: 24),

              _FieldLabel(label: 'Nombre del deck'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: _inputDecoration(cs, 'Ej: Vocabulario japonés'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              _FieldLabel(label: 'Descripción'),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: _inputDecoration(cs, '¿Qué contiene este deck?'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              _FieldLabel(label: 'Tipo'),
              const SizedBox(height: 8),
              Row(
                children: model.DeckType.values.map((t) {
                  final selected = t == _selectedType;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedType = t),
                      selectedColor: AppColors.indigo.withValues(alpha: 0.2),
                      labelStyle: GoogleFonts.dmSans(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? AppColors.indigo : cs.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _FieldLabel(label: 'Color'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: List.generate(AppColors.deckAccents.length, (i) {
                  final selected = i == _accentIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _accentIndex = i),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.deckAccents[i],
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: cs.onSurface, width: 3)
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }),
              ),
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

  void _pickEmoji() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Emoji', style: Theme.of(context).textTheme.titleSmall),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 8,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                mainAxisSpacing: 4,
                children: '📚 ✝️ 🌍 🇺🇸 🇯🇵 🇧🇷 🇨🇦 🇦🇷 🇲🇽 🇳🇿 🇫🇷 🇮🇳 🇦🇺 🇪🇸 🇵🇹 🇩🇪 🇮🇹 🇬🇧 🇰🇷 🇨🇳 🇷🇺 🇳🇱 🇧🇪 🇨🇭 🇵🇱 🇬🇷 🇹🇷 🇿🇦 🇮🇪 🇸🇦 🇪🇬'.split(' ').map((e) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _emojiController.text = e);
                      Navigator.pop(ctx);
                    },
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);
      final typeStr = _selectedType == model.DeckType.bible
          ? 'bible'
          : _selectedType == model.DeckType.language
              ? 'language'
              : 'general';
      final id = widget.deck?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      await db.upsertDeck(DecksCompanion.insert(
        id: id,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        type: typeStr,
        accentColorIndex: Value(_accentIndex),
        emoji: Value(_emojiController.text.isEmpty ? null : _emojiController.text),
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
