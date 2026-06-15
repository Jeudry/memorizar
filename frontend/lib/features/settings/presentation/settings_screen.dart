import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// Hub central de preferencias. Consolida tema, idioma, recordatorios,
/// accesibilidad, racha y acceso a logs/cuenta — todo en un solo lugar.
/// El botón de tema que vivía suelto en el home apunta acá.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ReferencePage(
      active: AppRoutes.home,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Ajustes'),



          // ── Apariencia ──────────────────────────────────────────────
          _SettingsSection(
            title: 'APARIENCIA',
            children: [
              _SectionLabel('Tema'),
              const SizedBox(height: 6),
              _ChipSegment<ThemeMode>(
                options: const [
                  (ThemeMode.dark, 'Oscuro', Icons.dark_mode_rounded),
                  (ThemeMode.light, 'Claro', Icons.light_mode_rounded),
                  (ThemeMode.system, 'Sistema', Icons.settings_suggest_rounded),
                ],
                selected: store.themeMode,
                onChanged: store.setThemeMode,
              ),
              const SizedBox(height: 14),
              _SectionLabel('Idioma'),
              const SizedBox(height: 6),
              _ChipSegment<String>(
                options: const [
                  ('es', 'Español', null),
                  ('en', 'English', null),
                ],
                selected: store.locale,
                onChanged: (v) {
                  store.setLocale(v);
                  if (store.isLoggedIn) store.updateProfile(locale: v);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Accesibilidad ───────────────────────────────────────────
          _SettingsSection(
            title: 'ACCESIBILIDAD',
            children: [
              _ToggleRow(
                label: 'Tipografía para dislexia',
                hint: 'Usa una fuente diseñada para fácil lectura.',
                value: store.dyslexiaMode,
                onChanged: store.setDyslexiaMode,
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Letra grande',
                hint: 'Aumenta el tamaño del texto en toda la app.',
                value: store.bigFont,
                onChanged: store.setBigFont,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Recordatorios ───────────────────────────────────────────
          _SettingsSection(
            title: 'RECORDATORIOS',
            children: [
              _ToggleRow(
                label: 'Notificación diaria',
                hint: 'Te recordamos practicar a la hora que elijas.',
                value: store.reminderEnabled,
                onChanged: store.setReminderEnabled,
              ),
              if (store.reminderEnabled) ...[
                const SizedBox(height: 10),
                _SectionLabel('Hora'),
                const SizedBox(height: 6),
                _HourSlider(
                  hour: store.reminderHour,
                  onChanged: store.setReminderHour,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Cuenta + datos ──────────────────────────────────────────
          _SettingsSection(
            title: 'CUENTA Y DATOS',
            children: [
              if (store.isLoggedIn)
                GhostButton(
                  'Mi cuenta',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.account),
                )
              else
                Cta(
                  'Iniciar sesión',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                ),
              const SizedBox(height: 8),
              GhostButton(
                'Compartir mi progreso',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compartir progreso estará disponible en la Fase 2.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              GhostButton(
                'Buscar en mis mazos',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Búsqueda global estará disponible en la Fase 2.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Legal + about ───────────────────────────────────────────
          _SettingsSection(
            title: 'INFORMACIÓN',
            children: [
              GhostButton(
                'Legal y privacidad',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.legalMenu),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: HtmlRefColors.glassSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HtmlRefColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: RefColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Memorizar · v1.0 (Fase 1)',
                        style: TextStyle(
                          color: RefColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Text(
                      'Memorizar',
                      style: TextStyle(
                        color: RefColors.muted,
                        fontSize: 10,
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

// ── Helpers visuales ──────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: RefColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: RefColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      );
}

class _ChipSegment<T> extends StatelessWidget {
  final List<(T, String, IconData?)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  const _ChipSegment({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (val, label, icon) in options)
          GestureDetector(
            onTap: () => onChanged(val),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: val == selected
                    ? RefColors.pink.withValues(alpha: .18)
                    : HtmlRefColors.glassSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: val == selected
                      ? RefColors.pink
                      : HtmlRefColors.glassBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: val == selected ? RefColors.pink : RefColors.ink.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: val == selected ? RefColors.pink : RefColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
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

class _ToggleRow extends StatelessWidget {
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    color: RefColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: RefColors.pink,
          ),
        ],
      ),
    );
  }
}

class _HourSlider extends StatelessWidget {
  final int hour;
  final ValueChanged<int> onChanged;
  const _HourSlider({required this.hour, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: hour.toDouble(),
            min: 0,
            max: 23,
            divisions: 23,
            label: '${hour.toString().padLeft(2, '0')}:00',
            activeColor: RefColors.pink,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: HtmlRefColors.glassSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: HtmlRefColors.glassBorder),
          ),
          child: Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
