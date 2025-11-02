import 'package:flutter/material.dart';

/// Tipos de botões disponíveis
enum FortsSmartButtonType {
  primary,
  secondary,
  outline,
  text,
  danger,
  success,
}

/// Widget de botão personalizado para o FortSmart Agro
class FortsSmartButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final FortsSmartButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Widget? icon;
  final bool iconLeading;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;

  const FortsSmartButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = FortsSmartButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height,
    this.width,
    this.padding,
    this.borderRadius = 8.0,
    this.icon,
    this.iconLeading = true,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Configurações de cor baseadas no tipo de botão
    Color getBackgroundColor() {
      if (backgroundColor != null) return backgroundColor!;
      
      switch (type) {
        case FortsSmartButtonType.primary:
          return theme.primaryColor;
        case FortsSmartButtonType.secondary:
          return isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;
        case FortsSmartButtonType.outline:
        case FortsSmartButtonType.text:
          return Colors.transparent;
        case FortsSmartButtonType.danger:
          return Colors.red[700]!;
        case FortsSmartButtonType.success:
          return Colors.green[600]!;
      }
    }

    Color getTextColor() {
      if (textColor != null) return textColor!;
      
      switch (type) {
        case FortsSmartButtonType.primary:
          return Colors.white;
        case FortsSmartButtonType.secondary:
          return isDarkMode ? Colors.white : Colors.black87;
        case FortsSmartButtonType.outline:
          return theme.primaryColor;
        case FortsSmartButtonType.text:
          return theme.primaryColor;
        case FortsSmartButtonType.danger:
          return Colors.white;
        case FortsSmartButtonType.success:
          return Colors.white;
      }
    }

    Color getBorderColor() {
      if (borderColor != null) return borderColor!;
      
      switch (type) {
        case FortsSmartButtonType.outline:
          return theme.primaryColor;
        case FortsSmartButtonType.danger:
          return Colors.red[700]!;
        case FortsSmartButtonType.success:
          return Colors.green[600]!;
        default:
          return Colors.transparent;
      }
    }

    // Construir o conteúdo do botão
    Widget buildButtonContent() {
      final textWidget = Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? 16.0,
          fontWeight: fontWeight ?? FontWeight.bold,
          color: onPressed == null 
              ? Colors.grey 
              : getTextColor(),
        ),
      );

      if (isLoading) {
        return SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
          ),
        );
      }

      if (icon == null) {
        return textWidget;
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: iconLeading
            ? [
                icon!,
                const SizedBox(width: 8),
                textWidget,
              ]
            : [
                textWidget,
                const SizedBox(width: 8),
                icon!,
              ],
      );
    }

    // Construir o botão baseado no tipo
    Widget buildButton() {
      final buttonContent = buildButtonContent();
      final buttonStyle = ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
          }
          return getBackgroundColor();
        }),
        foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return Colors.grey;
          }
          return getTextColor();
        }),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: onPressed == null ? Colors.grey : getBorderColor(),
              width: type == FortsSmartButtonType.outline ? 2.0 : 0.0,
            ),
          ),
        ),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevation: MaterialStateProperty.all<double>(
          type == FortsSmartButtonType.text ? 0 : elevation,
        ),
        minimumSize: MaterialStateProperty.all<Size>(
          Size(width ?? (isFullWidth ? double.infinity : 0), height ?? 48),
        ),
      );

      if (type == FortsSmartButtonType.text) {
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
      } else {
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
      }
    }

    return buildButton();
  }
}

/// Widget de botão flutuante personalizado para o FortSmart Agro
class FortsSmartFloatingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final double? size;
  final bool mini;
  final bool extended;
  final String? label;

  const FortsSmartFloatingButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 6.0,
    this.size,
    this.mini = false,
    this.extended = false,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: icon,
        label: Text(label!),
        backgroundColor: backgroundColor ?? theme.primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: elevation,
        tooltip: tooltip,
      );
    }
    
    return FloatingActionButton(
      onPressed: onPressed,
      mini: mini,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation,
      tooltip: tooltip,
      child: icon,
    );
  }
}

/// Widget de botão com ícone personalizado para o FortSmart Agro
class FortsSmartIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final Color? color;
  final double? size;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool showBackground;
  final Color? backgroundColor;

  const FortsSmartIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.color,
    this.size,
    this.padding = const EdgeInsets.all(8.0),
    this.borderRadius,
    this.showBackground = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (showBackground) {
      return InkWell(
        onTap: onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.primaryColor.withOpacity(0.1),
            borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: padding,
            child: IconTheme(
              data: IconThemeData(
                color: color ?? theme.primaryColor,
                size: size,
              ),
              child: icon,
            ),
          ),
        ),
      );
    }
    
    return IconButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      color: color,
      iconSize: size ?? 24.0,
      padding: padding,
      splashRadius: 24.0,
    );
  }
}

/// Widget de botão simples para o sistema de subáreas
class FortSmartButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const FortSmartButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.green,
          foregroundColor: foregroundColor ?? Colors.white,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
