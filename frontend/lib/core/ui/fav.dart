import 'package:flutter/material.dart';

import '../theme/ref_colors.dart';

/// Square avatar tile: muestra la FOTO de perfil ([avatarUrl]) si existe, y si
/// no (o si falla la carga) cae a la inicial/emoji sobre el gradiente. Con
/// punto de "en línea" opcional.
class Fav extends StatelessWidget {
  final String text;
  final String avatarUrl;
  final Gradient gradient;
  final double size;
  final bool online;

  const Fav(
    this.text, {
    super.key,
    this.avatarUrl = '',
    this.gradient = RefColors.primary,
    this.size = 38,
    this.online = false,
  });

  Widget _initial() => Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * .36,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl.trim().isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(size * .32),
            border: Border.all(color: RefColors.border),
          ),
          child: hasPhoto
              ? Image.network(
                  avatarUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  // Mientras carga o si falla, se ve la inicial sobre el gradiente.
                  loadingBuilder: (_, child, prog) =>
                      prog == null ? child : _initial(),
                  errorBuilder: (_, _, _) => _initial(),
                )
              : _initial(),
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
