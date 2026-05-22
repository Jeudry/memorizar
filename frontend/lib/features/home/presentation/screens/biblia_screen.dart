// Generado del refactor de ui_screens.dart.
// BibliaScreen + pickers (book/chapter/verse), themes, version dropdown.
part of '../ui_screens.dart';

class BibliaScreen extends StatefulWidget {
  const BibliaScreen({super.key});

  @override
  State<BibliaScreen> createState() => _BibliaScreenState();
}

class _BibliaScreenState extends State<BibliaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _step = 'book';
  String _selectedBook = 'Salmos';
  int _selectedChapter = 23;

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setSearch(String value) {
    setState(() {
      _searchController.text = value;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });
  }

  void _clearSearch() {
    setState(_searchController.clear);
  }

  void _pickBook(String book) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = 1;
      _step = 'chap';
    });
  }

  void _pickChapter(int chapter) {
    setState(() {
      _selectedChapter = chapter;
      _step = 'verse';
    });
  }

  void _toggleVerse(int verse) {
    final item = AppScope.of(context)
        .versesFor(_selectedBook, _selectedChapter)
        .firstWhere((item) => item.verse == verse);
    AppScope.of(context).toggleBibleVerse(item);
    setState(() {});
  }

  void _selectAllInChapter() {
    AppScope.of(context)
        .addAllVersesInChapter(_selectedBook, _selectedChapter);
    setState(() {});
  }

  void _selectAllInBook() {
    AppScope.of(context).addAllVersesInBook(_selectedBook);
    setState(() {});
  }

  void _selectAllInBible() {
    AppScope.of(context).addAllVersesInBible();
    setState(() {});
  }

  Set<String> _fullBooks(AppStore store) {
    final selectedBookNames =
        store.selectedBibleVerses.map((v) => v.book).toSet();
    return selectedBookNames
        .where((b) => store.isWholeBookSelected(b))
        .toSet();
  }

  Set<String> _partialBooks(AppStore store) {
    final selectedBookNames =
        store.selectedBibleVerses.map((v) => v.book).toSet();
    return selectedBookNames
        .where((b) => !store.isWholeBookSelected(b))
        .toSet();
  }

  void _finishBibleSelection() {
    final created = AppScope.of(context).createBibleDeckFromSelection();
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un versículo.')),
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.iniciar);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final selectedForChapter = store.selectedBibleVerses
        .where(
          (verse) =>
              verse.book == _selectedBook && verse.chapter == _selectedChapter,
        )
        .map((verse) => verse.verse)
        .toSet();
    final confirmingSelection = _step == 'continue';
    return ReferencePage(
      active: AppRoutes.repasar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Elegir de la Biblia'),
          if (!confirmingSelection) ...[
            Glass(
              radius: 18,
              color: HtmlRefColors.glassBg,
              border: Border.all(color: HtmlRefColors.glassBorder),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: RefColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: RefColors.ink,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Ej: Juan 3:16, Salmos 23, Rom 8:28-30',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: RefColors.dim,
                        ),
                      ),
                    ),
                  ),
                  if (_isSearching)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: HtmlRefColors.glassStrong,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            '×',
                            style: TextStyle(
                              color: RefColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_isSearching)
            _BibleSearchResults(
              query: _searchController.text,
              onClear: _clearSearch,
              onFill: _setSearch,
              onAddVerse: (verse) {
                store.addBibleVerse(verse);
                setState(() {});
              },
            )
          else
            _BibleBrowseStep(
              step: _step,
              selectedBook: _selectedBook,
              selectedChapter: _selectedChapter,
              selectedVerses: selectedForChapter,
              onStep: (step) => setState(() => _step = step),
              onBook: _pickBook,
              onChapter: _pickChapter,
              onVerse: _toggleVerse,
              // "Confirmar versículos →" desde la lista de versículos NO
              // debe crear el mazo todavía — debe llevar al paso 'continue'
              // donde se ve el listado completo y se decide seguir agregando
              // o terminar. _finishBibleSelection se queda para el botón
              // "Terminar selección" del paso 'continue'.
              onConfirmVerses: () => setState(() => _step = 'continue'),
              onFinish: _finishBibleSelection,
              onSelectAllChapter: _selectAllInChapter,
              onSelectAllBook: _selectAllInBook,
              onSelectAllBible: _selectAllInBible,
              fullBooks: _fullBooks(store),
              partialBooks: _partialBooks(store),
            ),
          const SizedBox(height: 14),
          Glass(
            color: HtmlRefColors.glassBg,
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SELECCIONADOS · ${store.selectedBibleVerses.length}',
                        style: TextStyle(
                          color: RefColors.dim,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: store.clearBibleSelection,
                      child: const Text(
                        'VACIAR',
                        style: TextStyle(
                          color: RefColors.muted,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (store.selectedBibleVerses.isEmpty)
                  const Text(
                    'Toca versículos para agregarlos a tu mazo.',
                    style: TextStyle(color: RefColors.muted, fontSize: 12),
                  )
                else
                  ...() {
                    final entries = _summarizeSelection(
                      store.selectedBibleVerses,
                      store,
                    );
                    // En la pantalla de confirmar selección mostramos TODO
                    // el listado para que el usuario pueda revisar antes de
                    // avanzar. En la pantalla de browse normal mantenemos el
                    // resumen truncado a 8 para no comer espacio del flujo.
                    final visible = confirmingSelection
                        ? entries
                        : entries.take(8).toList();
                    final hidden = entries.length - visible.length;
                    return [
                      for (final e in visible)
                        _SelectedVerseRef(
                          e.title,
                          e.subtitle,
                          onRemove: () {
                            store.removeBibleVerses(e.verses);
                            setState(() {});
                          },
                        ),
                      if (hidden > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '+ $hidden ${hidden == 1 ? "rango más" : "rangos más"}',
                            style: const TextStyle(
                              color: RefColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ];
                  }(),
              ],
            ),
          ),
          if (!confirmingSelection) ...[
            const SizedBox(height: 14),
            const _ThemesBrowse(),
          ],
          // El CTA global "Siguiente →" se removió: el flujo ya tiene sus
          // propios botones ("Confirmar versículos →" en la lista del
          // capítulo, "Finalizar" en la pantalla de revisión) y mostrar otro
          // CTA aquí abajo confundía.
        ],
      ),
    );
  }
}

class _BibleSearchResults extends StatelessWidget {
  final String query;
  final VoidCallback onClear;
  final ValueChanged<String> onFill;
  final ValueChanged<BibleVerseData> onAddVerse;

  const _BibleSearchResults({
    required this.query,
    required this.onClear,
    required this.onFill,
    required this.onAddVerse,
  });

  @override
  Widget build(BuildContext context) {
    final results = AppScope.of(context).searchBible(query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(6, 0, 6, 10),
          child: Text(
            'Puedes escribir libros enteros, capítulos, versículos o rangos',
            style: TextStyle(color: RefColors.muted, fontSize: 11),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickSearchChip('+ Salmos 23', () => onFill('Salmos 23')),
              const SizedBox(width: 6),
              _QuickSearchChip('+ Juan 3', () => onFill('Juan 3')),
              const SizedBox(width: 6),
              _QuickSearchChip('+ Rom 8:28-30', () => onFill('Rom 8:28-30')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Glass(
          color: HtmlRefColors.glassBg,
          border: Border.all(color: HtmlRefColors.glassBorder),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (results.isEmpty) ...[
                const Text(
                  'Sin resultados cargados para esa búsqueda',
                  style: TextStyle(
                    color: RefColors.pink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No encontré coincidencias en Reina Valera 1909. Prueba con una referencia como Salmos 23, Juan 3:16 o una palabra del texto.',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ] else
                for (final verse in results) ...[
                  Text(
                    '${verse.ref} · RV1909',
                    style: const TextStyle(
                      color: RefColors.pink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${verse.text}"',
                    style: const TextStyle(
                      color: RefColors.ink,
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Cta('+ Añadir ${verse.ref}', onTap: () => onAddVerse(verse)),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 4),
              GhostButton('Cerrar búsqueda', onTap: onClear),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickSearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickSearchChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: HtmlRefColors.glassSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: HtmlRefColors.glassBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _BibleBrowseStep extends StatelessWidget {
  final String step;
  final String selectedBook;
  final int selectedChapter;
  final Set<int> selectedVerses;
  final ValueChanged<String> onStep;
  final ValueChanged<String> onBook;
  final ValueChanged<int> onChapter;
  final ValueChanged<int> onVerse;
  final VoidCallback onConfirmVerses;
  final VoidCallback onFinish;
  final VoidCallback onSelectAllChapter;
  final VoidCallback onSelectAllBook;
  final VoidCallback onSelectAllBible;
  final Set<String> fullBooks;
  final Set<String> partialBooks;

  const _BibleBrowseStep({
    required this.step,
    required this.selectedBook,
    required this.selectedChapter,
    required this.selectedVerses,
    required this.onStep,
    required this.onBook,
    required this.onChapter,
    required this.onVerse,
    required this.onConfirmVerses,
    required this.onFinish,
    required this.onSelectAllChapter,
    required this.onSelectAllBook,
    required this.onSelectAllBible,
    required this.fullBooks,
    required this.partialBooks,
  });

  @override
  Widget build(BuildContext context) {
    if (step == 'chap') {
      return _ChapterPicker(
        selectedBook: selectedBook,
        onBack: () => onStep('book'),
        onChapter: onChapter,
        onSelectAllBook: onSelectAllBook,
      );
    }
    if (step == 'verse') {
      return _VersePicker(
        selectedBook: selectedBook,
        selectedChapter: selectedChapter,
        selectedVerses: selectedVerses,
        onBack: () => onStep('chap'),
        onVerse: onVerse,
        onConfirm: onConfirmVerses,
        onSelectAllChapter: onSelectAllChapter,
      );
    }
    if (step == 'continue') {
      return _ContinueSelectionCard(
        onBook: () => onStep('book'),
        onFinish: onFinish,
      );
    }
    return _BookPicker(
      onBook: onBook,
      onSelectAllBible: onSelectAllBible,
      fullBooks: fullBooks,
      partialBooks: partialBooks,
    );
  }
}

/// Traditional grouping used in most Spanish bibles. Order matters — categories
/// render in this order within their testament.
class _BibleCategory {
  final String label;
  final List<String> books;
  final Color accent;
  const _BibleCategory(this.label, this.books, this.accent);
}

// Category accents picked to NOT clash with the rosa/violeta background of
// the app and to stay distinct from the pink/violet selection state.
const _catTeal = Color(0xFF14B8A6);
const _catAmber = Color(0xFFFB923C);
const _catSkyBlue = Color(0xFF60A5FA);
const _catIndigo = Color(0xFF818CF8);

const _oldTestamentCategories = <_BibleCategory>[
  _BibleCategory(
    'Pentateuco',
    ['Gén', 'Éxo', 'Lev', 'Núm', 'Deut'],
    _catTeal,
  ),
  _BibleCategory(
    'Históricos',
    [
      'Jos', 'Jue', 'Rut', '1Sam', '2Sam', '1Re', '2Re',
      '1Cr', '2Cr', 'Esd', 'Neh', 'Est',
    ],
    RefColors.cyan,
  ),
  _BibleCategory(
    'Poéticos',
    ['Job', 'Salmos', 'Prov', 'Ecl', 'Cant'],
    RefColors.lime,
  ),
  _BibleCategory(
    'Profetas mayores',
    ['Isa', 'Jer', 'Lam', 'Eze', 'Dan'],
    RefColors.sun,
  ),
  _BibleCategory(
    'Profetas menores',
    [
      'Ose', 'Joel', 'Amós', 'Abd', 'Jon', 'Miq',
      'Nah', 'Hab', 'Sof', 'Hag', 'Zac', 'Mal',
    ],
    _catAmber,
  ),
];

const _newTestamentCategories = <_BibleCategory>[
  _BibleCategory(
    'Evangelios',
    ['Mat', 'Mar', 'Luc', 'Juan'],
    _catIndigo,
  ),
  _BibleCategory('Hechos', ['Hech'], RefColors.cyan),
  _BibleCategory(
    'Cartas paulinas',
    [
      'Rom', '1Cor', '2Cor', 'Gál', 'Ef', 'Fil', 'Col',
      '1Tes', '2Tes', '1Tim', '2Tim', 'Tit', 'Flm',
    ],
    _catTeal,
  ),
  _BibleCategory(
    'Cartas generales',
    ['Heb', 'Stg', '1Pe', '2Pe', '1Jn', '2Jn', '3Jn', 'Jud'],
    RefColors.lime,
  ),
  _BibleCategory('Apocalíptico', ['Apoc'], RefColors.urgent),
];

class _BookPicker extends StatefulWidget {
  final ValueChanged<String> onBook;
  final VoidCallback? onSelectAllBible;
  final Set<String> fullBooks;
  final Set<String> partialBooks;

  const _BookPicker({
    required this.onBook,
    this.onSelectAllBible,
    this.fullBooks = const {},
    this.partialBooks = const {},
  });

  @override
  State<_BookPicker> createState() => _BookPickerState();
}

class _BookPickerState extends State<_BookPicker> {
  bool _showNew = false;

  @override
  Widget build(BuildContext context) {
    final categories = _showNew ? _newTestamentCategories : _oldTestamentCategories;
    final chip = RefChip(
      'Toda la Biblia',
      dense: true,
      color: widget.onSelectAllBible != null
          ? RefColors.pink.withValues(alpha: .22)
          : HtmlRefColors.glassSoft,
      textColor: RefColors.ink,
    );
    return Glass(
      color: HtmlRefColors.glassBg,
      border: Border.all(color: HtmlRefColors.glassBorder),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _BibleVersionDropdown()),
              const SizedBox(width: 10),
              if (widget.onSelectAllBible != null)
                GestureDetector(onTap: widget.onSelectAllBible, child: chip)
              else
                chip,
            ],
          ),
          const SizedBox(height: 10),
          _TestamentTabs(
            showNew: _showNew,
            onChanged: (v) => setState(() => _showNew = v),
          ),
          const SizedBox(height: 10),
          _BookGrid(
            books: [for (final cat in categories) ...cat.books],
            bookAccents: {
              for (final cat in categories)
                for (final b in cat.books) b: cat.accent,
            },
            selected: widget.fullBooks,
            partial: widget.partialBooks,
            onBook: widget.onBook,
          ),
        ],
      ),
    );
  }
}

class _TestamentTabs extends StatelessWidget {
  final bool showNew;
  final ValueChanged<bool> onChanged;
  const _TestamentTabs({required this.showNew, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TestamentTabButton(
              label: 'Antiguo',
              active: !showNew,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _TestamentTabButton(
              label: 'Nuevo',
              active: showNew,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestamentTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TestamentTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  // Sky-blue → light cyan, distinct from the rosa/violeta bg.
                  colors: [Color(0xFF60A5FA), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withValues(alpha: .35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : RefColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  final String text;
  final Color? accent;

  const _CategoryLabel(this.text, {this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent ?? RefColors.dim;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: accent ?? RefColors.dim,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String backLabel;
  final String title;
  final String action;
  final VoidCallback onBack;
  final VoidCallback? onAction;

  const _StepHeader({
    required this.backLabel,
    required this.title,
    required this.action,
    required this.onBack,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final chip = RefChip(
      action,
      dense: true,
      color: onAction != null
          ? RefColors.pink.withValues(alpha: .22)
          : HtmlRefColors.glassSoft,
      textColor: RefColors.ink,
    );
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left, color: RefColors.muted, size: 18),
              Text(
                backLabel,
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        if (onAction != null)
          GestureDetector(onTap: onAction, child: chip)
        else
          chip,
      ],
    );
  }
}

class _ChapterPicker extends StatelessWidget {
  final String selectedBook;
  final VoidCallback onBack;
  final ValueChanged<int> onChapter;
  final VoidCallback? onSelectAllBook;

  const _ChapterPicker({
    required this.selectedBook,
    required this.onBack,
    required this.onChapter,
    this.onSelectAllBook,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      color: HtmlRefColors.glassBg,
      border: Border.all(color: HtmlRefColors.glassBorder),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          _StepHeader(
            backLabel: 'Libros',
            title: selectedBook,
            action: 'Todo el libro',
            onBack: onBack,
            onAction: onSelectAllBook,
          ),
          const SizedBox(height: 10),
          _ChapterGrid(selectedBook: selectedBook, onChapter: onChapter),
        ],
      ),
    );
  }
}

class _ChapterGrid extends StatelessWidget {
  final String selectedBook;
  final ValueChanged<int> onChapter;

  const _ChapterGrid({required this.selectedBook, required this.onChapter});

  @override
  Widget build(BuildContext context) {
    final chapters = List.generate(
      _chapterCountFor(selectedBook),
      (index) => index + 1,
    );
    const selected = <int>{};
    const partial = <int>{};

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520
            ? 9
            : constraints.maxWidth >= 440
            ? 8
            : 7;
        return GridView.builder(
          itemCount: chapters.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1.12,
          ),
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            final isSelected = selected.contains(chapter);
            final isPartial = partial.contains(chapter);
            return GestureDetector(
              onTap: () => onChapter(chapter),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? RefColors.pink
                      : isPartial
                      ? HtmlRefColors.bookPartial
                      : HtmlRefColors.glassSoft,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    width: 1.4,
                    color: isSelected
                        ? Colors.transparent
                        : isPartial
                        ? HtmlRefColors.bookPartialBorder
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$chapter',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<String> books;
  final Set<String> selected;
  final Set<String> partial;
  final ValueChanged<String> onBook;
  /// Per-category tint applied to unselected tiles so the user can group
  /// books by genre at a glance. Falls back to glassSoft when missing.
  final Map<String, Color> bookAccents;

  const _BookGrid({
    required this.books,
    required this.selected,
    required this.partial,
    required this.onBook,
    this.bookAccents = const {},
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520
            ? 6
            : constraints.maxWidth >= 440
            ? 5
            : 4;
        return GridView.builder(
          itemCount: books.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 2.28,
          ),
          itemBuilder: (context, index) {
            final book = books[index];
            final isSelected = selected.contains(book);
            final isPartial = partial.contains(book);
            // Category tint applied to unselected tiles. The selected /
            // partial states still win above this.
            final acc = bookAccents[book];
            final defaultBg = acc != null
                ? acc.withValues(alpha: .32)
                : HtmlRefColors.glassSoft;
            final defaultBorder = acc != null
                ? acc.withValues(alpha: .65)
                : Colors.transparent;
            return GestureDetector(
              onTap: () => onBook(book),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? HtmlRefColors.bookSelected
                      : isPartial
                      ? HtmlRefColors.bookPartial
                      : defaultBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    width: 1.4,
                    color: isSelected
                        ? RefColors.pink
                        : isPartial
                        ? HtmlRefColors.bookPartialBorder
                        : defaultBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    book,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VersePicker extends StatefulWidget {
  final String selectedBook;
  final int selectedChapter;
  final Set<int> selectedVerses;
  final VoidCallback onBack;
  final ValueChanged<int> onVerse;
  final VoidCallback onConfirm;
  final VoidCallback? onSelectAllChapter;

  const _VersePicker({
    required this.selectedBook,
    required this.selectedChapter,
    required this.selectedVerses,
    required this.onBack,
    required this.onVerse,
    required this.onConfirm,
    this.onSelectAllChapter,
  });

  @override
  State<_VersePicker> createState() => _VersePickerState();
}

class _VersePickerState extends State<_VersePicker> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final verses = store.versesFor(widget.selectedBook, widget.selectedChapter);
    final canonicalBook = verses.isEmpty
        ? widget.selectedBook
        : verses.first.book;
    final selectedInStore = store.selectedBibleVerses
        .where(
          (verse) =>
              verse.book == canonicalBook &&
              verse.chapter == widget.selectedChapter,
        )
        .map((verse) => verse.verse)
        .toSet();
    final effectiveSelected = {...widget.selectedVerses, ...selectedInStore};

    return Glass(
      color: HtmlRefColors.glassBg,
      border: Border.all(color: HtmlRefColors.glassBorder),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _StepHeader(
            backLabel: 'Capítulos',
            title: '${widget.selectedBook} ${widget.selectedChapter}',
            action: 'Todo el cap',
            onBack: widget.onBack,
            onAction: widget.onSelectAllChapter,
          ),
          const SizedBox(height: 10),
          if (verses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HtmlRefColors.glassSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HtmlRefColors.glassBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No encontré este capítulo',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'La Reina Valera 1909 está cargada localmente. Si ves esto, revisa que el libro y capítulo existan.',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: verses.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    return _VerseItem(
                      number: verse.verse,
                      text: verse.text,
                      selected: effectiveSelected.contains(verse.verse),
                      onTap: () => widget.onVerse(verse.verse),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          Cta(
            verses.isEmpty ? 'Volver a capítulos' : 'Confirmar versículos →',
            onTap: verses.isEmpty
                ? widget.onBack
                : (effectiveSelected.isEmpty ? null : widget.onConfirm),
            disabled: verses.isNotEmpty && effectiveSelected.isEmpty,
          ),
        ],
      ),
    );
  }
}

String _clipText(String text) {
  if (text.length <= 34) return text;
  return '${text.substring(0, 34)}...';
}

/// Dropdown compacto que muestra la versión bíblica activa y deja al usuario
/// cambiar entre las que están cargadas. Vive dentro del header del
/// `_BookPicker`.
class _BibleVersionDropdown extends StatelessWidget {
  const _BibleVersionDropdown();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final entries = AppStore.bundledBibles.entries.toList();
    final current = entries.firstWhere(
      (e) => e.key == store.bibleVersion,
      orElse: () => entries.first,
    );

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: current.key,
        isDense: true,
        isExpanded: true,
        dropdownColor: RefColors.glassStrong,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: RefColors.muted,
          size: 18,
        ),
        style: const TextStyle(
          color: RefColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        selectedItemBuilder: (_) => [
          for (final e in entries)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: HtmlRefColors.glassSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HtmlRefColors.glassBorder),
              ),
              child: Text(
                e.value.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RefColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
        items: [
          for (final e in entries)
            DropdownMenuItem<String>(
              value: e.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.value.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    e.value.license,
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (id) {
          if (id != null) store.setBibleVersion(id);
        },
      ),
    );
  }
}

/// Acciones disponibles al hacer long-press sobre un mazo: cambiar visibilidad
/// (si soy dueño) o reportar (siempre disponible). En Fase 1 todos los mazos
/// son del usuario, así que mostramos ambas; cuando llegue auth real
/// filtraremos por owner.
void _showDeckActionsSheet(BuildContext context, MemoryDeckData deck) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return Container(
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HtmlRefColors.glassBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HtmlRefColors.glassBorder),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  GlyphIcon(deck.icon, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      deck.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _VisibilityBadge(visibility: deck.visibility),
                ],
              ),
            ),
            _DeckActionRow(
              icon: Icons.visibility_outlined,
              label: 'Cambiar visibilidad',
              subtitle: 'Privado, amigos o comunidad',
              onTap: () {
                Navigator.of(sheetCtx).pop();
                showVisibilityConsentSheet(
                  context,
                  deckId: deck.id,
                  deckTitle: deck.title,
                  current: deck.visibility,
                );
              },
            ),
            _DeckActionRow(
              icon: Icons.share_outlined,
              label: 'Compartir con amigo',
              subtitle: 'Enviar este mazo a un amigo de tu lista',
              accent: RefColors.lime,
              onTap: () {
                Navigator.of(sheetCtx).pop();
                showShareDeckSheet(context, deck: deck);
              },
            ),
            _DeckActionRow(
              icon: Icons.flag_outlined,
              label: 'Reportar',
              subtitle: 'Avisar a moderación si viola las normas',
              accent: RefColors.urgent,
              onTap: () {
                Navigator.of(sheetCtx).pop();
                showReportDeckSheet(
                  context,
                  deckId: deck.id,
                  deckTitle: deck.title,
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

/// Bottom sheet para compartir un mazo con un amigo. Si no hay sesión, manda
/// al login. Lista a tus amigos aceptados; al elegir uno, hace POST a
/// `/v1/social/shares`.
void showShareDeckSheet(BuildContext context, {required MemoryDeckData deck}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ShareDeckSheet(deck: deck),
  );
}

class _ShareDeckSheet extends StatefulWidget {
  final MemoryDeckData deck;
  const _ShareDeckSheet({required this.deck});

  @override
  State<_ShareDeckSheet> createState() => _ShareDeckSheetState();
}

class _ShareDeckSheetState extends State<_ShareDeckSheet> {
  FriendsResult? _data;
  bool _loading = true;
  String? _busyFriendId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final r = await store.api.listFriends();
      if (!mounted) return;
      setState(() => _data = r);
    } catch (_) {
      // muestra estado vacío.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share(String friendUserId, String friendLabel) async {
    final store = AppScope.of(context);
    setState(() => _busyFriendId = friendUserId);
    try {
      // Payload mínimo del mazo. El receptor lo deserializa al "copiar" el mazo.
      final payload = jsonEncode({
        'title': widget.deck.title,
        'icon': widget.deck.icon,
        'cards': [
          for (final c in widget.deck.cards)
            {
              'id': c.id,
              'front': c.front,
              'back': c.back,
              'source': c.source,
              'icon': c.icon,
            },
        ],
      });
      await store.api.shareDeck(
        deckId: widget.deck.id,
        title: widget.deck.title,
        summary: '${widget.deck.cards.length} tarjetas',
        payloadJson: payload,
        targetUserId: friendUserId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mazo compartido con $friendLabel')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pude compartir: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyFriendId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final friends = _data?.friends ?? const [];
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
              'Compartir "${widget.deck.title}"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (!store.isLoggedIn)
              Column(
                children: [
                  const Text(
                    'Necesitas iniciar sesión para compartir mazos con tus amigos.',
                    style: TextStyle(color: RefColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Cta(
                    'Iniciar sesión',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                  ),
                ],
              )
            else if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (friends.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Todavía no tienes amigos. Agrega alguno desde la pestaña Amigos para compartir.',
                  style: TextStyle(color: RefColors.muted, fontSize: 13),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final f in friends)
                        () {
                          final myId = store.currentUser?.id ?? '';
                          final otherId = f.requesterId == myId
                              ? f.addresseeId
                              : f.requesterId;
                          return _ShareFriendRow(
                            label: otherId,
                            busy: _busyFriendId == otherId,
                            onTap: () => _share(otherId, otherId),
                          );
                        }(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShareFriendRow extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onTap;
  const _ShareFriendRow({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: HtmlRefColors.glassSoft,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: HtmlRefColors.glassBorder),
        ),
        child: Row(
          children: [
            const Fav('A', size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.send_rounded,
                color: RefColors.lime,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final DeckVisibility visibility;
  const _VisibilityBadge({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (visibility) {
      DeckVisibility.private => (
        Icons.lock_outline_rounded,
        'Privado',
        RefColors.muted,
      ),
      DeckVisibility.friends => (
        Icons.people_outline_rounded,
        'Amigos',
        RefColors.cyan,
      ),
      DeckVisibility.public => (
        Icons.public_rounded,
        'Público',
        RefColors.lime,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  const _DeckActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.accent = RefColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: HtmlRefColors.glassSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HtmlRefColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: accent.withValues(alpha: .45)),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: RefColors.muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the "Tarjetas más débiles" list. Bible cards from the same
/// chapter collapse into a single row with verse ranges so 5 consecutive
/// verses don't show up as 5 near-identical items.
class _ReviewGroup {
  final String icon;
  final String front;
  final String source;
  final int totalLapses;
  final int avgRetention;
  const _ReviewGroup({
    required this.icon,
    required this.front,
    required this.source,
    required this.totalLapses,
    required this.avgRetention,
  });
}

/// Try to parse a Bible-style card front into (chapter prefix, verse number).
///
/// Acepta dos formatos:
/// - `"Salmos 106:1"` (deck creado vía Biblia interna)
/// - `"Versículo 1"` con `deckTitle = "Salmos 106"` → prefijo derivado del
///   título del mazo (deck creado al pegar contenido y segmentar).
/// Retorna null para tarjetas que no encajen en ninguno de los dos.
({String prefix, int verse})? _parseBibleRef(String front, {String? deckTitle}) {
  final clean = front.trim();
  final colon = RegExp(r'^(.+?)\s*:\s*(\d+)$').firstMatch(clean);
  if (colon != null) {
    return (prefix: colon.group(1)!.trim(), verse: int.parse(colon.group(2)!));
  }
  // "Versículo 16", "v. 16", "Verso 16" → usa el título del mazo como prefijo.
  final loose = RegExp(
    r'^(?:vers[íi]culo|verso|v\.?)\s+(\d+)$',
    caseSensitive: false,
  ).firstMatch(clean);
  if (loose != null && deckTitle != null && deckTitle.trim().isNotEmpty) {
    return (prefix: deckTitle.trim(), verse: int.parse(loose.group(1)!));
  }
  return null;
}

/// Una tarjeta lista para agrupar — guarda el deck dueño para que el
/// agrupador pueda usar `deck.title` como prefijo cuando el `front` no trae
/// un libro completo (ej. "Versículo 1" en mazos creados desde Especificar).
typedef _ReviewCardWithDeck = ({MemoryCardData card, MemoryDeckData deck});

List<_ReviewCardWithDeck> _attachDecks(
  List<MemoryCardData> cards,
  AppStore store,
) {
  final deckOfCard = <String, MemoryDeckData>{};
  for (final deck in store.decks) {
    for (final c in deck.cards) {
      deckOfCard[c.id] = deck;
    }
  }
  return [
    for (final c in cards)
      if (deckOfCard[c.id] != null)
        (card: c, deck: deckOfCard[c.id]!),
  ];
}

List<_ReviewGroup> _groupReviewCards(List<_ReviewCardWithDeck> cards) {
  if (cards.isEmpty) return const [];
  final order = <String>[];
  final byKey = <String, List<_ReviewCardWithDeck>>{};
  for (final entry in cards) {
    final ref = _parseBibleRef(
      entry.card.front,
      deckTitle: entry.deck.title,
    );
    // Cuando hay ref, agrupar también por deck.id para no fusionar mazos
    // distintos que casualmente compartan título o capítulo.
    final key = ref != null
        ? 'bible:${entry.deck.id}:${ref.prefix}'
        : 'solo:${entry.card.id}';
    if (!byKey.containsKey(key)) order.add(key);
    byKey.putIfAbsent(key, () => []).add(entry);
  }
  final out = <_ReviewGroup>[];
  for (final key in order) {
    final group = byKey[key]!;
    if (key.startsWith('solo:')) {
      final c = group.first.card;
      out.add(_ReviewGroup(
        icon: c.icon,
        front: c.front,
        source: c.source,
        totalLapses: c.lapses,
        avgRetention: c.retention,
      ));
      continue;
    }
    final verses = <int>[];
    var totalLapses = 0;
    var totalRetention = 0;
    String? prefix;
    for (final entry in group) {
      final ref = _parseBibleRef(
        entry.card.front,
        deckTitle: entry.deck.title,
      );
      if (ref != null) {
        prefix ??= ref.prefix;
        verses.add(ref.verse);
      }
      totalLapses += entry.card.lapses;
      totalRetention += entry.card.retention;
    }
    final first = group.first.card;
    out.add(_ReviewGroup(
      icon: first.icon,
      front: verses.length == 1
          ? '$prefix:${verses.first}'
          : '$prefix:${_compactRanges(verses)}',
      source: first.source,
      totalLapses: totalLapses,
      avgRetention: (totalRetention / group.length).round(),
    ));
  }
  return out;
}

/// One row in the "Seleccionado" card. The picker collapses contiguous
/// verse / chapter ranges into single rows so a whole-Bible selection
/// renders as a handful of items rather than thousands.
class _SelectionEntry {
  final String title;
  final String subtitle;
  /// The actual verses this row represents — used by the × button to drop the
  /// whole range from the selection in one tap.
  final List<BibleVerseData> verses;
  const _SelectionEntry(this.title, this.subtitle, this.verses);
}

String _compactRanges(List<int> nums) {
  if (nums.isEmpty) return '';
  final sorted = [...nums]..sort();
  final ranges = <String>[];
  var start = sorted.first;
  var prev = start;
  for (var i = 1; i < sorted.length; i++) {
    final n = sorted[i];
    if (n == prev + 1) {
      prev = n;
    } else {
      ranges.add(start == prev ? '$start' : '$start-$prev');
      start = n;
      prev = n;
    }
  }
  ranges.add(start == prev ? '$start' : '$start-$prev');
  return ranges.join(', ');
}

List<_SelectionEntry> _summarizeSelection(
  List<BibleVerseData> selected,
  AppStore store,
) {
  if (selected.isEmpty) return const [];

  // Group selected verses: book → chapter → verse numbers.
  final byBook = <String, Map<int, List<int>>>{};
  for (final v in selected) {
    byBook
        .putIfAbsent(v.book, () => <int, List<int>>{})
        .putIfAbsent(v.chapter, () => <int>[])
        .add(v.verse);
  }

  final entries = <_SelectionEntry>[];
  // Preserve the order in which the user added books.
  final orderedBooks = <String>{};
  for (final v in selected) {
    orderedBooks.add(v.book);
  }

  // Index selected verses for quick lookup when assembling each entry's
  // `verses` payload.
  final byKey = <String, BibleVerseData>{
    for (final v in selected) '${v.book}:${v.chapter}:${v.verse}': v,
  };
  List<BibleVerseData> versesFor(String book, Iterable<int> chapters) {
    final out = <BibleVerseData>[];
    for (final chap in chapters) {
      for (final n in byBook[book]![chap]!) {
        final v = byKey['$book:$chap:$n'];
        if (v != null) out.add(v);
      }
    }
    return out;
  }

  for (final book in orderedBooks) {
    final chapters = byBook[book]!;
    if (store.isWholeBookSelected(book)) {
      final totalVerses = chapters.values
          .map((list) => list.length)
          .fold<int>(0, (a, b) => a + b);
      entries.add(_SelectionEntry(
        book,
        'Libro completo · $totalVerses vs',
        versesFor(book, chapters.keys),
      ));
      continue;
    }

    final fullChapters = <int>[];
    final partialChapters = <int>[];
    for (final chap in chapters.keys) {
      if (store.isWholeChapterSelected(book, chap)) {
        fullChapters.add(chap);
      } else {
        partialChapters.add(chap);
      }
    }

    if (fullChapters.isNotEmpty) {
      fullChapters.sort();
      final ranges = _compactRanges(fullChapters);
      final totalVerses = fullChapters
          .map((c) => chapters[c]!.length)
          .fold<int>(0, (a, b) => a + b);
      entries.add(
        _SelectionEntry(
          '$book $ranges',
          fullChapters.length == 1
              ? 'Capítulo completo · $totalVerses vs'
              : 'Capítulos completos · $totalVerses vs',
          versesFor(book, fullChapters),
        ),
      );
    }

    partialChapters.sort();
    for (final chap in partialChapters) {
      final verses = chapters[chap]!;
      final preview = selected
          .firstWhere(
            (v) => v.book == book && v.chapter == chap && v.verse == verses.first,
          )
          .text;
      entries.add(
        _SelectionEntry(
          '$book $chap:${_compactRanges(verses)}',
          _clipText(preview),
          versesFor(book, [chap]),
        ),
      );
    }
  }
  return entries;
}

String _cardStudyText(BuildContext context) {
  return AppScope.of(context).activeCard.back;
}

/// Versos del batch/grupo actual, con número y texto. Si la sesión es de
/// un solo item, devuelve ese item como verso único. El número del verso
/// se extrae del front (`"Salmo 1:1"` → 1). Para decks no bíblicos donde
/// el front no es una referencia, el número es secuencial 1..N.
List<({int number, String text})> _currentBatchVerses(BuildContext context) {
  final store = AppScope.of(context);
  final batch = const <MemoryCardData>[];
  if (batch.isEmpty) {
    final card = store.activeCard;
    final m = RegExp(r':(\d+)$').firstMatch(card.front.trim());
    return [(number: int.tryParse(m?.group(1) ?? '') ?? 1, text: card.back)];
  }
  return [
    for (var i = 0; i < batch.length; i++)
      () {
        final m =
            RegExp(r':(\d+)$').firstMatch(batch[i].front.trim());
        final num = int.tryParse(m?.group(1) ?? '') ?? (i + 1);
        return (number: num, text: batch[i].back);
      }()
  ];
}

/// Widget reusable: un verso renderizado como fila — número anclado
/// (color pink, llamativo) seguido de las palabras. El callback `wordStyle`
/// permite a cada call site decidir el estilo por palabra (highlight,
/// blur, hidden, etc.). Si `wordStyle` es null, todas las palabras usan
/// `defaultStyle`.
class _VerseLine extends StatelessWidget {
  final int number;
  final List<String> words;
  final TextStyle defaultStyle;
  final TextStyle? Function(int wordIndex)? wordStyle;
  final double fontSize;

  const _VerseLine({
    required this.number,
    required this.words,
    required this.defaultStyle,
    this.wordStyle,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Text(
            '$number',
            style: TextStyle(
              color: RefColors.pink,
              fontSize: (fontSize * 0.7).clamp(12, 18),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        for (var i = 0; i < words.length; i++)
          Text(
            words[i],
            style: (wordStyle?.call(i) ?? defaultStyle).copyWith(
              fontSize: fontSize,
            ),
          ),
      ],
    );
  }
}

String _cardSourceText(BuildContext context) {
  final store = AppScope.of(context);
  final card = store.activeCard;
  if (store.activeDeck.isBible) return '${card.front} · ${card.source}';
  // Para decks no bíblicos, el `source` por defecto es "Contenido propio"
  // que es redundante (ya estás dentro de tu mazo). Solo mostramos el
  // título del deck.
  return store.activeDeck.title;
}


List<String> _studyWords(String text) {
  final cleaned = text
      .replaceAll(RegExp(r'[“”"]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return const ['Jehová', 'es', 'mi', 'pastor'];
  return cleaned.split(' ');
}

List<MemoryCardData> _quizOptions(MemoryDeckData deck, MemoryCardData correct) {
  final pool = deck.cards.where((item) => item.id != correct.id).toList();
  final rng = math.Random(correct.id.hashCode);
  pool.shuffle(rng);
  final distractors = pool.take(3).toList();
  if (distractors.length < 3) {
    distractors.addAll([
      MemoryCardData(
        id: 'distractor-front',
        front: 'Idea cercana',
        back: 'Una respuesta parecida, pero no corresponde a ${correct.front}.',
        source: 'Distractor',
        icon: correct.icon,
      ),
      MemoryCardData(
        id: 'distractor-partial',
        front: 'Fragmento incompleto',
        back: _firstWords(correct.back, 4),
        source: 'Distractor',
        icon: correct.icon,
      ),
    ]);
  }
  final options = [correct, ...distractors.take(3)];
  options.shuffle(rng);
  return options;
}

String _firstWords(String text, int count) {
  final words = _studyWords(text);
  return words.take(count).join(' ');
}

int _flowStepNumber(String slug) {
  final match = RegExp(r'^(\d+)').firstMatch(slug);
  if (match == null) return slug == 'mini-review' ? 13 : 14;
  return int.parse(match.group(1)!);
}

String _realStepTitle(String slug) {
  if (slug == '01-escuchar') return 'Escuchar';
  if (slug == '02-niebla-n1') return 'Niebla N1';
  if (slug == '03-leer-voz') return 'Leer en voz';
  if (slug == '04-escuchar-voz') return 'Escuchar tu voz';
  if (slug.contains('bloques')) return 'Ordena el texto';
  if (slug == '12-completar-n3') return 'Completado';
  if (slug.contains('completar')) return 'Completa memoria';
  if (slug.contains('primera-letra')) return 'Iniciales';
  if (slug.contains('quiz')) return 'Quiz real';
  if (slug == '15-banco-completo') return 'Banco completo';
  if (slug == '17-niebla-n2') return 'Niebla N2';
  if (slug == '16-niebla' || slug == '16-niebla-n3') return 'Niebla N3';
  if (slug == '18-recit-n1') return 'Completar recitación';
  if (slug.contains('voz')) return 'Recitación';
  return 'Estudio activo';
}

ExerciseFlowData _flowData(String slug) {
  return flowScreens.firstWhere(
    (item) => item.slug == slug,
    orElse: () => ExerciseFlowData(slug, _realStepTitle(slug), 'Práctica'),
  );
}

List<ExerciseFlowData> _sessionFlowSteps(AppStore store) {
  final difficulty = store.sessionDifficulty.clamp(0, 2);
  final seed = store.sessionFlowSeed;
  final rng = math.Random(seed ^ (difficulty * 1009));

  List<String> pick(List<String> pool, int count) {
    final copy = [...pool]..shuffle(rng);
    return copy.take(count.clamp(0, copy.length)).toList();
  }

  // Intro: pasos básicos de preparación (escuchar / leer / bloques).
  final intro = <String>[
    '01-escuchar',
    '03-leer-voz',
    '04-escuchar-voz',
    '05-bloques',
  ];
  final level1 = <String>[
    '06-completar-n1',
    '07-primera-letra-n1',
    '18-recit-n1', // completar recitación (un trozo seguido a recitar)
  ];
  final level2 = <String>[
    '08-voz-guiada',
    '17-niebla-n2', // recitación intermedia, blur medio
    '10-completar-n2',
    '11-primera-letra-n2',
  ];
  final level3Optional = <String>[
    if (store.isPremium) '09-quiz',
    '12-completar-n3',
    '13-primera-letra-n3',
    '15-banco-completo',
    '16-niebla-n3', // niebla densa (el "16-niebla" original ahora renombrado)
  ];

  final slugs = <String>[
    ...intro,
    // Niebla N1: primer ejercicio activo de recitación → bloque de práctica,
    // no el bloque inicial. El usuario recita el texto borroso con el mic.
    '02-niebla-n1',
    ...pick(level1, difficulty == 0 ? 1 : 2),
    if (difficulty >= 1) ...pick(level2, difficulty == 1 ? 2 : 3),
    if (difficulty >= 1) ...pick(level3Optional, difficulty == 1 ? 2 : 3),
    '14-voz-final',
  ];
  return slugs.map(_flowData).toList();
}

String _nextFlowSlug(AppStore store, String slug) {
  final steps = _sessionFlowSteps(store);
  final index = steps.indexWhere((item) => item.slug == slug);
  if (index < 0 || index == steps.length - 1) return 'final-review';
  return steps[index + 1].slug;
}

bool _isPassiveStep(String slug) {
  // 02-lectura-frag fue reemplazado por 02-niebla-n1 que es interactivo
  // (recitación con mic), no pasivo.
  return slug == '01-escuchar' ||
      slug == '03-leer-voz' ||
      slug == '04-escuchar-voz';
}

bool _isCompletionSlug(String slug) => slug.contains('completar');

bool _isFirstLetterSlug(String slug) => slug.contains('primera-letra');

bool _isFinalVoiceSlug(String slug) => slug.endsWith('voz-final');

bool _isWordBankSlug(String slug) => slug == '15-banco-completo';

bool _isFogSlug(String slug) =>
    slug == '02-niebla-n1' ||
    slug == '17-niebla-n2' ||
    slug == '16-niebla' ||
    slug == '16-niebla-n3';

int _fogLevelForSlug(String slug) {
  if (slug == '02-niebla-n1') return 1;
  if (slug == '17-niebla-n2') return 2;
  return 3; // niebla-n3 / niebla legacy
}

int _completionLevelForSlug(String slug) {
  if (slug.endsWith('-n3')) return 3;
  if (slug.endsWith('-n2')) return 2;
  return 1;
}

int _letterLevelForSlug(String slug) {
  if (slug.endsWith('-n3')) return 3;
  if (slug.endsWith('-n2')) return 2;
  return 1;
}

String _phaseLabelFor(String slug) {
  if (_isFogSlug(slug)) {
    return 'Construir';
  }
  // Ejercicios activos → bloque de práctica ("Probar"), aunque su número de
  // paso sea bajo (la niebla N1 es paso 02 pero es un ejercicio, no prep).
  if (_completionLevelForSlug(slug) >= 3 ||
      _letterLevelForSlug(slug) >= 3 ||
      slug == '09-quiz' ||
      _isWordBankSlug(slug) ||
      _isFinalVoiceSlug(slug)) {
    return 'Probar';
  }
  if (_flowStepNumber(slug) <= 4) return 'Preparar';
  return 'Construir';
}

List<String> _orderedBlocks(String text) {
  final words = _studyWords(text);
  final size = words.length > 18 ? 4 : 3;
  final cleanRegex = RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]');
  final blocks = <String>[];
  for (var i = 0; i < words.length; i += size) {
    final chunk = words
        .skip(i)
        .take(size)
        .map((w) => w.replaceAll(cleanRegex, ''))
        .where((w) => w.isNotEmpty)
        .join(' ');
    blocks.add(chunk);
  }
  return blocks;
}

String _targetWord(String text, {required int level}) {
  final words = _studyWords(text)
      .where(
        (word) =>
            word.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '').length > 3,
      )
      .toList();
  if (words.isEmpty) return _studyWords(text).first;
  final offset = switch (level) {
    1 => 0,
    2 => words.length ~/ 2,
    _ => words.length - 1,
  };
  return words[offset.clamp(0, words.length - 1)];
}

List<String> _completionTargetsFor(String text, {required int level}) {
  final words = _studyWords(text);
  if (words.isEmpty) return [];
  // N3: hide ALL words (including very short ones like "el", "y", "la").
  if (level >= 3) {
    return [...words];
  }
  final candidateIndexes = <int>[];
  for (var i = 0; i < words.length; i++) {
    final clean = words[i].replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '');
    if (clean.length > 2) candidateIndexes.add(i);
  }
  final sourceIndexes = candidateIndexes.isEmpty
      ? List<int>.generate(words.length, (i) => i)
      : candidateIndexes;
  if (sourceIndexes.isEmpty) return [];
  final targetCount = switch (level) {
    1 => 3,
    2 => (sourceIndexes.length * 0.65).round(),
    _ => sourceIndexes.length,
  }.clamp(1, sourceIndexes.length).toInt();
  final rng = math.Random();
  final pickPool = List<int>.from(sourceIndexes);
  pickPool.shuffle(rng);
  final picked = <int>{};
  for (final idx in pickPool) {
    final word = words[idx];
    final alreadyPicked = picked.any(
      (existing) => _sameAnswer(words[existing], word),
    );
    if (alreadyPicked) continue;
    picked.add(idx);
    if (picked.length >= targetCount) break;
  }
  // Return targets in text order, not shuffle order.
  final ordered = picked.toList()..sort();
  return ordered.map((i) => words[i]).toList();
}

List<String> _completionOptions(
  String text,
  String target, {
  int offset = 0,
  int seed = 0,
}) {
  final cleanRegex = RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]');
  final cleanTarget = target.replaceAll(cleanRegex, '');
  final pool = <String>[];
  final words = _studyWords(text);
  for (final word in words) {
    final clean = word.replaceAll(cleanRegex, '');
    if (clean.length > 3 &&
        !_sameAnswer(clean, cleanTarget) &&
        !pool.any((p) => _sameAnswer(p, clean))) {
      pool.add(clean);
    }
  }
  final rng = math.Random(
    seed == 0 ? DateTime.now().microsecondsSinceEpoch : seed,
  );
  pool.shuffle(rng);
  final distractors = pool.take(4).toList();
  final options = <String>[cleanTarget, ...distractors];
  options.shuffle(rng);
  return options;
}

String _firstLetterAnswer(String text, {required int level}) {
  final words = _firstLetterTargets(text, level: level);
  return words.map((word) => word.substring(0, 1)).join('');
}

List<String> _firstLetterTargets(String text, {required int level}) {
  final words = _studyWords(text);
  if (words.isEmpty) return [];
  final targetCount = switch (level) {
    1 => 4,
    2 => (words.length * 0.7).round(),
    _ => words.length,
  };
  final visibleWords = switch (level) {
    1 => 3,
    2 => 1,
    _ => 0,
  };
  final rng = math.Random();
  final available = words.skip(visibleWords).toList();
  if (available.isEmpty) return words.take(1).toList();
  final indexes = List.generate(available.length, (i) => i);
  indexes.shuffle(rng);
  final selected = indexes
      .take(targetCount.clamp(1, available.length).toInt())
      .toList();
  selected.sort();
  return selected.map((i) => available[i]).toList();
}

int _editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final m = a.length;
  final n = b.length;
  var prev = List<int>.generate(n + 1, (i) => i);
  var curr = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final del = prev[j] + 1;
      final ins = curr[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      curr[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}

String _normalizeForVoice(String s) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var t = s.toLowerCase();
  for (final e in accents.entries) {
    t = t.replaceAll(e.key, e.value);
  }
  return t.replaceAll(RegExp(r'[^a-z]'), '');
}

/// Match leniency for voice input. Ignores case + accents and tolerates a small
/// number of Levenshtein edits scaled by word length so STT misreads of one
/// vowel/consonant don't fail short words like "creo" vs "crio".
bool _voiceMatch(String spoken, String target) {
  final a = _normalizeForVoice(spoken);
  final b = _normalizeForVoice(target);
  if (a.isEmpty || b.isEmpty) return a == b;
  if (a == b) return true;
  // Substring match for short STT garbage (e.g. "el creo" vs "creo").
  if (b.length >= 3 && (a.contains(b) || b.contains(a))) return true;
  final maxLen = math.max(a.length, b.length);
  final dist = _editDistance(a, b);
  // Allow ~33% edits, minimum 1.
  final allowed = (maxLen * 0.34).floor().clamp(1, 4);
  // For very short targets (≤3), only 1 edit allowed.
  if (b.length <= 3) return dist <= 1;
  return dist <= allowed;
}

bool _sameAnswer(String a, String b) {
  String normalize(String value) {
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    var text = value.toLowerCase();
    for (final entry in accents.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text.replaceAll(RegExp(r'[^a-z]'), '');
  }

  return normalize(a) == normalize(b);
}

bool _similarEnoughForVoice(String spoken, String expected) {
  final s = _normalizeSpeechText(spoken);
  final e = _normalizeSpeechText(expected);
  if (s == e) return true;
  if (s.contains(e) || e.contains(s)) return true;
  final maxLen = s.length > e.length ? s.length : e.length;
  if (maxLen <= 1) return s == e;
  int distance = 0;
  final minLength = s.length < e.length ? s.length : e.length;
  for (var i = 0; i < minLength; i++) {
    if (s[i] != e[i]) distance++;
  }
  distance += (maxLen - minLength);
  final similarity = 1 - (distance / maxLen);
  return similarity >= 0.5;
}

String _normalizeSpeechText(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var text = value.toLowerCase();
  for (final entry in accents.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return text
      .replaceAll(RegExp(r'[^a-z\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

double _speechSimilarity(String spoken, String target) {
  final spokenWords = _normalizeSpeechText(
    spoken,
  ).split(' ').where((word) => word.isNotEmpty).toList();
  final targetWords = _normalizeSpeechText(
    target,
  ).split(' ').where((word) => word.isNotEmpty).toList();
  if (spokenWords.isEmpty || targetWords.isEmpty) return 0;

  final matchedTargets = <int>{};
  var matched = 0;
  for (final spokenWord in spokenWords) {
    for (var i = 0; i < targetWords.length; i++) {
      if (matchedTargets.contains(i)) continue;
      if (spokenWord == targetWords[i] ||
          _wordSimilarity(spokenWord, targetWords[i]) >= .78) {
        matchedTargets.add(i);
        matched++;
        break;
      }
    }
  }

  final recall = matched / targetWords.length;
  final precision = matched / spokenWords.length;
  final coverage = (recall * .7) + (precision * .3);
  final lengthRatio =
      math.min(spokenWords.length, targetWords.length) /
      math.max(spokenWords.length, targetWords.length);
  return ((coverage * .86) + (lengthRatio * .14)).clamp(0.0, 1.0);
}

double _wordSimilarity(String a, String b) {
  if (a == b) return 1;
  final longer = math.max(a.length, b.length);
  if (longer == 0) return 1;
  return 1 - (_levenshtein(a, b) / longer);
}

int _levenshtein(String a, String b) {
  final previous = List<int>.generate(b.length + 1, (index) => index);
  final current = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = math.min(
        math.min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    for (var j = 0; j <= b.length; j++) {
      previous[j] = current[j];
    }
  }
  return previous[b.length];
}

List<String> _studyBlocks(BuildContext context) {
  final words = _studyWords(_cardStudyText(context));
  final blocks = <String>[];
  for (var i = 0; i < words.length; i += 2) {
    blocks.add(words.skip(i).take(2).join(' '));
  }
  return blocks.take(4).toList();
}

String _maskedStudyLine(BuildContext context, {required int visibleWords}) {
  final words = _studyWords(_cardStudyText(context));
  return [
    for (var i = 0; i < words.length; i++) i < visibleWords ? words[i] : '____',
  ].join(' ');
}

class _VerseItem extends StatelessWidget {
  final int number;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _VerseItem({
    required this.number,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x2EFF3EA5) : HtmlRefColors.glassSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 1.5,
            color: selected ? RefColors.pink : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$number',
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 11.4, height: 1.32),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? RefColors.lime : HtmlRefColors.glassStrong,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : HtmlRefColors.glassBorder,
                  width: 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: RefColors.lime.withValues(alpha: .35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: RefColors.successInk,
                      size: 17,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueSelectionCard extends StatelessWidget {
  final VoidCallback onBook;
  final VoidCallback onFinish;

  const _ContinueSelectionCard({required this.onBook, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Glass(
      color: Colors.transparent,
      border: Border.all(color: RefColors.lime.withValues(alpha: .3)),
      gradient: LinearGradient(
        colors: [
          RefColors.lime.withValues(alpha: .15),
          RefColors.cyan.withValues(alpha: .08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Column(
        children: [
          const Icon(Icons.track_changes, color: RefColors.lime, size: 40),
          const SizedBox(height: 6),
          const Text(
            '¿Quieres seguir seleccionando?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 8,
                child: _ContinueOption(
                  icon: Icons.library_books_rounded,
                  title: 'Sí',
                  onTap: onBook,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 15,
                child: _ContinueOption(
                  icon: Icons.check_rounded,
                  title: 'Finalizar',
                  primary: true,
                  onTap: onFinish,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContinueOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool primary;
  final VoidCallback onTap;

  const _ContinueOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: primary ? RefColors.primary : null,
          color: primary ? null : HtmlRefColors.glassSoft,
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: HtmlRefColors.glassBorder),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: RefColors.pink.withValues(alpha: .35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: RefColors.ink),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedVerseRef extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRemove;

  const _SelectedVerseRef(this.title, this.subtitle, {this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              title,
              style: const TextStyle(
                color: RefColors.pink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: RefColors.ink),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: onRemove != null
                    ? RefColors.urgent.withValues(alpha: .18)
                    : HtmlRefColors.glassStrong,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: onRemove != null
                      ? RefColors.urgent.withValues(alpha: .55)
                      : HtmlRefColors.glassBorder,
                ),
              ),
              child: Center(
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: onRemove != null
                        ? RefColors.urgent
                        : RefColors.ink,
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

class _ThemesBrowse extends StatelessWidget {
  const _ThemesBrowse();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'BUSCAR POR TEMA',
                  style: TextStyle(
                    color: RefColors.dim,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                'Ver más →',
                style: TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              _ThemeChip('♥', 'Amor', '42', RefColors.pink),
              SizedBox(width: 8),
              _ThemeChip('♜', 'Fe', '38', RefColors.sun),
              SizedBox(width: 8),
              _ThemeChip('🤝', 'Perdón', '24', RefColors.violet),
            ],
          ),
        ),
        // const SizedBox(height: 12),
        // const _PlansEntry(),
      ],
    );
  }
}

class _PlansEntry extends StatelessWidget {
  const _PlansEntry();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pushNamed(context, AppRoutes.home),
      child: Glass(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: RefColors.cyan.withValues(alpha: .14),
        child: Row(
          children: const [
            Text('📅', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planes de lectura',
                    style: TextStyle(
                      color: RefColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Avanza día a día por temas guiados',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: RefColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String icon;
  final String title;
  final String count;
  final Color color;

  const _ThemeChip(this.icon, this.title, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      color: color.withValues(alpha: .18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 5),
          Text(
            '· $count',
            style: const TextStyle(fontSize: 11, color: RefColors.muted),
          ),
        ],
      ),
    );
  }
}

