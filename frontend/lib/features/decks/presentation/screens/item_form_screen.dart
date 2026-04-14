import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorizar/core/theme/app_colors.dart';
import 'package:memorizar/features/decks/data/models/item.dart' as model;
import 'package:memorizar/features/decks/data/providers/item_form_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.item?.front ?? '');
    _backController = TextEditingController(text: widget.item?.back ?? '');
    _bookController = TextEditingController(text: widget.item?.book ?? '');
    _chapterController = TextEditingController(text: widget.item?.chapter?.toString() ?? '');
    _verseController = TextEditingController(text: widget.item?.verse?.toString() ?? '');
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

  Future<void> _save() async {
    final key = (widget.deckId, widget.item);
    final notifier = ref.read(itemFormProvider(key).notifier);
    final success = await notifier.save();
    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (widget.deckId, widget.item);
    final formState = ref.watch(itemFormProvider(key));
    final notifier = ref.read(itemFormProvider(key).notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.item != null ? 'Editar tarjeta' : 'Nueva tarjeta'),
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
            // Front
            Text('Frente', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _frontController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Pregunta o término',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: notifier.setFront,
            ),
            const SizedBox(height: 20),

            // Back
            Text('Respuesta', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _backController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Respuesta o definición',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: notifier.setBack,
            ),
            const SizedBox(height: 20),

            // Bible metadata toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('📖  Metadatos bíblicos', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Switch(
                        value: formState.hasBibleMeta,
                        onChanged: notifier.setHasBibleMeta,
                        activeThumbColor: AppColors.deckAccents[0],
                      ),
                    ],
                  ),
                  if (formState.hasBibleMeta) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _bookController,
                            decoration: InputDecoration(
                              labelText: 'Libro',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: notifier.setBook,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _chapterController,
                            decoration: InputDecoration(
                              labelText: 'Cap',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: notifier.setChapter,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _verseController,
                            decoration: InputDecoration(
                              labelText: 'Verso',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: notifier.setVerse,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}