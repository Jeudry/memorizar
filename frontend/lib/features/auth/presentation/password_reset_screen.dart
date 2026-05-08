import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// Pantalla de reset de contraseña. Dos modos:
///   - request: pide email → backend genera token (en dev viene en respuesta)
///   - confirm: pega token + escribe nueva contraseña
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  bool _busy = false;
  String? _devToken;
  String? _error;
  String? _ok;

  @override
  void initState() {
    super.initState();
    final me = AppScope.of(context).currentUser;
    if (me != null) _emailCtrl.text = me.email;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _error = null;
      _ok = null;
    });
    try {
      final t = await AppScope.of(context)
          .api
          .requestPasswordReset(_emailCtrl.text.trim());
      setState(() => _devToken = t);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_tokenCtrl.text.trim().isEmpty || _newPwCtrl.text.length < 8) {
      setState(() => _error = 'Token y nueva contraseña (8+ caracteres) requeridos.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).api.confirmPasswordReset(
            token: _tokenCtrl.text.trim(),
            newPassword: _newPwCtrl.text,
          );
      setState(() => _ok = 'Contraseña actualizada. Inicia sesión con la nueva.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePage(
      showBottomNav: false,
      active: AppRoutes.account,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RefTopBar(title: 'Cambiar contraseña'),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('1. Pedir token', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                _Field(
                  controller: _emailCtrl,
                  hint: 'Tu correo',
                  icon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 8),
                Cta('Pedir token', onTap: _busy ? null : _request, disabled: _busy),
                if (_devToken != null && _devToken!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: RefColors.sun.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: RefColors.sun.withValues(alpha: .55),
                      ),
                    ),
                    child: SelectableText(
                      _devToken!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text('2. Confirmar nueva contraseña',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                _Field(
                  controller: _tokenCtrl,
                  hint: 'Token',
                  icon: Icons.vpn_key_outlined,
                ),
                const SizedBox(height: 8),
                _Field(
                  controller: _newPwCtrl,
                  hint: 'Nueva contraseña (8+)',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 10),
                Cta('Confirmar', onTap: _busy ? null : _confirm, disabled: _busy),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: RefColors.urgent, fontSize: 12)),
                ],
                if (_ok != null) ...[
                  const SizedBox(height: 10),
                  Text(_ok!, style: const TextStyle(color: RefColors.lime, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
              obscureText: obscure,
              autocorrect: false,
              style: const TextStyle(fontSize: 13, color: RefColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(color: RefColors.dim, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
