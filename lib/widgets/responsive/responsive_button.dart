import 'package:flutter/material.dart';
import '../../utils/responsive_screen_utils.dart';

/// Botão responsivo que se adapta ao tamanho da tela
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final double? elevation;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final Widget? icon;
  final MainAxisAlignment? alignment;
  final bool isFullWidth;
  final bool isOutlined;
  final bool isText;
  final bool isLoading;
  final Widget? loadingWidget;

  const ResponsiveButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.onLongPress,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.icon,
    this.alignment,
    this.isFullWidth = false,
    this.isOutlined = false,
    this.isText = false,
    this.isLoading = false,
    this.loadingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveScreenUtils.getBalancedScale(context);
    final responsivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: ResponsiveScreenUtils.scale(context, 16.0),
      vertical: ResponsiveScreenUtils.scale(context, 12.0),
    );
    
    final responsiveBorderRadius = borderRadius != null
        ? ResponsiveScreenUtils.scale(context, borderRadius!)
        : ResponsiveScreenUtils.scale(context, 8.0);
    
    final responsiveElevation = elevation != null
        ? ResponsiveScreenUtils.scale(context, elevation!)
        : ResponsiveScreenUtils.scale(context, 2.0);

    Widget buttonChild;
    if (isLoading) {
      buttonChild = loadingWidget ?? SizedBox(
        width: ResponsiveScreenUtils.scale(context, 20.0),
        height: ResponsiveScreenUtils.scale(context, 20.0),
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    } else {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignment ?? MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            ResponsiveSizedBox(width: 8.0),
          ],
          ResponsiveText(
            text,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ],
      );
    }

    Widget button;
    if (isText) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        onLongPress: isLoading ? null : onLongPress,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          disabledForegroundColor: disabledForegroundColor,
          padding: responsivePadding,
          minimumSize: Size(
            width != null ? ResponsiveScreenUtils.scale(context, width!) : 0,
            height != null ? ResponsiveScreenUtils.scale(context, height!) : 0,
          ),
        ),
        child: buttonChild,
      );
    } else if (isOutlined) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        onLongPress: isLoading ? null : onLongPress,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          disabledForegroundColor: disabledForegroundColor,
          backgroundColor: backgroundColor,
          disabledBackgroundColor: disabledBackgroundColor,
          padding: responsivePadding,
          minimumSize: Size(
            width != null ? ResponsiveScreenUtils.scale(context, width!) : 0,
            height != null ? ResponsiveScreenUtils.scale(context, height!) : 0,
          ),
          side: BorderSide(
            color: foregroundColor ?? Theme.of(context).colorScheme.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
          ),
        ),
        child: buttonChild,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        onLongPress: isLoading ? null : onLongPress,
        style: ElevatedButton.styleFrom(
          foregroundColor: foregroundColor,
          disabledForegroundColor: disabledForegroundColor,
          backgroundColor: backgroundColor,
          disabledBackgroundColor: disabledBackgroundColor,
          elevation: responsiveElevation,
          padding: responsivePadding,
          minimumSize: Size(
            width != null ? ResponsiveScreenUtils.scale(context, width!) : 0,
            height != null ? ResponsiveScreenUtils.scale(context, height!) : 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
          ),
        ),
        child: buttonChild,
      );
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    if (margin != null) {
      return Container(
        margin: EdgeInsets.only(
          left: ResponsiveScreenUtils.scale(context, margin!.left),
          top: ResponsiveScreenUtils.scale(context, margin!.top),
          right: ResponsiveScreenUtils.scale(context, margin!.right),
          bottom: ResponsiveScreenUtils.scale(context, margin!.bottom),
        ),
        child: button,
      );
    }

    return button;
  }
}

/// Botão de ícone responsivo
class ResponsiveIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final String? tooltip;

  const ResponsiveIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.onLongPress,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.borderRadius,
    this.padding,
    this.margin,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveSize = size != null
        ? ResponsiveScreenUtils.scale(context, size!)
        : ResponsiveScreenUtils.scale(context, 48.0);
    
    final responsiveBorderRadius = borderRadius != null
        ? ResponsiveScreenUtils.scale(context, borderRadius!)
        : ResponsiveScreenUtils.scale(context, 24.0);
    
    final responsivePadding = padding ?? EdgeInsets.all(
      ResponsiveScreenUtils.scale(context, 12.0),
    );

    Widget button = IconButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      icon: Icon(
        icon,
        size: ResponsiveScreenUtils.scale(context, 24.0),
        color: foregroundColor,
      ),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: responsivePadding,
        minimumSize: Size(responsiveSize, responsiveSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsiveBorderRadius),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    if (margin != null) {
      return Container(
        margin: EdgeInsets.only(
          left: ResponsiveScreenUtils.scale(context, margin!.left),
          top: ResponsiveScreenUtils.scale(context, margin!.top),
          right: ResponsiveScreenUtils.scale(context, margin!.right),
          bottom: ResponsiveScreenUtils.scale(context, margin!.bottom),
        ),
        child: button,
      );
    }

    return button;
  }
}

/// Botão flutuante responsivo
class ResponsiveFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget? child;
  final IconData? icon;
  final String? text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final double? borderRadius;
  final EdgeInsets? padding;
  final bool isExtended;

  const ResponsiveFloatingActionButton({
    Key? key,
    this.onPressed,
    this.onLongPress,
    this.child,
    this.icon,
    this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.isExtended = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveElevation = elevation != null
        ? ResponsiveScreenUtils.scale(context, elevation!)
        : ResponsiveScreenUtils.scale(context, 6.0);
    
    final responsiveBorderRadius = borderRadius != null
        ? ResponsiveScreenUtils.scale(context, borderRadius!)
        : ResponsiveScreenUtils.scale(context, 28.0);
    
    final responsivePadding = padding ?? EdgeInsets.all(
      ResponsiveScreenUtils.scale(context, 16.0),
    );

    if (isExtended) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        onLongPress: onLongPress,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: responsiveElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsiveBorderRadius),
        ),
        child: child ?? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon),
              ResponsiveSizedBox(width: 8.0),
            ],
            if (text != null) ResponsiveText(text!),
          ],
        ),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: responsiveElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
      ),
      child: child ?? (icon != null ? Icon(icon) : null),
    );
  }
}
