// Generado del refactor de ui_screens.dart.
// EspecificarScreen + helpers (step indicator, page head, tool chip, edit card).
part of '../ui_screens.dart';

class EspecificarScreen extends StatefulWidget {
  final bool embedded;
  final void Function(String deckId, String title)? onDeckCreated;
  final VoidCallback? onCancel;

  const EspecificarScreen({
    super.key,
    this.embedded = false,
    this.onDeckCreated,
    this.onCancel,
  });

  @override
  State<EspecificarScreen> createState() => _EspecificarScreenState();
}

class _EspecificarScreenState extends State<EspecificarScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  List<MemoryCardData> _segmentedCards = const [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    final text = _contentController.text.trim();
    if (_titleController.text.trim().isEmpty) {
      final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) {
        final firstLine = lines.first;
        final bibleRefRegExp = RegExp(
          r'^((?:[1-3]\s*)?[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:\s+[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*\s+\d+:\d+(?:-\d+)?)(?:\s+[A-Za-z0-9]+)?$'
        );
        if (bibleRefRegExp.hasMatch(firstLine)) {
          _titleController.text = firstLine;
        }
      }
    }
    setState(() {
      _segmentedCards = AppScope.of(
        context,
      ).segmentContent(_contentController.text, title: _titleController.text);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El portapapeles está vacío.')),
      );
      return;
    }
    
    // Auto-extract title if title is empty
    String? extractedTitle;
    if (_titleController.text.trim().isEmpty) {
      final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) {
        final firstLine = lines.first;
        final bibleRefRegExp = RegExp(
          r'^((?:[1-3]\s*)?[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:\s+[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*\s+\d+:\d+(?:-\d+)?)(?:\s+[A-Za-z0-9]+)?$'
        );
        if (bibleRefRegExp.hasMatch(firstLine)) {
          extractedTitle = firstLine;
        }
      }
    }

    setState(() {
      if (extractedTitle != null) {
        _titleController.text = extractedTitle;
      }
      _contentController.text = text; // Raw content remains as pasted
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
      _segmentedCards = AppScope.of(
        context,
      ).segmentContent(text, title: _titleController.text);
    });
  }

  void _createDeck() {
    if (_submitting) return;
    final cards = _segmentedCards.isEmpty
        ? AppScope.of(context).segmentContent(
            _contentController.text,
            title: _titleController.text,
          )
        : _segmentedCards;
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pega o escribe contenido antes de continuar.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final created = AppScope.of(context).createDeckFromCards(
      title: _titleController.text,
      icon: '🧠',
      cards: cards,
    );
    if (created == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pega o escribe contenido antes de continuar.'),
        ),
      );
      return;
    }
    if (widget.embedded && widget.onDeckCreated != null) {
      widget.onDeckCreated!(created.id, created.title);
    } else {
      Navigator.pushNamed(context, AppRoutes.iniciar);
    }
  }

  void _clearAll() {
    setState(() {
      _titleController.clear();
      _contentController.clear();
      _segmentedCards = const [];
    });
  }

  /// Importa un archivo CSV/TSV de dos columnas (frente, dorso) y precarga
  /// las tarjetas en el editor para revisarlas antes de crear el mazo.
  Future<void> _importCsvFile() async {
    if (_submitting) return;
    const typeGroup = XTypeGroup(
      label: 'CSV / TSV',
      extensions: ['csv', 'tsv', 'txt'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null || !mounted) return;
    try {
      final content = await file.readAsString();
      final result = parseCsvCards(content);
      if (!mounted) return;
      if (result.cards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No encontré filas válidas: el archivo debe tener dos columnas (frente y dorso).',
            ),
          ),
        );
        return;
      }
      final baseName = file.name.replaceAll(RegExp(r'\.(csv|tsv|txt)$'), '');
      setState(() {
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = baseName;
        }
        _segmentedCards = [
          for (var i = 0; i < result.cards.length; i++)
            MemoryCardData(
              id: 'csv-${DateTime.now().microsecondsSinceEpoch}-$i',
              front: result.cards[i].front,
              back: result.cards[i].back,
              source: file.name,
              icon: '📂',
            ),
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.cards.length} tarjetas importadas'
            '${result.skippedRows > 0 ? ' · ${result.skippedRows} filas saltadas' : ''}. Revísalas y crea el mazo.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo leer el archivo: $e')),
      );
    }
  }

  void _updateSegmentedCard(int index, {String? front, String? back}) {
    if (index < 0 || index >= _segmentedCards.length) return;
    final cards = [..._segmentedCards];
    cards[index] = cards[index].copyWith(front: front, back: back);
    setState(() => _segmentedCards = cards);
  }

  void _deleteSegmentedCard(int index) {
    if (index < 0 || index >= _segmentedCards.length) return;
    final cards = [..._segmentedCards]..removeAt(index);
    setState(() => _segmentedCards = cards);
  }

  @override
  Widget build(BuildContext context) {
    final cards = _segmentedCards;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded) ...[
          const RefTopBar(title: 'Nuevo contenido'),
          const _StepIndicator(active: 0, count: 3),
          const _PageHead(
            'Pega lo que quieres memorizar',
            'La app lo segmenta en tarjetas automáticamente · puedes editarlas después',
          ),
        ],
          Glass(
            color: Colors.transparent,
            gradient: const LinearGradient(
              colors: [Color(0x1AFFFFFF), Color(0x3DFFB400)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: HtmlRefColors.glassStrong,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: HtmlRefColors.glassBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(child: GlyphIcon('🧠', size: 26)),
                      Positioned(
                        right: -5,
                        bottom: -5,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: RefColors.pink,
                            shape: BoxShape.circle,
                            border: Border.all(color: RefColors.bg, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: RefColors.ink,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOMBRE DEL MAZO',
                        style: TextStyle(
                          fontSize: 10,
                          color: RefColors.muted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      _InputLike(controller: _titleController),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Glass(
            color: Colors.transparent,
            gradient: const LinearGradient(
              colors: [Color(0x1AFFFFFF), Color(0x24FFB400)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'CONTENIDO',
                        style: TextStyle(
                          color: RefColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      '✨ ${cards.length} líneas detectadas',
                      style: TextStyle(
                        color: RefColors.lime,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: HtmlRefColors.glassSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: HtmlRefColors.glassBorder,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    onChanged: (_) => _refreshPreview(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: RefColors.ink,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pega aquí lo que quieres memorizar...',
                      hintStyle: TextStyle(color: RefColors.dim),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pasteFromClipboard,
                        child: const _ToolChip('📋 Pegar'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: _clearAll,
                        child: const _ToolChip('🧹 Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: _importCsvFile,
                        child: const _ToolChip('📂 Importar CSV'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Glass(
            color: const Color(0xCC2B1852),
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Vista previa',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '✨ ${cards.length} tarjetas',
                      style: TextStyle(
                        fontSize: 11,
                        color: RefColors.lime,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '💡  Agrupa versículos partidos por línea · edita si hace falta',
                  style: TextStyle(fontSize: 11, color: RefColors.muted),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 240,
                  child: cards.isEmpty
                      ? const Center(
                          child: Text(
                            'Todavía no hay tarjetas. Pega contenido real para ver la segmentación.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: RefColors.muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              for (var i = 0; i < cards.length; i++)
                                _EditCard(
                                  key: ValueKey(cards[i].id),
                                  (i + 1).toString().padLeft(2, '0'),
                                  cards[i].front,
                                  cards[i].back,
                                  onFrontChanged: (value) =>
                                      _updateSegmentedCard(i, front: value),
                                  onBackChanged: (value) =>
                                      _updateSegmentedCard(i, back: value),
                                  onDelete: () => _deleteSegmentedCard(i),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: GhostButton('Ajustes avanzados')),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: Cta('Siguiente →', onTap: _createDeck)),
            ],
          ),
        ],
      );

    if (widget.embedded) {
      return content;
    }
    return ReferencePage(
      active: AppRoutes.home,
      child: content,
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int active;
  final int count;

  const _StepIndicator({required this.active, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  gradient: i == active ? RefColors.primary : null,
                  color: i == active ? null : HtmlRefColors.glassSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputLike extends StatelessWidget {
  final TextEditingController controller;

  const _InputLike({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HtmlRefColors.glassBorder, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _PageHead extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PageHead(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: RefColors.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  final String text;
  final bool primary;

  const _ToolChip(this.text, {this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: primary ? RefColors.primary : null,
        color: primary ? null : HtmlRefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: primary ? Colors.transparent : HtmlRefColors.glassBorder,
        ),
        boxShadow: primary
            ? [
                BoxShadow(
                  color: RefColors.pink.withValues(alpha: .3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  final String n;
  final String title;
  final String answer;
  final ValueChanged<String> onFrontChanged;
  final ValueChanged<String> onBackChanged;
  final VoidCallback onDelete;

  const _EditCard(
    this.n,
    this.title,
    this.answer, {
    super.key,
    required this.onFrontChanged,
    required this.onBackChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  n,
                  style: const TextStyle(
                    fontSize: 10,
                    color: RefColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: HtmlRefColors.glassStrong,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HtmlRefColors.glassBorder),
                  ),
                  child: TextFormField(
                    initialValue: title,
                    onChanged: onFrontChanged,
                    minLines: 1,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: RefColors.ink,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: HtmlRefColors.glassStrong,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: HtmlRefColors.glassBorder),
                  ),
                  child: const Center(
                    child: Text(
                      '×',
                      style: TextStyle(color: RefColors.muted, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HtmlRefColors.glassStrong,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HtmlRefColors.glassBorder),
            ),
            child: TextFormField(
              initialValue: answer,
              onChanged: onBackChanged,
              minLines: 2,
              maxLines: 5,
              style: const TextStyle(
                fontSize: 11,
                color: RefColors.muted,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

