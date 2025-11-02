import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LoadingIndicatorWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingIndicatorWidget({
    Key? key,
    this.size = 36.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}
