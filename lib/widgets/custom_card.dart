import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Widget de card personalizado para uso em todo o aplicativo
class CustomCard extends StatelessWidget {
  /// Título do card
  final String title;
  
  /// Conteúdo do card
  final Widget child;
  
  /// Ícone opcional para o título
  final IconData? icon;
  
  /// Cor do card (opcional)
  final Color? color;
  
  /// Ações adicionais para o título (opcional)
  final List<Widget>? actions;
  
  /// Padding interno do card (opcional)
  final EdgeInsetsGeometry? contentPadding;
  
  /// Margem externa do card (opcional)
  final EdgeInsetsGeometry? margin;
  
  /// Elevação do card (opcional)
  final double? elevation;
  
  /// Construtor
  const CustomCard({
    Key? key,
    required this.title,
    required this.child,
    this.icon,
    this.color,
    this.actions,
    this.contentPadding,
    this.margin,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        elevation: elevation ?? 12.0,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xE6232323), // fundo escuro translúcido
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Padding(
                padding: contentPadding ?? const EdgeInsets.all(20.0),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho do card
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: color ?? AppColors.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[            
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.28),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20.0,
              ),
            ),
            const SizedBox(width: 14.0),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ) ?? const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: 8),
            ...actions!,
          ],
        ],
      ),
    );
  }
}
