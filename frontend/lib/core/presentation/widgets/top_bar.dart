import 'package:flutter/material.dart';
import 'back_button.dart';
import 'glass_icon_button.dart';

/// A standard top bar widget used across multiple screens in the application.
class TopBar extends StatelessWidget {
  /// The title to display in the center of the top bar.
  final String title;

  /// Optional trailing widget. If null, a default sun icon button is shown.
  final Widget? trailing;

  const TopBar({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const CustomBackButton(),
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
          trailing ?? const GlassIconButton(icon: Icons.wb_sunny_outlined),
        ],
      ),
    );
  }
}
