import 'package:flutter/material.dart';

import 'back_button.dart';
import 'icon_button.dart';

/// Standard top bar: back button on the left, centred title, theme toggle on
/// the right. Used by the reference screens.
class RefTopBar extends StatelessWidget {
  final String title;

  const RefTopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const RefBackButton(),
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
          const RefIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}
