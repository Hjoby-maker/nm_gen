// lib/presentation/widgets/favorite_icon.dart
import 'package:flutter/material.dart';

/// Иконка звездочки для обозначения избранного человека.
/// Может быть как статичной, так и кликабельной (для переключения).
class FavoriteIcon extends StatelessWidget {
  const FavoriteIcon({
    super.key,
    required this.isFavorite,
    this.size = 20,
    this.onTap,
    this.color,
  });

  final bool isFavorite;
  final double size;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        color ?? (isFavorite ? Colors.amber : Colors.grey.shade400);

    return GestureDetector(
      onTap: onTap,
      child: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        size: size,
        color: iconColor,
      ),
    );
  }
}

/// Кликабельная звездочка с эффектом анимации при нажатии
class AnimatedFavoriteIcon extends StatefulWidget {
  const AnimatedFavoriteIcon({
    super.key,
    required this.isFavorite,
    this.size = 20,
    this.onTap,
    this.color,
  });

  final bool isFavorite;
  final double size;
  final VoidCallback? onTap;
  final Color? color;

  @override
  State<AnimatedFavoriteIcon> createState() => _AnimatedFavoriteIconState();
}

class _AnimatedFavoriteIconState extends State<AnimatedFavoriteIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          // Запускаем анимацию
          _controller.forward().then((_) => _controller.reverse());
          widget.onTap!();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FavoriteIcon(
              isFavorite: widget.isFavorite,
              size: widget.size,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}
