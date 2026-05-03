import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/presentation/widgets/status_chip.dart';
import '../../../core/theme.dart';
import 'glyph_icon.dart';
import 'home_screen.dart';

class RefColors {
  static const bg = AppColors.bgBase;
  static const glass = AppColors.glassBg;
  static const glassStrong = AppColors.glassStrong;
  static const glassSoft = AppColors.glassSoft;
  static const border = AppColors.glassBorder;
  static const inner = AppColors.glassInner;
  static const ink = AppColors.ink;
  static const muted = AppColors.inkMuted;
  static const dim = AppColors.inkDim;
  static const pink = AppColors.accentPink;
  static const sun = AppColors.accentSun;
  static const cyan = AppColors.accentCyan;
  static const violet = AppColors.accentViolet;
  static const lime = AppColors.accentLime;
  static const urgent = AppColors.urgent;
  static const successInk = Color(0xFF06280F);

  static const primary = LinearGradient(
    colors: [pink, sun],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const cool = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const success = LinearGradient(
    colors: [lime, Color(0xFF3ED97A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const purple = LinearGradient(
    colors: [violet, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const limeGrad = LinearGradient(
    colors: [lime, Color(0xFF5BE47D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class HtmlRefColors {
  static const glassBg = Color(0x1AFFFFFF);
  static const glassSoft = Color(0x0FFFFFFF);
  static const glassStrong = Color(0x29FFFFFF);
  static const glassBorder = Color(0x2EFFFFFF);
  static const bookSelected = Color(0x33FF3EA5);
  static const bookPartial = Color(0x2600D4FF);
  static const bookPartialBorder = Color(0x9900D4FF);
}

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

class ReferencePage extends StatelessWidget {
  final Widget child;
  final bool showBottomNav;
  final String active;

  final bool scrollable;

  const ReferencePage({
    super.key,
    required this.child,
    this.showBottomNav = true,
    this.active = AppRoutes.home,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RefColors.bg,
      body: Stack(
        children: [
          const AppAuroraBackground(),
          SafeArea(
            child: scrollable
                ? SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(18, 4, 18, showBottomNav ? 118 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [child],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(18, 4, 18, showBottomNav ? 118 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [Expanded(child: child)],
                    ),
                  ),
          ),
          if (showBottomNav)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _BottomNav(active: active),
            ),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Border? border;
  final Gradient? gradient;

  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.color = RefColors.glass,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          inner: AppColors.glassSaturate,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: border ?? Border.all(color: RefColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const _BackButton(),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const _IconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final bool exitText;

  const _BackButton({this.exitText = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chevron_left_rounded, size: 24),
          if (exitText)
            const Text('Salir', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;

  const _IconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 14,
      padding: EdgeInsets.zero,
      child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String active;

  const _BottomNav({required this.active});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      color: RefColors.bg.withValues(alpha: .6),
      child: Row(
        children: const [
          _BottomItem(Icons.home_outlined, 'Inicio', AppRoutes.home),
          _BottomItem(Icons.rectangle_outlined, 'Mazos', AppRoutes.repasar),
          _BottomItem(Icons.people_outline, 'Amigos', AppRoutes.amigos),
          _BottomItem(Icons.public, 'Comunidad', AppRoutes.comunidad),
          _BottomItem(Icons.pie_chart_outline, 'Stats', AppRoutes.stats),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _BottomItem(this.icon, this.label, this.route);

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorWidgetOfExactType<_BottomNav>();
    final isActive = parent?.active == route;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) Navigator.pushReplacementNamed(context, route);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: isActive
              ? BoxDecoration(
                  gradient: RefColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: RefColors.pink.withValues(alpha: .4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : RefColors.muted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : RefColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool dense;
  final Color? color;
  final Color? textColor;

  const _Chip(this.text, {this.dense = false, this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color ?? RefColors.glassStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RefColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

}

class _Cta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _Cta(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          gradient: RefColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: RefColors.pink.withValues(alpha: .4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _GhostButton(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: RefColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RefColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String title;
  final String? action;

  const _SectionHead(this.title, {this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          if (action != null)
            Text(
              action!,
              style: const TextStyle(color: RefColors.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _Fav extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final double size;
  final bool online;

  const _Fav(
    this.text, {
    this.gradient = RefColors.primary,
    this.size = 38,
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
            border: Border.all(color: RefColors.border),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: text == '+' ? Colors.white : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * .36,
              ),
            ),
          ),
        ),
        if (online)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: RefColors.lime,
                shape: BoxShape.circle,
                border: Border.all(color: RefColors.bg, width: 2),
                boxShadow: const [
                  BoxShadow(color: RefColors.lime, blurRadius: 6),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  final double value;
  final Gradient gradient;

  const _Progress(this.value, {this.gradient = RefColors.primary});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: RefColors.glassSoft,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value,
          child: Container(decoration: BoxDecoration(gradient: gradient)),
        ),
      ),
    );
  }
}

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
          const _TopBar(title: 'Elegir de la Biblia'),
          if (!confirmingSelection) ...[
            _Glass(
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
              onConfirmVerses: () => setState(() => _step = 'continue'),
              onFinish: _finishBibleSelection,
            ),
          const SizedBox(height: 14),
          _Glass(
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
                  for (final verse in store.selectedBibleVerses.take(5))
                    _SelectedVerseRef(verse.ref, _clipText(verse.text)),
              ],
            ),
          ),
          if (!confirmingSelection) ...[
            const SizedBox(height: 14),
            const _ThemesBrowse(),
            const SizedBox(height: 16),
            _Cta('Siguiente →', onTap: _finishBibleSelection),
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
        _Glass(
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
                  _Cta('+ Añadir ${verse.ref}', onTap: () => onAddVerse(verse)),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 4),
              _GhostButton('Cerrar búsqueda', onTap: onClear),
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
  });

  @override
  Widget build(BuildContext context) {
    if (step == 'chap') {
      return _ChapterPicker(
        selectedBook: selectedBook,
        onBack: () => onStep('book'),
        onChapter: onChapter,
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
      );
    }
    if (step == 'continue') {
      return _ContinueSelectionCard(
        onBook: () => onStep('book'),
        onFinish: onFinish,
      );
    }
    return _BookPicker(onBook: onBook);
  }
}

class _BookPicker extends StatelessWidget {
  final ValueChanged<String> onBook;

  const _BookPicker({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      color: HtmlRefColors.glassBg,
      border: Border.all(color: HtmlRefColors.glassBorder),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Libros',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              _Chip(
                'Toda la Biblia',
                dense: true,
                color: HtmlRefColors.glassSoft,
                textColor: RefColors.ink,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _CategoryLabel('ANTIGUO TESTAMENTO'),
          _BookGrid(
            books: _oldTestamentBooks.map((book) => book.name).toList(),
            selected: const {},
            partial: const {},
            onBook: onBook,
          ),
          const SizedBox(height: 8),
          const _CategoryLabel('NUEVO TESTAMENTO'),
          _BookGrid(
            books: _newTestamentBooks.map((book) => book.name).toList(),
            selected: const {},
            partial: const {},
            onBook: onBook,
          ),
        ],
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  final String text;

  const _CategoryLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: RefColors.dim,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String backLabel;
  final String title;
  final String action;
  final VoidCallback onBack;

  const _StepHeader({
    required this.backLabel,
    required this.title,
    required this.action,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
        _Chip(
          action,
          dense: true,
          color: HtmlRefColors.glassSoft,
          textColor: RefColors.ink,
        ),
      ],
    );
  }
}

class _ChapterPicker extends StatelessWidget {
  final String selectedBook;
  final VoidCallback onBack;
  final ValueChanged<int> onChapter;

  const _ChapterPicker({
    required this.selectedBook,
    required this.onBack,
    required this.onChapter,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
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

  const _BookGrid({
    required this.books,
    required this.selected,
    required this.partial,
    required this.onBook,
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
            return GestureDetector(
              onTap: () => onBook(book),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? HtmlRefColors.bookSelected
                      : isPartial
                      ? HtmlRefColors.bookPartial
                      : HtmlRefColors.glassSoft,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    width: 1.4,
                    color: isSelected
                        ? RefColors.pink
                        : isPartial
                        ? HtmlRefColors.bookPartialBorder
                        : Colors.transparent,
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

  const _VersePicker({
    required this.selectedBook,
    required this.selectedChapter,
    required this.selectedVerses,
    required this.onBack,
    required this.onVerse,
    required this.onConfirm,
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
    final canonicalBook = verses.isEmpty ? widget.selectedBook : verses.first.book;
    final selectedInStore = store.selectedBibleVerses
        .where(
          (verse) =>
              verse.book == canonicalBook && verse.chapter == widget.selectedChapter,
        )
        .map((verse) => verse.verse)
        .toSet();
    final effectiveSelected = {...widget.selectedVerses, ...selectedInStore};

    return _Glass(
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
          _Cta(
            verses.isEmpty ? 'Volver a capítulos' : 'Confirmar versículos →',
            onTap: verses.isEmpty ? widget.onBack : widget.onConfirm,
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
    return _Glass(
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

  const _SelectedVerseRef(this.title, this.subtitle);

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
          Container(
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
                style: TextStyle(fontSize: 14, color: RefColors.ink),
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
    return _Glass(
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
          const _TopBar(title: 'Nuevo contenido'),
          const _StepIndicator(active: 0, count: 3),
          const _PageHead(
            'Pega lo que quieres memorizar',
            'La app lo segmenta en tarjetas automáticamente · puedes editarlas después',
          ),
          _Glass(
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
          _Glass(
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
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: _createDeck,
                        child: const _ToolChip('+ Crear mazo', primary: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _Glass(
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
              const Expanded(child: _GhostButton('Ajustes avanzados')),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _Cta('Siguiente →', onTap: _createDeck)),
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

class _IniciarScreenState extends State<IniciarScreen> {
  int _difficulty = 1;
  int? _dailyTarget;
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
    _selectedIcon = deck.icon;
    _showIconPicker = false;
    _deckTitleController.text = deck.title;
  }

  @override
  void dispose() {
    _deckTitleController.dispose();
    super.dispose();
  }

  int _recommendedTarget(int total) => total <= 0 ? 0 : total.clamp(1, 4);

  void _stepTarget(int delta, int total) {
    if (total <= 0) return;
    final current = _dailyTarget ?? _recommendedTarget(total);
    setState(() {
      _dailyTarget = (current + delta).clamp(1, total);
    });
  }

  void _setDailyTarget(int value, int total) {
    if (total <= 0) return;
    setState(() => _dailyTarget = value.clamp(1, total));
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
    Navigator.pushNamed(context, '${AppRoutes.flow}/01-escuchar');
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
          const _TopBar(title: 'Configurar sesión'),
          _Glass(
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
                  _Glass(
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
          _Glass(
            color: HtmlRefColors.glassBg,
            border: Border.all(color: HtmlRefColors.glassBorder),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
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
                    Text(
                      totalCards == 0
                          ? 'Sin tarjetas'
                          : 'Finalizaría en $estimatedDays días',
                      style: TextStyle(
                        fontSize: 10,
                        color: RefColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
                            child: _Progress(
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
                            onTap: () => _setDailyTarget(1, totalCards),
                            child: _Chip(
                              '1 · breve',
                              dense: true,
                              color: dailyTarget == 1 ? RefColors.lime : null,
                              textColor: dailyTarget == 1
                                  ? RefColors.successInk
                                  : RefColors.ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          GestureDetector(
                            onTap: () => _setDailyTarget(
                              _recommendedTarget(totalCards),
                              totalCards,
                            ),
                            child: _Chip(
                              '2 · recomendado',
                              dense: true,
                              color:
                                  dailyTarget == _recommendedTarget(totalCards)
                                  ? RefColors.lime
                                  : null,
                              textColor:
                                  dailyTarget == _recommendedTarget(totalCards)
                                  ? RefColors.successInk
                                  : RefColors.ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          GestureDetector(
                            onTap: () => _setDailyTarget(4, totalCards),
                            child: _Chip(
                              '4 · intenso',
                              dense: true,
                              color: dailyTarget >= 4 ? RefColors.lime : null,
                              textColor: dailyTarget >= 4
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
                child: _GhostButton(
                  'Guardar y empezar luego',
                  onTap: () => _saveForLater(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 10,
                child: _Cta(
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
    return _Glass(
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
          const _TopBar(title: 'Repasar'),
          const _PageHead(
            'Memoria activa',
            'Rescata lo que ya dominaste antes de que se pierda',
          ),
          _Glass(
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
                const _Chip(
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
                _Cta(
                  '▶ Rescatar ahora · 5 min',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.flashcards),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Glass(
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
          const _SectionHead('⚠ Tarjetas más débiles', action: 'Ver todas'),
          for (final card in dueCards)
            _ReviewItem(
              card.icon,
              card.front,
              '${card.source} · ${card.lapses} fallos',
              '${card.retention}%',
              urgent: card.retention < 60,
              onTap: () => Navigator.pushNamed(context, AppRoutes.flashcards),
            ),
          const _SectionHead('Mazos con retención baja'),
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
    return _Glass(
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
                _Progress(value),
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
          const _TopBar(title: 'Comunidad'),
          const _PageHead(
            'Descubre mazos',
            'Creados por personas que aprenden como tú',
          ),
          _Glass(
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
          const _SectionHead('Destacado esta semana', action: 'Ver todo'),
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
          const _SectionHead('Populares', action: 'Filtrar'),
          _DeckGrid(decks: decks),
          const _SectionHead('Creadores a seguir', action: 'Ver todos'),
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
      child: _Glass(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Fav(
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
    return _Glass(
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
        child: _Glass(
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
                  _Chip(
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
          child: _Glass(
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
          const _TopBar(title: 'Amigos'),
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
      child: _Glass(
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
      child: _Glass(
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
      child: _Glass(
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
      child: _Glass(
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
          const _TopBar(title: 'Tu progreso'),
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
      child: _Glass(
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
      child: _Glass(
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
              const Expanded(child: _GhostButton('+ Invitar')),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _Cta(
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
          const _Progress(.48),
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
              const Expanded(child: _GhostButton('💬 Pedir ayuda')),
              const SizedBox(width: 8),
              Expanded(
                child: _Cta(
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
                child: _GhostButton(
                  'Salir',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.amigos),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Cta(
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
          const _BackButton(),
          Expanded(
            child: Center(
              child: _Chip(
                center,
                dense: true,
                color: live
                    ? RefColors.lime.withValues(alpha: .16)
                    : RefColors.glassStrong,
                textColor: live ? RefColors.lime : RefColors.ink,
              ),
            ),
          ),
          const _IconButton(icon: Icons.wb_sunny_outlined),
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
    return _Glass(
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
          _Chip(
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
                _Fav(
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
    return _Glass(
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
          _Chip(value, dense: true),
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
    return _Glass(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _Fav(avatar, size: 30, gradient: gradient),
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
    return const _Glass(
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
    return _Glass(
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
    return _Glass(
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
          if (voter != null) _Fav(voter!, size: 22),
        ],
      ),
    );
  }
}

class _CoopGameChat extends StatelessWidget {
  const _CoopGameChat();

  @override
  Widget build(BuildContext context) {
    return const _Glass(
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
    return const _Glass(
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
    return _Glass(
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
    return _Glass(
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
    return const _Glass(
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
                _Progress(
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
    return const _Glass(
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

class _Stat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _Stat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Glass(
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
            child: _Progress(progress.clamp(.05, 1.0)),
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

class _FlashcardsTopBar extends StatelessWidget {
  final String title;

  const _FlashcardsTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const _BackButton(exitText: true),
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
          const _IconButton(icon: Icons.wb_sunny_outlined),
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
            child: _Glass(
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
      child: _Glass(
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
    return _Glass(
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
