import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/ref_colors.dart';
import '../../../core/ui/widgets.dart';

/// Pantalla de verificación de correo. Pide el token al backend (en dev
/// llega en la respuesta) y deja al usuario confirmarlo. Cuando llegue el
/// SMTP real, el token entra por link y este screen solo confirma.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _tokenCtrl = TextEditingController();
  bool _busy = false;
  String? _devToken;
  String? _error;
  String? _ok;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _error = null;
      _ok = null;
    });
    try {
      final token = await AppScope.of(context).api.requestEmailVerify();
      setState(() => _devToken = token);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final t = _tokenCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).api.confirmEmailVerify(t);
      if (!mounted) return;
      // Refrescar perfil para que el flag emailVerified se actualice.
      final me = await AppScope.of(context).api.me();
      if (!mounted) return;
      AppScope.of(context).overwriteCurrentUser(me);
      setState(() => _ok = '¡Correo verificado!');
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
          const RefTopBar(title: 'Verificar correo'),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Verificar tu correo te permite recuperar contraseña y recibir notificaciones por email.',
                  style: TextStyle(color: RefColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Cta(
                  _devToken == null ? 'Pedir código' : 'Reenviar código',
                  onTap: _busy ? null : _request,
                  disabled: _busy,
                ),
                if (_devToken != null && _devToken!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: RefColors.sun.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: RefColors.sun.withValues(alpha: .55),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DEV TOKEN (mientras no haya SMTP real)',
                          style: TextStyle(
                            color: RefColors.sun,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _devToken!,
                          style: const TextStyle(
                            color: RefColors.ink,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _LabeledField(
                  controller: _tokenCtrl,
                  hint: 'Pega el token aquí',
                  icon: Icons.vpn_key_outlined,
                ),
                const SizedBox(height: 12),
                Cta(
                  'Confirmar',
                  onTap: _busy ? null : _confirm,
                  disabled: _busy,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: RefColors.urgent,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (_ok != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _ok!,
                    style: const TextStyle(color: RefColors.lime, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _LabeledField({
    required this.controller,
    required this.hint,
    required this.icon,
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
              obscureText: false,
              autocorrect: false,
              style: const TextStyle(fontSize: 13, color: RefColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: RefColors.dim,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
