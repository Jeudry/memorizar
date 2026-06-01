import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';
import '../services/social_auth_service.dart';

/// Pantalla de inicio de sesión premium y súper compacta.
/// Coloca los accesos rápidos de un solo click en la parte superior,
/// seguidos de un divisor estético y el formulario de correo abajo.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _social = SocialAuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  
  /// Sub-modo dentro de email: false = sign in, true = sign up.
  bool _isSignUp = false;

  late AnimationController _logoAnimationCtrl;

  @override
  void initState() {
    super.initState();
    _logoAnimationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _logoAnimationCtrl.dispose();
    super.dispose();
  }

  Future<void> _emailSubmit() async {
    if (_busy) return;
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Correo y contraseña son obligatorios.');
      return;
    }
    final store = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        if (pass.length < 8) {
          throw Exception('La contraseña debe tener al menos 8 caracteres.');
        }
        await store.registerWithEmail(
          email: email,
          password: pass,
          displayName: _nameCtrl.text.trim().isEmpty
              ? email.split('@').first
              : _nameCtrl.text.trim(),
        );
      } else {
        await store.loginWithEmail(email: email, password: pass);
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _parseError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
      setState(() => _error = _parseError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _continueAsGuest() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  String _parseError(Object e) {
    String raw = e.toString().replaceAll('Exception: ', '');
    // Limpiar formatos de HttpException para no exponer URLs internas
    if (raw.contains('HttpException') || raw.contains('http:')) {
      if (raw.startsWith('HttpException:')) {
        final parts = raw.split(',');
        if (parts.isNotEmpty) {
          raw = parts.first.replaceAll('HttpException:', '').trim();
        }
      }
    }
    
    // Mapeo en español amigable
    if (raw.contains('email already in use') || raw.contains('already in use')) {
      return 'Este correo electrónico ya está registrado. Por favor, inicia sesión.';
    }
    if (raw.contains('invalid credentials') || raw.contains('invalid session')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (raw.contains('weak password') || raw.contains('at least 8 characters')) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (raw.contains('SERVICE_DISABLED') || raw.contains('People API')) {
      return 'Acceso denegado: Habilita la People API en Google Cloud.';
    }
    
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.home,
      scrollable: true,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 440),
          margin: EdgeInsets.symmetric(
            vertical: isDesktop ? 24 : 8,
            horizontal: isDesktop ? 16 : 0,
          ),
          child: Glass(
            radius: 28,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera Animada con Logo Flotante
                Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimationCtrl,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 3 * _logoAnimationCtrl.value),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: RefColors.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: RefColors.pink.withValues(alpha: .4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Guarda tu progreso, sincroniza tus mazos y conéctate con la comunidad de estudio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RefColors.muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Cartel de Error Estilizado
                if (_error != null) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: RefColors.urgent.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: RefColors.urgent.withValues(alpha: .35),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: RefColors.urgent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
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
                  const SizedBox(height: 18),
                ],

                // 1. Proveedores de Acceso Rápido (Primero en jerarquía)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CompactProviderButton(
                            icon: Icons.g_mobiledata_rounded,
                            label: 'Google',
                            color: const Color(0xFFEA4335),
                            onTap: _busy ? null : () => _socialLogin('google'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactProviderButton(
                            icon: Icons.apple_rounded,
                            label: 'Apple',
                            color: Colors.white,
                            onTap: _busy ? null : () => _socialLogin('apple'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _CompactProviderButton(
                      icon: Icons.facebook_rounded,
                      label: 'Facebook',
                      color: const Color(0xFF1877F2),
                      onTap: _busy ? null : () => _socialLogin('facebook'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                
                // 2. Divisor estético intermedio
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: RefColors.border.withValues(alpha: .4),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'o accede con correo',
                        style: TextStyle(
                          color: RefColors.dim,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: RefColors.border.withValues(alpha: .4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Formulario de Credenciales (Abajo en jerarquía)
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isSignUp) ...[
                        _LoginField(
                          controller: _nameCtrl,
                          hint: 'Nombre completo',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _LoginField(
                        controller: _emailCtrl,
                        hint: 'Correo electrónico',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      _LoginField(
                        controller: _passCtrl,
                        hint: 'Contraseña',
                        icon: Icons.lock_outline_rounded,
                        obscure: true,
                      ),
                      const SizedBox(height: 16),
                      _busy
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(RefColors.pink),
                                ),
                              ),
                            )
                          : Cta(
                              _isSignUp ? 'Crear cuenta' : 'Iniciar sesión',
                              onTap: _emailSubmit,
                            ),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isSignUp = !_isSignUp;
                            _error = null;
                          }),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Text(
                              _isSignUp
                                  ? '¿Ya tienes cuenta? Inicia sesión'
                                  : '¿No tienes cuenta aún? Regístrate gratis',
                              style: const TextStyle(
                                color: RefColors.cyan,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                decorationColor: RefColors.cyan,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Divisor a invitado
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: RefColors.border.withValues(alpha: .3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Continuar como invitado
                _busy
                    ? const SizedBox()
                    : GhostButton(
                        'Continuar como invitado',
                        onTap: _continueAsGuest,
                      ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Tu contenido vive solo localmente. Si reinstalas la app sin haber iniciado sesión antes, perderás tus mazos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RefColors.dim,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Enlaces Legales
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.legalMenu),
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'Términos · Privacidad · Directrices',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _isFocused ? HtmlRefColors.glassStrong : HtmlRefColors.glassSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused ? RefColors.cyan : HtmlRefColors.glassBorder,
          width: 1.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: RefColors.cyan.withValues(alpha: .1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            widget.icon, 
            color: _isFocused ? RefColors.cyan : RefColors.muted, 
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              autocorrect: false,
              enableSuggestions: !widget.obscure,
              style: const TextStyle(
                color: RefColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: widget.hint,
                hintStyle: const TextStyle(color: RefColors.dim, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactProviderButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _CompactProviderButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_CompactProviderButton> createState() => _CompactProviderButtonState();
}

class _CompactProviderButtonState extends State<_CompactProviderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    
    return Opacity(
      opacity: disabled ? .45 : 1,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered ? HtmlRefColors.glassStrong : HtmlRefColors.glassSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered ? widget.color.withValues(alpha: .4) : HtmlRefColors.glassBorder,
                width: 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: .1),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon, 
                      color: widget.color, 
                      size: widget.icon == Icons.g_mobiledata_rounded ? 22 : 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
