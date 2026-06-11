import 'package:flutter/material.dart';

class PhotoBanner extends StatelessWidget {
  final String imageUrl;
  final Color color;
  final Widget? child;

  const PhotoBanner({
    super.key,
    required this.imageUrl,
    required this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const SizedBox.shrink();
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}