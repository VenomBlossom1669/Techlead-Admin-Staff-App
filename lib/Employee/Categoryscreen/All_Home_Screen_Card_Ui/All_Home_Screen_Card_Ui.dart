// lib/widgets/menu_card.dart

import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final Gradient? gradient;
  final Color? color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;
  final double height;
  final double width;

  const MenuCard({
    super.key,
    this.gradient,
    this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.borderRadius,
    this.height = 120,
    this.width = 250,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderRadius ?? BorderRadius.circular(20);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: height,
        width: width,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? color ?? Colors.green : null,
          borderRadius: border,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(4, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: border,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.white24,
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
