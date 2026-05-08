import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_state.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// Pantalla "Mi cuenta" — perfil editable, theme/locale toggles, logout y
/// borrar cuenta.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _avatarCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AppScope.of(context).currentUser;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _avatarCtrl = TextEditingController(text: user?.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: RefColors.glassStrong,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RefColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: RefColors.cyan),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: RefColors.cyan),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 82,
    );
    if (picked == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final store = AppScope.of(context);
      final relUrl = await store.api.uploadAvatar(filePath: picked.path);
      // El backend devuelve `/avatars/userId.png` — concatenamos baseUrl.
      final fullUrl = '${store.api.baseUrl}$relUrl';
      _avatarCtrl.text = fullUrl;
      await store.updateProfile(avatarUrl: fullUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context).updateProfile(
        displayName: _nameCtrl.text.trim(),
        avatarUrl: _avatarCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RefColors.glassStrong,
        title: Text(AppStrings.t(context, 'account.deleteConfirmTitle')),
        content: Text(AppStrings.t(context, 'account.deleteConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.t(context, 'account.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: RefColors.urgent),
            child: Text(AppStrings.t(context, 'account.deleteConfirmCta')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).deleteAccount();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error borrando cuenta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final user = store.currentUser;
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RefTopBar(title: AppStrings.t(context, 'account.title')),
          if (user == null) ...[
            Glass(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline_rounded, color: RefColors.cyan, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'No has iniciado sesión',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Cta(
                    'Iniciar sesión',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                  ),
                ],
              ),
            ),
          ] else ...[
            Glass(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            _AvatarPreview(
                              url: _avatarCtrl.text,
                              initial: user.initial,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: RefColors.pink,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: RefColors.glassStrong,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: RefColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (!user.emailVerified)
                              const Text(
                                'Correo sin verificar',
                                style: TextStyle(
                                  color: RefColors.sun,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    label: 'Tu nombre',
                    controller: _nameCtrl,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 8),
                  _ProfileField(
                    label: 'URL de avatar',
                    controller: _avatarCtrl,
                    icon: Icons.image_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Cta(
                    AppStrings.t(context, 'common.save'),
                    onTap: _saving ? null : _save,
                    disabled: _saving,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(context, 'account.theme'),
                    style: const TextStyle(
                      color: RefColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ChipSegment(
                    options: [
                      (ThemeMode.dark, AppStrings.t(context, 'account.themeDark')),
                      (ThemeMode.light, AppStrings.t(context, 'account.themeLight')),
                      (ThemeMode.system, AppStrings.t(context, 'account.themeSystem')),
                    ],
                    selected: store.themeMode,
                    onChanged: store.setThemeMode,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppStrings.t(context, 'account.language'),
                    style: const TextStyle(
                      color: RefColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ChipSegment(
                    options: [
                      ('es', AppStrings.t(context, 'account.langEs')),
                      ('en', AppStrings.t(context, 'account.langEn')),
                    ],
                    selected: store.locale,
                    onChanged: (v) {
                      store.setLocale(v);
                      if (store.isLoggedIn) {
                        store.updateProfile(locale: v);
                      }
                    },
                  ),
                ],
              ),
            ),
            if (!user.emailVerified) ...[
              const SizedBox(height: 8),
              GhostButton(
                'Verificar mi correo',
                onTap: () => Navigator.pushNamed(context, AppRoutes.verifyEmail),
              ),
            ],
            const SizedBox(height: 8),
            GhostButton(
              'Cambiar contraseña',
              onTap: () => Navigator.pushNamed(context, AppRoutes.passwordReset),
            ),
            const SizedBox(height: 12),
            GhostButton(
              AppStrings.t(context, 'account.signOut'),
              onTap: () async {
                await store.logout();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (_) => false,
                );
              },
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _confirmDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: RefColors.urgent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: RefColors.urgent.withValues(alpha: .55),
                  ),
                ),
                child: Center(
                  child: Text(
                    AppStrings.t(context, 'account.deleteAccount'),
                    style: const TextStyle(
                      color: RefColors.urgent,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final String url;
  final String initial;
  const _AvatarPreview({required this.url, required this.initial});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Fav(initial, size: 56);
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RefColors.border),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HtmlRefColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: RefColors.muted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autocorrect: false,
              style: const TextStyle(fontSize: 13, color: RefColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: label,
                hintStyle: const TextStyle(color: RefColors.dim, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSegment<T> extends StatelessWidget {
  final List<(T, String)> options;
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
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in options)
          GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: opt.$1 == selected ? RefColors.primary : null,
                color: opt.$1 == selected ? null : HtmlRefColors.glassSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: opt.$1 == selected
                      ? Colors.transparent
                      : HtmlRefColors.glassBorder,
                ),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  color: opt.$1 == selected ? Colors.white : RefColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
