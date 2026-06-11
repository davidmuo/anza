import 'package:flutter/material.dart';

class MiniAvatar extends StatelessWidget {
  final String seed;
  final String label;
  final Color color;
  final double radius;

  const MiniAvatar({
    super.key,
    required this.seed,
    required this.label,
    required this.color,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: color,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: radius * 0.75,
                ),
              ),
            ),
            Image.network(
              'https://i.pravatar.cc/150?u=anza-$seed',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}