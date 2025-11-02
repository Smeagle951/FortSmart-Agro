import 'package:flutter/material.dart';

/// Widget que serve como placeholder para imagens enquanto estão carregando
class ImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final Color color;

  const ImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.image,
          color: color.withOpacity(0.6),
          size: 48,
        ),
      ),
    );
  }
}
