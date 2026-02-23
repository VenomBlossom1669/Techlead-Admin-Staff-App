import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomNavItemWithBadge extends StatefulWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final Future<void> Function() onTap;
  final bool isActive;

  const BottomNavItemWithBadge({
    Key? key,
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.onTap,
    required this.isActive,
  }) : super(key: key);


  @override
  State<BottomNavItemWithBadge> createState() => _BottomNavItemWithBadgeState();
}

class _BottomNavItemWithBadgeState extends State<BottomNavItemWithBadge> {
  bool _isNavigating = false;

  Future<void> _handleTap() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: widget.isActive
                    ? (Matrix4.identity()
                  ..scale(1.2))
                    : Matrix4.identity(),
                child: Icon(
                  widget.icon,
                  color: widget.isActive ? Colors.amber : Colors.white,
                ),
              ),
              if (widget.badgeCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.badgeCount.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: "Times New Roman",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              color: widget.isActive ? Colors.amber : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
