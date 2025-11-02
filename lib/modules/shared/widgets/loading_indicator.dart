import 'package:flutter/material.dart';

/// Widget de indicador de carregamento reutilizável
class LoadingIndicator extends StatelessWidget {
  final String message;
  final double size;
  final Color? color;

  const LoadingIndicator({
    Key? key,
    this.message = 'Carregando...',
    this.size = 50.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
