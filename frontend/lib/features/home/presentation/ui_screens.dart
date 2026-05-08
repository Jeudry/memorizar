import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/app_state.dart';
import '../../legal/presentation/community_guidelines_screen.dart';
import '../../legal/presentation/dmca_screen.dart';
import '../../legal/presentation/legal_menu_screen.dart';
import '../../legal/presentation/privacy_policy_screen.dart';
import '../../legal/presentation/terms_of_service_screen.dart';
import '../../legal/presentation/visibility_consent_dialog.dart';
import '../../moderation/presentation/moderation_queue_screen.dart';
import '../../moderation/presentation/report_dialog.dart';
import 'glyph_icon.dart';
import 'home_screen.dart';

// Imports for the extracted shared building blocks.
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

// Bible book data — used by BibliaScreen below. Kept here until the bible
// feature is extracted to its own folder.
class _BibleBook {
  final String name;
  final int chapters;

  const _BibleBook(this.name, this.chapters);
}

const _oldTestamentBooks = [
  _BibleBook('Gén', 50),
  _BibleBook('Éxo', 40),
  _BibleBook('Lev', 27),
  _BibleBook('Núm', 36),
  _BibleBook('Deut', 34),
  _BibleBook('Jos', 24),
  _BibleBook('Jue', 21),
  _BibleBook('Rut', 4),
  _BibleBook('1Sam', 31),
  _BibleBook('2Sam', 24),
  _BibleBook('1Re', 22),
  _BibleBook('2Re', 25),
  _BibleBook('1Cr', 29),
  _BibleBook('2Cr', 36),
  _BibleBook('Esd', 10),
  _BibleBook('Neh', 13),
  _BibleBook('Est', 10),
  _BibleBook('Job', 42),
  _BibleBook('Salmos', 150),
  _BibleBook('Prov', 31),
  _BibleBook('Ecl', 12),
  _BibleBook('Cant', 8),
  _BibleBook('Isa', 66),
  _BibleBook('Jer', 52),
  _BibleBook('Lam', 5),
  _BibleBook('Eze', 48),
  _BibleBook('Dan', 12),
  _BibleBook('Ose', 14),
  _BibleBook('Joel', 3),
  _BibleBook('Amós', 9),
  _BibleBook('Abd', 1),
  _BibleBook('Jon', 4),
  _BibleBook('Miq', 7),
  _BibleBook('Nah', 3),
  _BibleBook('Hab', 3),
  _BibleBook('Sof', 3),
  _BibleBook('Hag', 2),
  _BibleBook('Zac', 14),
  _BibleBook('Mal', 4),
];

const _newTestamentBooks = [
  _BibleBook('Mat', 28),
  _BibleBook('Mar', 16),
  _BibleBook('Luc', 24),
  _BibleBook('Juan', 21),
  _BibleBook('Hech', 28),
  _BibleBook('Rom', 16),
  _BibleBook('1Cor', 16),
  _BibleBook('2Cor', 13),
  _BibleBook('Gál', 6),
  _BibleBook('Ef', 6),
  _BibleBook('Fil', 4),
  _BibleBook('Col', 4),
  _BibleBook('1Tes', 5),
  _BibleBook('2Tes', 3),
  _BibleBook('1Tim', 6),
  _BibleBook('2Tim', 4),
  _BibleBook('Tit', 3),
  _BibleBook('Flm', 1),
  _BibleBook('Heb', 13),
  _BibleBook('Stg', 5),
  _BibleBook('1Pe', 5),
  _BibleBook('2Pe', 3),
  _BibleBook('1Jn', 5),
  _BibleBook('2Jn', 1),
  _BibleBook('3Jn', 1),
  _BibleBook('Jud', 1),
  _BibleBook('Apoc', 22),
];

int _chapterCountFor(String book) {
  for (final item in [..._oldTestamentBooks, ..._newTestamentBooks]) {
    if (item.name == book) return item.chapters;
  }
  return 1;
}

/// Master route → builder map. Kept in this file (rather than core/router/)
/// because it references every feature screen, all of which still live here.
/// Once each feature lives in its own folder this can move.
Map<String, WidgetBuilder> buildAppRoutes() => {
  AppRoutes.home: (_) => const HomeScreen(),
  AppRoutes.bgNocturnoMate: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.nocturnoMate),
  AppRoutes.bgVinoAhumado: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.vinoAhumado),
  AppRoutes.bgTintaProfunda: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.tintaProfunda),
  AppRoutes.bgBrasaSuave: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.brasaSuave),
  AppRoutes.bgCarbonAmbar: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.carbonAmbar),
  AppRoutes.bgCiruelaTostada: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.ciruelaTostada),
  AppRoutes.bgPetroleoDorado: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.petroleoDorado),
  AppRoutes.bgNaranjaNocturno: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.naranjaNocturno),
  AppRoutes.bgActualSuave: (_) =>
      const HomeScreen(backgroundVariant: HomeBackgroundVariant.actualSuave),
  AppRoutes.biblia: (_) => const BibliaScreen(),
  AppRoutes.especificar: (_) => const EspecificarScreen(),
  AppRoutes.iniciar: (_) => const IniciarScreen(),
  AppRoutes.repasar: (_) => const RepasarScreen(),
  AppRoutes.comunidad: (_) => const ComunidadScreen(),
  AppRoutes.amigos: (_) => const AmigosScreen(),
  AppRoutes.stats: (_) => const StatsScreen(),
  AppRoutes.cooperativo: (_) => const CooperativoScreen(),
  AppRoutes.cooperativoJuego: (_) => const CooperativoGameScreen(),
  AppRoutes.cooperativoLogrado: (_) => const CooperativoSuccessScreen(),
  AppRoutes.ejercicios: (_) => ExerciseFlowScreen(data: flowScreens.first),
  AppRoutes.flashcards: (_) => const FlashcardsScreen(),
  AppRoutes.premium: (_) => const PremiumScreen(),
  '${AppRoutes.flow}/progress-tree': (_) => const _ProgressTreeScreen(),
  for (final screen in flowScreens)
    '${AppRoutes.flow}/${screen.slug}': (_) => ExerciseFlowScreen(data: screen),
  AppRoutes.legalMenu: (_) => const LegalMenuScreen(),
  AppRoutes.legalTerms: (_) => const TermsOfServiceScreen(),
  AppRoutes.legalPrivacy: (_) => const PrivacyPolicyScreen(),
  AppRoutes.legalDmca: (_) => const DmcaScreen(),
  AppRoutes.legalCommunity: (_) => const CommunityGuidelinesScreen(),
  AppRoutes.moderationQueue: (_) => const ModerationQueueScreen(),
};

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
              onConfirmVerses: _finishBibleSelection,
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
                    final visible = entries.take(8).toList();
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
            const SizedBox(height: 16),
            _ActionCta(
              label: store.selectedBibleVerses.isEmpty
                  ? 'Selecciona al menos un versículo'
                  : 'Siguiente →',
              enabled: store.selectedBibleVerses.isNotEmpty,
              onTap: _finishBibleSelection,
            ),
          ],
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
              const Text(
                'Libros',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(width: 10),
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

String _cardSourceText(BuildContext context) {
  final store = AppScope.of(context);
  final card = store.activeCard;
  if (store.activeDeck.isBible) return '${card.front} · ${card.source}';
  return '${store.activeDeck.title} · ${card.source}';
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
  if (slug == '02-lectura-frag') return 'Lectura fragmentada';
  if (slug == '03-leer-voz') return 'Leer en voz';
  if (slug == '04-escuchar-voz') return 'Escuchar tu voz';
  if (slug.contains('bloques')) return 'Ordena el texto';
  if (slug == '12-completar-n3') return 'Completado';
  if (slug.contains('completar')) return 'Completa memoria';
  if (slug.contains('primera-letra')) return 'Iniciales';
  if (slug.contains('quiz')) return 'Quiz real';
  if (slug == '15-banco-completo') return 'Banco completo';
  if (slug == '16-niebla') return 'Niebla';
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

  final intro = <String>[
    '01-escuchar',
    '02-lectura-frag',
    '03-leer-voz',
    '04-escuchar-voz',
  ];
  final level1 = <String>[
    '05-bloques',
    '06-completar-n1',
    '07-primera-letra-n1',
  ];
  final level2 = <String>[
    '08-voz-guiada',
    '10-completar-n2',
    '11-primera-letra-n2',
  ];
  final level3Optional = <String>[
    if (store.isPremium) '09-quiz',
    '12-completar-n3',
    '13-primera-letra-n3',
    '15-banco-completo',
    '16-niebla',
  ];

  final slugs = <String>[
    ...intro,
    ...pick(level1, difficulty == 0 ? 2 : 3),
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
  return slug == '01-escuchar' ||
      slug == '02-lectura-frag' ||
      slug == '03-leer-voz' ||
      slug == '04-escuchar-voz';
}

bool _isCompletionSlug(String slug) => slug.contains('completar');

bool _isFirstLetterSlug(String slug) => slug.contains('primera-letra');

bool _isFinalVoiceSlug(String slug) => slug.endsWith('voz-final');

bool _isWordBankSlug(String slug) => slug == '15-banco-completo';

bool _isFogSlug(String slug) => slug == '16-niebla';

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
  if (_flowStepNumber(slug) <= 4) return 'Preparar';
  if (_completionLevelForSlug(slug) >= 3 ||
      _letterLevelForSlug(slug) >= 3 ||
      slug == '09-quiz' ||
      _isWordBankSlug(slug) ||
      _isFogSlug(slug) ||
      _isFinalVoiceSlug(slug)) {
    return 'Probar';
  }
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
                  title: 'Terminar selección',
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
      ],
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

class EspecificarScreen extends StatefulWidget {
  const EspecificarScreen({super.key});

  @override
  State<EspecificarScreen> createState() => _EspecificarScreenState();
}

class _EspecificarScreenState extends State<EspecificarScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  List<MemoryCardData> _segmentedCards = const [];

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
    setState(() {
      _contentController.text = text;
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
      _segmentedCards = AppScope.of(
        context,
      ).segmentContent(text, title: _titleController.text);
    });
  }

  void _createDeck() {
    final cards = _segmentedCards.isEmpty
        ? AppScope.of(context).segmentContent(
            _contentController.text,
            title: _titleController.text,
          )
        : _segmentedCards;
    final created = AppScope.of(context).createDeckFromCards(
      title: _titleController.text,
      icon: '🧠',
      cards: cards,
    );
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pega o escribe contenido antes de continuar.'),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.iniciar);
  }

  void _segmentContent() {
    final cards = AppScope.of(
      context,
    ).segmentContent(_contentController.text, title: _titleController.text);
    setState(() => _segmentedCards = cards);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cards.isEmpty
              ? 'No hay texto para segmentar.'
              : '${cards.length} tarjetas segmentadas.',
        ),
      ),
    );
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
    return ReferencePage(
      active: AppRoutes.home,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Nuevo contenido'),
          const _StepIndicator(active: 0, count: 3),
          const _PageHead(
            'Pega lo que quieres memorizar',
            'La app lo segmenta en tarjetas automáticamente · puedes editarlas después',
          ),
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
                    GestureDetector(
                      onTap: _pasteFromClipboard,
                      child: const _ToolChip('📋 Pegar'),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _segmentContent,
                      child: const _ToolChip('✨ Segmentar'),
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
      ),
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

class IniciarScreen extends StatefulWidget {
  const IniciarScreen({super.key});

  @override
  State<IniciarScreen> createState() => _IniciarScreenState();
}

/// Which quick-pick chip the user explicitly tapped. Used to disambiguate
/// when the numeric target matches more than one preset (e.g. when the deck
/// only has 1 card both "breve" and "recomendado" map to 1).
enum _DailyQuickPick { breve, recomendado, intenso, none }

class _IniciarScreenState extends State<IniciarScreen> {
  int _difficulty = 1;
  int? _dailyTarget;
  _DailyQuickPick _quickPick = _DailyQuickPick.recomendado;
  String? _deckId;
  String _selectedIcon = '✝️';
  bool _showIconPicker = false;
  late final TextEditingController _deckTitleController;

  @override
  void initState() {
    super.initState();
    _deckTitleController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deck = AppScope.of(context).activeDeck;
    if (_deckId == deck.id) return;
    _deckId = deck.id;
    _dailyTarget = _recommendedTarget(deck.cards.length);
    _quickPick = _pickForValue(_dailyTarget!, deck.cards.length);
    _selectedIcon = deck.icon;
    _showIconPicker = false;
    _deckTitleController.text = deck.title;
  }

  @override
  void dispose() {
    _deckTitleController.dispose();
    super.dispose();
  }

  /// "Recomendado" sits between breve (1) and intenso (4). Capped at 3 so it
  /// never collides with intenso visually. For 1-card decks recommended just
  /// equals breve and the chip is hidden in render.
  int _recommendedTarget(int total) {
    if (total <= 0) return 0;
    if (total <= 1) return 1;
    return ((total / 12).ceil()).clamp(2, 3);
  }

  /// Pick the chip whose value the current daily target lands on, so the
  /// badge follows the user when they step with +/-. Strict equality only —
  /// values that don't exactly match a preset leave every chip dim.
  _DailyQuickPick _pickForValue(int value, int total) {
    final rec = _recommendedTarget(total);
    if (value == rec && total > 1) return _DailyQuickPick.recomendado;
    if (value == 1) return _DailyQuickPick.breve;
    if (value == 4) return _DailyQuickPick.intenso;
    return _DailyQuickPick.none;
  }

  void _stepTarget(int delta, int total) {
    if (total <= 0) return;
    final current = _dailyTarget ?? _recommendedTarget(total);
    final next = (current + delta).clamp(1, total);
    setState(() {
      _dailyTarget = next;
      _quickPick = _pickForValue(next, total);
    });
  }

  void _setDailyTarget(int value, int total, _DailyQuickPick pick) {
    if (total <= 0) return;
    setState(() {
      _dailyTarget = value.clamp(1, total);
      _quickPick = pick;
    });
  }

  void _renameDeck(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    AppScope.of(context).updateActiveDeck(title: clean);
  }

  void _setDeckIcon(String icon) {
    setState(() => _selectedIcon = icon);
    AppScope.of(context).updateActiveDeck(icon: icon);
  }

  int _difficultyMinutes(int difficulty, int dailyTarget) {
    final perCard = switch (difficulty) {
      0 => 4,
      1 => 5,
      _ => 6,
    };
    if (dailyTarget <= 0) return 0;
    return (dailyTarget * perCard).clamp(perCard, 45);
  }

  void _saveForLater(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión guardada para continuar luego.')),
    );
    Navigator.pushNamed(context, AppRoutes.repasar);
  }

  void _startSession(BuildContext context, MemoryDeckData deck) {
    if (deck.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea tarjetas antes de empezar.')),
      );
      Navigator.pushNamed(context, AppRoutes.especificar);
      return;
    }
    final target =
        (_dailyTarget ?? _recommendedTarget(deck.cards.length)).clamp(
          1,
          deck.cards.length,
        );
    AppScope.of(context).configureSession(
      difficulty: _difficulty,
      dailyTarget: target,
    );
    Navigator.pushNamed(context, '${AppRoutes.flow}/progress-tree');
  }

  @override
  Widget build(BuildContext context) {
    final deck = AppScope.of(context).activeDeck;
    final totalCards = deck.cards.length;
    final dailyTarget = (_dailyTarget ?? _recommendedTarget(totalCards)).clamp(
      totalCards == 0 ? 0 : 1,
      totalCards == 0 ? 0 : totalCards,
    );
    final estimatedDays = totalCards == 0
        ? 0
        : (totalCards / dailyTarget).ceil().clamp(1, 30);
    return ReferencePage(
      active: AppRoutes.repasar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Configurar sesión'),
          Glass(
            color: Colors.transparent,
            gradient: const LinearGradient(
              colors: [Color(0x1AFFFFFF), Color(0x4DFFB400)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                RefColors.pink.withValues(alpha: .4),
                                RefColors.violet.withValues(alpha: .2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: HtmlRefColors.glassBorder,
                            ),
                          ),
                          child: Center(child: GlyphIcon(deck.icon, size: 28)),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: GestureDetector(
                            onTap: () => setState(() => _showIconPicker = true),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: RefColors.primary,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .28),
                                ),
                              ),
                              child: const Icon(Icons.add_rounded, size: 17),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: HtmlRefColors.glassSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: HtmlRefColors.glassBorder,
                              ),
                            ),
                            child: TextField(
                              controller: _deckTitleController,
                              onChanged: _renameDeck,
                              onSubmitted: _renameDeck,
                              onEditingComplete: () =>
                                  _renameDeck(_deckTitleController.text),
                              style: const TextStyle(
                                color: RefColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Nombre del mazo',
                                hintStyle: TextStyle(
                                  color: RefColors.muted,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            totalCards == 0
                                ? 'Agrega tarjetas para estimar la sesión'
                                : '${deck.cards.length} tarjetas · dominarás en ~$estimatedDays días',
                            style: const TextStyle(
                              fontSize: 11,
                              color: RefColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_showIconPicker) ...[
                  const SizedBox(height: 12),
                  Glass(
                    radius: 14,
                    padding: const EdgeInsets.all(10),
                    color: HtmlRefColors.glassSoft,
                    border: Border.all(color: HtmlRefColors.glassBorder),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'ICONO DEL MAZO',
                                style: TextStyle(
                                  color: RefColors.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showIconPicker = false),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_rounded, size: 15),
                                  SizedBox(width: 4),
                                  Text(
                                    'Volver',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final choice in const [
                              ('✝️', Icons.add_rounded),
                              ('📜', Icons.article_rounded),
                              ('🧠', Icons.psychology_rounded),
                              ('✨', Icons.auto_awesome_rounded),
                              ('🎯', Icons.track_changes_rounded),
                              ('⚡', Icons.bolt_rounded),
                            ])
                              GestureDetector(
                                onTap: () => _setDeckIcon(choice.$1),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _selectedIcon == choice.$1
                                        ? RefColors.pink.withValues(alpha: .25)
                                        : HtmlRefColors.glassSoft,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedIcon == choice.$1
                                          ? RefColors.pink
                                          : HtmlRefColors.glassBorder,
                                      width: _selectedIcon == choice.$1
                                          ? 1.6
                                          : 1,
                                    ),
                                  ),
                                  child: Icon(choice.$2, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OptionGroup(
            title: 'Dificultad',
            options: [
              (
                Icons.spa_rounded,
                'Fácil',
                '~${_difficultyMinutes(0, dailyTarget)} min · con pistas',
              ),
              (
                Icons.psychology_alt_rounded,
                'Intermedio',
                '~${_difficultyMinutes(1, dailyTarget)} min · balanceado',
              ),
              (
                Icons.timer_rounded,
                'Experto',
                '~${_difficultyMinutes(2, dailyTarget)} min · intenso',
              ),
            ],
            active: _difficulty,
            onSelect: (index) => setState(() => _difficulty = index),
          ),
          const SizedBox(height: 12),
          Glass(
            color: HtmlRefColors.glassBg,
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Center(
                  child: Text(
                    'CANTIDAD A MEMORIZAR',
                    style: TextStyle(
                      fontSize: 10,
                      color: RefColors.cyan,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    totalCards == 0
                        ? 'Sin tarjetas'
                        : 'Finalizaría en $estimatedDays ${estimatedDays == 1 ? "día" : "días"}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: RefColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _RoundStep(
                                '−',
                                onTap: () => _stepTarget(-1, totalCards),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '$dailyTarget',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _RoundStep(
                                '+',
                                onTap: () => _stepTarget(1, totalCards),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          SizedBox(
                            width: 190,
                            child: RefProgress(
                              totalCards == 0
                                  ? 0
                                  : (dailyTarget / totalCards).clamp(.12, 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 138,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _setDailyTarget(
                              1,
                              totalCards,
                              _DailyQuickPick.breve,
                            ),
                            child: RefChip(
                              '1 · breve',
                              dense: true,
                              color: _quickPick == _DailyQuickPick.breve
                                  ? RefColors.lime
                                  : null,
                              textColor: _quickPick == _DailyQuickPick.breve
                                  ? RefColors.successInk
                                  : RefColors.ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          GestureDetector(
                            onTap: () => _setDailyTarget(
                              _recommendedTarget(totalCards),
                              totalCards,
                              _DailyQuickPick.recomendado,
                            ),
                            child: RefChip(
                              '${_recommendedTarget(totalCards)} · recomendado',
                              dense: true,
                              color: _quickPick == _DailyQuickPick.recomendado
                                  ? RefColors.lime
                                  : null,
                              textColor:
                                  _quickPick == _DailyQuickPick.recomendado
                                  ? RefColors.successInk
                                  : RefColors.ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          GestureDetector(
                            onTap: () => _setDailyTarget(
                              4,
                              totalCards,
                              _DailyQuickPick.intenso,
                            ),
                            child: RefChip(
                              '4 · intenso',
                              dense: true,
                              color: _quickPick == _DailyQuickPick.intenso
                                  ? RefColors.lime
                                  : null,
                              textColor: _quickPick == _DailyQuickPick.intenso
                                  ? RefColors.successInk
                                  : RefColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 14,
                child: GhostButton(
                  'Guardar para luego',
                  onTap: () => _saveForLater(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 10,
                child: Cta(
                  '▶ Empezar',
                  onTap: () => _startSession(context, deck),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  final String title;
  final List<(IconData, String, String)> options;
  final int active;
  final ValueChanged<int>? onSelect;

  const _OptionGroup({
    required this.title,
    required this.options,
    required this.active,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      color: HtmlRefColors.glassBg,
      border: Border.all(color: HtmlRefColors.glassBorder),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: RefColors.muted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect?.call(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: i == active
                            ? RefColors.pink.withValues(alpha: .15)
                            : HtmlRefColors.glassSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: i == active
                              ? RefColors.pink
                              : HtmlRefColors.glassBorder,
                          width: 1.5,
                        ),
                        boxShadow: i == active
                            ? [
                                BoxShadow(
                                  color: RefColors.pink.withValues(alpha: .12),
                                  blurRadius: 0,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            options[i].$1,
                            size: 25,
                            color: i == active ? RefColors.pink : RefColors.ink,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            options[i].$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            options[i].$3,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: RefColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i != options.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundStep extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _RoundStep(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: HtmlRefColors.glassStrong,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HtmlRefColors.glassBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class RepasarScreen extends StatelessWidget {
  const RepasarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final dueCards = store.dueCards;
    final weakCount = dueCards.where((card) => card.retention < 60).length;
    return ReferencePage(
      active: AppRoutes.repasar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Repasar'),
          const _PageHead(
            'Memoria activa',
            'Rescata lo que ya dominaste antes de que se pierda',
          ),
          Glass(
            padding: const EdgeInsets.all(18),
            gradient: LinearGradient(
              colors: [
                RefColors.urgent.withValues(alpha: .22),
                RefColors.sun.withValues(alpha: .12),
              ],
            ),
            border: Border.all(color: RefColors.urgent.withValues(alpha: .35)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RefChip(
                  '⚠ EN RIESGO',
                  dense: true,
                  color: Color(0x33FF5A8A),
                  textColor: Color(0xFFFFB8CC),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: RefColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              RefColors.primary.createShader(bounds),
                          child: Text(
                            '$weakCount tarjetas',
                            style: TextStyle(
                              color: RefColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.18,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' están por caer bajo retención'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Un repaso de 5 minutos ahora las salva de perderse.',
                  style: TextStyle(color: RefColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Cta(
                  '▶ Rescatar ahora · 5 min',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.flashcards),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: const [
                GlyphIcon('✨', size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repaso recomendado',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Empieza por tarjetas débiles · luego mazos',
                        style: TextStyle(fontSize: 11, color: RefColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '›',
                  style: TextStyle(fontSize: 26, color: RefColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: HtmlRefColors.glassSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentTab(
                    'Por tarjeta · ${dueCards.length}',
                    active: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _SegmentTab('Por mazo · ${store.decks.length}'),
                ),
              ],
            ),
          ),
          const SectionHead('⚠ Tarjetas más débiles', action: 'Ver todas'),
          for (final group in _groupReviewCards(_attachDecks(dueCards, store)))
            _ReviewItem(
              group.icon,
              group.front,
              '${group.source} · ${group.totalLapses} ${group.totalLapses == 1 ? "fallo" : "fallos"}',
              '${group.avgRetention}%',
              urgent: group.avgRetention < 60,
              onTap: () => Navigator.pushNamed(context, AppRoutes.flashcards),
            ),
          const SectionHead('Mazos con retención baja'),
          for (final deck in store.decks.take(3))
            _DeckRetention(
              deck.icon,
              deck.title,
              '${deck.weakCount} débiles · ${deck.cards.length} tarjetas',
              deck.retention / 100,
            ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String text;
  final bool active;

  const _SegmentTab(this.text, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? HtmlRefColors.glassStrong : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: active ? Border.all(color: HtmlRefColors.glassBorder) : null,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? RefColors.ink : RefColors.muted,
          ),
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String pct;
  final bool urgent;
  final VoidCallback? onTap;

  const _ReviewItem(
    this.emoji,
    this.title,
    this.subtitle,
    this.pct, {
    this.urgent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: urgent
              ? RefColors.urgent.withValues(alpha: .08)
              : RefColors.glassSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: urgent
                ? RefColors.urgent.withValues(alpha: .4)
                : RefColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: RefColors.glassStrong,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RefColors.border),
              ),
              child: Center(child: GlyphIcon(emoji, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: RefColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _PercentBadge(pct, urgent: urgent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '›',
              style: TextStyle(color: RefColors.muted, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final String pct;
  final bool urgent;

  const _PercentBadge(this.pct, {required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: urgent
            ? RefColors.urgent.withValues(alpha: .18)
            : RefColors.sun.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: urgent
              ? RefColors.urgent.withValues(alpha: .4)
              : RefColors.sun.withValues(alpha: .4),
        ),
      ),
      child: Text(
        pct,
        style: TextStyle(
          color: urgent ? RefColors.urgent : RefColors.sun,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DeckRetention extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final double value;

  const _DeckRetention(this.emoji, this.title, this.subtitle, this.value);

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(12),
      color: RefColors.glassSoft,
      child: Row(
        children: [
          GlyphIcon(emoji, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: RefColors.muted),
                ),
                const SizedBox(height: 8),
                RefProgress(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ComunidadScreen extends StatelessWidget {
  const ComunidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final decks = store.decks;
    return ReferencePage(
      active: AppRoutes.comunidad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Comunidad'),
          const _PageHead(
            'Descubre mazos',
            'Creados por personas que aprenden como tú',
          ),
          Glass(
            radius: 18,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                Icon(Icons.search, size: 20, color: RefColors.muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Buscar por tema, idioma, asignatura...',
                    style: TextStyle(fontSize: 12, color: RefColors.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.45,
            children: const [
              _CategoryTile('🧠', 'Medicina', '184'),
              _CategoryTile('🌍', 'Idiomas', '412'),
              _CategoryTile('🧪', 'Ciencias', '256'),
              _CategoryTile('📜', 'Historia', '130'),
              _CategoryTile('✝️', 'Biblia', '89'),
              _CategoryTile('🎨', 'Arte', '76'),
              _CategoryTile('💻', 'Tech', '208'),
              _CategoryTile('⋯', 'Más', 'Todos'),
            ],
          ),
          const SizedBox(height: 6),
          const SectionHead('Destacado esta semana', action: 'Ver todo'),
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final deck in decks.take(3))
                  _FeaturedDeck(
                    deck.icon,
                    deck.title,
                    '${deck.cards.length} tarjetas · ${deck.retention}% retención',
                    '★ ${(4 + deck.retention / 100).toStringAsFixed(1)}',
                    LinearGradient(
                      colors: [
                        RefColors.pink.withValues(alpha: .22),
                        RefColors.violet.withValues(alpha: .22),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      store.setActiveDeck(deck.id);
                      Navigator.pushNamed(context, AppRoutes.iniciar);
                    },
                  ),
              ],
            ),
          ),
          const SectionHead('Populares', action: 'Filtrar'),
          _DeckGrid(decks: decks),
          const SectionHead('Creadores a seguir', action: 'Ver todos'),
          for (final deck in decks.take(2))
            _Creator(
              deck.title.characters.first.toUpperCase(),
              '${deck.title} · local',
              '${deck.cards.length} tarjetas disponibles',
              '${deck.retention}%',
              cyan: deck.isBible,
            ),
        ],
      ),
    );
  }
}

class _Creator extends StatelessWidget {
  final String initial;
  final String title;
  final String subtitle;
  final String stats;
  final bool cyan;

  const _Creator(
    this.initial,
    this.title,
    this.subtitle,
    this.stats, {
    this.cyan = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Fav(
              initial,
              gradient: cyan ? RefColors.cool : RefColors.primary,
              size: 42,
              online: cyan,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: RefColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              stats,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: RefColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckThumb extends StatelessWidget {
  final String glyph;

  const _DeckThumb(this.glyph);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: HtmlRefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      alignment: Alignment.center,
      child: GlyphIcon(glyph, size: 24),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String count;

  const _CategoryTile(this.emoji, this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      color: const Color(0x10FFFFFF),
      border: Border.all(color: const Color(0x24FFFFFF)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlyphIcon(emoji, size: 21),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: const TextStyle(fontSize: 8.5, color: RefColors.muted),
          ),
        ],
      ),
    );
  }
}

class _FeaturedDeck extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String rating;
  final Gradient gradient;
  final VoidCallback? onTap;

  const _FeaturedDeck(
    this.emoji,
    this.title,
    this.subtitle,
    this.rating,
    this.gradient, {
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 10),
        child: Glass(
          padding: const EdgeInsets.all(16),
          gradient: gradient,
          border: Border.all(color: HtmlRefColors.glassBorder),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -12,
                child: GlyphIcon(
                  emoji,
                  size: 80,
                  color: Colors.white.withValues(alpha: .2),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: RefColors.muted,
                    ),
                  ),
                  const Spacer(),
                  RefChip(
                    rating,
                    dense: true,
                    color: const Color(0x22FFB400),
                    textColor: RefColors.sun,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckGrid extends StatelessWidget {
  final List<MemoryDeckData> decks;

  const _DeckGrid({required this.decks});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: decks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final deck = decks[index];
        return GestureDetector(
          onTap: () {
            AppScope.of(context).setActiveDeck(deck.id);
            Navigator.pushNamed(context, AppRoutes.iniciar);
          },
          // Long-press abre el menú de visibilidad / reportar para que el
          // usuario pueda compartir el mazo o, si lo ve en comunidad, marcarlo.
          onLongPress: () => _showDeckActionsSheet(context, deck),
          child: Glass(
            radius: 16,
            padding: const EdgeInsets.all(8),
            color: const Color(0x10FFFFFF),
            border: Border.all(color: const Color(0x24FFFFFF)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DeckThumb(deck.icon),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: RefColors.sun,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          (4 + deck.retention / 100).toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: RefColors.sun,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  deck.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${deck.cards.length} tarjetas',
                  style: const TextStyle(fontSize: 10, color: RefColors.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AmigosScreen extends StatelessWidget {
  const AmigosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      active: AppRoutes.amigos,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Amigos'),
          const _InviteHero(),
          const _FriendSearch(),
          const _PendingInvite(),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '8 amigos',
                    style: TextStyle(
                      color: RefColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(text: ' · 2 online'),
                ],
              ),
              style: TextStyle(
                fontSize: 11,
                color: RefColors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: .4,
              ),
            ),
          ),
          const _FriendCard(
            initial: 'M',
            name: 'Marco Ruiz · ♕',
            status: 'Sala abierta · Biología',
            badges: ['🔥 Racha 14', '🎓 3 mazos'],
            primaryAction: 'Unirme',
            gradient: RefColors.primary,
            online: true,
            live: true,
          ),
          const _FriendCard(
            initial: 'L',
            name: 'Lucía Pardo',
            status: 'Estudiando Francés · ahora',
            badges: ['🔥 Racha 7'],
            primaryAction: 'Invitar',
            gradient: RefColors.purple,
            online: true,
            live: true,
          ),
          const _FriendCard(
            initial: 'K',
            name: 'Kai Nakamura',
            status: 'Nivel 11 · racha 5d',
            badges: ['📚 Química', '🔥 Racha'],
            primaryAction: 'Invitar',
            gradient: RefColors.cool,
          ),
          const _FriendCard(
            initial: 'S',
            name: 'Sofía Lima',
            status: 'Nivel 14 · racha 21d 🔥',
            badges: ['🌟 Top'],
            primaryAction: 'Invitar',
            gradient: RefColors.primary,
          ),
          const _FriendCard(
            initial: 'R',
            name: 'Raúl Fernández',
            status: 'Nivel 6 · racha 3d',
            badges: [],
            primaryAction: 'Invitar',
            gradient: RefColors.limeGrad,
          ),
        ],
      ),
    );
  }
}

class _InviteHero extends StatelessWidget {
  const _InviteHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.all(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF55C8FF), Color(0xFF7757FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: Colors.transparent),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -44,
              top: -60,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: .22),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const GlyphIcon('🤝', size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crecen juntos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Invita amigos y multipliquen su progreso',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xE6FFFFFF),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '+ Invitar',
                    style: TextStyle(
                      color: Color(0xFF063079),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
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

class _FriendSearch extends StatelessWidget {
  const _FriendSearch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        gradient: LinearGradient(
          colors: [
            RefColors.violet.withValues(alpha: .14),
            RefColors.sun.withValues(alpha: .16),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 19, color: RefColors.muted),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Buscar amigo...',
                style: TextStyle(fontSize: 13, color: RefColors.dim),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: HtmlRefColors.glassStrong,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HtmlRefColors.glassBorder),
              ),
              child: const Row(
                children: [
                  Text(
                    'Todos',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 13,
                    color: RefColors.muted,
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

class _PendingInvite extends StatelessWidget {
  const _PendingInvite();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: const Color(0x18FFB400),
        border: Border.all(color: const Color(0x4DFFB400)),
        child: Row(
          children: [
            const _FriendAvatar('N', gradient: RefColors.primary, size: 36),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nora te invita a ser amiga',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Os conocéis por Sofía',
                    style: TextStyle(fontSize: 10, color: RefColors.muted),
                  ),
                ],
              ),
            ),
            const _MiniButton('Aceptar', primary: true),
            const SizedBox(width: 6),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: HtmlRefColors.glassSoft,
                shape: BoxShape.circle,
                border: Border.all(color: HtmlRefColors.glassBorder),
              ),
              child: const Icon(Icons.close_rounded, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final String initial;
  final String name;
  final String status;
  final List<String> badges;
  final String primaryAction;
  final Gradient gradient;
  final bool online;
  final bool live;

  const _FriendCard({
    required this.initial,
    required this.name,
    required this.status,
    required this.badges,
    required this.primaryAction,
    required this.gradient,
    this.online = false,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.all(14),
        color: const Color(0x12FFFFFF),
        border: Border.all(color: const Color(0x2EFFFFFF)),
        child: Row(
          children: [
            _FriendAvatar(
              initial,
              gradient: gradient,
              size: 46,
              online: online,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      color: live ? RefColors.lime : RefColors.muted,
                      fontWeight: live ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final badge in badges) _FriendBadge(badge),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MiniButton(primaryAction, primary: true),
                const SizedBox(height: 5),
                const _MiniButton('Mensaje'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  final String initial;
  final Gradient gradient;
  final double size;
  final bool online;

  const _FriendAvatar(
    this.initial, {
    required this.gradient,
    this.size = 46,
    this.online = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(size * .32),
            border: Border.all(color: HtmlRefColors.glassBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: size * .34,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (online)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: RefColors.lime,
                shape: BoxShape.circle,
                border: Border.all(color: RefColors.bg, width: 2),
                boxShadow: const [
                  BoxShadow(color: RefColors.lime, blurRadius: 7),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String text;
  final bool primary;

  const _MiniButton(this.text, {this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: primary ? RefColors.limeGrad : null,
        color: primary ? null : HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: primary ? Colors.transparent : HtmlRefColors.glassBorder,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: primary ? RefColors.successInk : RefColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FriendBadge extends StatelessWidget {
  final String text;

  const _FriendBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ReferencePage(
      active: AppRoutes.stats,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Tu progreso'),
          const _StatsPeriodTabs(),
          _StreakHeroCard(store: store),
          _Stat('🎯', '${store.averageRetention}%', 'Retención promedio'),
          _Stat('⚡', '${store.dominatedCards}', 'Tarjetas dominadas'),
          _Stat('🧩', '${store.totalCards}', 'Tarjetas totales'),
        ],
      ),
    );
  }
}

class _StatsPeriodTabs extends StatelessWidget {
  const _StatsPeriodTabs();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        radius: 12,
        padding: const EdgeInsets.all(4),
        color: HtmlRefColors.glassSoft,
        border: Border.all(color: HtmlRefColors.glassBorder),
        child: Row(
          children: const [
            Expanded(child: _PeriodTab('Hoy')),
            Expanded(child: _PeriodTab('Semana', active: true)),
            Expanded(child: _PeriodTab('Mes')),
            Expanded(child: _PeriodTab('Todo')),
          ],
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool active;

  const _PeriodTab(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: active ? HtmlRefColors.glassStrong : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: active ? Border.all(color: HtmlRefColors.glassBorder) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: active ? RefColors.ink : RefColors.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StreakHeroCard extends StatelessWidget {
  final AppStore store;

  const _StreakHeroCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        gradient: LinearGradient(
          colors: [
            RefColors.violet.withValues(alpha: .22),
            RefColors.sun.withValues(alpha: .34),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: HtmlRefColors.glassBorder),
        child: Column(
          children: [
            Text(
              'Tu racha 🔥',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${store.streakDays}',
                  style: const TextStyle(
                    fontSize: 52,
                    height: .95,
                    fontWeight: FontWeight.w900,
                    color: RefColors.sun,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'DÍAS\nSEGUIDOS',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.18,
                    color: RefColors.muted,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StreakMetric('${store.completedCards}', 'TARJETAS HOY'),
                const SizedBox(width: 22),
                _StreakMetric('${store.estimatedPendingMinutes} min', 'TIEMPO'),
                const SizedBox(width: 22),
                _StreakMetric('${store.averageRetention}%', 'ACIERTOS'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakMetric extends StatelessWidget {
  final String value;
  final String label;

  const _StreakMetric(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: RefColors.muted,
            fontWeight: FontWeight.w800,
            letterSpacing: .45,
          ),
        ),
      ],
    );
  }
}

class CooperativoScreen extends StatelessWidget {
  const CooperativoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      active: AppRoutes.amigos,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CoopTopBar(center: '🔒 SALA · 4F2K'),
          const _CoopLobbyHero(),
          const SizedBox(height: 14),
          const _CoopSettingsCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: GhostButton('+ Invitar')),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Cta(
                  'Estoy listo · Empezar →',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.cooperativoJuego),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CooperativoGameScreen extends StatelessWidget {
  const CooperativoGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CoopTopBar(center: 'EN JUEGO · 3/4', live: true),
          const _CoopTeamRow(),
          const SizedBox(height: 14),
          const RefProgress(.48),
          const SizedBox(height: 14),
          const _CoopQuestionCard(),
          const SizedBox(height: 14),
          const _SharedHint(),
          const SizedBox(height: 14),
          const _CoopOption(letter: 'A', text: 'Filtrar impurezas del aire'),
          const SizedBox(height: 10),
          const _CoopOption(
            letter: 'B',
            text: 'Intercambio de gases con la sangre',
            selected: true,
            voter: 'M',
          ),
          const SizedBox(height: 10),
          const _CoopOption(letter: 'C', text: 'Producir mucosidad protectora'),
          const SizedBox(height: 10),
          const _CoopOption(
            letter: 'D',
            text: 'Regular la temperatura corporal',
          ),
          const SizedBox(height: 14),
          const _CoopGameChat(),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: GhostButton('💬 Pedir ayuda')),
              const SizedBox(width: 8),
              Expanded(
                child: Cta(
                  'Confirmar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.cooperativoLogrado,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CooperativoSuccessScreen extends StatelessWidget {
  const CooperativoSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CoopTopBar(center: 'Sala cerrada'),
          const _CoopCelebrateCard(),
          const SizedBox(height: 14),
          const _CoopScoreCard(),
          const SizedBox(height: 14),
          const _CoopShareCard(),
          const SizedBox(height: 14),
          const _CoopRecapCard(),
          const SizedBox(height: 14),
          const _CoopAchievements(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Salir',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.amigos),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Cta(
                  'Otra ronda →',
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.cooperativo,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoopTopBar extends StatelessWidget {
  final String center;
  final bool live;

  const _CoopTopBar({required this.center, this.live = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(),
          Expanded(
            child: Center(
              child: RefChip(
                center,
                dense: true,
                color: live
                    ? RefColors.lime.withValues(alpha: .16)
                    : RefColors.glassStrong,
                textColor: live ? RefColors.lime : RefColors.ink,
              ),
            ),
          ),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _CoopLobbyHero extends StatelessWidget {
  const _CoopLobbyHero();

  @override
  Widget build(BuildContext context) {
    final deck = AppScope.of(context).activeDeck;
    return Glass(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .34),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          RefChip(
            'SALA COOPERATIVA · ${deck.subtitle.toUpperCase()}',
            dense: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlyphIcon(deck.icon, size: 27),
              const SizedBox(width: 7),
              Text(
                deck.title.replaceAll(' · ', '\n'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Turnos rotativos · ${deck.cards.length} tarjetas · ~${(deck.cards.length * 2).clamp(6, 20)} min',
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CoopParticipant('M', 'Marco', 'Listo', host: true, ready: true),
              SizedBox(width: 14),
              _CoopParticipant('A', 'Ana (tú)', 'Listo', ready: true),
              SizedBox(width: 14),
              _CoopParticipant(
                'L',
                'Lucía',
                'Cargando...',
                loading: true,
                gradient: RefColors.purple,
              ),
              SizedBox(width: 14),
              _CoopParticipant('+', 'Invitar', '1 libre', empty: true),
            ],
          ),
          const SizedBox(height: 16),
          const _CoopChat(
            messages: [
              ('M', 'Marco:', '¡Empezamos en 1 min! preparen café ☕'),
              ('L', 'Lucía:', 'lista en 30 seg'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoopParticipant extends StatelessWidget {
  final String initials;
  final String name;
  final String status;
  final bool host;
  final bool ready;
  final bool empty;
  final bool loading;
  final Gradient gradient;

  const _CoopParticipant(
    this.initials,
    this.name,
    this.status, {
    this.host = false,
    this.ready = false,
    this.empty = false,
    this.loading = false,
    this.gradient = RefColors.cool,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: empty ? Colors.transparent : null,
        gradient: empty ? null : gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: host ? RefColors.sun : RefColors.border,
          width: host ? 2 : 1,
          style: empty ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: host
            ? [
                BoxShadow(
                  color: RefColors.sun.withValues(alpha: .36),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: empty ? RefColors.dim : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              if (ready)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: RefColors.lime,
                      shape: BoxShape.circle,
                      border: Border.all(color: RefColors.bg, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: RefColors.successInk,
                      size: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            host ? '$name ♕' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: empty ? RefColors.dim : RefColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: loading ? RefColors.sun : RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopChat extends StatelessWidget {
  final List<(String, String, String)> messages;

  const _CoopChat({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: RefColors.inner)),
      ),
      child: Column(
        children: [
          for (final message in messages) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Fav(
                  message.$1,
                  size: 24,
                  gradient: message.$1 == 'L'
                      ? RefColors.purple
                      : RefColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: RefColors.muted,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: '${message.$2} ',
                          style: const TextStyle(
                            color: RefColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(text: message.$3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RefColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Escribe un mensaje...',
                    style: TextStyle(
                      color: RefColors.dim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: RefColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopSettingsCard extends StatelessWidget {
  const _CoopSettingsCard();

  @override
  Widget build(BuildContext context) {
    final deck = AppScope.of(context).activeDeck;
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONFIGURACIÓN DE LA SALA',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _CoopSettingRow('Mazo', deck.title, 'Cambiar'),
          const _CoopSettingRow(
            'Modo',
            'Todos responden · el grupo avanza junto',
            'Sincro',
          ),
          _CoopSettingRow(
            'Tarjetas',
            '${deck.cards.length} tarjetas seleccionadas',
            '${deck.cards.length}',
          ),
        ],
      ),
    );
  }
}

class _CoopSettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;

  const _CoopSettingRow(this.title, this.subtitle, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: RefColors.inner)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          RefChip(value, dense: true),
        ],
      ),
    );
  }
}

class _CoopTeamRow extends StatelessWidget {
  const _CoopTeamRow();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CoopMate('M', 'Marco', '✓ Respondió', done: true),
          SizedBox(width: 8),
          _CoopMate('A', 'Tú', 'Tu turno...', answering: true),
          SizedBox(width: 8),
          _CoopMate('L', 'Lucía', 'Esperando', gradient: RefColors.purple),
        ],
      ),
    );
  }
}

class _CoopMate extends StatelessWidget {
  final String avatar;
  final String name;
  final String status;
  final bool done;
  final bool answering;
  final Gradient gradient;

  const _CoopMate(
    this.avatar,
    this.name,
    this.status, {
    this.done = false,
    this.answering = false,
    this.gradient = RefColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Fav(avatar, size: 30, gradient: gradient),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: done
                      ? RefColors.lime
                      : answering
                      ? RefColors.sun
                      : RefColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoopQuestionCard extends StatelessWidget {
  const _CoopQuestionCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PREGUNTA 6 / 12',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                'Tu turno · Ana',
                style: TextStyle(
                  color: RefColors.sun,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '¿Cuál es la función principal de los alvéolos pulmonares?',
            style: TextStyle(
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w900,
              letterSpacing: -.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedHint extends StatelessWidget {
  const _SharedHint();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.sun.withValues(alpha: .12),
      border: Border.all(color: RefColors.sun.withValues(alpha: .34)),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marco compartió una pista',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                Text(
                  '"Piensa en qué ocurre entre oxígeno y sangre"',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopOption extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final String? voter;

  const _CoopOption({
    required this.letter,
    required this.text,
    this.selected = false,
    this.voter,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(16),
      color: selected ? RefColors.cyan.withValues(alpha: .14) : RefColors.glass,
      border: Border.all(
        color: selected
            ? RefColors.cyan.withValues(alpha: .52)
            : RefColors.border,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: selected ? RefColors.cyan : RefColors.glassSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? Colors.transparent : RefColors.border,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: selected ? const Color(0xFF003A4A) : RefColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          if (voter != null) Fav(voter!, size: 22),
        ],
      ),
    );
  }
}

class _CoopGameChat extends StatelessWidget {
  const _CoopGameChat();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      radius: 18,
      padding: EdgeInsets.all(14),
      child: _CoopChat(
        messages: [
          ('M', 'Marco:', 'ánimo! la que pensamos ayer'),
          ('L', 'Lucía:', '👍'),
        ],
      ),
    );
  }
}

class _CoopCelebrateCard extends StatelessWidget {
  const _CoopCelebrateCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.fromLTRB(22, 24, 22, 22),
      gradient: RefColors.success,
      border: Border(),
      child: Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 52)),
          SizedBox(height: 6),
          Text(
            '¡Lo lograron juntos!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RefColors.successInk,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '20 tarjetas · 12 min · 85% aciertos',
            style: TextStyle(
              color: RefColors.successInk,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopScoreCard extends StatelessWidget {
  const _CoopScoreCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [RefColors.lime, RefColors.lime, RefColors.glassSoft],
                stops: [0, .85, .85],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: RefColors.bg,
                shape: BoxShape.circle,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '85%',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'ACIERTO',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              children: [
                _CoopScoreRow('Correctas', '17 / 20'),
                _CoopScoreRow('Incorrectas', '3'),
                _CoopScoreRow('Tiempo', '12 min'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopScoreRow extends StatelessWidget {
  final String label;
  final String value;

  const _CoopScoreRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: RefColors.inner)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CoopShareCard extends StatelessWidget {
  const _CoopShareCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Text('📸', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparte el logro del grupo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Imagen o texto · sin cuenta necesaria',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: RefColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Compartir',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopRecapCard extends StatelessWidget {
  const _CoopRecapCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📖 CÓMO LES FUE A LAS TARJETAS',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          _CoopRecapItem(
            '1',
            'Alvéolos · función',
            'Marco · sin errores',
            1,
            '✓ 100%',
          ),
          _CoopRecapItem(
            '2',
            'Bronquios principales',
            'Ana · 1 error',
            .92,
            '✓ 92%',
          ),
          _CoopRecapItem(
            '3',
            'Diafragma · función',
            'Lucía · 2 errores',
            .85,
            '⚡ 85%',
            warn: true,
          ),
          _CoopRecapItem(
            '4',
            'Tráquea · anillos',
            'Marco · sin errores',
            .98,
            '✓ 98%',
          ),
          _CoopRecapItem(
            '5',
            'Intercambio gaseoso',
            'Ana · 3 errores',
            .78,
            '⚡ 78%',
            warn: true,
          ),
        ],
      ),
    );
  }
}

class _CoopRecapItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final double progress;
  final String score;
  final bool warn;

  const _CoopRecapItem(
    this.number,
    this.title,
    this.subtitle,
    this.progress,
    this.score, {
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: RefColors.inner)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RefColors.border),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                RefProgress(
                  progress,
                  gradient: warn
                      ? const LinearGradient(
                          colors: [RefColors.sun, RefColors.urgent],
                        )
                      : RefColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(
            score,
            color: (warn ? RefColors.sun : RefColors.lime).withValues(
              alpha: .14,
            ),
            borderColor: (warn ? RefColors.sun : RefColors.lime).withValues(
              alpha: .38,
            ),
            textColor: warn ? RefColors.sun : RefColors.lime,
          ),
        ],
      ),
    );
  }
}

class _CoopAchievements extends StatelessWidget {
  const _CoopAchievements();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 LOGROS DESBLOQUEADOS HOY',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CoopAchievement(
                  '🤝',
                  'En equipo',
                  '3 sesiones co-op',
                  warm: true,
                ),
                SizedBox(width: 8),
                _CoopAchievement(
                  '💡',
                  'Buena pista',
                  'Ayudaste 2x',
                  warm: true,
                ),
                SizedBox(width: 8),
                _CoopAchievement('🔥', 'Racha 10', '3 días restantes'),
                SizedBox(width: 8),
                _CoopAchievement('🌟', 'Precisión', '90% en 3 sesiones'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopAchievement extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool warm;

  const _CoopAchievement(
    this.icon,
    this.title,
    this.subtitle, {
    this.warm = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: warm ? null : RefColors.glassSoft,
        gradient: warm
            ? LinearGradient(
                colors: [
                  RefColors.sun.withValues(alpha: .18),
                  RefColors.pink.withValues(alpha: .12),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warm ? RefColors.sun.withValues(alpha: .38) : RefColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EjerciciosScreen extends StatefulWidget {
  const EjerciciosScreen({super.key});

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen> {
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final card = store.activeCard;
    final deck = store.activeDeck;
    final progress = deck.cards.isEmpty
        ? 0.0
        : ((store.currentCardIndex + 1) / deck.cards.length).clamp(.08, 1.0);
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ExerciseTimerTopBar(),
          _SessionEntryMeta(
            current: store.currentCardIndex + 1,
            total: deck.cards.length,
          ),
          RefProgress(progress),
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            gradient: LinearGradient(
              colors: [
                RefColors.violet.withValues(alpha: .24),
                RefColors.sun.withValues(alpha: .16),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.title,
                  style: const TextStyle(
                    color: RefColors.sun,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  card.front,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  card.back,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RefColors.ink,
                    fontSize: 15,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _FlowHintCard(
            icon: '🧭',
            text:
                'Primero vas a leer y escuchar el contenido. Después vienen reconstrucción, completar palabras, iniciales y repaso final.',
          ),
          const SizedBox(height: 14),
          _SessionPlanCard(total: deck.cards.length),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Quiz premium',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Cta(
                  'Empezar estudio →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/01-escuchar',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseTimerTopBar extends StatelessWidget {
  const _ExerciseTimerTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: RefColors.glassStrong,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: RefColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: RefColors.pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      '02:14',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _SessionEntryMeta extends StatelessWidget {
  final int current;
  final int total;

  const _SessionEntryMeta({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total == 0 ? 'SESIÓN SIN TARJETAS' : 'Ítem $current de $total',
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const _ExerciseXpChip(),
        ],
      ),
    );
  }
}

class _SessionPlanCard extends StatelessWidget {
  final int total;

  const _SessionPlanCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(14),
      color: RefColors.glassSoft,
      child: Column(
        children: [
          _PlanRow('1', 'Absorber', 'Lee y escucha el contenido real'),
          const SizedBox(height: 8),
          _PlanRow('2', 'Reconstruir', 'Ordena bloques y completa palabras'),
          const SizedBox(height: 8),
          _PlanRow('3', 'Verificar', 'Quiz y mini-review al final'),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String n;
  final String title;
  final String subtitle;

  const _PlanRow(this.n, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: RefColors.glassStrong,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RefColors.border),
          ),
          child: Text(
            n,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: RefColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseXpChip extends StatelessWidget {
  const _ExerciseXpChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RefColors.glassStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RefColors.border),
      ),
      child: const Row(
        children: [
          Text('⭐', style: TextStyle(fontSize: 12)),
          SizedBox(width: 7),
          Text(
            '+120',
            style: TextStyle(
              color: RefColors.sun,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            ' XP',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ExerciseQuestionBlock extends StatelessWidget {
  final String contextLabel;
  final String question;

  const _ExerciseQuestionBlock({
    this.contextLabel = 'ANATOMÍA · SISTEMA MUSCULAR',
    this.question =
        '¿Cuál de los siguientes músculos flexiona el antebrazo sobre el brazo?',
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contextLabel,
            style: const TextStyle(
              color: RefColors.sun,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: const TextStyle(
              fontSize: 22,
              height: 1.28,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseOption extends StatelessWidget {
  final String letter;
  final String title;
  final String? tip;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  const _ExerciseOption({
    required this.letter,
    required this.title,
    this.tip,
    this.selected = false,
    this.correct = false,
    this.wrong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = correct
        ? RefColors.lime
        : wrong
        ? RefColors.urgent
        : selected
        ? RefColors.cyan
        : RefColors.border;
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(16),
        color: (correct || wrong || selected)
            ? accent.withValues(alpha: .14)
            : RefColors.glass,
        border: Border.all(color: accent.withValues(alpha: .5)),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (correct || wrong || selected)
                    ? accent
                    : RefColors.glassSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (correct || wrong || selected)
                      ? Colors.transparent
                      : RefColors.border,
                ),
              ),
              child: Center(
                child: correct || wrong
                    ? Icon(
                        correct ? Icons.check_rounded : Icons.close_rounded,
                        color: correct ? const Color(0xFF153A18) : Colors.white,
                        size: 18,
                      )
                    : Text(
                        letter,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF003A4A)
                              : RefColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (tip != null)
                    Text(
                      tip!,
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
        ),
      ),
    );
  }
}

class ExerciseFlowData {
  final String slug;
  final String title;
  final String subtitle;

  const ExerciseFlowData(this.slug, this.title, this.subtitle);
}

const flowScreens = [
  ExerciseFlowData('01-escuchar', 'Escuchar', 'Primero absorbe la idea'),
  ExerciseFlowData('02-lectura-frag', 'Lectura fragmentada', 'Divide y repite'),
  ExerciseFlowData('03-leer-voz', 'Leer en voz', 'Activa memoria auditiva'),
  ExerciseFlowData('04-escuchar-voz', 'Escuchar voz', 'Reconoce sin mirar'),
  ExerciseFlowData('05-bloques', 'Bloques', 'Ordena piezas clave'),
  ExerciseFlowData('06-completar-n1', 'Completar N1', 'Recuerdo con apoyo'),
  ExerciseFlowData(
    '07-primera-letra-n1',
    'Primera letra N1',
    'Menos pistas, más memoria',
  ),
  ExerciseFlowData('08-voz-guiada', 'Voz guiada', 'Responde en voz alta'),
  ExerciseFlowData('09-quiz', 'Quiz', 'Elige la respuesta correcta'),
  ExerciseFlowData('10-completar-n2', 'Completar N2', 'Recuerdo más fuerte'),
  ExerciseFlowData('11-primera-letra-n2', 'Primera letra N2', 'Casi sin ayuda'),
  ExerciseFlowData('12-completar-n3', 'Completado N3', 'Más huecos visibles'),
  ExerciseFlowData(
    '13-primera-letra-n3',
    'Iniciales N3',
    'Todas las pistas ocultas',
  ),
  ExerciseFlowData(
    '15-banco-completo',
    'Banco completo',
    'Vacía el banco eligiendo bien',
  ),
  ExerciseFlowData(
    '16-niebla',
    'Niebla',
    'Recita mientras se nubla más',
  ),
  ExerciseFlowData('14-voz-final', 'Voz final', 'Demuestra dominio'),
  ExerciseFlowData('mini-review', 'Mini review', 'Cierre rápido'),
  ExerciseFlowData('final-review', 'Review final', 'Resumen de sesión'),
];

class ExerciseFlowScreen extends StatelessWidget {
  final ExerciseFlowData data;

  const ExerciseFlowScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.slug == '09-quiz' && !AppScope.of(context).isPremium) {
      return const PremiumScreen();
    }
    return _RealExerciseFlowScreen(data: data);
    // ignore: dead_code
    if (data.slug == '01-escuchar') return const _ListenFlowScreen();
    if (data.slug == '02-lectura-frag') {
      return const _FragmentedReadingFlowScreen();
    }
    if (data.slug == '03-leer-voz') return const _ReadAloudFlowScreen();
    if (data.slug == '04-escuchar-voz') {
      return const _ListenOwnVoiceFlowScreen();
    }
    if (data.slug == '05-bloques') return const _BlocksFlowScreen();
    if (data.slug == '06-completar-n1') return const _CompleteN1FlowScreen();
    if (data.slug == '07-primera-letra-n1') {
      return const _FirstLetterFlowScreen(level: 1);
    }
    if (data.slug == '08-voz-guiada') return const _GuidedVoiceFlowScreen();
    if (data.slug == '09-quiz') return const _QuizFlowScreen();
    if (data.slug == '10-completar-n2') return const _CompleteN2FlowScreen();
    if (data.slug == '11-primera-letra-n2') {
      return const _FirstLetterFlowScreen(level: 2);
    }
    if (data.slug == '12-voz-final') return const _FinalVoiceFlowScreen();
    if (data.slug == 'mini-review') return const _MiniReviewFlowScreen();
    if (data.slug == 'final-review') return const _FinalReviewFlowScreen();

    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExerciseTopBar(center: data.title),
          _PageHead(data.title, data.subtitle),
          const _QuestionCard(
            ctx: 'ANATOMÍA · SISTEMA MUSCULAR',
            turn: '2/4',
            question: 'Bíceps braquial: principal flexor del codo.',
            options: [
              ('A', 'Lo recuerdo con seguridad', true),
              ('B', 'Necesito una pista más', false),
            ],
          ),
        ],
      ),
    );
  }
}

class _RealExerciseFlowScreen extends StatefulWidget {
  final ExerciseFlowData data;

  const _RealExerciseFlowScreen({required this.data});

  @override
  State<_RealExerciseFlowScreen> createState() =>
      _RealExerciseFlowScreenState();
}

enum _QuizQuestionType { frontToBack, backToFront }

class _QuizRound {
  final MemoryCardData target;
  final _QuizQuestionType type;
  final List<MemoryCardData> options;
  int? selectedIdx;

  _QuizRound({required this.target, required this.type, required this.options});

  bool get answered => selectedIdx != null;
  bool get correct =>
      selectedIdx != null && options[selectedIdx!].id == target.id;
}

class _RealExerciseFlowScreenState extends State<_RealExerciseFlowScreen> {
  bool _checked = false;
  int _fragmentVisibleWords = 8;
  String? _blockOrderCardId;
  List<int> _blockOrderIndexes = [];
  int? _selectedBlockPosition;
  String? _completionCardId;
  int _completionLevel = 1;
  List<String> _completionTargets = [];
  List<String?> _completionAnswers = [];
  int _activeCompletionIndex = 0;
  int _completionMistakes = 0;
  int _completionSeed = 1;
  Timer? _completionTimer;
  int _completionSecondsLeft = 0;
  bool _completionLost = false;
  String? _letterCardId;
  int _letterLevel = 1;
  List<String> _letterTargets = [];
  List<String?> _letterAnswers = [];
  int _activeLetterIndex = 0;
  int _letterMistakes = 0;
  Timer? _letterTimer;
  int _letterSecondsLeft = 0;
  bool _letterLost = false;

  String? _quizCardId;
  List<_QuizRound> _quizRounds = [];
  int _quizRoundIndex = 0;
  int _quizScore = 0;

  String? _bankCardId;
  List<String> _bankTargets = [];
  List<String?> _bankAnswers = [];
  List<String> _bankAvailable = [];
  final Set<String> _bankRemoving = <String>{};
  int _bankActiveIndex = 0;
  int _bankMistakes = 0;
  int _bankPartIndex = 0;
  static const int _bankPartSize = 10;
  static const int _bankSplitThreshold = 15;

  // Shared timestamp for the most recent wrong attempt across non-voice
  // exercises (bank/letter/completion). Used to drive a red-flash effect.
  int? _lastNonVoiceWrongAt;
  void _flagNonVoiceWrong() {
    _lastNonVoiceWrongAt = DateTime.now().millisecondsSinceEpoch;
  }
  bool _nonVoiceWrongRecent() {
    final ts = _lastNonVoiceWrongAt;
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < 700;
  }

  String? _fogCardId;
  int _fogRound = 0;
  bool _fogFinished = false;

  @override
  void dispose() {
    _completionTimer?.cancel();
    _letterTimer?.cancel();
    super.dispose();
  }

  /// Seconds-per-target for timed levels. N3 is faster (less time per hueco).
  static const double _completionSecondsPerTargetN2 = 5.0;
  static const double _completionSecondsPerTargetN3 = 2.8;
  static const double _letterSecondsPerTargetN2 = 5.0;
  static const double _letterSecondsPerTargetN3 = 2.8;

  int _completionTimeFor(int level, int targetCount) {
    if (level <= 1 || targetCount <= 0) return 0;
    final perTarget = level >= 3
        ? _completionSecondsPerTargetN3
        : _completionSecondsPerTargetN2;
    final raw = (targetCount * perTarget).round();
    // Hard floor / ceiling so very short or very long verses stay reasonable.
    return raw.clamp(level >= 3 ? 25 : 35, 180);
  }

  int _letterTimeFor(int level, int targetCount) {
    if (level <= 1 || targetCount <= 0) return 0;
    final perTarget = level >= 3
        ? _letterSecondsPerTargetN3
        : _letterSecondsPerTargetN2;
    final raw = (targetCount * perTarget).round();
    return raw.clamp(level >= 3 ? 25 : 35, 180);
  }

  String _formatMmSs(int totalSeconds) {
    final s = totalSeconds.clamp(0, 9999);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  void _startCompletionTimer(int seconds) {
    _completionTimer?.cancel();
    _completionSecondsLeft = seconds;
    _completionLost = false;
    if (seconds <= 0) return;
    _completionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _completionSecondsLeft -= 1;
        if (_completionSecondsLeft <= 0) {
          _completionSecondsLeft = 0;
          _completionLost = true;
          timer.cancel();
        }
      });
    });
  }

  void _stopCompletionTimerOnSuccess() {
    if (_completionTimer != null) {
      _completionTimer!.cancel();
      _completionTimer = null;
    }
  }

  void _retryCompletion() {
    setState(() {
      _completionCardId = null;
      _completionLost = false;
    });
  }

  void _startLetterTimer(int seconds) {
    _letterTimer?.cancel();
    _letterSecondsLeft = seconds;
    _letterLost = false;
    if (seconds <= 0) return;
    _letterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _letterSecondsLeft -= 1;
        if (_letterSecondsLeft <= 0) {
          _letterSecondsLeft = 0;
          _letterLost = true;
          timer.cancel();
        }
      });
    });
  }

  void _stopLetterTimerOnSuccess() {
    if (_letterTimer != null) {
      _letterTimer!.cancel();
      _letterTimer = null;
    }
  }

  void _retryLetter() {
    setState(() {
      _letterCardId = null;
      _letterLost = false;
    });
  }

  void _ensureBankState(String cardId, String text) {
    if (_bankCardId == cardId) return;
    _bankCardId = cardId;
    _bankTargets = _studyWords(text);
    _bankAnswers = List<String?>.filled(_bankTargets.length, null);
    final cleanRegex = RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]');
    final cleanWords = _bankTargets
        .map((w) => w.replaceAll(cleanRegex, ''))
        .where((w) => w.isNotEmpty)
        .toList();
    final rng = math.Random(DateTime.now().microsecondsSinceEpoch);
    _bankAvailable = [...cleanWords]..shuffle(rng);
    _bankActiveIndex = 0;
    _bankMistakes = 0;
    _bankPartIndex = 0;
    _bankRemoving.clear();
    _checked = false;
  }

  bool _bankIsSplit() => _bankTargets.length > _bankSplitThreshold;

  int _bankPartCount() {
    if (!_bankIsSplit()) return 1;
    return ((_bankTargets.length + _bankPartSize - 1) ~/ _bankPartSize);
  }

  (int, int) _bankPartRange([int? part]) {
    final p = part ?? _bankPartIndex;
    if (!_bankIsSplit()) return (0, _bankTargets.length);
    final start = p * _bankPartSize;
    final end = ((p + 1) * _bankPartSize).clamp(0, _bankTargets.length);
    return (start, end);
  }

  bool _bankPartComplete([int? part]) {
    final (start, end) = _bankPartRange(part);
    if (end <= start) return false;
    for (var i = start; i < end; i++) {
      final answer = _bankAnswers[i];
      if (answer == null || !_sameAnswer(answer, _bankTargets[i])) return false;
    }
    return true;
  }

  bool _bankComplete() {
    if (_bankTargets.isEmpty) return false;
    for (var i = 0; i < _bankTargets.length; i++) {
      final answer = _bankAnswers[i];
      if (answer == null || !_sameAnswer(answer, _bankTargets[i])) return false;
    }
    return true;
  }

  void _selectBankWord(String word) {
    if (_bankTargets.isEmpty || _bankComplete()) return;
    if (_bankRemoving.contains(word)) return;
    final (partStart, partEnd) = _bankPartRange();
    // Clamp the active blank to the current part — if the active index drifted
    // to a later part, snap it back to the first unfilled blank in this part.
    var idx = _bankActiveIndex;
    if (idx < partStart || idx >= partEnd || _bankAnswers[idx] != null) {
      idx = -1;
      for (var i = partStart; i < partEnd; i++) {
        if (_bankAnswers[i] == null) {
          idx = i;
          break;
        }
      }
      if (idx == -1) return;
      _bankActiveIndex = idx;
    }
    final correct = _sameAnswer(word, _bankTargets[idx]);
    if (correct) {
      setState(() {
        _bankAnswers[idx] = word;
        _bankRemoving.add(word);
        // Find next unfilled blank inside the current part.
        var next = -1;
        for (var i = partStart; i < partEnd; i++) {
          if (_bankAnswers[i] == null) {
            next = i;
            break;
          }
        }
        if (next >= 0) _bankActiveIndex = next;
        HapticFeedback.lightImpact();
      });
      // Hold the chip in "removing" state long enough for the fade+shrink
      // animation to play, then drop it from the available list.
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        setState(() {
          final removeAt =
              _bankAvailable.indexWhere((w) => _sameAnswer(w, word));
          if (removeAt >= 0) _bankAvailable.removeAt(removeAt);
          _bankRemoving.remove(word);
          if (_bankPartComplete()) {
            if (_bankPartIndex + 1 < _bankPartCount()) {
              // Advance to next part: highlight the next part's first blank.
              _bankPartIndex += 1;
              final (nextStart, _) = _bankPartRange();
              _bankActiveIndex = nextStart;
              HapticFeedback.lightImpact();
            } else {
              HapticFeedback.heavyImpact();
              _autoAdvanceBank();
            }
          }
        });
      });
    } else {
      setState(() {
        _bankMistakes += 1;
        _flagNonVoiceWrong();
        HapticFeedback.mediumImpact();
      });
      _scheduleFlashRebuild();
    }
  }

  void _scheduleFlashRebuild() {
    Future<void>.delayed(const Duration(milliseconds: 720), () {
      if (mounted) setState(() {});
    });
  }

  void _autoAdvanceBank() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = AppScope.of(context);
      store.markExerciseStepCompleted('15-banco-completo');
      Navigator.push(
        context,
        AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
      );
    });
  }

  void _activateBankBlank(int index) {
    if (index < 0 || index >= _bankTargets.length) return;
    if (_bankAnswers[index] != null) return;
    final (partStart, partEnd) = _bankPartRange();
    if (index < partStart || index >= partEnd) return;
    setState(() => _bankActiveIndex = index);
  }

  void _ensureFogState(String cardId) {
    if (_fogCardId == cardId) return;
    _fogCardId = cardId;
    _fogRound = 0;
    _fogFinished = false;
  }

  void _onFogRoundCompleted() {
    setState(() {
      if (_fogRound >= 2) {
        _fogFinished = true;
        HapticFeedback.heavyImpact();
      } else {
        _fogRound += 1;
        HapticFeedback.lightImpact();
      }
    });
  }

  void _revealFragment(String slug, int totalWords) {
    if (totalWords <= 0) return;
    setState(() {
      _fragmentVisibleWords = (_fragmentVisibleWords + 8).clamp(1, totalWords);
      if (_fragmentVisibleWords >= totalWords) {
        AppScope.of(context).markExerciseStepCompleted(slug);
      }
    });
  }

  bool _completionCorrect(String slug, MemoryCardData card) {
    _ensureCompletionState(card.id, card.back, _completionLevelForSlug(slug));
    return _completionComplete();
  }

  bool _letterCorrect(String slug, MemoryCardData card) {
    _ensureLetterState(card.id, card.back, _letterLevelForSlug(slug));
    return _letterComplete();
  }

  bool _hasCompletionInput() => _completionAnswers.any(
    (answer) => answer != null && answer.trim().isNotEmpty,
  );

  bool _hasLetterInput() => _letterAnswers.any((answer) => answer != null);

  bool _quizCorrect(MemoryCardData card, MemoryDeckData deck) {
    if (_quizCardId != card.id || _quizRounds.isEmpty) return false;
    return _quizPassed;
  }

  /// Llamado al terminar el último paso (voz final). Notifica al store que
  /// la tarjeta actual quedó completa y decide a dónde ir según el target
  /// diario de la sesión: siguiente tarjeta o review final.
  void _completeSessionCard(
    BuildContext context,
    AppStore store, {
    required bool correct,
  }) {
    final keepGoing = store.advanceToNextSessionCard(correct: correct);
    if (!mounted) return;
    if (keepGoing) {
      // Reset estado UI per-tarjeta (banco, completar, niebla, etc.).
      setState(() {
        _completionCardId = null;
        _letterCardId = null;
        _bankCardId = null;
        _fogCardId = null;
        _quizCardId = null;
        _blockOrderCardId = null;
        _checked = false;
      });
      Navigator.pushNamedAndRemoveUntil(
        context,
        '${AppRoutes.flow}/progress-tree',
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1600),
          content: Text(
            'Tarjeta ${store.sessionCardsCompleted} de ${store.sessionDailyTarget} · siguiente',
          ),
        ),
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '${AppRoutes.flow}/final-review',
        (route) => route.isFirst,
      );
    }
  }

  bool _canAdvanceAnsweredStep(
    String slug,
    MemoryCardData card,
    MemoryDeckData deck,
  ) {
    if (slug == '05-bloques') return _blocksAreCorrect();
    if (_isCompletionSlug(slug)) {
      return _completionCorrect(slug, card);
    }
    if (_isFirstLetterSlug(slug)) {
      return _letterCorrect(slug, card);
    }
    if (slug == '09-quiz') {
      if (_quizRounds.isEmpty) return false;
      if (!_quizFinished) {
        return _quizRounds[_quizRoundIndex].answered;
      }
      return true;
    }
    if (_isWordBankSlug(slug)) return _bankComplete();
    if (_isFogSlug(slug)) return _fogFinished;
    return true;
  }

  void _ensureBlockOrder(String cardId, List<String> blocks) {
    if (_blockOrderCardId == cardId &&
        _blockOrderIndexes.length == blocks.length) {
      return;
    }
    _blockOrderCardId = cardId;
    if (blocks.length < 2) {
      _blockOrderIndexes = List.generate(blocks.length, (index) => index);
    } else {
      final rng = math.Random();
      var shuffled = List<int>.generate(blocks.length, (i) => i);
      do {
        shuffled.shuffle(rng);
      } while (_isIdentity(shuffled));
      _blockOrderIndexes = shuffled;
    }
    _selectedBlockPosition = null;
    _checked = false;
  }

  bool _isIdentity(List<int> order) {
    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) return false;
    }
    return true;
  }

  void _moveBlock(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final movedIndex = _blockOrderIndexes.removeAt(oldIndex);
      _blockOrderIndexes.insert(newIndex, movedIndex);
      _selectedBlockPosition = null;
      _checked = true;
    });
  }

  void _selectBlockDestination(int targetIndex) {
    final selectedPosition = _selectedBlockPosition;
    if (selectedPosition == null) return;
    _moveBlock(selectedPosition, targetIndex);
  }

  void _toggleSelectedBlock(int index) {
    setState(() {
      _selectedBlockPosition = _selectedBlockPosition == index ? null : index;
    });
  }

  int _correctBlockCount() {
    var count = 0;
    for (var index = 0; index < _blockOrderIndexes.length; index++) {
      if (_blockOrderIndexes[index] == index) count += 1;
    }
    return count;
  }

  bool _blocksAreCorrect() {
    return _blockOrderIndexes.isNotEmpty &&
        _correctBlockCount() == _blockOrderIndexes.length;
  }

  void _ensureCompletionState(String cardId, String text, int level) {
    if (_completionCardId == cardId && _completionLevel == level) return;
    _completionCardId = cardId;
    _completionLevel = level;
    _completionTargets = _completionTargetsFor(text, level: level);
    _completionAnswers = List<String?>.filled(_completionTargets.length, null);
    _activeCompletionIndex = 0;
    _completionMistakes = 0;
    _completionSeed = DateTime.now().microsecondsSinceEpoch;
    _checked = false;
    final seconds = _completionTimeFor(level, _completionTargets.length);
    _startCompletionTimer(seconds);
  }

  bool _completionComplete() {
    if (_completionTargets.isEmpty) return false;
    for (var index = 0; index < _completionTargets.length; index++) {
      final answer = _completionAnswers[index];
      if (answer == null || !_sameAnswer(answer, _completionTargets[index])) {
        return false;
      }
    }
    return true;
  }

  void _selectCompletionWord(String word) {
    if (_completionTargets.isEmpty || _completionComplete()) return;
    if (_completionLost) return;
    final currentIndex = _activeCompletionIndex.clamp(
      0,
      _completionTargets.length - 1,
    );
    final correct = _sameAnswer(word, _completionTargets[currentIndex]);
    setState(() {
      _checked = true;
      _completionSeed = DateTime.now().microsecondsSinceEpoch;
      if (correct) {
        _completionAnswers[currentIndex] = word;
        final nextIndex = _completionAnswers.indexWhere(
          (answer) => answer == null || answer.trim().isEmpty,
        );
        if (nextIndex >= 0) _activeCompletionIndex = nextIndex;
        if (_completionComplete()) _stopCompletionTimerOnSuccess();
      } else {
        _completionMistakes += 1;
        _flagNonVoiceWrong();
        HapticFeedback.mediumImpact();
      }
    });
    if (!correct) _scheduleFlashRebuild();
  }

  void _activateCompletionBlank(int index) {
    if (index < 0 || index >= _completionTargets.length) return;
    if (_completionAnswers[index] != null) return;
    setState(() => _activeCompletionIndex = index);
  }

  void _ensureLetterState(String cardId, String text, int level) {
    if (_letterCardId == cardId && _letterLevel == level) return;
    _letterCardId = cardId;
    _letterLevel = level;
    _letterTargets = _firstLetterTargets(text, level: level);
    _letterAnswers = List<String?>.filled(_letterTargets.length, null);
    _activeLetterIndex = 0;
    _letterMistakes = 0;
    _checked = false;
    final seconds = _letterTimeFor(level, _letterTargets.length);
    _startLetterTimer(seconds);
  }

  bool _letterComplete() {
    if (_letterTargets.isEmpty) return false;
    for (var index = 0; index < _letterTargets.length; index++) {
      final answer = _letterAnswers[index];
      if (answer == null || !_sameAnswer(answer, _letterTargets[index])) {
        return false;
      }
    }
    return true;
  }

  void _selectFirstLetter(String letter) {
    if (_letterTargets.isEmpty || _letterComplete()) return;
    if (_letterLost) return;
    final currentIndex = _activeLetterIndex.clamp(0, _letterTargets.length - 1);
    final target = _letterTargets[currentIndex];
    final correct = _sameAnswer(letter, target.substring(0, 1));
    setState(() {
      _checked = true;
      if (correct) {
        _letterAnswers[currentIndex] = target;
        final nextIndex = _letterAnswers.indexWhere((answer) => answer == null);
        if (nextIndex >= 0) _activeLetterIndex = nextIndex;
        if (_letterComplete()) _stopLetterTimerOnSuccess();
      } else {
        _letterMistakes += 1;
        _flagNonVoiceWrong();
        HapticFeedback.mediumImpact();
      }
    });
    if (!correct) _scheduleFlashRebuild();
  }

  void _ensureQuizRounds(MemoryDeckData deck, MemoryCardData card) {
    if (_quizCardId == card.id && _quizRounds.isNotEmpty) return;
    _quizCardId = card.id;
    _quizRoundIndex = 0;
    _quizScore = 0;
    _quizRounds = _buildQuizRounds(deck, card);
  }

  List<_QuizRound> _buildQuizRounds(
    MemoryDeckData deck,
    MemoryCardData activeCard,
  ) {
    final rng = math.Random(
      activeCard.id.hashCode ^ DateTime.now().millisecondsSinceEpoch,
    );
    final rounds = <_QuizRound>[];
    final allCards = [
      activeCard,
      ...deck.cards.where((c) => c.id != activeCard.id),
    ];
    final usedTargets = <String>{};
    final shuffledPool = [...allCards]..shuffle(rng);
    final targets = <MemoryCardData>[activeCard];
    usedTargets.add(activeCard.id);
    for (final c in shuffledPool) {
      if (targets.length >= 5) break;
      if (usedTargets.contains(c.id)) continue;
      targets.add(c);
      usedTargets.add(c.id);
    }
    while (targets.length < 5) {
      targets.add(activeCard);
    }
    for (var i = 0; i < 5; i++) {
      final target = targets[i];
      final type = i.isEven
          ? _QuizQuestionType.frontToBack
          : _QuizQuestionType.backToFront;
      final distractorPool = allCards.where((c) => c.id != target.id).toList()
        ..shuffle(rng);
      final distractors = distractorPool.take(3).toList();
      while (distractors.length < 3) {
        distractors.add(
          MemoryCardData(
            id: 'placeholder-${distractors.length}-${target.id}',
            front: 'Opción aproximada',
            back: _firstWords(target.back, 4),
            source: 'Placeholder',
            icon: target.icon,
          ),
        );
      }
      final options = [target, ...distractors]..shuffle(rng);
      rounds.add(_QuizRound(target: target, type: type, options: options));
    }
    return rounds;
  }

  void _selectQuizOption(int idx) {
    if (_quizRoundIndex >= _quizRounds.length) return;
    final round = _quizRounds[_quizRoundIndex];
    if (round.answered) return;
    HapticFeedback.selectionClick();
    setState(() {
      round.selectedIdx = idx;
      if (round.correct) _quizScore += 1;
    });
    if (round.correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _advanceQuizRound() {
    if (_quizRoundIndex < _quizRounds.length - 1) {
      setState(() => _quizRoundIndex += 1);
    }
  }

  void _resetQuiz() {
    setState(() {
      _quizCardId = null;
      _quizRounds = [];
      _quizRoundIndex = 0;
      _quizScore = 0;
    });
  }

  bool get _quizFinished =>
      _quizRounds.isNotEmpty &&
      _quizRoundIndex == _quizRounds.length - 1 &&
      _quizRounds.last.answered;

  bool get _quizPassed => _quizFinished && _quizScore >= 3;

  void _activateLetterBlank(int index) {
    if (index < 0 || index >= _letterTargets.length) return;
    if (_letterAnswers[index] != null) return;
    setState(() => _activeLetterIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final card = store.activeCard;
    final deck = store.activeDeck;
    final slug = widget.data.slug;
    if (slug == 'final-review') return _RealFinalReview(store: store);
    if (slug == 'mini-review') return _RealPairingReview(store: store);

    final steps = _sessionFlowSteps(store);
    final stepIndex = steps.indexWhere((step) => step.slug == slug);
    final step = stepIndex < 0 ? _flowStepNumber(slug) : stepIndex + 1;
    final totalSteps = steps.length;
    if (slug == '02-lectura-frag' && store.isExerciseStepCompleted(slug)) {
      _fragmentVisibleWords = _studyWords(card.back).length;
    }
    return ReferencePage(
      showBottomNav: false,
      scrollable:
          slug != '01-escuchar' &&
          slug != '08-voz-guiada' &&
          !_isFinalVoiceSlug(slug), // Allow voice/listen steps to expand
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlowStepHeader(
            step: '$step',
            totalSteps: totalSteps,
            title: _realStepTitle(slug),
            progress: step.clamp(1, totalSteps),
          ),
          if (slug == '01-escuchar' ||
              slug == '08-voz-guiada' ||
              _isFinalVoiceSlug(slug))
            Expanded(
              child: _RedFlash(
                active: _nonVoiceWrongRecent(),
                child: _realExerciseBody(context, store, card, deck, slug),
              ),
            )
          else
            _RedFlash(
              active: _nonVoiceWrongRecent(),
              child: _realExerciseBody(context, store, card, deck, slug),
            ),
          const SizedBox(height: 14),
          _realExerciseFooter(context, store, card, deck, slug),
        ],
      ),
    );
  }

  Widget _realExerciseBody(
    BuildContext context,
    AppStore store,
    MemoryCardData card,
    MemoryDeckData deck,
    String slug,
  ) {
    if (slug == '01-escuchar') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ListenAudioCard(
              onCompleted: () => store.markExerciseStepCompleted(slug),
            ),
          ),
        ],
      );
    }

    if (slug == '02-lectura-frag') {
      final totalWords = _studyWords(card.back).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressiveFragmentCard(
            visibleWords: _fragmentVisibleWords,
            onTap: () => _revealFragment(slug, totalWords),
          ),
        ],
      );
    }

    if (slug == '03-leer-voz') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadAloudPracticeCard(
            targetText: card.back,
            source: card.front,
            onCompleted: (recognized, audioPath) {
              store.saveVoiceReadForCurrentCard(recognized);
              if (audioPath != null) {
                store.saveVoiceAudioPathForCurrentCard(audioPath);
              }
              store.markExerciseStepCompleted(slug);
            },
          ),
        ],
      );
    }

    if (slug == '04-escuchar-voz') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ListenOwnVoicePracticeCard(
            originalText: card.back,
            voiceText: store.voiceReadForCurrentCard(),
            audioPath: store.voiceAudioPathForCurrentCard(),
            source: card.front,
            onCompleted: () => store.markExerciseStepCompleted(slug),
          ),
        ],
      );
    }

    if (slug == '08-voz-guiada' || _isFinalVoiceSlug(slug)) {
      final hidden = _isFinalVoiceSlug(slug);
      return _RecitationStep(
        targetText: card.back,
        finalMode: hidden,
        colorMode: hidden ? _ListeningColorMode.pink : _ListeningColorMode.blue,
        onCompleted: (passed) {
          store.markExerciseStepCompleted(slug);
          if (hidden) store.answerCurrentCard(passed);
        },
      );
    }

    if (slug == '05-bloques') {
      final blocks = _orderedBlocks(card.back);
      _ensureBlockOrder(card.id, blocks);
      final selectingDestination = _selectedBlockPosition != null;
      final hasInteracted = _checked || selectingDestination;
      final correctCount = hasInteracted ? _correctBlockCount() : 0;
      final allCorrect = _blocksAreCorrect();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Glass(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: hasInteracted
                            ? '$correctCount / ${blocks.length}'
                            : '${blocks.length} bloques',
                        style: const TextStyle(
                          color: RefColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(text: hasInteracted ? ' correctos' : ''),
                    ],
                  ),
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                RefChip(
                  hasInteracted && allCorrect
                      ? 'Correcto'
                      : selectingDestination
                      ? 'Elige destino'
                      : 'Toca un bloque',
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Glass(
            padding: const EdgeInsets.all(14),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final t = Curves.easeOutCubic.transform(animation.value);
                    return Transform.scale(
                      scale: 1 + 0.06 * t,
                      child: Material(
                        color: Colors.transparent,
                        elevation: 12 * t,
                        shadowColor: RefColors.pink.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      ),
                    );
                  },
                );
              },
              itemCount: _blockOrderIndexes.length,
              itemBuilder: (context, index) {
                final blockText = blocks[_blockOrderIndexes[index]];
                return ReorderableDragStartListener(
                  key: ValueKey('block-$index-${_blockOrderIndexes[index]}'),
                  index: index,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _blockOrderIndexes.length - 1 ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () => _toggleSelectedBlock(index),
                      child: _VerseBlock(
                        blockText,
                        correct:
                            hasInteracted && _blockOrderIndexes[index] == index,
                        selected: _selectedBlockPosition == index,
                        wrong: _checked && _blockOrderIndexes[index] != index,
                      ),
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                _moveBlock(oldIndex, newIndex);
              },
            ),
          ),
          if (hasInteracted)
            _InlineResult(
              correct: hasInteracted && allCorrect,
              neutral: !allCorrect,
              text: allCorrect
                  ? 'Orden correcto.'
                  : selectingDestination
                  ? 'Ahora toca una línea de destino para colocar ese bloque ahí.'
                  : 'Toca un bloque, elige una posición y acomódalo hasta que todo quede verde.',
            ),
        ],
      );
    }

    if (_isCompletionSlug(slug)) {
      final level = _completionLevelForSlug(slug);
      final isHarder = level >= 2;
      _ensureCompletionState(card.id, card.back, level);
      final activeTarget = _completionTargets.isEmpty
          ? _targetWord(card.back, level: level)
          : _completionTargets[_activeCompletionIndex.clamp(
              0,
              _completionTargets.length - 1,
            )];
      final words = _completionOptions(
        card.back,
        activeTarget,
        seed: _completionSeed,
      );
      final hasInput = _hasCompletionInput();
      final complete = _completionComplete();
      final remainingAttempts = (3 - _completionMistakes).clamp(0, 3);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompleteStatsCard(
            level2: isHarder,
            firstValue:
                '${_completionAnswers.where((answer) => answer != null).length}/${_completionTargets.length}',
            firstLabel: 'HUECOS',
            secondValue: '$remainingAttempts/3',
            secondLabel: 'INTENTOS',
            timeValue: _formatMmSs(_completionSecondsLeft),
          ),
          const SizedBox(height: 14),
          _CompletionPromptCard(
            label: card.front,
            text: card.back,
            targets: _completionTargets,
            answers: _completionAnswers,
            activeIndex: _activeCompletionIndex,
            onBlankTap: _activateCompletionBlank,
          ),
          const SizedBox(height: 14),
          if (complete)
            Glass(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              color: RefColors.lime.withValues(alpha: .14),
              border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
              child: Column(
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: RefColors.lime,
                    size: 36,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '¡Completado!',
                    style: TextStyle(
                      color: RefColors.lime,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Todos los huecos están correctos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RefColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (_completionLost)
            _LostPanel(
              title: '¡Tiempo agotado!',
              subtitle: 'Se acabó el tiempo. Inténtalo de nuevo.',
              onRetry: _retryCompletion,
            )
          else
            Glass(
              padding: const EdgeInsets.all(14),
              color: RefColors.glassSoft,
              child: Column(
                children: [
                  const Text(
                    'ELIGE LA PALABRA CORRECTA',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final word in words)
                        GestureDetector(
                          onTap: remainingAttempts == 0
                              ? null
                              : () => _selectCompletionWord(word),
                          child: _WordChip(word, active: false),
                        ),
                    ],
                  ),
                  if (hasInput && !complete && remainingAttempts > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Si fallas, las opciones se barajan de nuevo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RefColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (remainingAttempts == 0 && !complete) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Sin intentos restantes.',
                      style: TextStyle(
                        color: RefColors.urgent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    if (_isFirstLetterSlug(slug)) {
      final level = _letterLevelForSlug(slug);
      final isHarder = level >= 2;
      _ensureLetterState(card.id, card.back, level);
      final hasInput = _hasLetterInput();
      final complete = _letterComplete();
      final remainingAttempts = (3 - _letterMistakes).clamp(0, 3);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompleteStatsCard(
            level2: isHarder,
            firstValue:
                '${_letterAnswers.where((answer) => answer != null).length}/${_letterTargets.length}',
            firstLabel: 'LETRAS',
            secondValue: '$remainingAttempts/3',
            secondLabel: 'INTENTOS',
            timeValue: _formatMmSs(_letterSecondsLeft),
          ),
          const SizedBox(height: 12),
          _FirstLetterSentence(
            text: card.back,
            level: level,
            targets: _letterTargets,
            answers: _letterAnswers,
            activeIndex: _activeLetterIndex,
            onBlankTap: _activateLetterBlank,
          ),
          const SizedBox(height: 14),
          if (complete)
            Glass(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              color: RefColors.lime.withValues(alpha: .14),
              border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
              child: Column(
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: RefColors.lime,
                    size: 36,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '¡Completado!',
                    style: TextStyle(
                      color: RefColors.lime,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Todas las palabras fueron reveladas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RefColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (_letterLost)
            _LostPanel(
              title: '¡Tiempo agotado!',
              subtitle: 'Se acabó el tiempo. Inténtalo de nuevo.',
              onRetry: _retryLetter,
            )
          else ...[
            _KeyboardCard(
              onLetterTap: remainingAttempts == 0 ? null : _selectFirstLetter,
            ),
            if (hasInput && !complete && remainingAttempts == 0) ...[
              const SizedBox(height: 8),
              Text(
                'Sin intentos restantes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: RefColors.urgent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ],
      );
    }

    if (_isWordBankSlug(slug)) {
      _ensureBankState(card.id, card.back);
      final filled = _bankAnswers.where((a) => a != null).length;
      final isSplit = _bankIsSplit();
      final partCount = _bankPartCount();
      final (partStart, partEnd) = _bankPartRange();
      final partTargets = _bankTargets.sublist(partStart, partEnd);
      final partAnswers = _bankAnswers.sublist(partStart, partEnd);
      final partText = partTargets.join(' ');
      // Words available for the current part: take from _bankAvailable up to
      // the multiset of still-unfilled targets in this part.
      final cleanRegex = RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]');
      String clean(String w) => w.replaceAll(cleanRegex, '').toLowerCase();
      final neededCounts = <String, int>{};
      for (var i = partStart; i < partEnd; i++) {
        if (_bankAnswers[i] != null) continue;
        final key = clean(_bankTargets[i]);
        neededCounts[key] = (neededCounts[key] ?? 0) + 1;
      }
      final partAvailable = <String>[];
      for (final w in _bankAvailable) {
        final key = clean(w);
        final left = neededCounts[key] ?? 0;
        if (left > 0) {
          partAvailable.add(w);
          neededCounts[key] = left - 1;
        }
      }
      final partActiveIndex = (_bankActiveIndex - partStart).clamp(0, partTargets.length - 1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompleteStatsCard(
            level2: false,
            firstValue: '$filled/${_bankTargets.length}',
            firstLabel: 'HUECOS',
            secondValue: '$_bankMistakes',
            secondLabel: 'FALLOS',
          ),
          if (isSplit) ...[
            const SizedBox(height: 10),
            _BankPartHeader(
              partIndex: _bankPartIndex,
              partCount: partCount,
            ),
          ],
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0.18, 0),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _CompletionPromptCard(
              key: ValueKey('bank-prompt-$_bankPartIndex'),
              label: card.front,
              text: partText,
              targets: partTargets,
              answers: partAnswers,
              activeIndex: partActiveIndex,
              onBlankTap: (i) => _activateBankBlank(partStart + i),
            ),
          ),
          const SizedBox(height: 14),
          if (_bankComplete())
            Glass(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              color: RefColors.lime.withValues(alpha: .14),
              border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
              child: Column(
                children: const [
                  Icon(Icons.check_circle_rounded, color: RefColors.lime, size: 36),
                  SizedBox(height: 10),
                  Text('¡Banco vaciado!',
                      style: TextStyle(
                          color: RefColors.lime,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Cada palabra encontró su lugar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: RefColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            Glass(
              padding: const EdgeInsets.all(14),
              color: RefColors.glassSoft,
              child: Column(
                children: [
                  Text(
                    isSplit
                        ? 'BANCO · PARTE ${_bankPartIndex + 1}'
                        : 'BANCO DE PALABRAS',
                    style: const TextStyle(
                      color: RefColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final word in partAvailable)
                        AnimatedScale(
                          key: ValueKey('bank-$word'),
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInBack,
                          scale: _bankRemoving.contains(word) ? 0.0 : 1.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 240),
                            opacity:
                                _bankRemoving.contains(word) ? 0.0 : 1.0,
                            child: GestureDetector(
                              onTap: () => _selectBankWord(word),
                              child: _WordChip(word, active: false),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    }

    if (_isFogSlug(slug)) {
      _ensureFogState(card.id);
      return _FogStep(
        targetText: card.back,
        round: _fogRound,
        finished: _fogFinished,
        onRoundCompleted: _onFogRoundCompleted,
      );
    }

    _ensureQuizRounds(deck, card);
    final round = _quizRounds[_quizRoundIndex];
    final answered = round.answered;
    final isFrontToBack = round.type == _QuizQuestionType.frontToBack;
    final question = isFrontToBack
        ? '¿Qué texto corresponde a ${round.target.front}?'
        : '¿A qué referencia pertenece este texto?';
    final contextLabel = isFrontToBack
        ? (deck.isBible ? round.target.source : deck.title.toUpperCase())
        : '"${_firstWords(round.target.back, 8)}…"';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ronda ${_quizRoundIndex + 1} / ${_quizRounds.length}',
                style: const TextStyle(
                  color: RefColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Puntos: $_quizScore',
                style: const TextStyle(
                  color: RefColors.lime,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _ExerciseQuestionBlock(contextLabel: contextLabel, question: question),
        const SizedBox(height: 14),
        for (var i = 0; i < round.options.length; i++) ...[
          _ExerciseOption(
            letter: String.fromCharCode(65 + i),
            title: isFrontToBack
                ? round.options[i].back
                : round.options[i].front,
            tip: isFrontToBack
                ? round.options[i].front
                : round.options[i].source,
            selected: round.selectedIdx == i,
            correct: answered && round.options[i].id == round.target.id,
            wrong: round.selectedIdx == i && !round.correct,
            onTap: answered ? () {} : () => _selectQuizOption(i),
          ),
          const SizedBox(height: 10),
        ],
        if (answered)
          _InlineResult(
            correct: round.correct,
            text: round.correct
                ? '¡Correcto!'
                : 'Respuesta correcta: ${isFrontToBack ? round.target.back : round.target.front}',
          ),
        if (_quizFinished) ...[
          const SizedBox(height: 14),
          Glass(
            radius: 16,
            padding: const EdgeInsets.all(14),
            color: (_quizPassed ? RefColors.lime : RefColors.urgent).withValues(
              alpha: .14,
            ),
            border: Border.all(
              color: (_quizPassed ? RefColors.lime : RefColors.urgent)
                  .withValues(alpha: .55),
            ),
            child: Column(
              children: [
                Text(
                  _quizPassed
                      ? '¡Quiz superado! $_quizScore / ${_quizRounds.length}'
                      : 'Casi: $_quizScore / ${_quizRounds.length}. Necesitas 3 para avanzar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _quizPassed ? RefColors.lime : RefColors.urgent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!_quizPassed) ...[
                  const SizedBox(height: 10),
                  GhostButton('Reintentar', onTap: _resetQuiz),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _realExerciseFooter(
    BuildContext context,
    AppStore store,
    MemoryCardData card,
    MemoryDeckData deck,
    String slug,
  ) {
    final next = _nextFlowSlug(store, slug);
    final completed = store.isExerciseStepCompleted(slug);
    if (slug == '02-lectura-frag') {
      return Row(
        children: [
          SizedBox(
            width: 118,
            child: GhostButton(
              'Reiniciar',
              onTap: () => setState(() {
                _fragmentVisibleWords = 4;
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCta(
              label: completed
                  ? 'Siguiente →'
                  : 'Revela todo para continuar',
              enabled: completed,
              onTap: () {
                Navigator.push(
                  context,
                  AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
                );
              },
            ),
          ),
        ],
      );
    }
    if (slug == '01-escuchar' ||
        slug == '03-leer-voz' ||
        slug == '04-escuchar-voz' ||
        slug == '08-voz-guiada' ||
        _isFinalVoiceSlug(slug)) {
      final showSkip =
          slug == '03-leer-voz' ||
          slug == '04-escuchar-voz' ||
          slug == '08-voz-guiada' ||
          _isFinalVoiceSlug(slug);
      final cta = _ActionCta(
        label: _footerLabel(slug, checked: _checked, completed: completed),
        enabled: completed,
        onTap: () => Navigator.push(
          context,
          AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
        ),
      );
      if (!showSkip) return cta;
      return Row(
        children: [
          SizedBox(
            width: 118,
            child: GhostButton(
              'Saltar',
              onTap: () {
                store.markExerciseStepCompleted(slug);
                Navigator.push(
                  context,
                  AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: cta),
        ],
      );
    }
    return Row(
      children: [
        SizedBox(
          width: 118,
          child: GhostButton(
            'Pista',
            onTap: () {
              if (slug == '05-bloques') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Primer bloque: ${_orderedBlocks(card.back).first}',
                    ),
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Pista: ${_firstWords(card.back, 6)}')),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCta(
            label: _footerLabel(slug, checked: _checked, completed: completed),
            enabled: _footerEnabled(
              slug,
              checked: _checked,
              completed: completed,
            ),
            onTap: () {
              if (_isPassiveStep(slug)) {
                if (!completed) {
                  store.markExerciseStepCompleted(slug);
                  return;
                }
                if (_isFinalVoiceSlug(slug)) {
                  _completeSessionCard(context, store, correct: true);
                  return;
                }
                Navigator.push(
                  context,
                  AppRoutes.slideRoute('${AppRoutes.flow}/$next'),
                );
                return;
              }
              if (slug == '09-quiz') {
                if (_quizRounds.isEmpty) return;
                final round = _quizRounds[_quizRoundIndex];
                if (!round.answered) return;
                if (!_quizFinished) {
                  _advanceQuizRound();
                  return;
                }
                if (!_quizPassed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Necesitas 3 aciertos. Reintenta.'),
                    ),
                  );
                  return;
                }
                store.answerCurrentCard(true);
                store.markExerciseStepCompleted(slug);
                Navigator.push(
                  context,
                  AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
                );
                return;
              }
              if (!_checked) {
                if (slug == '05-bloques') {
                  if (_blocksAreCorrect()) {
                    store.markExerciseStepCompleted(slug);
                    Navigator.push(
                      context,
                      AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
                    );
                    return;
                  }
                  setState(() => _checked = true);
                  return;
                }
                setState(() => _checked = true);
                return;
              }
              final correct = _currentStepCorrect(slug, card, deck);
              if (!correct && slug != '09-quiz') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Corrige el ejercicio para avanzar.'),
                  ),
                );
                return;
              }
              if (slug == '09-quiz') {
                store.answerCurrentCard(correct);
              }
              store.markExerciseStepCompleted(slug);
              Navigator.push(
                context,
                AppRoutes.slideRoute('${AppRoutes.flow}/progress-tree'),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _currentStepCorrect(
    String slug,
    MemoryCardData card,
    MemoryDeckData deck,
  ) {
    if (slug == '05-bloques') {
      return _blocksAreCorrect();
    }
    if (_isCompletionSlug(slug)) {
      return _completionCorrect(slug, card);
    }
    if (_isFirstLetterSlug(slug)) {
      return _letterCorrect(slug, card);
    }
    if (slug == '09-quiz') {
      return _quizCorrect(card, deck);
    }
    return true;
  }

  String _footerLabel(
    String slug, {
    required bool checked,
    required bool completed,
  }) {
    if (slug == '01-escuchar') {
      return completed ? 'Siguiente →' : 'Escucha completa requerida';
    }
    if (slug == '03-leer-voz') {
      return completed ? 'Siguiente →' : 'Lee en voz alta para continuar';
    }
    if (slug == '04-escuchar-voz') {
      return completed ? 'Siguiente →' : 'Escucha tu lectura para continuar';
    }
    if (slug == '08-voz-guiada') {
      return completed ? 'Siguiente →' : 'Recita para continuar';
    }
    if (_isFinalVoiceSlug(slug)) {
      return completed ? 'Review final →' : 'Recita final para cerrar';
    }
    if (slug == '05-bloques') {
      return _blocksAreCorrect() ? 'Siguiente →' : 'Ordena para continuar';
    }
    if (_isCompletionSlug(slug)) {
      return _completionComplete() ? 'Completado →' : 'Completa los huecos';
    }
    if (_isFirstLetterSlug(slug)) {
      return _letterComplete() ? 'Completado →' : 'Elige primeras letras';
    }
    if (slug == '09-quiz') {
      if (_quizRounds.isEmpty) return 'Cargando…';
      final round = _quizRounds[_quizRoundIndex];
      if (!round.answered) return 'Elige una opción';
      if (!_quizFinished) return 'Siguiente ronda →';
      return _quizPassed ? 'Completado →' : 'Reintenta';
    }
    if (_isPassiveStep(slug)) {
      return completed ? 'Siguiente →' : 'Marcar terminado';
    }
    return checked ? 'Siguiente →' : 'Comprobar →';
  }

  bool _footerEnabled(
    String slug, {
    required bool checked,
    required bool completed,
  }) {
    if (slug == '01-escuchar') return completed;
    if (slug == '04-escuchar-voz') return completed;
    if (slug == '05-bloques' ||
        slug == '09-quiz' ||
        _isCompletionSlug(slug) ||
        _isFirstLetterSlug(slug)) {
      return _canAdvanceAnsweredStep(
        slug,
        AppScope.of(context).activeCard,
        AppScope.of(context).activeDeck,
      );
    }
    return true;
  }
}

class _CompletionPromptCard extends StatelessWidget {
  final String label;
  final String text;
  final List<String> targets;
  final List<String?> answers;
  final int activeIndex;
  final ValueChanged<int> onBlankTap;

  const _CompletionPromptCard({
    super.key,
    required this.label,
    required this.text,
    required this.targets,
    required this.answers,
    required this.activeIndex,
    required this.onBlankTap,
  });

  @override
  Widget build(BuildContext context) {
    final usedTargetIndexes = <int>{};
    final spans = <InlineSpan>[];
    for (final word in _studyWords(text)) {
      final targetIndex = _matchingUnusedTargetIndex(word, usedTargetIndexes);
      if (targetIndex == null) {
        spans.add(TextSpan(text: '$word '));
        continue;
      }
      usedTargetIndexes.add(targetIndex);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 4),
            child: _CompletionBlank(
              answer: answers[targetIndex],
              active:
                  activeIndex == targetIndex && answers[targetIndex] == null,
              complete: answers[targetIndex] != null,
              wordLength: targets[targetIndex].length,
              onTap: () => onBlankTap(targetIndex),
            ),
          ),
        ),
      );
    }
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .25),
          RefColors.sun.withValues(alpha: .18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: RefColors.sun,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: RefColors.ink,
                fontSize: 20,
                height: 1.6,
                fontWeight: FontWeight.w900,
                fontFamily: 'Outfit',
              ),
              children: spans,
            ),
          ),
        ],
      ),
    );
  }

  int? _matchingUnusedTargetIndex(String word, Set<int> usedTargetIndexes) {
    for (var index = 0; index < targets.length; index++) {
      if (usedTargetIndexes.contains(index)) continue;
      if (_sameAnswer(word, targets[index])) return index;
    }
    return null;
  }
}

class _RedFlash extends StatelessWidget {
  final bool active;
  final Widget child;

  const _RedFlash({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? RefColors.urgent.withValues(alpha: .85)
              : Colors.transparent,
          width: 2,
        ),
        color: active
            ? RefColors.urgent.withValues(alpha: .08)
            : Colors.transparent,
      ),
      padding: const EdgeInsets.all(2),
      child: child,
    );
  }
}

class _BankPartHeader extends StatelessWidget {
  final int partIndex;
  final int partCount;

  const _BankPartHeader({required this.partIndex, required this.partCount});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: Container(
        key: ValueKey('bank-part-$partIndex'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: RefColors.cyan.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RefColors.cyan.withValues(alpha: .55)),
        ),
        child: Row(
          children: [
            const Icon(Icons.view_agenda_rounded,
                color: RefColors.cyan, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Parte ${partIndex + 1} de $partCount',
                style: const TextStyle(
                  color: RefColors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < partCount; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == partIndex ? 18 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= partIndex
                          ? RefColors.cyan
                          : RefColors.cyan.withValues(alpha: .25),
                      borderRadius: BorderRadius.circular(3),
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

class _CompletionBlank extends StatelessWidget {
  final String? answer;
  final bool active;
  final bool complete;
  final int wordLength;
  final VoidCallback onTap;

  const _CompletionBlank({
    required this.answer,
    required this.active,
    required this.complete,
    required this.wordLength,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = complete
        ? RefColors.lime
        : active
        ? RefColors.cyan
        : RefColors.border;
    final length = wordLength.clamp(1, 14);
    return GestureDetector(
      onTap: complete ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: BoxConstraints(minWidth: (length * 10.0).clamp(28, 160)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: complete || active ? .16 : .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: .62), width: 1.5),
        ),
        child: Text(
          answer ?? '_' * length,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: complete ? RefColors.lime : RefColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ActionCta extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionCta({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (enabled) return Cta(label, onTap: onTap);
    return Opacity(opacity: .45, child: IgnorePointer(child: Cta(label)));
  }
}

class _InlineResult extends StatelessWidget {
  final bool correct;
  final bool neutral;
  final String text;

  const _InlineResult({
    required this.correct,
    required this.text,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = neutral
        ? RefColors.cyan
        : correct
        ? RefColors.lime
        : RefColors.urgent;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Glass(
        padding: const EdgeInsets.all(12),
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .45)),
        child: Text(
          '${neutral
              ? '•'
              : correct
              ? '✓'
              : '×'} $text',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProgressiveFragmentCard extends StatelessWidget {
  final int visibleWords;
  final VoidCallback onTap;

  const _ProgressiveFragmentCard({
    required this.visibleWords,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final safeVisible = visibleWords.clamp(0, words.length);
    final store = AppScope.of(context);
    final source = store.activeDeck.isBible
        ? '${_cardSourceText(context)} · RV1909'
        : _cardSourceText(context);
    return GestureDetector(
      onTap: safeVisible >= words.length ? null : onTap,
      child: Glass(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        gradient: LinearGradient(
          colors: [
            RefColors.violet.withValues(alpha: .22),
            RefColors.cyan.withValues(alpha: .10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                source,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Toca para aclarar lo siguiente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (var i = 0; i < words.length; i++)
                  i < safeVisible
                      ? Text(
                          words[i],
                          style: const TextStyle(
                            fontSize: 24,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                            color: RefColors.ink,
                          ),
                        )
                      : ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: Text(
                            words[i],
                            style: TextStyle(
                              fontSize: 24,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                              color: RefColors.muted.withValues(alpha: .45),
                            ),
                          ),
                        ),
              ],
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: RefProgress(
                words.isEmpty ? 0 : (safeVisible / words.length).clamp(.05, 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealPairingReview extends StatefulWidget {
  final AppStore store;

  const _RealPairingReview({required this.store});

  @override
  State<_RealPairingReview> createState() => _RealPairingReviewState();
}

class _RealPairingReviewState extends State<_RealPairingReview> {
  String? _frontId;
  String? _backId;
  final Set<String> _matched = {};

  @override
  Widget build(BuildContext context) {
    final cards = widget.store.activeDeck.cards.take(4).toList();
    final allMatched = cards.isNotEmpty && _matched.length == cards.length;
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowStepHeader(step: '12', title: 'Mini review', progress: 12),
          const _FlowTitle(
            title: 'Asocia referencia y texto',
            subtitle: 'Toca una referencia y luego el texto que le corresponde',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final card in cards)
                      _PairButton(
                        text: card.front,
                        active: _frontId == card.id,
                        done: _matched.contains(card.id),
                        onTap: () => setState(() => _frontId = card.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    for (final card in cards.reversed)
                      _PairButton(
                        text: _clipText(card.back),
                        active: _backId == card.id,
                        done: _matched.contains(card.id),
                        onTap: () => _selectBack(context, card.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Cta(
            allMatched ? 'Review final →' : 'Saltar review →',
            onTap: () =>
                Navigator.pushNamed(context, '${AppRoutes.flow}/final-review'),
          ),
        ],
      ),
    );
  }

  void _selectBack(BuildContext context, String id) {
    setState(() => _backId = id);
    if (_frontId == null) return;
    if (_frontId == id) {
      setState(() {
        _matched.add(id);
        _frontId = null;
        _backId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pareja correcta.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa pareja no corresponde.')),
      );
    }
  }
}

class _PairButton extends StatelessWidget {
  final String text;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  const _PairButton({
    required this.text,
    required this.active,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = done
        ? RefColors.lime
        : active
        ? RefColors.cyan
        : RefColors.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: done ? null : onTap,
        child: Glass(
          padding: const EdgeInsets.all(12),
          color: accent.withValues(alpha: done || active ? .12 : .04),
          border: Border.all(color: accent.withValues(alpha: .45)),
          child: Text(
            done ? '✓ $text' : text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _RealFinalReview extends StatelessWidget {
  final AppStore store;

  const _RealFinalReview({required this.store});

  @override
  Widget build(BuildContext context) {
    final deck = store.activeDeck;
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowStepHeader(
            step: '12',
            title: 'Review final',
            progress: 12,
          ),
          Glass(
            padding: const EdgeInsets.all(20),
            gradient: LinearGradient(
              colors: [
                RefColors.lime.withValues(alpha: .22),
                RefColors.sun.withValues(alpha: .18),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesión completada',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '${deck.title} · ${store.completedCards} respuestas registradas · ${deck.retention}% retención',
                  style: const TextStyle(color: RefColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final card in deck.cards.take(5))
            _ReviewItem(
              card.icon,
              card.front,
              _clipText(card.back),
              '${card.retention}%',
              urgent: card.retention < 60,
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Repetir',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/01-escuchar',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Cta(
                  'Volver a inicio →',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.home),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListenFlowScreen extends StatelessWidget {
  const _ListenFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlowTopBar(
            chip: 'Ítem 1/5 · ${AppScope.of(context).activeCard.front}',
          ),
          const _FlowStepHeader(
            step: '1',
            title: '🎧 Escuchar',
            progress: 1,
            difficulty: '🌿 Inter',
          ),
          const _FlowTitle(
            title: 'Escucha y sigue',
            subtitle: 'El texto se resalta al ritmo del audio',
          ),
          const _ListenAudioCard(),
          const SizedBox(height: 14),
          const _FlowHintCard(
            icon: '💡',
            text:
                'Escúchalo al menos 3 veces antes de avanzar. Tu cerebro está formando la pista auditiva.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('🔁 Repetir')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente paso →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/02-lectura-frag',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FragmentedReadingFlowScreen extends StatelessWidget {
  const _FragmentedReadingFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          const _FlowStepHeader(
            step: '2',
            title: '👁 Lectura fragmentada',
            progress: 2,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Lee conforme aparece',
            subtitle: 'Activa tu atención · lo verás de a poco',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: RefProgress(.66),
          ),
          const _FragmentedTextCard(),
          const SizedBox(height: 14),
          const _SpeedSelectorCard(),
          const SizedBox(height: 14),
          const _TapPauseCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('← Repetir')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/03-leer-voz',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadAloudFlowScreen extends StatelessWidget {
  const _ReadAloudFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Zen mode'),
          const _FlowStepHeader(
            step: '3',
            title: '🗣 Dilo sin prisas',
            progress: 3,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Léelo en voz alta',
            subtitle: 'Tu voz refuerza la memoria auditiva',
          ),
          const SizedBox(height: 44),
          const _KaraokeLine(fontSize: 29),
          const SizedBox(height: 48),
          const _PulseMic(),
          const SizedBox(height: 42),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 54),
            child: RefProgress(.74),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              '• TE ESCUCHO',
              style: TextStyle(
                color: RefColors.pink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('Reiniciar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Finalizar grabación →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/04-escuchar-voz',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListenOwnVoiceFlowScreen extends StatelessWidget {
  const _ListenOwnVoiceFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '👂 Tu propia voz'),
          const _FlowStepHeader(
            step: '4',
            title: '🎤 Escúchate',
            progress: 4,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Tu grabación',
            subtitle: 'Oír tu propia voz refuerza la memoria auditiva',
          ),
          const _VoiceQuoteCard(),
          const SizedBox(height: 14),
          const _WaveformCard(kind: _WaveKind.original),
          const SizedBox(height: 14),
          const _WaveformCard(kind: _WaveKind.you),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 180, child: GhostButton('🔁 Regrabar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/05-bloques',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlocksFlowScreen extends StatelessWidget {
  const _BlocksFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '🧩 Reorganizar'),
          const _FlowStepHeader(
            step: '5',
            title: '🧩 Reorganiza los bloques',
            progress: 5,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Reconstruye el texto',
            subtitle: 'Arrastra los bloques al orden correcto',
          ),
          const _BlocksCounterCard(),
          const SizedBox(height: 14),
          const _BlocksListCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('👁 Pista')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Comprobar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/06-completar-n1',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompleteN1FlowScreen extends StatelessWidget {
  const _CompleteN1FlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          const _FlowStepHeader(
            step: '6',
            title: '📝 Completar palabra',
            progress: 6,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Completa el versículo · Nivel 1',
            subtitle: 'Toca una palabra del banco y llena el hueco',
          ),
          const _CompleteStatsCard(),
          const SizedBox(height: 14),
          const _CompleteSentenceCard(),
          const SizedBox(height: 14),
          const _WordBankCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('👁 Pista')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Siguiente →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FirstLetterFlowScreen extends StatelessWidget {
  final int level;

  const _FirstLetterFlowScreen({required this.level});

  @override
  Widget build(BuildContext context) {
    final isLevel2 = level == 2;
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          _FlowStepHeader(
            step: isLevel2 ? '11' : '7',
            title: '🔤 Primera letra',
            progress: isLevel2 ? 11 : 7,
            difficulty: isLevel2 ? '🌳' : '🌿',
          ),
          _FlowTitle(
            title: 'Escribe la primera letra · Nivel $level',
            subtitle: isLevel2
                ? 'Casi todo está oculto · cronómetro · intentos limitados'
                : 'De cada hueco escribe únicamente su letra inicial',
          ),
          _CompleteStatsCard(
            level2: isLevel2,
            firstValue: isLevel2 ? '1/5' : '1/3',
          ),
          const SizedBox(height: 14),
          _FirstLetterSentence(level: level),
          const SizedBox(height: 14),
          if (!isLevel2) ...[
            const _FlowHintCard(
              icon: '💡',
              text:
                  'No te preocupes por la exactitud: acentos, mayúsculas o minúsculas no cuentan.',
            ),
            const SizedBox(height: 14),
          ],
          const _KeyboardCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('👁 Pista')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Siguiente →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    isLevel2
                        ? '${AppRoutes.flow}/12-voz-final'
                        : '${AppRoutes.flow}/08-voz-guiada',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuidedVoiceFlowScreen extends StatelessWidget {
  const _GuidedVoiceFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '🎤 Recitar completo'),
          const _FlowStepHeader(
            step: '8',
            title: '🎤 Voz con palabras ocultas',
            progress: 8,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Recita el versículo completo',
            subtitle: 'Algunas palabras están ocultas · dilas de memoria',
          ),
          const _CompleteStatsCard(
            firstValue: '3/7',
            firstLabel: 'PALABRAS',
            secondValue: '2',
            secondLabel: 'INTENTOS RESTANTES',
          ),
          const SizedBox(height: 14),
          const _VoiceHiddenWordsCard(finalMode: false),
          const SizedBox(height: 14),
          const _ListeningHud(colorMode: _ListeningColorMode.blue),
          const SizedBox(height: 14),
          const _FlowHintCard(
            icon: '💡',
            text:
                'Recita todo literalmente, no solo las ocultas · si pausas más de 5s reiniciamos.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('🔁 Reset')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Terminé →',
                  onTap: () =>
                      Navigator.pushNamed(context, '${AppRoutes.flow}/09-quiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizFlowScreen extends StatelessWidget {
  const _QuizFlowScreen();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final card = store.activeCard;
    final deck = store.activeDeck;
    final options = [
      card,
      ...deck.cards.where((item) => item.id != card.id),
    ].take(4).toList();
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Quiz · 5 preguntas'),
          const _FlowStepHeader(
            step: '9',
            title: '🧠 Entiende el significado',
            progress: 9,
            difficulty: '🌿',
          ),
          const _FlowTitle(
            title: 'Quiz de comprensión',
            subtitle: '5 preguntas de tipos distintos según el contenido',
          ),
          const _QuizNav(),
          const SizedBox(height: 14),
          _ExerciseQuestionBlock(
            contextLabel: deck.isBible ? card.source : deck.title.toUpperCase(),
            question: deck.isBible
                ? '¿Qué texto pertenece a ${card.front}?'
                : '¿Cuál explicación corresponde a ${card.front}?',
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < options.length; i++) ...[
            _ExerciseOption(
              letter: String.fromCharCode(65 + i),
              title: options[i].back,
              tip: options[i].source,
              selected: i == 0,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 140, child: GhostButton('💡 Explicar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Confirmar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/10-completar-n2',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompleteN2FlowScreen extends StatelessWidget {
  const _CompleteN2FlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Ítem 1/5'),
          const _FlowStepHeader(
            step: '10',
            title: '📝 Completar palabra',
            progress: 10,
            difficulty: '🌳',
          ),
          const _FlowTitle(
            title: 'Completa el versículo · Nivel 2',
            subtitle: 'Más huecos · cronómetro · intentos limitados',
          ),
          const _CompleteStatsCard(
            level2: true,
            firstValue: '1/5',
            secondValue: '2/3',
          ),
          const SizedBox(height: 14),
          const _CompleteSentenceCard(level2: true),
          const SizedBox(height: 14),
          const _WordBankCard(level2: true),
          const SizedBox(height: 14),
          const _WarningCard(
            text:
                'Nivel 2: si fallas 3 veces o se acaba el tiempo, vuelves al paso anterior.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('↩ Vaciar')),
              const SizedBox(width: 10),
              Expanded(
                child: Cta(
                  'Comprobar →',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '${AppRoutes.flow}/11-primera-letra-n2',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinalVoiceFlowScreen extends StatelessWidget {
  const _FinalVoiceFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: '🏆 EXAMEN FINAL'),
          const _FlowStepHeader(
            step: '12',
            title: '🎤 Recitación final',
            progress: 12,
            difficulty: '🌳',
          ),
          const _FlowTitle(
            title: 'Recita el versículo completo · Examen',
            subtitle: 'Sin ayudas · todas las palabras están ocultas',
          ),
          const _CompleteStatsCard(
            level2: true,
            firstValue: '0/7',
            firstLabel: 'PALABRAS',
            secondValue: '2',
            secondLabel: 'INTENTOS RESTANTES',
            timeValue: '00:30',
          ),
          const SizedBox(height: 14),
          const _VoiceHiddenWordsCard(finalMode: true),
          const SizedBox(height: 14),
          const _ListeningHud(colorMode: _ListeningColorMode.pink),
          const SizedBox(height: 14),
          const _WarningCard(
            text:
                'Examen final: recita todo de memoria sin parar más de 5s. Si fallas 2 veces vuelves al paso anterior.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 112, child: GhostButton('🔁 Reset')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Terminé →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniReviewFlowScreen extends StatelessWidget {
  const _MiniReviewFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'Mini-repaso'),
          const _MiniReviewHero(),
          const SizedBox(height: 14),
          const _MiniReviewTabs(),
          const SizedBox(height: 16),
          const _FlowTitle(
            title: '🎯 Asocia cada referencia con su texto',
            subtitle:
                'Toca una referencia y luego su texto · arrastrar también funciona',
          ),
          const _MiniReviewCounter(),
          const SizedBox(height: 14),
          const _PairMatchCard(),
          const SizedBox(height: 18),
          const _FlowHintCard(
            icon: '💡',
            text: 'Toca una referencia y luego su texto correspondiente',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 96, child: GhostButton('Saltar')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Siguiente ejercicio →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinalReviewFlowScreen extends StatelessWidget {
  const _FinalReviewFlowScreen();

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FlowTopBar(chip: 'FIN DE SESIÓN'),
          const _FinalSuccessHero(),
          const SizedBox(height: 16),
          const _FinalScoreCard(),
          const SizedBox(height: 14),
          const _ShareAchievementCard(),
          const SizedBox(height: 14),
          const _FinalVersesCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 96, child: GhostButton('Repetir')),
              const SizedBox(width: 10),
              Expanded(child: Cta('Volver a inicio →')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowTopBar extends StatelessWidget {
  final String chip;

  const _FlowTopBar({required this.chip});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final dynamicChip = chip.contains('Ítem') || chip.contains('Item')
        ? 'Ítem ${store.currentCardIndex + 1}/${store.activeDeck.cards.length} · ${store.activeCard.front}'
        : chip;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(),
          Expanded(child: Center(child: RefChip(dynamicChip, dense: true))),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _FlowStepHeader extends StatelessWidget {
  final String step;
  final String title;
  final int progress;
  final int totalSteps;
  final String? difficulty;

  const _FlowStepHeader({
    required this.step,
    required this.title,
    required this.progress,
    this.totalSteps = 12,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        color: RefColors.glassStrong,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const RefBackButton(),
                const SizedBox(width: 10),
                Text(
                  'PASO $step/$totalSteps',
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${store.activeDeck.cards.length} items · paso $step de $totalSteps · ${store.activeDeck.title}',
                      ),
                    ),
                  ),
                  child: const RefIconButton(icon: Icons.info_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  for (var i = 1; i <= totalSteps; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: i < progress
                              ? RefColors.lime
                              : i == progress
                              ? RefColors.pink
                              : RefColors.glassSoft,
                        ),
                      ),
                    ),
                    if (i < totalSteps) const SizedBox(width: 5),
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

class _FlowTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FlowTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: RefColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniReviewHero extends StatelessWidget {
  const _MiniReviewHero();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .32),
          RefColors.sun.withValues(alpha: .48),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: RefColors.lime.withValues(alpha: .46)),
      child: const Row(
        children: [
          Text('🎉', style: TextStyle(fontSize: 36)),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completaste 2 ítems',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Antes de seguir, repasa con 3 ejercicios cortos',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniReviewTabs extends StatelessWidget {
  const _MiniReviewTabs();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _MiniReviewTab('EJ 1', 'Asociar', active: true)),
        SizedBox(width: 8),
        Expanded(child: _MiniReviewTab('EJ 2', 'Memoria')),
        SizedBox(width: 8),
        Expanded(child: _MiniReviewTab('EJ 3', 'Quiz rápido', warm: true)),
      ],
    );
  }
}

class _MiniReviewTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final bool warm;

  const _MiniReviewTab(
    this.title,
    this.subtitle, {
    this.active = false,
    this.warm = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? RefColors.pink.withValues(alpha: .16)
            : warm
            ? RefColors.sun.withValues(alpha: .18)
            : RefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? RefColors.pink
              : warm
              ? RefColors.sun.withValues(alpha: .40)
              : RefColors.border,
          width: active ? 1.6 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: active ? RefColors.pink : RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MiniReviewCounter extends StatelessWidget {
  const _MiniReviewCounter();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      radius: 18,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gradient: LinearGradient(
        colors: [Color(0x66372B86), Color(0x66754D44)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      child: Row(
        children: [
          Text(
            '1 / 3',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          Text(
            ' pares',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Spacer(),
          Text(
            'Intentos: 1/2',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PairMatchCard extends StatelessWidget {
  const _PairMatchCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 16),
      color: RefColors.glassStrong,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _PairColumnTitle('REFERENCIAS')),
              SizedBox(width: 10),
              Expanded(child: _PairColumnTitle('TEXTOS')),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PairTile('Sal 23:1', selected: true, correct: true),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _PairTile(
                  '"Jehová es mi pastor;\nnada me faltará."',
                  selected: true,
                  correct: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _PairTile('Juan 3:16', selected: true)),
              SizedBox(width: 10),
              Expanded(
                child: _PairTile('"Fíate de Jehová con\ntodo tu corazón..."'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _PairTile('Prov 3:5')),
              SizedBox(width: 10),
              Expanded(
                child: _PairTile('"De tal manera amó\nDios al mundo..."'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PairColumnTitle extends StatelessWidget {
  final String label;

  const _PairColumnTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: RefColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }
}

class _PairTile extends StatelessWidget {
  final String text;
  final bool selected;
  final bool correct;

  const _PairTile(this.text, {this.selected = false, this.correct = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = correct
        ? RefColors.lime
        : selected
        ? RefColors.pink
        : RefColors.border;
    return Container(
      height: 64,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: correct
            ? RefColors.lime.withValues(alpha: .10)
            : selected
            ? RefColors.pink.withValues(alpha: .12)
            : RefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withValues(alpha: .78),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: correct ? RefColors.lime : RefColors.ink,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (correct)
            const Positioned(
              right: 0,
              top: 0,
              child: Icon(Icons.check_rounded, color: RefColors.lime, size: 16),
            ),
        ],
      ),
    );
  }
}

class _FinalSuccessHero extends StatelessWidget {
  const _FinalSuccessHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF90FA6D), Color(0xFF39D985)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 42)),
          SizedBox(height: 12),
          Text(
            '¡Lo lograste!',
            style: TextStyle(
              color: Color(0xFF06280F),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '5 tarjetas · 18 min · 93% aciertos',
            style: TextStyle(
              color: Color(0xFF06351A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalScoreCard extends StatelessWidget {
  const _FinalScoreCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .32),
          RefColors.sun.withValues(alpha: .42),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      child: Row(
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: RefColors.lime, width: 4),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '93%',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'ACIERTO',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              children: [
                _FinalScoreRow('Correctas', '67 / 72'),
                _FinalScoreRow('Incorrectas', '5'),
                _FinalScoreRow('Tiempo', '18 min', last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _FinalScoreRow(this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ShareAchievementCard extends StatelessWidget {
  const _ShareAchievementCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RefColors.glassStrong,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('📸')),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparte tu logro',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Imagen o texto · sin cuenta necesaria',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: RefColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Compartir',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalVersesCard extends StatelessWidget {
  const _FinalVersesCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
      color: RefColors.glassStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📖 LOS 5 VERSÍCULOS',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 14),
          _FinalVerseRow(
            index: '1',
            title: 'Sal 23:1 · "Jehová es mi pastor..."',
            meta: '12 pasos · sin errores',
            percent: '100%',
            value: 1,
          ),
          _FinalVerseRow(
            index: '2',
            title: 'Sal 23:2 · "En lugares de pastos..."',
            meta: '12 pasos · 1 error',
            percent: '95%',
            value: .95,
          ),
          _FinalVerseRow(
            index: '3',
            title: 'Sal 23:3 · "Confortará mi alma..."',
            meta: '12 pasos · 2 errores',
            percent: '85%',
            value: .85,
            warn: true,
          ),
          _FinalVerseRow(
            index: '4',
            title: 'Sal 23:4 · "Aunque ande en valle..."',
            meta: '12 pasos · sin errores',
            percent: '98%',
            value: .98,
          ),
          _FinalVerseRow(
            index: '5',
            title: 'Sal 23:5 · "Aderezas mesa..."',
            meta: '12 pasos · 1 error',
            percent: '88%',
            value: .88,
            warn: true,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _FinalVerseRow extends StatelessWidget {
  final String index;
  final String title;
  final String meta;
  final String percent;
  final double value;
  final bool warn;
  final bool last;

  const _FinalVerseRow({
    required this.index,
    required this.title,
    required this.meta,
    required this.percent,
    required this.value,
    this.warn = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = warn ? RefColors.sun : RefColors.lime;
    return Container(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      margin: EdgeInsets.only(bottom: last ? 0 : 4),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RefColors.glassSoft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: RefColors.border),
            ),
            child: Text(
              index,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 5,
                    color: RefColors.glassSoft,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(color: accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: .5)),
            ),
            child: Text(
              '${warn ? '⚡' : '✓'} $percent',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadAloudPracticeCard extends StatefulWidget {
  final String targetText;
  final String source;
  final void Function(String text, String? audioPath) onCompleted;

  const _ReadAloudPracticeCard({
    required this.targetText,
    required this.source,
    required this.onCompleted,
  });

  @override
  State<_ReadAloudPracticeCard> createState() => _ReadAloudPracticeCardState();
}

class _ReadAloudPracticeCardState extends State<_ReadAloudPracticeCard> {
  static const _passScore = .60;
  late final stt.SpeechToText _speech;
  bool _ready = false;
  bool _listening = false;
  bool _completed = false;
  String _recognized = '';
  String _status = 'Toca el micrófono y lee el texto.';
  double _score = 0;
  final _audioRecorder = AudioRecorder();
  String? _recordedPath;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _status = 'No pude escuchar bien. Intenta otra vez.';
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _ready = available;
      _status = available
          ? 'Toca el micrófono y lee el texto.'
          : 'Activa permiso de micrófono para leer en voz.';
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    _audioRecorder.stop().then((_) => _audioRecorder.dispose());
    super.dispose();
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      _finishCapture();
    }
  }

  Future<void> _toggleListening() async {
    if (!_ready) {
      await _initSpeech();
      return;
    }
    if (_listening) {
      // User tapped stop — end both capture streams and finalize.
      await _speech.stop();
      _finishCapture();
      return;
    }
    setState(() {
      _recognized = '';
      _score = 0;
      _completed = false;
      _listening = true;
      _status = 'Escuchando... lee el texto completo.';
    });

    // Start the file recorder FIRST so the first words make it onto disk.
    // The audio session is shared with speech_to_text on iOS — recording in
    // a file via AVAudioRecorder does not collide with SFSpeechRecognizer's
    // engine tap.
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        _recordedPath = path;
      }
    } catch (e) {
      debugPrint('Audio Recorder Error: $e');
    }

    // Tiny breath so AVAudioSession is fully alive before SFSpeech attaches.
    await Future.delayed(const Duration(milliseconds: 120));

    try {
      await _speech.listen(
        localeId: 'es_ES',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 12),
        onResult: _handleResult,
      );
    } catch (e) {
      debugPrint('STT Listen Error: $e');
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords;
    final score = _speechSimilarity(recognized, widget.targetText);
    final passed = score >= _passScore;
    if (!mounted) return;
    setState(() {
      _recognized = recognized;
      _score = score;
      if (passed) {
        _completed = true;
        _status = 'Vas bien — sigue leyendo o toca detener para guardar.';
      }
    });
    // IMPORTANT: do NOT stop on first passed result. Let the user finish.
  }

  bool _finalizing = false;
  Future<void> _finishCapture() async {
    if (_finalizing) return;
    _finalizing = true;
    try {
      final path = await _audioRecorder.stop();
      if (path != null) _recordedPath = path;
      if (!mounted) return;
      setState(() => _listening = false);
      _grade(_recognized);
    } finally {
      _finalizing = false;
    }
  }

  void _grade(String recognized) {
    final score = _speechSimilarity(recognized, widget.targetText);
    final passed = score >= _passScore;
    if (!mounted) return;
    setState(() {
      _score = score;
      _completed = passed;
      _status = passed
          ? '60% o más está fino. Puedes avanzar.'
          : 'Se parece poco todavía. Reintenta leyendo más completo.';
    });
    if (passed) widget.onCompleted(recognized, _recordedPath);
  }


  @override
  Widget build(BuildContext context) {
    final percent = (_score * 100).round();
    final accent = _completed
        ? RefColors.lime
        : _score >= .45
        ? RefColors.sun
        : RefColors.pink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          gradient: LinearGradient(
            colors: [
              RefColors.violet.withValues(alpha: .24),
              RefColors.cyan.withValues(alpha: .10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.source,
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.targetText,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: HtmlRefColors.glassSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HtmlRefColors.glassBorder),
                ),
                child: Text(
                  _recognized.isEmpty
                      ? 'Aquí aparecerá lo que entendió el reconocimiento de voz.'
                      : _recognized,
                  style: TextStyle(
                    color: _recognized.isEmpty ? RefColors.dim : RefColors.ink,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: _listening ? RefColors.primary : null,
                        color: _listening ? null : RefColors.glassStrong,
                        shape: BoxShape.circle,
                        border: Border.all(color: RefColors.border),
                      ),
                      child: Icon(
                        _listening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$percent% parecido',
                          style: TextStyle(
                            color: accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RefProgress(_score.clamp(.02, 1.0)),
                        const SizedBox(height: 7),
                        Text(
                          _status,
                          style: const TextStyle(
                            color: RefColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListenOwnVoicePracticeCard extends StatefulWidget {
  final String originalText;
  final String voiceText;
  final String source;
  final String? audioPath;
  final VoidCallback onCompleted;

  const _ListenOwnVoicePracticeCard({
    required this.originalText,
    required this.voiceText,
    required this.source,
    this.audioPath,
    required this.onCompleted,
  });

  @override
  State<_ListenOwnVoicePracticeCard> createState() =>
      _ListenOwnVoicePracticeCardState();
}

class _ListenOwnVoicePracticeCardState
    extends State<_ListenOwnVoicePracticeCard> {
  late final FlutterTts _tts;
  late final AudioPlayer _audioPlayer;
  int _tab = 1;
  bool _playing = false;
  bool _completed = false;
  int _highlightedCount = 0;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playing = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _audioDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && _audioDuration.inMilliseconds > 0 && _playing) {
        final progress =
            position.inMilliseconds / _audioDuration.inMilliseconds;
        setState(() {
          _highlightedCount = (progress * _currentText.length).toInt().clamp(
            0,
            _currentText.length,
          );
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _highlightedCount = 0;
        if (_tab == 1) _completed = true;
      });
      if (_tab == 1) widget.onCompleted();
    });

    _tts.setStartHandler(() {
      if (mounted) setState(() => _playing = true);
    });

    _tts.setProgressHandler((text, start, end, word) {
      if (mounted) {
        setState(() {
          _highlightedCount = end.clamp(0, _currentText.length);
        });
      }
    });

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _highlightedCount = 0;
        if (_tab == 1 && widget.voiceText.trim().isNotEmpty) {
          _completed = true;
        }
      });
      if (_tab == 1 && widget.voiceText.trim().isNotEmpty) {
        widget.onCompleted();
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _playing = false;
          _highlightedCount = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _currentText {
    if (_tab == 1 && widget.voiceText.trim().isEmpty) {
      return 'Primero completa el paso de leer en voz para guardar tu lectura.';
    }
    return widget.originalText;
  }

  Future<void> _play() async {
    if (_playing) {
      await _tts.stop();
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _playing = false;
          _highlightedCount = 0;
        });
      }
      return;
    }

    if (_tab == 1 && widget.audioPath != null) {
      await _audioPlayer.setPlaybackRate(1);
      await _audioPlayer.play(DeviceFileSource(widget.audioPath!));
      final duration = await _audioPlayer.getDuration();
      if (mounted && duration != null) {
        setState(() => _audioDuration = duration);
      }
    } else {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(_tab == 0 ? 0.44 : 0.48);
      await _tts.setPitch(_tab == 0 ? 1.0 : .92);
      await _tts.speak(_currentText);
    }
  }

  Future<void> _switchTab(int tab) async {
    await _tts.stop();
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _tab = tab;
      _playing = false;
      _highlightedCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasVoice = widget.voiceText.trim().isNotEmpty;
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .25),
          RefColors.sun.withValues(alpha: .16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: HtmlRefColors.glassSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HtmlRefColors.glassBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VoiceTab(
                    'Tuyo',
                    active: _tab == 1,
                    onTap: () => _switchTab(1),
                  ),
                  const SizedBox(width: 4),
                  _VoiceTab(
                    'Original',
                    active: _tab == 0,
                    onTap: () => _switchTab(0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.source,
            style: const TextStyle(
              color: RefColors.pink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(minHeight: 138),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HtmlRefColors.glassSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HtmlRefColors.glassBorder),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: _tab == 1 && !hasVoice
                      ? RefColors.dim
                      : RefColors.ink.withValues(alpha: 0.4),
                  fontSize: 18,
                  height: 1.38,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
                children: [
                  if (_highlightedCount > 0)
                    TextSpan(
                      text: _currentText.substring(0, _highlightedCount),
                      style: const TextStyle(color: RefColors.ink),
                    ),
                  TextSpan(text: _currentText.substring(_highlightedCount)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _PlayerMainButton(paused: _playing, onTap: _play),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _tab == 0
                      ? 'Escucha el original para comparar.'
                      : hasVoice
                      ? (_completed
                            ? 'Ya escuchaste tu lectura. Puedes avanzar.'
                            : 'Reproduce tu lectura para cerrar el paso.')
                      : 'No hay lectura guardada todavía.',
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _VoiceTab(this.label, {required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? RefColors.primary : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : RefColors.muted,
          ),
        ),
      ),
    );
  }
}

class _ListenAudioCard extends StatefulWidget {
  final VoidCallback? onCompleted;

  const _ListenAudioCard({this.onCompleted});

  @override
  State<_ListenAudioCard> createState() => _ListenAudioCardState();
}

class _ListenAudioCardState extends State<_ListenAudioCard> {
  late final FlutterTts _tts;
  final ScrollController _textScrollController = ScrollController();
  bool _playing = false;
  bool _completed = false;
  int _wordIndex = 0;
  int _ttsStartWordOffset = 0;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setStartHandler(() {
      if (mounted) setState(() => _playing = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _playing = false;
          _completed = true;
          _wordIndex = 0;
        });
        widget.onCompleted?.call();
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _playing = false);
    });
    _tts.setProgressHandler((text, startOffset, endOffset, word) {
      if (!mounted) return;
      final before = text.substring(0, startOffset.clamp(0, text.length));
      final index = _studyWords(
        before,
      ).length.clamp(0, _studyWords(text).length);
      final absoluteIndex = (_ttsStartWordOffset + index).clamp(
        0,
        _studyWords(_cardStudyText(context)).length,
      );
      setState(() => _wordIndex = absoluteIndex);
      _scrollToProgress(
        absoluteIndex,
        _studyWords(_cardStudyText(context)).length,
      );
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _textScrollController.dispose();
    super.dispose();
  }

  void _scrollToProgress(int index, int total) {
    if (total <= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_textScrollController.hasClients) return;
      final max = _textScrollController.position.maxScrollExtent;
      if (max <= 0) return;
      final target = max * (index / (total - 1)).clamp(0.0, 1.0);
      _textScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _toggle(String text) async {
    if (_playing) {
      await _tts.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.44);
    await _tts.setPitch(1.0);
    await _speakFromCurrent(text);
  }

  Future<void> _restart(String text) async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _wordIndex = 0;
        _playing = false;
        _completed = false;
      });
    }
    await _toggle(text);
  }

  Future<void> _speakFromCurrent(String text) async {
    final words = _studyWords(text);
    final start = _wordIndex.clamp(0, words.length - 1);
    _ttsStartWordOffset = start;
    final remaining = words.skip(start).join(' ');
    await _tts.speak(remaining);
  }

  Future<void> _skipForward(String text) async {
    final words = _studyWords(text);
    final nextIndex = (_wordIndex + 12).clamp(0, words.length - 1);
    await _tts.stop();
    if (mounted) {
      setState(() {
        _wordIndex = nextIndex;
        _playing = false;
      });
    }
    _scrollToProgress(nextIndex, words.length);
    await _toggle(text);
  }

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final source = _cardSourceText(context).toUpperCase();
    final text = _cardStudyText(context);
    final safeIndex = _wordIndex.clamp(0, words.length - 1);
    final lead = words.take(safeIndex).join(' ');
    final current = words[safeIndex];
    final tail = words.skip(safeIndex + 1).join(' ');
    final progress = words.isEmpty ? 0.0 : ((safeIndex + 1) / words.length);
    return Glass(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .34),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Text(
            source,
            style: TextStyle(
              color: RefColors.pink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 34),
          Expanded(
            child: Center(
              child: Scrollbar(
                controller: _textScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _textScrollController,
                  padding: const EdgeInsets.only(right: 10),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (lead.isNotEmpty)
                          TextSpan(
                            text: '$lead ',
                            style: const TextStyle(color: RefColors.lime),
                          ),
                        TextSpan(
                          text: current,
                          style: const TextStyle(
                            color: RefColors.ink,
                            backgroundColor: Color(0x44273CFE),
                          ),
                        ),
                        TextSpan(
                          text: tail.isEmpty ? '' : ' $tail',
                          style: const TextStyle(color: RefColors.muted),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: RefProgress(progress.clamp(.03, 1.0)),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                _playing ? 'Leyendo' : 'Listo',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${safeIndex + 1}/${words.length} palabras',
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: RefColors.inner),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlayerSmallButton(
                Icons.replay_rounded,
                onTap: () => _restart(text),
              ),
              const SizedBox(width: 18),
              _PlayerMainButton(paused: _playing, onTap: () => _toggle(text)),
              const SizedBox(width: 18),
              _PlayerSmallButton(
                Icons.forward_5_rounded,
                onTap: () => _skipForward(text),
              ),
            ],
          ),
          if (_completed) ...[
            const SizedBox(height: 12),
            const StatusChip(
              'ESCUCHA COMPLETA',
              color: Color(0x338DFD63),
              borderColor: Color(0x668DFD63),
              textColor: RefColors.lime,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerSmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PlayerSmallButton(this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: RefColors.glassStrong,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RefColors.border),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

class _PlayerMainButton extends StatelessWidget {
  final bool paused;
  final VoidCallback? onTap;

  const _PlayerMainButton({this.paused = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: RefColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: RefColors.pink.withValues(alpha: .42),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          paused ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 34,
        ),
      ),
    );
  }
}

class _FlowHintCard extends StatelessWidget {
  final String icon;
  final String text;

  const _FlowHintCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FragmentedTextCard extends StatelessWidget {
  const _FragmentedTextCard();

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final visible = words.take(3).join(' ');
    final active = words.length > 3 ? words[3] : '';
    final hidden = words.skip(4).join(' ');
    final activeSplit = active.length < 2 ? active.length : 2;
    return Glass(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: SizedBox(
        height: 150,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$visible '),
                TextSpan(
                  text: active.isEmpty ? '' : active.substring(0, activeSplit),
                  style: const TextStyle(
                    color: RefColors.ink,
                    decoration: TextDecoration.underline,
                    decorationColor: RefColors.pink,
                    decorationThickness: 3,
                  ),
                ),
                TextSpan(
                  text: active.isEmpty
                      ? hidden
                      : '${active.substring(activeSplit)} $hidden',
                  style: const TextStyle(color: RefColors.dim),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 29,
              height: 1.45,
              fontWeight: FontWeight.w900,
              letterSpacing: -.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedSelectorCard extends StatelessWidget {
  const _SpeedSelectorCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text(
            'VELOCIDAD',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: _SpeedPill('Lenta')),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: RefColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Normal',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Expanded(child: _SpeedPill('Rápida')),
        ],
      ),
    );
  }
}

class _SpeedPill extends StatelessWidget {
  final String label;

  const _SpeedPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: RefColors.glassSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RefColors.border),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: RefColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TapPauseCard extends StatelessWidget {
  const _TapPauseCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.cyan.withValues(alpha: .08),
      border: Border.all(color: RefColors.cyan.withValues(alpha: .28)),
      child: Row(
        children: [
          const Text('👆', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Toca la pantalla para pausar · desliza → para saltar al final',
              style: TextStyle(
                color: RefColors.ink,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: RefColors.cyan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '⏸ Pausar',
              style: TextStyle(
                color: Color(0xFF003A4A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KaraokeLine extends StatelessWidget {
  final double fontSize;

  const _KaraokeLine({this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    final lead = words.take(3).join(' ');
    final current = words.length > 3 ? words[3] : words.last;
    final tail = words.skip(4).join(' ');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$lead ',
            style: const TextStyle(color: RefColors.lime),
          ),
          TextSpan(
            text: current,
            style: const TextStyle(
              color: RefColors.ink,
              backgroundColor: Color(0x553B173E),
              decoration: TextDecoration.underline,
              decorationColor: RefColors.pink,
              decorationThickness: 3,
            ),
          ),
          TextSpan(
            text: tail.isEmpty ? '' : ' $tail',
            style: const TextStyle(color: RefColors.muted),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.42,
        fontWeight: FontWeight.w900,
        letterSpacing: -.35,
      ),
    );
  }
}

class _PulseMic extends StatelessWidget {
  const _PulseMic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final size in [150.0, 122.0, 98.0])
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: RefColors.pink.withValues(alpha: .35),
                    width: 2,
                  ),
                ),
              ),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: RefColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: RefColors.pink.withValues(alpha: .45),
                    blurRadius: 34,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🎤', style: TextStyle(fontSize: 36)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceQuoteCard extends StatelessWidget {
  const _VoiceQuoteCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .33),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: const _KaraokeLine(fontSize: 22),
    );
  }
}

enum _WaveKind { original, you }

class _WaveformCard extends StatelessWidget {
  final _WaveKind kind;

  const _WaveformCard({required this.kind});

  @override
  Widget build(BuildContext context) {
    final isYou = kind == _WaveKind.you;
    return Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              StatusChip(
                isYou ? 'TÚ' : 'ORIGINAL',
                color: (isYou ? RefColors.pink : RefColors.cyan).withValues(
                  alpha: .18,
                ),
                borderColor: (isYou ? RefColors.pink : RefColors.cyan)
                    .withValues(alpha: .38),
                textColor: isYou ? RefColors.pink : RefColors.cyan,
              ),
              if (isYou) ...[
                const SizedBox(width: 8),
                const StatusChip(
                  '3/5 REP',
                  color: RefColors.glassStrong,
                  textColor: RefColors.pink,
                ),
              ],
              const Spacer(),
              const _SpeedMini('0.5×'),
              const SizedBox(width: 4),
              const _SpeedMini('1×', active: true),
              const SizedBox(width: 4),
              const _SpeedMini('1.5×'),
            ],
          ),
          const SizedBox(height: 14),
          _WaveBars(color: isYou ? RefColors.pink : RefColors.cyan),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                isYou ? '0:01' : '0:00',
                style: const TextStyle(
                  color: RefColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const _PlayerTinyButton(Icons.replay_rounded),
              const SizedBox(width: 10),
              _PlayerRoundButton(paused: isYou),
              const SizedBox(width: 10),
              const _PlayerTinyButton(Icons.replay_rounded, mirror: true),
              const Spacer(),
              const Text(
                '0:04',
                style: TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedMini extends StatelessWidget {
  final String label;
  final bool active;

  const _SpeedMini(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? null : RefColors.glassStrong,
        gradient: active ? RefColors.primary : null,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: active ? Colors.transparent : RefColors.border,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _WaveBars extends StatelessWidget {
  final Color color;

  const _WaveBars({required this.color});

  @override
  Widget build(BuildContext context) {
    const heights = [
      24.0,
      40.0,
      30.0,
      52.0,
      34.0,
      44.0,
      25.0,
      38.0,
      48.0,
      31.0,
      42.0,
      29.0,
    ];
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < heights.length; i++) ...[
            Expanded(
              child: Container(
                height: heights[i],
                decoration: BoxDecoration(
                  color: color.withValues(alpha: i < 6 ? .95 : .55),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < heights.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

class _PlayerTinyButton extends StatelessWidget {
  final IconData icon;
  final bool mirror;

  const _PlayerTinyButton(this.icon, {this.mirror = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: RefColors.glassStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RefColors.border),
      ),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(mirror ? -1.0 : 1.0, 1.0, 1.0),
        child: Icon(icon, size: 19),
      ),
    );
  }
}

class _PlayerRoundButton extends StatelessWidget {
  final bool paused;

  const _PlayerRoundButton({this.paused = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: paused ? 58 : 52,
      height: paused ? 58 : 52,
      decoration: BoxDecoration(
        color: paused ? null : RefColors.glassStrong,
        gradient: paused ? RefColors.primary : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: paused ? Colors.transparent : RefColors.border,
        ),
        boxShadow: paused
            ? [
                BoxShadow(
                  color: RefColors.pink.withValues(alpha: .35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Icon(paused ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }
}

class _BlocksCounterCard extends StatelessWidget {
  const _BlocksCounterCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '2 / 4',
                  style: TextStyle(
                    color: RefColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(text: ' en su lugar'),
              ],
            ),
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Spacer(),
          RefChip('Intento 1/3', dense: true),
        ],
      ),
    );
  }
}

class _BlocksListCard extends StatelessWidget {
  const _BlocksListCard();

  @override
  Widget build(BuildContext context) {
    final blocks = _studyBlocks(context);
    return Glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            _VerseBlock(
              blocks[i],
              correct: i < 2,
              selected: i == 2,
              wrong: i == 3,
            ),
            if (i != blocks.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _VerseBlock extends StatelessWidget {
  final String text;
  final bool correct;
  final bool selected;
  final bool wrong;

  const _VerseBlock(
    this.text, {
    this.correct = false,
    this.selected = false,
    this.wrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = correct
        ? RefColors.lime
        : wrong
        ? RefColors.urgent
        : selected
        ? RefColors.pink
        : RefColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: correct
            ? RefColors.lime.withValues(alpha: .12)
            : wrong
            ? RefColors.urgent.withValues(alpha: .12)
            : selected
            ? Colors.transparent
            : RefColors.glassSoft,
        gradient: selected
            ? LinearGradient(
                colors: [
                  RefColors.pink.withValues(alpha: .2),
                  const Color(0xFF7C3AFF).withValues(alpha: .1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? RefColors.pink : accent.withValues(alpha: .48),
          width: 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: RefColors.pink.withValues(alpha: .3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          if (correct || wrong)
            Icon(
              correct ? Icons.check_rounded : Icons.close_rounded,
              color: correct ? RefColors.lime : RefColors.urgent,
              size: 18,
            ),
        ],
      ),
    );
  }
}

class _BlockMoveTarget extends StatelessWidget {
  final bool visible;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<int> onAccept;

  const _BlockMoveTarget({
    required this.visible,
    required this.active,
    required this.onTap,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => active,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        final shown = visible || highlighted;
        return GestureDetector(
          onTap: active ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: shown ? 34 : 6,
            margin: EdgeInsets.symmetric(vertical: shown ? 6 : 2),
            padding: shown
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: RefColors.cyan.withValues(alpha: highlighted ? .20 : .10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: RefColors.cyan.withValues(
                  alpha: shown ? (highlighted ? .72 : .42) : 0,
                ),
              ),
            ),
            child: shown
                ? Center(
                    child: Text(
                      'Mover aquí',
                      style: TextStyle(
                        color: active
                            ? RefColors.cyan
                            : RefColors.cyan.withValues(alpha: .45),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _LostPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _LostPanel({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      color: RefColors.urgent.withValues(alpha: .12),
      border: Border.all(color: RefColors.urgent.withValues(alpha: .55)),
      child: Column(
        children: [
          const Icon(
            Icons.timer_off_rounded,
            color: RefColors.urgent,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.urgent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RefColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onRetry();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [RefColors.pink, RefColors.urgent],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Reintentar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteStatsCard extends StatelessWidget {
  final bool level2;
  final String firstValue;
  final String firstLabel;
  final String secondValue;
  final String secondLabel;
  final String timeValue;

  const _CompleteStatsCard({
    this.level2 = false,
    this.firstValue = '1/3',
    this.firstLabel = 'HUECOS',
    this.secondValue = '2/2',
    this.secondLabel = 'INTENTOS',
    this.timeValue = '00:45',
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 15),
      gradient: LinearGradient(
        colors: const [Color(0x55372B86), Color(0x668B5B21)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FlashStat(firstValue, firstLabel),
          _FlashStat(secondValue, secondLabel),
          if (level2)
            _FlashStat(timeValue, 'TIEMPO', valueColor: RefColors.sun),
        ],
      ),
    );
  }
}

class _CompleteSentenceCard extends StatelessWidget {
  final bool level2;

  const _CompleteSentenceCard({this.level2 = false});

  @override
  Widget build(BuildContext context) {
    final text = _maskedStudyLine(context, visibleWords: level2 ? 1 : 3);
    return Glass(
      padding: EdgeInsets.symmetric(
        horizontal: level2 ? 14 : 18,
        vertical: level2 ? 32 : 34,
      ),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .32),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          height: 1.6,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WordBankCard extends StatelessWidget {
  final bool level2;

  const _WordBankCard({this.level2 = false});

  @override
  Widget build(BuildContext context) {
    final base = _studyWords(_cardStudyText(context)).take(level2 ? 8 : 5);
    final words = [...base, if (level2) 'camino' else 'guía', 'padre'];
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.glassSoft,
      child: Column(
        children: [
          const Text(
            'ELIGE LA PALABRA CORRECTA',
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [for (final word in words) _WordChip(word)],
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool correct;

  const _WordChip(this.label, {this.active = false, this.correct = false});

  @override
  Widget build(BuildContext context) {
    final accent = correct
        ? RefColors.lime
        : active
        ? RefColors.cyan
        : RefColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (active || correct)
            ? accent.withValues(alpha: .14)
            : RefColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: .55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (correct) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 15,
              color: RefColors.lime,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FirstLetterSentence extends StatelessWidget {
  final String? text;
  final int level;
  final List<String>? targets;
  final List<String?>? answers;
  final int activeIndex;
  final ValueChanged<int>? onBlankTap;

  const _FirstLetterSentence({
    this.text,
    required this.level,
    this.targets,
    this.answers,
    this.activeIndex = 0,
    this.onBlankTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHarder = level >= 2;
    final sourceText = text ?? _cardStudyText(context);
    final words = _studyWords(sourceText);
    final targetWords =
        targets ?? _firstLetterTargets(sourceText, level: level);
    final answerWords =
        answers ?? List<String?>.filled(targetWords.length, null);
    final visibleWords = switch (level) {
      1 => 3,
      2 => 1,
      _ => 0,
    };
    final usedTargetIndexes = <int>{};
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 32),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .28),
          RefColors.sun.withValues(alpha: .30),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Center(
        child: Wrap(
          spacing: isHarder ? 8 : 10,
          runSpacing: isHarder ? 12 : 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            for (var wordIndex = 0; wordIndex < words.length; wordIndex++)
              if (wordIndex < visibleWords)
                _LetterWord(words[wordIndex])
              else
                _letterWidget(
                  words[wordIndex],
                  usedTargetIndexes,
                  targetWords,
                  answerWords,
                ),
            const Text(
              '.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _letterWidget(
    String word,
    Set<int> usedTargetIndexes,
    List<String> targetWords,
    List<String?> answerWords,
  ) {
    final targetIndex = _matchingUnusedTargetIndex(
      word,
      usedTargetIndexes,
      targetWords,
    );
    if (targetIndex == null) return _LetterWord(word);
    usedTargetIndexes.add(targetIndex);
    return _LetterBlank(
      answer: answerWords[targetIndex],
      active: activeIndex == targetIndex && answerWords[targetIndex] == null,
      wordLength: word.length,
      onTap: () => onBlankTap?.call(targetIndex),
    );
  }

  int? _matchingUnusedTargetIndex(
    String word,
    Set<int> usedTargetIndexes,
    List<String> targetWords,
  ) {
    for (var index = 0; index < targetWords.length; index++) {
      if (usedTargetIndexes.contains(index)) continue;
      if (_sameAnswer(word, targetWords[index])) return index;
    }
    return null;
  }
}

class _LetterWord extends StatelessWidget {
  final String text;

  const _LetterWord(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -.2,
      ),
    );
  }
}

class _LetterBlank extends StatelessWidget {
  final String? answer;
  final bool active;
  final int wordLength;
  final VoidCallback onTap;

  const _LetterBlank({
    required this.answer,
    required this.active,
    required this.wordLength,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final complete = answer != null;
    final accent = complete
        ? RefColors.lime
        : active
        ? RefColors.cyan
        : RefColors.border;
    final length = wordLength.clamp(1, 14);
    return GestureDetector(
      onTap: complete ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: BoxConstraints(minWidth: (length * 10.0).clamp(28, 160)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: .35)
              : accent.withValues(alpha: complete ? .16 : .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: active ? 1.0 : .5),
            width: active ? 2.4 : 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: .6),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          answer ?? '_' * length,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: complete ? RefColors.lime : RefColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _KeyboardCard extends StatelessWidget {
  final ValueChanged<String>? onLetterTap;

  const _KeyboardCard({this.onLetterTap});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ñ'],
      ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
    ];
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              children: [
                if (i == 2) const Spacer(flex: 1),
                for (final letter in rows[i]) ...[
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _KeyCap(
                        letter,
                        onTap: onLetterTap == null
                            ? null
                            : () => onLetterTap!(letter),
                      ),
                    ),
                  ),
                ],
                if (i == 2) const Spacer(flex: 1),
              ],
            ),
            if (i < rows.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _KeyCap(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: .06)
              : Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .16),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

enum _ListeningColorMode { blue, pink }

class _VoiceRecitationPracticeCard extends StatefulWidget {
  final String targetText;
  final _ListeningColorMode colorMode;
  final void Function(bool passed) onCompleted;

  const _VoiceRecitationPracticeCard({
    required this.targetText,
    required this.colorMode,
    required this.onCompleted,
  });

  @override
  State<_VoiceRecitationPracticeCard> createState() =>
      _VoiceRecitationPracticeCardState();
}

class _VoiceRecitationPracticeCardState
    extends State<_VoiceRecitationPracticeCard> {
  stt.SpeechToText? _speech;
  bool _ready = false;
  bool _listening = false;
  bool _completed = false;
  String _recognized = '';
  int _currentBlock = 0;
  int? _lastWrongAt;
  int _attemptsRemaining = 5;

  late List<String> _targetBlocks;
  late List<bool> _blockSolved;

  @override
  void initState() {
    super.initState();
    _targetBlocks = _splitIntoBlocks(widget.targetText);
    _blockSolved = List<bool>.filled(_targetBlocks.length, false);
    _initSpeech();
  }

  @override
  void didUpdateWidget(covariant _VoiceRecitationPracticeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetText != widget.targetText) {
      _targetBlocks = _splitIntoBlocks(widget.targetText);
      _blockSolved = List<bool>.filled(_targetBlocks.length, false);
      _currentBlock = 0;
      _recognized = '';
      _attemptsRemaining = 5;
      _completed = false;
    }
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    final available = await _speech!.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    setState(() => _ready = available);
  }

  @override
  void dispose() {
    _speech?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_ready) {
      await _initSpeech();
      return;
    }
    if (_listening) {
      await _speech!.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
    });
    await _speech!.listen(
      localeId: 'es_ES',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 6),
      onResult: (result) => _handleRecognition(result.recognizedWords),
    );
  }

  void _handleRecognition(String text) {
    if (!mounted) return;
    setState(() => _recognized = text);
    if (_currentBlock >= _targetBlocks.length) return;

    final normalizedSpoken = _normalizeSpeechText(text);
    final expectedBlock = _targetBlocks[_currentBlock];
    final normalizedExpected = _normalizeSpeechText(expectedBlock);

    if (_blocksMatch(normalizedSpoken, normalizedExpected)) {
      setState(() {
        _blockSolved[_currentBlock] = true;
        _currentBlock += 1;
        _recognized = '';
      });
      if (_currentBlock >= _targetBlocks.length && !_completed) {
        _completed = true;
        _stopListeningOnComplete();
        widget.onCompleted(true);
      }
    } else if (normalizedSpoken.length >= 3) {
      setState(() {
        _lastWrongAt = DateTime.now().millisecondsSinceEpoch;
        _attemptsRemaining = (_attemptsRemaining - 1).clamp(0, 99);
      });
      if (_attemptsRemaining <= 0 && !_completed) {
        _completed = true;
        _stopListeningOnComplete();
        widget.onCompleted(false);
      }
    }
  }

  void _stopListeningOnComplete() {
    _speech?.cancel();
    if (mounted) setState(() => _listening = false);
  }

  bool _blocksMatch(String spoken, String expected) {
    if (spoken == expected) return true;
    if (spoken.contains(expected) || expected.contains(spoken)) return true;
    final spokenWords = spoken.split(' ').where((w) => w.isNotEmpty).toList();
    final expectedWords = expected
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (spokenWords.isEmpty || expectedWords.isEmpty) return false;
    int matchCount = 0;
    for (final expectedWord in expectedWords) {
      for (final spokenWord in spokenWords) {
        if (_wordsSimilar(spokenWord, expectedWord)) {
          matchCount++;
          break;
        }
      }
    }
    final matchRatio = matchCount / expectedWords.length;
    return matchRatio >= 0.5;
  }

  bool _wordsSimilar(String a, String b) {
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen <= 1) return a == b;
    int distance = 0;
    final minLength = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < minLength; i++) {
      if (a[i] != b[i]) distance++;
    }
    distance += (maxLen - minLength);
    final similarity = 1 - (distance / maxLen);
    return similarity >= 0.5;
  }

  List<String> _splitIntoBlocks(String text) {
    final words = _studyWords(text);
    if (words.length <= 6) return words;
    final blockSize = (words.length / 3).round().clamp(2, 5);
    final blocks = <String>[];
    for (var i = 0; i < words.length; i += blockSize) {
      final end = (i + blockSize).clamp(0, words.length);
      blocks.add(words.sublist(i, end).join(' '));
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final isBlue = widget.colorMode == _ListeningColorMode.blue;
    final accent = _completed
        ? RefColors.lime
        : isBlue
        ? RefColors.cyan
        : RefColors.pink;
    final wrongRecent =
        _lastWrongAt != null &&
        DateTime.now().millisecondsSinceEpoch - _lastWrongAt! < 1200;
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _targetBlocks.length; i++)
                _RecitationBlock(
                  text: _targetBlocks[i],
                  solved: _blockSolved[i],
                  active: i == _currentBlock && !_completed,
                  accent: accent,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: _listening ? .55 : .18),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: .85)),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .35),
                        blurRadius: _listening ? 28 : 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: RefColors.ink,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: wrongRecent
                        ? RefColors.urgent.withValues(alpha: .18)
                        : HtmlRefColors.glassSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: wrongRecent
                          ? RefColors.urgent
                          : HtmlRefColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    _recognized.isEmpty
                        ? (_listening ? 'Escuchando…' : 'Toca el mic y recita')
                        : _recognized,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _recognized.isEmpty
                          ? RefColors.dim
                          : RefColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: .6)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_attemptsRemaining',
                      style: TextStyle(
                        color: _attemptsRemaining <= 1
                            ? RefColors.urgent
                            : accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'intentos',
                      style: TextStyle(
                        color: accent.withValues(alpha: .85),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'restantes',
                      style: TextStyle(
                        color: accent.withValues(alpha: .85),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecitationBlock extends StatelessWidget {
  final String text;
  final bool solved;
  final bool active;
  final Color accent;

  const _RecitationBlock({
    required this.text,
    required this.solved,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = solved
        ? RefColors.lime
        : active
        ? accent
        : RefColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: blockColor.withValues(alpha: solved || active ? .16 : .06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: blockColor.withValues(alpha: .6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (solved) ...[
            const Icon(Icons.check_rounded, color: RefColors.lime, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            solved ? text : '_' * text.length.clamp(3, 20),
            style: TextStyle(
              color: solved ? RefColors.lime : RefColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningHud extends StatelessWidget {
  final _ListeningColorMode colorMode;

  const _ListeningHud({required this.colorMode});

  @override
  Widget build(BuildContext context) {
    final isBlue = colorMode == _ListeningColorMode.blue;
    final accent = isBlue ? RefColors.cyan : RefColors.pink;
    final icon = isBlue ? '🎧' : '🎤';
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .18),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: .45)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Empieza a recitar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '● ESCUCHANDO...',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceHiddenWordsCard extends StatelessWidget {
  final bool finalMode;

  const _VoiceHiddenWordsCard({required this.finalMode});

  @override
  Widget build(BuildContext context) {
    final words = _studyWords(_cardStudyText(context));
    if (finalMode) {
      return _buildAllHidden(words);
    }
    final rng = math.Random(DateTime.now().millisecondsSinceEpoch ~/ 60000);
    final hiddenRatio = 0.35;
    final hiddenCount = (words.length * hiddenRatio).round().clamp(
      1,
      words.length - 1,
    );
    final indices = List.generate(words.length, (i) => i);
    indices.shuffle(rng);
    final hiddenIndices = indices.take(hiddenCount).toSet();
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .30),
          RefColors.sun.withValues(alpha: .28),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < words.length; i++)
                    if (hiddenIndices.contains(i))
                      _HiddenWord(
                        wordLength: words[i].length,
                        active: false,
                        pink: false,
                      )
                    else
                      _LetterWord(words[i]),
                  const Text(
                    '.',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllHidden(List<String> words) {
    return Glass(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      gradient: LinearGradient(
        colors: [
          RefColors.violet.withValues(alpha: .30),
          RefColors.sun.withValues(alpha: .28),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < words.length; i++)
                    _HiddenWord(
                      wordLength: words[i].length,
                      active: i == 0,
                      pink: true,
                    ),
                  const Text(
                    '.',
                    style: TextStyle(
                      color: RefColors.muted,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HiddenWord extends StatelessWidget {
  final int wordLength;
  final bool active;
  final bool pink;
  final bool solved;
  final bool skipped;
  final bool wrongFlash;
  final String? word;

  const _HiddenWord({
    required this.wordLength,
    this.active = false,
    this.pink = false,
    this.solved = false,
    this.skipped = false,
    this.wrongFlash = false,
    this.word,
  });

  @override
  Widget build(BuildContext context) {
    final accent = wrongFlash
        ? RefColors.urgent
        : skipped
        ? RefColors.sun
        : solved
        ? RefColors.lime
        : active
        ? (pink ? RefColors.pink : RefColors.cyan)
        : RefColors.border;
    final filledColor = skipped ? RefColors.sun : RefColors.lime;
    final length = wordLength.clamp(1, 14);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(minWidth: (length * 10.0).clamp(28, 160)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: wrongFlash ? .28 : (solved || active ? .16 : .08),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: wrongFlash ? 1 : .62),
          width: wrongFlash ? 2 : 1.5,
        ),
      ),
      child: solved && word != null
          ? TweenAnimationBuilder<double>(
              key: ValueKey('solved-$word-$skipped'),
              tween: Tween(begin: 0.55, end: 1.0),
              duration: const Duration(milliseconds: 360),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                word!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: filledColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Text(
              '_' * length,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RefColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _QuizNav extends StatelessWidget {
  const _QuizNav();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++) ...[
            Expanded(child: _QuizChip('Q$i', active: i == 2)),
            if (i < 5) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _QuizChip extends StatelessWidget {
  final String label;
  final bool active;

  const _QuizChip(this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                colors: [
                  RefColors.cyan.withValues(alpha: .92),
                  const Color(0xFF347DFF).withValues(alpha: .92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : RefColors.glassStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? RefColors.cyan : RefColors.border,
          width: active ? 1.6 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : RefColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String text;

  const _WarningCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      color: RefColors.pink.withValues(alpha: .10),
      border: Border.all(color: RefColors.pink.withValues(alpha: .36)),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _Stat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GlyphIcon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: RefColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTopBar extends StatelessWidget {
  final String center;

  const _ExerciseTopBar({required this.center});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Inside the exercise flow the back arrow jumps to the progress
          // tree (the user's "session map"), not the previous step. Use
          // pushReplacement so we don't pile new entries on the stack.
          RefBackButton(
            onTap: () => Navigator.pushReplacementNamed(
              context,
              '${AppRoutes.flow}/progress-tree',
            ),
          ),
          Expanded(child: Center(child: RefChip(center, dense: true))),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String ctx;
  final String? turn;
  final String question;
  final List<(String, String, bool)> options;

  const _QuestionCard({
    required this.ctx,
    this.turn,
    required this.question,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Glass(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ctx,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RefColors.muted,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (turn != null)
                    Text(
                      turn!,
                      style: const TextStyle(
                        color: RefColors.sun,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                question,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final opt in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Glass(
              radius: 16,
              padding: const EdgeInsets.all(12),
              color: opt.$3
                  ? RefColors.pink.withValues(alpha: .14)
                  : RefColors.glass,
              border: Border.all(
                color: opt.$3
                    ? RefColors.pink.withValues(alpha: .45)
                    : RefColors.border,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: opt.$3 ? RefColors.primary : null,
                      color: opt.$3 ? null : RefColors.glassStrong,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        opt.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      opt.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final deck = store.activeDeck;
    final card = store.activeCard;
    final progress = (store.currentCardIndex + 1) / deck.cards.length;
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlashcardsTopBar(title: deck.title),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: RefProgress(progress.clamp(.05, 1.0)),
          ),
          _FlashcardDeck(deck: deck, card: card, index: store.currentCardIndex),
          const SizedBox(height: 20),
          _FlashcardActions(
            onAgain: () => store.answerCurrentCard(false),
            onHard: () => store.answerCurrentCard(false),
            onGood: () => store.answerCurrentCard(true),
            onEasy: () => store.answerCurrentCard(true),
          ),
          const SizedBox(height: 12),
          _FlashcardStatsStrip(
            correct: store.correctAnswers,
            wrong: store.wrongAnswers,
            precision: store.completedCards == 0
                ? deck.retention
                : ((store.correctAnswers / store.completedCards) * 100).round(),
          ),
        ],
      ),
    );
  }
}

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ReferencePage(
      showBottomNav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Premium'),
          Glass(
            padding: const EdgeInsets.all(20),
            gradient: LinearGradient(
              colors: [
                RefColors.pink.withValues(alpha: .28),
                RefColors.sun.withValues(alpha: .30),
                RefColors.violet.withValues(alpha: .22),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: RefColors.glassStrong,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: RefColors.border),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Memorizar Premium',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Sin anuncios y con ejercicios inteligentes cuando conectemos IA real.',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 13,
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _PremiumBenefit(
            icon: Icons.quiz_rounded,
            title: 'Quizes inteligentes',
            body:
                'Preguntas y opciones generadas para el contenido que estás memorizando.',
          ),
          const SizedBox(height: 10),
          const _PremiumBenefit(
            icon: Icons.block_rounded,
            title: 'Sin anuncios',
            body: 'La sesión queda limpia y sin interrupciones.',
          ),
          const SizedBox(height: 10),
          const _PremiumBenefit(
            icon: Icons.auto_awesome_rounded,
            title: 'Más ejercicios avanzados',
            body:
                'Variantes de examen para que cada intento se sienta distinto.',
          ),
          const SizedBox(height: 16),
          Cta(
            store.isPremium ? 'Premium activo' : 'Activar cuando esté listo',
            onTap: () {
              store.setPremiumPreview(!store.isPremium);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    store.isPremium
                        ? 'Preview premium activado para probar quizes.'
                        : 'Preview premium desactivado.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'Esto es un preview local. El cobro real se conecta luego con StoreKit/RevenueCat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PremiumBenefit({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(14),
      color: RefColors.glass,
      border: Border.all(color: RefColors.border),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: RefColors.sun.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: RefColors.sun.withValues(alpha: .45)),
            ),
            child: Icon(icon, color: RefColors.sun, size: 22),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashcardsTopBar extends StatelessWidget {
  final String title;

  const _FlashcardsTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(exitText: true),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Repaso espaciado',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _FlashcardDeck extends StatelessWidget {
  final MemoryDeckData deck;
  final MemoryCardData card;
  final int index;

  const _FlashcardDeck({
    required this.deck,
    required this.card,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 510,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: -8,
            left: 10,
            right: 10,
            bottom: 8,
            child: Transform.rotate(
              angle: -0.035,
              child: _DeckLayer(opacity: .5),
            ),
          ),
          Positioned.fill(
            top: -4,
            left: 5,
            right: 5,
            bottom: 4,
            child: Transform.rotate(
              angle: 0.018,
              child: _DeckLayer(opacity: .7),
            ),
          ),
          Positioned.fill(
            child: Glass(
              radius: 26,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              gradient: LinearGradient(
                colors: [
                  RefColors.violet.withValues(alpha: .38),
                  RefColors.sun.withValues(alpha: .42),
                  RefColors.violet.withValues(alpha: .28),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FlashcardMeta(deck: deck, index: index),
                  Expanded(child: _FlashcardQuestion(card: card)),
                  _FlashcardHint(card: card),
                  const SizedBox(height: 14),
                  const _FlashcardNavHint(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckLayer extends StatelessWidget {
  final double opacity;

  const _DeckLayer({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RefColors.glassSoft.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: RefColors.border.withValues(alpha: opacity)),
      ),
    );
  }
}

class _FlashcardMeta extends StatelessWidget {
  final MemoryDeckData deck;
  final int index;

  const _FlashcardMeta({required this.deck, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deck.isBible
                    ? 'BIBLIA · ${deck.subtitle}'
                    : deck.subtitle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'TARJETA ${index + 1} DE ${deck.cards.length}',
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: RefColors.glassStrong,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RefColors.border),
          ),
          child: const Icon(Icons.volume_up_outlined, size: 19),
        ),
      ],
    );
  }
}

class _FlashcardQuestion extends StatelessWidget {
  final MemoryCardData card;

  const _FlashcardQuestion({required this.card});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          card.front,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            height: 1.18,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
      ),
    );
  }
}

class _FlashcardHint extends StatelessWidget {
  final MemoryCardData card;

  const _FlashcardHint({required this.card});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .30),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: RefColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💡', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                card.back,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardNavHint extends StatelessWidget {
  const _FlashcardNavHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _FlashcardArrow(Icons.arrow_back_rounded),
        Expanded(
          child: Text(
            'Toca para voltear ↻',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _FlashcardArrow(Icons.arrow_forward_rounded),
      ],
    );
  }
}

class _FlashcardArrow extends StatelessWidget {
  final IconData icon;

  const _FlashcardArrow(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: RefColors.glassStrong,
        shape: BoxShape.circle,
        border: Border.all(color: RefColors.border),
      ),
      child: Icon(icon, size: 17),
    );
  }
}

class _FlashcardActions extends StatelessWidget {
  final VoidCallback onAgain;
  final VoidCallback onHard;
  final VoidCallback onGood;
  final VoidCallback onEasy;

  const _FlashcardActions({
    required this.onAgain,
    required this.onHard,
    required this.onGood,
    required this.onEasy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FlashcardAction('↻', 'DE NUEVO', RefColors.urgent, onAgain),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FlashcardAction('😬', 'DIFÍCIL', RefColors.sun, onHard),
        ),
        const SizedBox(width: 8),
        Expanded(child: _FlashcardAction('👍', 'BIEN', RefColors.cyan, onGood)),
        const SizedBox(width: 8),
        Expanded(child: _FlashcardAction('✨', 'FÁCIL', RefColors.lime, onEasy)),
      ],
    );
  }
}

class _FlashcardAction extends StatelessWidget {
  final String icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _FlashcardAction(this.icon, this.label, this.accent, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        color: accent.withValues(alpha: .10),
        border: Border.all(color: accent.withValues(alpha: .34)),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: icon == '↻' ? 22 : 20)),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RefColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardStatsStrip extends StatelessWidget {
  final int correct;
  final int wrong;
  final int precision;

  const _FlashcardStatsStrip({
    required this.correct,
    required this.wrong,
    required this.precision,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      color: RefColors.glassStrong,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FlashStat('$correct', 'CORRECTAS'),
          _FlashStat('$wrong', 'FALLADAS'),
          _FlashStat('$precision%', 'PRECISIÓN'),
        ],
      ),
    );
  }
}

class _FlashStat extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _FlashStat(this.value, this.label, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: RefColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      ],
    );
  }
}

class _ProgressTreeScreen extends StatefulWidget {
  const _ProgressTreeScreen();

  @override
  State<_ProgressTreeScreen> createState() => _ProgressTreeScreenState();
}

class _ProgressTreeScreenState extends State<_ProgressTreeScreen> {
  final GlobalKey _currentStepKey = GlobalKey();
  int _lastScrolledIndex = -1;

  void _scheduleScrollToCurrent(int currentIndex, {int attempt = 0}) {
    if (_lastScrolledIndex == currentIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_lastScrolledIndex == currentIndex) return;
      final ctx = _currentStepKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.35,
        );
        _lastScrolledIndex = currentIndex;
        return;
      }
      // Layout not ready — retry up to ~1s.
      if (attempt < 8) {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted) _scheduleScrollToCurrent(currentIndex, attempt: attempt + 1);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final steps = _sessionFlowSteps(store);
    final firstIncompleteIndex = steps.indexWhere(
      (s) => !store.isExerciseStepCompleted(s.slug),
    );
    final currentStepIndex = firstIncompleteIndex < 0
        ? steps.length - 1
        : firstIncompleteIndex;

    _scheduleScrollToCurrent(currentStepIndex);

    return ReferencePage(
      showBottomNav: false,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: RefColors.glass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RefColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Progreso del ejercicio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (store.sessionDailyTarget > 1)
                      Text(
                        'Tarjeta ${(store.sessionCardsCompleted + 1).clamp(1, store.sessionDailyTarget)} de ${store.sessionDailyTarget}',
                        style: const TextStyle(
                          color: RefColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(2, 2, 0, 10),
              children: [
                for (final group in _phaseGroups(steps))
                  ..._buildGroup(
                    context: context,
                    group: group,
                    steps: steps,
                    currentStepIndex: currentStepIndex,
                    store: store,
                    currentStepKey: _currentStepKey,
                  ),
              ],
            ),
          ),
          // "Pausar y volver al inicio" — la sesión y el deck siguen guardados,
          // así que al volver el usuario retoma desde el mismo paso.
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: GhostButton(
              'Pausar y volver al inicio',
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<(String, int, int)> _phaseGroups(List<ExerciseFlowData> steps) {
    final groups = <(String, int, int)>[];
    var cursor = 0;
    while (cursor < steps.length) {
      final label = _phaseLabelFor(steps[cursor].slug);
      var end = cursor + 1;
      while (end < steps.length && _phaseLabelFor(steps[end].slug) == label) {
        end++;
      }
      groups.add((label, cursor, end));
      cursor = end;
    }
    return groups;
  }

  List<Widget> _buildGroup({
    required BuildContext context,
    required (String, int, int) group,
    required List<ExerciseFlowData> steps,
    required int currentStepIndex,
    required AppStore store,
    required GlobalKey currentStepKey,
  }) {
    final start = group.$2.clamp(0, steps.length);
    final end = group.$3.clamp(0, steps.length);
    if (start >= end) return const [];
    final groupSteps = steps.sublist(start, end);
    final active = currentStepIndex >= start && currentStepIndex < end;
    final completed = currentStepIndex >= end;
    final accent = completed
        ? RefColors.lime
        : active
        ? RefColors.pink
        : RefColors.muted;

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(58, 6, 4, 8),
        child: Row(
          children: [
            Text(
              group.$1.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 1,
                color: accent.withValues(alpha: active ? .45 : .22),
              ),
            ),
          ],
        ),
      ),
      for (int local = 0; local < groupSteps.length; local++)
        _ReferenceTimelineStep(
          key: (start + local) == currentStepIndex ? currentStepKey : null,
          step: groupSteps[local],
          index: start + local,
          totalCount: steps.length,
          currentIndex: currentStepIndex,
          store: store,
          isLastInGroup: local == groupSteps.length - 1,
          onTapStep: (slug) => Navigator.pushReplacementNamed(
            context,
            '${AppRoutes.flow}/$slug',
          ),
        ),
    ];
  }
}

class _ReferenceTimelineStep extends StatelessWidget {
  final ExerciseFlowData step;
  final int index;
  final int totalCount;
  final int currentIndex;
  final AppStore store;
  final void Function(String slug) onTapStep;
  final bool isLastInGroup;

  const _ReferenceTimelineStep({
    super.key,
    required this.step,
    required this.index,
    required this.totalCount,
    required this.currentIndex,
    required this.store,
    required this.onTapStep,
    this.isLastInGroup = false,
  });

  static const _activeCard = Color(0xFF4A3854);
  static const _idleCard = Color(0xFF363838);
  static const _badgeSize = 38.0;
  static const _titleAnchor = 24.0;

  @override
  Widget build(BuildContext context) {
    final isCompleted = store.isExerciseStepCompleted(step.slug);
    final isCurrent = index == currentIndex;
    final isLocked = !isCompleted && index > currentIndex;
    final isLast = isLastInGroup || index == totalCount - 1;
    final accent = isCompleted
        ? RefColors.lime
        : isCurrent
        ? RefColors.pink
        : RefColors.muted;
    final borderColor = isCompleted
        ? RefColors.lime.withValues(alpha: .85)
        : isCurrent
        ? RefColors.pink.withValues(alpha: .82)
        : RefColors.ink.withValues(alpha: .12);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Opacity(
        opacity: isLocked ? 0.42 : 1.0,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 56,
                child: Stack(
                  children: [
                    if (!isLast)
                      Positioned(
                        top: _titleAnchor + _badgeSize / 2,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? RefColors.lime.withValues(alpha: .58)
                                  : RefColors.muted.withValues(alpha: .38),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: _titleAnchor - _badgeSize / 2,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _TimelineIconBadge(
                          icon: _timelineIconFor(step.slug),
                          accent: accent,
                          active: isCurrent,
                          completed: isCompleted,
                          locked: isLocked,
                          size: _badgeSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: isLocked ? null : () => onTapStep(step.slug),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? _activeCard : _idleCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                        width: isCurrent || isCompleted ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                step.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isLocked
                                      ? RefColors.muted
                                      : RefColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (isLocked)
                              Icon(
                                Icons.lock_rounded,
                                color: RefColors.muted.withValues(alpha: .68),
                                size: 22,
                              )
                            else if (isCompleted)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: RefColors.lime,
                                size: 22,
                              )
                            else
                              Icon(
                                isCurrent
                                    ? Icons.chevron_right_rounded
                                    : Icons.play_arrow_rounded,
                                color: isCurrent
                                    ? RefColors.pink
                                    : RefColors.muted,
                                size: 26,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isLocked
                                ? RefColors.muted
                                : RefColors.ink.withValues(alpha: .82),
                            fontSize: 12,
                            height: 1.26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineIconBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool active;
  final bool completed;
  final bool locked;
  final double size;

  const _TimelineIconBadge({
    required this.icon,
    required this.accent,
    required this.active,
    required this.completed,
    required this.locked,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? RefColors.pink.withValues(alpha: .72)
            : completed
            ? RefColors.lime.withValues(alpha: .18)
            : RefColors.glassStrong,
        border: Border.all(
          color: active
              ? RefColors.pink.withValues(alpha: .95)
              : completed
              ? RefColors.lime.withValues(alpha: .85)
              : RefColors.ink.withValues(alpha: .14),
          width: active || completed ? 1.6 : 1,
        ),
      ),
      child: Icon(
        icon,
        color: active
            ? RefColors.ink
            : locked
            ? RefColors.muted
            : completed
            ? RefColors.lime
            : accent,
        size: size * .55,
      ),
    );
  }
}

IconData _timelineIconFor(String slug) {
  if (_isCompletionSlug(slug)) return Icons.keyboard_alt_rounded;
  if (_isFirstLetterSlug(slug)) return Icons.short_text_rounded;
  if (_isFinalVoiceSlug(slug)) return Icons.mic_rounded;
  switch (slug) {
    case '01-escuchar':
    case '02-lectura-frag':
      return Icons.menu_book_rounded;
    case '03-leer-voz':
    case '08-voz-guiada':
      return Icons.mic_rounded;
    case '04-escuchar-voz':
      return Icons.headphones_rounded;
    case '05-bloques':
      return Icons.segment_rounded;
    case '09-quiz':
      return Icons.help_outline_rounded;
    default:
      return Icons.radio_button_unchecked_rounded;
  }
}

class _FogStep extends StatefulWidget {
  final String targetText;
  final int round; // 0,1,2
  final bool finished;
  final VoidCallback onRoundCompleted;

  const _FogStep({
    required this.targetText,
    required this.round,
    required this.finished,
    required this.onRoundCompleted,
  });

  @override
  State<_FogStep> createState() => _FogStepState();
}

class _FogStepState extends State<_FogStep>
    with SingleTickerProviderStateMixin {
  stt.SpeechToText? _speech;
  bool _ready = false;
  bool _listening = false;
  bool _starting = false;
  late AnimationController _pulse;
  late List<String> _allWords;
  Set<int> _solved = <int>{};
  int _processedTokenCount = 0;
  String _lastSpoken = '';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _allWords = _studyWords(widget.targetText);
    _initSpeech();
  }

  @override
  void didUpdateWidget(_FogStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetText != widget.targetText) {
      _allWords = _studyWords(widget.targetText);
      _solved = <int>{};
      _processedTokenCount = 0;
    }
    if (oldWidget.round != widget.round) {
      _solved = <int>{};
      _processedTokenCount = 0;
      _lastSpoken = '';
    }
  }

  Future<bool> _initSpeech() async {
    await _speech?.cancel();
    final speech = stt.SpeechToText();
    _speech = speech;
    final ok = await speech.initialize(
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          _pulse.stop();
          _pulse.value = 0;
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        _pulse.stop();
        _pulse.value = 0;
        setState(() {
          _ready = false;
          _listening = false;
        });
      },
    );
    if (!mounted) return false;
    setState(() => _ready = ok);
    return ok;
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech?.cancel();
    super.dispose();
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]'), '');

  Future<void> _toggle() async {
    if (_starting || widget.finished) return;
    final speech = _speech;
    if (_listening || (speech?.isListening ?? false)) {
      _pulse.stop();
      _pulse.value = 0;
      HapticFeedback.selectionClick();
      await speech?.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    _starting = true;
    try {
      if (_speech == null || !_ready) {
        final ok = await _initSpeech();
        if (!mounted || !ok) return;
      }
      HapticFeedback.lightImpact();
      _processedTokenCount = 0;
      _solved = <int>{};
      _pulse.repeat();
      setState(() => _listening = true);
      await _speech!.listen(
        localeId: 'es_ES',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 8),
        onResult: _onResult,
      );
    } catch (_) {
      if (mounted) {
        _pulse.stop();
        _pulse.value = 0;
        setState(() {
          _ready = false;
          _listening = false;
        });
      }
    } finally {
      _starting = false;
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final text = result.recognizedWords;
    final isFinal = result.finalResult;
    final raw = text.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
    if (raw.isEmpty) return;
    if (raw.last != _lastSpoken) {
      setState(() => _lastSpoken = raw.last);
    }
    final lockedCount = isFinal ? raw.length : raw.length - 1;
    var processedNow = _processedTokenCount;
    int pointer = _solved.length;
    void process(String token) {
      if (pointer >= _allWords.length) return;
      if (token.trim().isEmpty) return;
      if (_voiceMatch(token, _allWords[pointer])) {
        setState(() => _solved.add(pointer));
        pointer += 1;
        HapticFeedback.lightImpact();
      }
    }
    for (var i = processedNow; i < lockedCount; i++) {
      process(raw[i]);
      processedNow = i + 1;
    }
    _processedTokenCount = processedNow;
    if (_solved.length >= _allWords.length) {
      _speech?.stop();
      _pulse.stop();
      _pulse.value = 0;
      setState(() => _listening = false);
      widget.onRoundCompleted();
    }
  }

  double get _blurSigma {
    if (widget.finished) return 18.0;
    switch (widget.round) {
      case 0:
        return 3.0;
      case 1:
        return 7.0;
      default:
        return 14.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final solvedCount = _solved.length;
    final total = _allWords.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.finished
                    ? 'Recitación completada'
                    : 'Ronda ${widget.round + 1} / 3',
                style: const TextStyle(
                  color: RefColors.pink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              Text(
                '$solvedCount / $total',
                style: const TextStyle(
                  color: RefColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Glass(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          gradient: LinearGradient(
            colors: [
              RefColors.violet.withValues(alpha: .22),
              RefColors.cyan.withValues(alpha: .10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImageFiltered(
              imageFilter:
                  ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
              child: Text(
                widget.targetText,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.finished)
          Glass(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            color: RefColors.lime.withValues(alpha: .14),
            border: Border.all(color: RefColors.lime.withValues(alpha: .55)),
            child: Column(
              children: const [
                Icon(Icons.check_circle_rounded,
                    color: RefColors.lime, size: 36),
                SizedBox(height: 10),
                Text(
                  '¡Niebla disipada!',
                  style: TextStyle(
                    color: RefColors.lime,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Recitaste el texto de memoria.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RefColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                height: 64,
                decoration: BoxDecoration(
                  gradient: _listening ? RefColors.primary : null,
                  color: _listening ? null : RefColors.glassStrong,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _listening
                        ? RefColors.pink
                        : RefColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _listening ? 'Escuchando...' : 'Recita el texto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecitationStep extends StatefulWidget {
  final String targetText;
  final bool finalMode;
  final _ListeningColorMode colorMode;
  final void Function(bool passed) onCompleted;

  const _RecitationStep({
    required this.targetText,
    required this.finalMode,
    required this.colorMode,
    required this.onCompleted,
  });

  @override
  State<_RecitationStep> createState() => _RecitationStepState();
}

class _RecitationStepState extends State<_RecitationStep>
    with SingleTickerProviderStateMixin {
  stt.SpeechToText? _speech;
  late final AnimationController _micPulse;
  bool _ready = false;
  bool _listening = false;
  bool _completed = false;
  bool _startingListening = false;
  bool _warmingMic = false;
  String _lastSpokenWord = '';
  int _attemptsLeft = 7;
  int? _lastWrongAt;
  int _processedTokenCount = 0;
  String _lastRawText = '';

  late List<String> _allWords;
  late Set<int> _hiddenIndexes; // word indexes that need to be recited
  late List<int> _orderedHidden; // hidden indexes sorted (text order)
  late Set<int> _solvedIndexes;
  late Set<int> _skippedIndexes;
  int _activePointer = 0; // index into _orderedHidden

  @override
  void initState() {
    super.initState();
    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _resetExerciseState();
    // Pre-warm STT en background para evitar cold-start en el primer tap.
    _initSpeech();
  }

  @override
  void didUpdateWidget(_RecitationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetText != widget.targetText ||
        oldWidget.finalMode != widget.finalMode) {
      _micPulse.stop();
      _micPulse.value = 0;
      _speech?.cancel();
      setState(_resetExerciseState);
    }
  }

  void _resetExerciseState() {
    _allWords = _studyWords(widget.targetText);
    _hiddenIndexes = _pickHiddenIndexes();
    _orderedHidden = _hiddenIndexes.toList()..sort();
    _solvedIndexes = <int>{};
    _skippedIndexes = <int>{};
    _activePointer = 0;
    _attemptsLeft = 7;
    _lastSpokenWord = '';
    _lastWrongAt = null;
    _processedTokenCount = 0;
    _completed = false;
    _listening = false;
    _startingListening = false;
  }

  Set<int> _pickHiddenIndexes() {
    if (widget.finalMode) {
      return Set<int>.from(List<int>.generate(_allWords.length, (i) => i));
    }
    final rng = math.Random();
    final ratio = 0.35;
    final count = (_allWords.length * ratio).round().clamp(
      1,
      _allWords.length - 1,
    );
    final indices = List<int>.generate(_allWords.length, (i) => i);
    indices.shuffle(rng);
    return indices.take(count).toSet();
  }

  Future<bool> _initSpeech() async {
    await _speech?.cancel();
    final speech = stt.SpeechToText();
    _speech = speech;
    final available = await speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          _micPulse.stop();
          _micPulse.value = 0;
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        _micPulse.stop();
        _micPulse.value = 0;
        setState(() {
          _ready = false;
          _listening = false;
        });
      },
    );
    if (!mounted) return false;
    setState(() => _ready = available);
    return available;
  }

  @override
  void dispose() {
    _micPulse.dispose();
    _speech?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_startingListening || _completed) return;
    final speech = _speech;
    if (_listening || (speech?.isListening ?? false)) {
      _micPulse.stop();
      _micPulse.value = 0;
      HapticFeedback.selectionClick();
      await speech?.stop();
      if (mounted) {
        setState(() {
          _listening = false;
          _warmingMic = false;
        });
      }
      return;
    }
    _startingListening = true;
    setState(() {
      _processedTokenCount = 0;
      _lastRawText = '';
    });
    try {
      if (_speech == null || !_ready) {
        final available = await _initSpeech();
        if (!mounted || !available) return;
      }
      HapticFeedback.lightImpact();
      _micPulse.repeat();
      // Visual "warming up": user sees 'Preparando mic...' for 450ms while the
      // iOS audio session activates. Without this the first word always gets
      // swallowed because capture starts a few hundred ms after listen().
      setState(() {
        _listening = true;
        _warmingMic = true;
      });
      // Fire listen() — do NOT await its full completion (it returns when the
      // session ends). Errors are caught and reset state.
      _speech!
          .listen(
            localeId: 'es_ES',
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.dictation,
              partialResults: true,
              cancelOnError: false,
            ),
            listenFor: const Duration(seconds: 90),
            pauseFor: const Duration(seconds: 12),
            onResult: _handleRecognition,
          )
          .catchError((Object _) {
        if (!mounted) return;
        _micPulse.stop();
        _micPulse.value = 0;
        setState(() {
          _ready = false;
          _listening = false;
          _warmingMic = false;
        });
      });
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _warmingMic = false);
    } catch (_) {
      if (!mounted) return;
      _micPulse.stop();
      _micPulse.value = 0;
      setState(() {
        _ready = false;
        _listening = false;
        _warmingMic = false;
      });
    } finally {
      _startingListening = false;
    }
  }

  String _normalizeToken(String token) =>
      token.toLowerCase().replaceAll(RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]'), '');

  void _handleRecognition(SpeechRecognitionResult result) {
    if (!mounted) return;
    final text = result.recognizedWords;
    final isFinal = result.finalResult;
    final rawTokens = text
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
    if (rawTokens.isEmpty) return;
    // If iOS reset the running text (new sentence), restart processing pointer.
    if (text.length < _lastRawText.length || _processedTokenCount > rawTokens.length) {
      _processedTokenCount = 0;
    }
    _lastRawText = text;
    if (rawTokens.last != _lastSpokenWord) {
      setState(() => _lastSpokenWord = rawTokens.last);
    }
    final lockedCount = isFinal ? rawTokens.length : rawTokens.length - 1;
    var processedNow = _processedTokenCount;
    void processToken(String rawToken, {required bool locked}) {
      if (_completed) return;
      if (_activePointer >= _orderedHidden.length) return;
      final expectedIdx = _orderedHidden[_activePointer];
      final expected = _allWords[expectedIdx];
      // Match in expected order first (fast path).
      if (_voiceMatch(rawToken, expected)) {
        HapticFeedback.lightImpact();
        setState(() {
          _solvedIndexes.add(expectedIdx);
          // Advance pointer past any already-solved indexes.
          while (_activePointer < _orderedHidden.length &&
              _solvedIndexes.contains(_orderedHidden[_activePointer])) {
            _activePointer += 1;
          }
        });
        if (_activePointer >= _orderedHidden.length && !_completed) {
          _completed = true;
          _micPulse.stop();
          _micPulse.value = 0;
          HapticFeedback.heavyImpact();
          _speech?.cancel();
          if (mounted) setState(() => _listening = false);
          widget.onCompleted(_skippedIndexes.isEmpty);
        }
        return;
      }
      // Out-of-order match: user recited the full content, fill any remaining
      // hidden slot whose word matches.
      for (final idx in _orderedHidden) {
        if (_solvedIndexes.contains(idx)) continue;
        if (_voiceMatch(rawToken, _allWords[idx])) {
          HapticFeedback.lightImpact();
          setState(() {
            _solvedIndexes.add(idx);
            while (_activePointer < _orderedHidden.length &&
                _solvedIndexes.contains(_orderedHidden[_activePointer])) {
              _activePointer += 1;
            }
          });
          if (_activePointer >= _orderedHidden.length && !_completed) {
            _completed = true;
            _micPulse.stop();
            _micPulse.value = 0;
            HapticFeedback.heavyImpact();
            _speech?.cancel();
            if (mounted) setState(() => _listening = false);
            widget.onCompleted(_skippedIndexes.isEmpty);
          }
          return;
        }
      }
      // Tokens that are part of the visible (non-hidden) content shouldn't
      // be penalized — the user is reciting the verse around the gaps.
      for (var i = 0; i < _allWords.length; i++) {
        if (_hiddenIndexes.contains(i)) continue;
        if (_voiceMatch(rawToken, _allWords[i])) return;
      }
      if (locked) {
        HapticFeedback.mediumImpact();
        setState(() {
          _lastWrongAt = DateTime.now().millisecondsSinceEpoch;
          if (_attemptsLeft > 0) _attemptsLeft -= 1;
        });
        if (_attemptsLeft == 0 && !_completed) {
          _completed = true;
          _micPulse.stop();
          _micPulse.value = 0;
          HapticFeedback.heavyImpact();
          _speech?.cancel();
          if (mounted) setState(() => _listening = false);
          widget.onCompleted(false);
        }
      }
    }

    for (var i = processedNow; i < lockedCount; i++) {
      processToken(rawTokens[i], locked: true);
      processedNow = i + 1;
    }
    if (!isFinal && processedNow < rawTokens.length) {
      final lastIdx = rawTokens.length - 1;
      final beforeAdvance = _activePointer;
      processToken(rawTokens[lastIdx], locked: false);
      if (_activePointer != beforeAdvance) {
        processedNow = lastIdx + 1;
      }
    }
    _processedTokenCount = processedNow;
  }

  @override
  Widget build(BuildContext context) {
    final isBlue = widget.colorMode == _ListeningColorMode.blue;
    final accent = _completed
        ? RefColors.lime
        : isBlue
        ? RefColors.cyan
        : RefColors.pink;
    final wrongRecent =
        _lastWrongAt != null &&
        DateTime.now().millisecondsSinceEpoch - _lastWrongAt! < 1200;
    final activeIdx = _activePointer < _orderedHidden.length
        ? _orderedHidden[_activePointer]
        : -1;
    final solvedCount = _solvedIndexes.length;
    final totalCount = _orderedHidden.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_completed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.scale(
                scale: 0.85 + 0.15 * t,
                child: Opacity(opacity: t, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: RefColors.success,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: RefColors.lime.withValues(alpha: .55),
                      blurRadius: 26,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      color: RefColors.successInk,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¡Recitación completada!',
                        style: TextStyle(
                          color: RefColors.successInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Palabra ${(_activePointer + 1).clamp(1, totalCount == 0 ? 1 : totalCount)} de ${totalCount == 0 ? 1 : totalCount}',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
              Text(
                '$solvedCount/$totalCount completadas',
                style: TextStyle(
                  color: RefColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Glass(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            gradient: LinearGradient(
              colors: [
                RefColors.violet.withValues(alpha: .30),
                RefColors.sun.withValues(alpha: .28),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < _allWords.length; i++)
                          if (_hiddenIndexes.contains(i))
                            _HiddenWord(
                              wordLength: _allWords[i].length,
                              active: i == activeIdx,
                              pink: !isBlue,
                              solved: _solvedIndexes.contains(i),
                              skipped: _skippedIndexes.contains(i),
                              wrongFlash: i == activeIdx && wrongRecent,
                              word: _allWords[i],
                            )
                          else
                            _LetterWord(_allWords[i]),
                        const Text(
                          '.',
                          style: TextStyle(
                            color: RefColors.muted,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Glass(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _toggleListening,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_listening)
                        AnimatedBuilder(
                          animation: _micPulse,
                          builder: (context, _) {
                            final t = _micPulse.value;
                            return Container(
                              width: 56 + 14 * t,
                              height: 56 + 14 * t,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withValues(alpha: 1 - t),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: accent.withValues(
                            alpha: _listening ? .55 : .18,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withValues(alpha: .85),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: .35),
                              blurRadius: _listening ? 28 : 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _startingListening
                              ? Icons.more_horiz_rounded
                              : _listening
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: RefColors.ink,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: wrongRecent
                        ? RefColors.urgent.withValues(alpha: .18)
                        : HtmlRefColors.glassSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: wrongRecent
                          ? RefColors.urgent
                          : HtmlRefColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    _lastSpokenWord.isEmpty
                        ? (_warmingMic
                            ? 'Preparando mic…'
                            : _listening
                                ? 'Escuchando…'
                                : 'Toca el mic y recita')
                        : _lastSpokenWord,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _lastSpokenWord.isEmpty
                          ? RefColors.dim
                          : RefColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: .6)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'intentos',
                      style: TextStyle(
                        color: accent.withValues(alpha: .9),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    Text(
                      'restantes',
                      style: TextStyle(
                        color: accent.withValues(alpha: .9),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_attemptsLeft',
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
