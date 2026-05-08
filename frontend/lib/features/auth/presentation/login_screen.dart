import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';
import '../services/social_auth_service.dart';

/// Pantalla de inicio de sesión. En Fase 1 los botones sociales solo arman un
/// `providerUserId` sintético y mandan los datos al backend — la integración
/// real con Google/Apple SDK es una tarea separada (Fase 2).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _social = SocialAuthService();
  bool _busy = false;
  String? _error;

  Future<void> _socialLogin(String provider) async {
    if (_busy) return;
    final store = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final SocialAuthResult result;
      switch (provider) {
        case 'google':
          result = await _social.signInWithGoogle();
          break;
        case 'apple':
          result = await _social.signInWithApple();
          break;
        case 'facebook':
        default:
          result = await _social.signInWithFacebook();
          break;
      }
      await store.socialLogin(
        provider: result.provider,
        providerUserId: result.providerUserId,
        email: result.email,
        displayName: result.displayName,
        avatarUrl: result.avatarUrl,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    } on SocialAuthCancelled {
      // Usuario canceló — no mostramos error.
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _continueAsGuest() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: RefColors.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: RefColors.pink.withValues(alpha: .35),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Memorizar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Inicia sesión para guardar tu progreso, sincronizar mazos\ny conectarte con amigos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RefColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RefColors.urgent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: RefColors.urgent.withValues(alpha: .55),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: RefColors.urgent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: RefColors.urgent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _ProviderButton(
            icon: Icons.g_mobiledata_rounded,
            label: 'Continuar con Google',
            color: const Color(0xFFEA4335),
            onTap: _busy ? null : () => _socialLogin('google'),
          ),
          const SizedBox(height: 10),
          _ProviderButton(
            icon: Icons.apple_rounded,
            label: 'Continuar con Apple',
            color: Colors.white,
            onTap: _busy ? null : () => _socialLogin('apple'),
          ),
          const SizedBox(height: 10),
          _ProviderButton(
            icon: Icons.facebook_rounded,
            label: 'Continuar con Facebook',
            color: const Color(0xFF1877F2),
            onTap: _busy ? null : () => _socialLogin('facebook'),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: RefColors.border,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'o',
                  style: TextStyle(
                    color: RefColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: RefColors.border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GhostButton(
            'Continuar como invitado',
            onTap: _busy ? null : _continueAsGuest,
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Como invitado tu contenido vive solo en este dispositivo. '
              'Si reinstalas la app sin haber iniciado sesión antes, se pierde.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RefColors.dim,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.legalMenu),
              child: const Text(
                'Términos · Privacidad · Comunidad',
                style: TextStyle(
                  color: RefColors.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationColor: RefColors.cyan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? .4 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: HtmlRefColors.glassSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HtmlRefColors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: color.withValues(alpha: .55)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
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
      ),
    );
  }
}
