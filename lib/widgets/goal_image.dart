import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GoalImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const GoalImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return fallback ?? const SizedBox.shrink();

    final url = imageUrl!;

    if (url.startsWith('data:')) {
      try {
        final data = url.split(',').last;
        final bytes = base64Decode(data);
        return Image.memory(bytes, width: width, height: height, fit: fit);
      } catch (_) {
        return fallback ?? const SizedBox.shrink();
      }
    }

    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => fallback ?? const SizedBox.shrink(),
        errorWidget: (_, __, ___) => fallback ?? const SizedBox.shrink(),
      );
    }

    if (!kIsWeb) {
      try {
        return Image.file(File(url), width: width, height: height, fit: fit);
      } catch (_) {
        return fallback ?? const SizedBox.shrink();
      }
    }

    return fallback ?? const SizedBox.shrink();
  }
}
