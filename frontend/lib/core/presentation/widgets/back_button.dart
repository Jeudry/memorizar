import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final bool exitText;
  final VoidCallback? onTap;

  const CustomBackButton({super.key, this.exitText = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // Hardcoded fallback route for this specific project structure
          Navigator.pushReplacementNamed(context, '/'); 
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
