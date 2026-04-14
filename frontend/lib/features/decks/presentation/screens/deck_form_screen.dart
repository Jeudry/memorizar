import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/deck.dart';
import 'package:memorizar/features/decks/data/providers/form_providers.dart';

class DeckFormScreen extends ConsumerStatefulWidget {
  const DeckFormScreen({super.key, this.deck});
  final Deck? deck;

  @override
  ConsumerState<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends ConsumerState<DeckFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _emojiController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck?.name ?? '');
    _descController = TextEditingController(text: widget.deck?.description ?? '');
    _emojiController = TextEditingController(text: widget.deck?.emoji ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(deckFormProvider(widget.deck).notifier);
    final success = await notifier.save();
    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(deckFormProvider(widget.deck));
    final notifier = ref.read(deckFormProvider(widget.deck).notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.deck != null ? 'Editar deck' : 'Nuevo deck'),
        actions: [
          TextButton(
            onPressed: formState.isValid && !formState.isSaving ? _save : null,
            child: formState.isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Guardar', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview card
            _DeckPreview(
              name: _nameController.text.isEmpty ? 'Nombre del deck' : _nameController.text,
              emoji: _emojiController.text.isEmpty ? '📚' : _emojiController.text,
              accent: AppColors.deckAccents[formState.accentColorIndex],
            ),
            const SizedBox(height: 24),

            // Emoji
            Text('Emoji', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: TextField(
                    controller: _emojiController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: notifier.setEmoji,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Escribe un emoji o déjala en blanco',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name
            Text('Nombre', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Ej: Vocabulario japonés',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: notifier.setName,
            ),
            const SizedBox(height: 20),

            // Description
            Text('Descripción', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: '¿Qué contiene este deck?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: notifier.setDescription,
            ),
            const SizedBox(height: 20),

            // Type
            Text('Tipo', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: DeckType.values.map((t) {
                final isSelected = t == formState.type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: t != DeckType.values.last ? 8 : 0),
                    child: InkWell(
                      onTap: () => notifier.setType(t),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.deckAccents[formState.accentColorIndex].withValues(alpha: 0.15)
                              : cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.deckAccents[formState.accentColorIndex]
                                : cs.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          t.label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.deckAccents[formState.accentColorIndex]
                                : cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Accent color
            Text('Color', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(AppColors.deckAccents.length, (i) {
                final isSelected = i == formState.accentColorIndex;
                return InkWell(
                  onTap: () => notifier.setAccent(i),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.deckAccents[i],
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.surface, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.deckAccents[i].withValues(alpha: 0.5), blurRadius: 8)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckPreview extends StatelessWidget {
  const _DeckPreview({required this.name, required this.emoji, required this.accent});
  final String name;
  final String emoji;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '0 tarjetas',
                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}