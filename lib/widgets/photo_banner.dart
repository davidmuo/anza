import 'dart:io';

import 'package:flutter/material.dart';

class PhotoBanner extends StatelessWidget {
  final String imageUrl;
  final Color color;
  final Widget? child;

  /// Local file path for a photo the poster attached to this event, if
  /// any. When set, this is shown instead of [imageUrl].
  final String? imagePath;

  const PhotoBanner({
    super.key,
    required this.imageUrl,
    required this.color,
    this.imagePath,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    return Container(
      color: color,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (path != null)
            Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          else
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
          ?child,
        ],
      ),
    );
  }
}