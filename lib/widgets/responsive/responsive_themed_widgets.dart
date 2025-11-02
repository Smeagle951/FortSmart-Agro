import 'package:flutter/material.dart';
import '../../utils/responsive_screen_utils.dart';
import '../../services/dynamic_theme_manager.dart';
import '../../models/user_preferences.dart';
import 'responsive_widgets.dart';

/// Widgets responsivos que se integram com temas dinâmicos
class ResponsiveThemedWidgets {
  static DynamicThemeManager? _themeManager;
  
  /// Inicializa o gerenciador de temas
  static void initialize(DynamicThemeManager themeManager) {
    _themeManager = themeManager;
  }
  
  /// Obtém o gerenciador de temas
  static DynamicThemeManager? get themeManager => _themeManager;
  
  /// Obtém as preferências atuais
  static UserPreferences? get preferences => _themeManager?.preferences;
}

/// Texto responsivo com tema dinâmico
class ResponsiveThemedText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  final double? letterSpacing;
  final double? lineHeight;
  final TextDecoration? decoration;
  final bool useThemeColor;
  final bool useThemeFontSize;

  const ResponsiveThemedText(
    this.text, {
    Key? key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
    this.letterSpacing,
    this.lineHeight,
    this.decoration,
    this.useThemeColor = true,
    this.useThemeFontSize = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preferences = ResponsiveThemedWidgets.preferences;
    
    // Calcula tamanho da fonte
    double finalFontSize = fontSize ?? 16.0;
    if (useThemeFontSize && preferences != null) {
      finalFontSize = ResponsiveScreenUtils.scale(
        context, 
        finalFontSize * _getFontSizeMultiplier(preferences.fontSizeLevel)
      );
    } else {
      finalFontSize = ResponsiveScreenUtils.scale(context, finalFontSize);
    }
    
    // Calcula peso da fonte
    FontWeight finalFontWeight = fontWeight ?? FontWeight.normal;
    if (preferences?.boldText == true && fontWeight == null) {
      finalFontWeight = FontWeight.bold;
    }
    
    // Calcula cor
    Color? finalColor = color;
    if (useThemeColor && color == null) {
      finalColor = theme.colorScheme.onSurface;
    }
    
    // Calcula espaçamento de letras
    double? finalLetterSpacing = letterSpacing;
    if (letterSpacing != null) {
      finalLetterSpacing = ResponsiveScreenUtils.scale(context, letterSpacing!);
    }
    
    // Calcula altura da linha
    double? finalLineHeight = lineHeight;
    if (lineHeight != null) {
      finalLineHeight = ResponsiveScreenUtils.scale(context, lineHeight!);
    }

    return Text(
      text,
      style: style?.copyWith(
        fontSize: finalFontSize,
        fontWeight: finalFontWeight,
        color: finalColor,
        letterSpacing: finalLetterSpacing,
        height: finalLineHeight,
        decoration: decoration,
      ) ?? TextStyle(
        fontSize: finalFontSize,
        fontWeight: finalFontWeight,
        color: finalColor,
        letterSpacing: finalLetterSpacing,
        height: finalLineHeight,
        decoration: decoration,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
  
  double _getFontSizeMultiplier(FontSizeLevel level) {
    switch (level) {
      case FontSizeLevel.extraSmall:
        return 0.8;
      case FontSizeLevel.small:
        return 0.9;
      case FontSizeLevel.medium:
        return 1.0;
      case FontSizeLevel.large:
        return 1.2;
      case FontSizeLevel.extraLarge:
        return 1.4;
      case FontSizeLevel.huge:
        return 1.6;
    }
  }
}

/// Título responsivo com tema dinâmico
class ResponsiveThemedTitle extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;

  const ResponsiveThemedTitle(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveThemedText(
      text,
      fontSize: fontSize ?? 24.0,
      fontWeight: FontWeight.bold,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Botão responsivo com tema dinâmico
class ResponsiveThemedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? foregroundColor;
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
  final bool useThemeColors;
  final bool useThemeElevation;

  const ResponsiveThemedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.onLongPress,
    this.backgroundColor,
    this.foregroundColor,
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
    this.useThemeColors = true,
    this.useThemeElevation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preferences = ResponsiveThemedWidgets.preferences;
    
    // Calcula cores baseadas no tema
    Color? finalBackgroundColor = backgroundColor;
    Color? finalForegroundColor = foregroundColor;
    
    if (useThemeColors) {
      if (isOutlined || isText) {
        finalForegroundColor = foregroundColor ?? theme.colorScheme.primary;
        if (!isText) {
          finalBackgroundColor = backgroundColor ?? Colors.transparent;
        }
      } else {
        finalBackgroundColor = backgroundColor ?? theme.colorScheme.primary;
        finalForegroundColor = foregroundColor ?? theme.colorScheme.onPrimary;
      }
    }
    
    // Calcula elevação baseada no tema
    double finalElevation = elevation ?? 2.0;
    if (useThemeElevation && preferences?.highContrast == true) {
      finalElevation = 4.0;
    }
    
    // Calcula padding responsivo
    final EdgeInsets responsivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: ResponsiveScreenUtils.scale(context, 16.0),
      vertical: ResponsiveScreenUtils.scale(context, 12.0),
    );
    
    // Calcula raio da borda responsivo
    final double responsiveBorderRadius = borderRadius != null
        ? ResponsiveScreenUtils.scale(context, borderRadius!)
        : ResponsiveScreenUtils.scale(context, 8.0);

    Widget buttonChild;
    if (isLoading) {
      buttonChild = loadingWidget ?? SizedBox(
        width: ResponsiveScreenUtils.scale(context, 20.0),
        height: ResponsiveScreenUtils.scale(context, 20.0),
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(finalForegroundColor!),
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
          ResponsiveThemedText(
            text,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: finalForegroundColor,
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
          foregroundColor: finalForegroundColor,
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
          foregroundColor: finalForegroundColor,
          backgroundColor: finalBackgroundColor,
          padding: responsivePadding,
          minimumSize: Size(
            width != null ? ResponsiveScreenUtils.scale(context, width!) : 0,
            height != null ? ResponsiveScreenUtils.scale(context, height!) : 0,
          ),
          side: BorderSide(
            color: finalForegroundColor!,
            width: preferences?.highContrast == true ? 2.0 : 1.0,
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
          foregroundColor: finalForegroundColor,
          backgroundColor: finalBackgroundColor,
          elevation: finalElevation,
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

/// Card responsivo com tema dinâmico
class ResponsiveThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final Border? border;
  final BoxShadow? shadow;
  final bool useThemeColors;
  final bool useThemeElevation;

  const ResponsiveThemedCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.border,
    this.shadow,
    this.useThemeColors = true,
    this.useThemeElevation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preferences = ResponsiveThemedWidgets.preferences;
    
    // Calcula cor baseada no tema
    Color? finalColor = color;
    if (useThemeColors && color == null) {
      finalColor = theme.colorScheme.surface;
    }
    
    // Calcula elevação baseada no tema
    double finalElevation = elevation ?? 2.0;
    if (useThemeElevation && preferences?.highContrast == true) {
      finalElevation = 4.0;
    }
    
    // Calcula raio da borda responsivo
    final double responsiveBorderRadius = borderRadius != null
        ? ResponsiveScreenUtils.scale(context, borderRadius!)
        : ResponsiveScreenUtils.scale(context, 12.0);
    
    // Calcula padding responsivo
    final EdgeInsets responsivePadding = padding ?? EdgeInsets.all(
      ResponsiveScreenUtils.scale(context, 16.0)
    );
    
    // Calcula margin responsivo
    final EdgeInsets? responsiveMargin = margin != null
        ? EdgeInsets.only(
            left: ResponsiveScreenUtils.scale(context, margin!.left),
            top: ResponsiveScreenUtils.scale(context, margin!.top),
            right: ResponsiveScreenUtils.scale(context, margin!.right),
            bottom: ResponsiveScreenUtils.scale(context, margin!.bottom),
          )
        : null;

    return Card(
      color: finalColor,
      elevation: finalElevation,
      margin: responsiveMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
        side: border != null 
            ? border! 
            : (preferences?.highContrast == true 
                ? BorderSide(color: theme.colorScheme.outline, width: 1.0)
                : BorderSide.none),
      ),
      shadowColor: shadow?.color ?? theme.shadowColor,
      child: Padding(
        padding: responsivePadding,
        child: child,
      ),
    );
  }
}

/// Container responsivo com tema dinâmico
class ResponsiveThemedContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Decoration? decoration;
  final double? elevation;
  final double? borderRadius;
  final Border? border;
  final BoxShadow? shadow;
  final Alignment? alignment;
  final Clip clipBehavior;
  final bool useThemeColors;

  const ResponsiveThemedContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.elevation,
    this.borderRadius,
    this.border,
    this.shadow,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.useThemeColors = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preferences = ResponsiveThemedWidgets.preferences;
    
    // Calcula cor baseada no tema
    Color? finalColor = color;
    if (useThemeColors && color == null) {
      finalColor = theme.colorScheme.surface;
    }
    
    // Calcula elevação baseada no tema
    double finalElevation = elevation ?? 0.0;
    if (preferences?.highContrast == true && elevation != null) {
      finalElevation = elevation! * 1.5;
    }
    
    // Calcula raio da borda responsivo
    final double? responsiveBorderRadius = borderRadius != null
        ? ResponsiveScreenUtils.scale(context, borderRadius!)
        : null;
    
    // Calcula padding responsivo
    final EdgeInsets? responsivePadding = padding != null
        ? EdgeInsets.only(
            left: ResponsiveScreenUtils.scale(context, padding!.left),
            top: ResponsiveScreenUtils.scale(context, padding!.top),
            right: ResponsiveScreenUtils.scale(context, padding!.right),
            bottom: ResponsiveScreenUtils.scale(context, padding!.bottom),
          )
        : null;
    
    // Calcula margin responsivo
    final EdgeInsets? responsiveMargin = margin != null
        ? EdgeInsets.only(
            left: ResponsiveScreenUtils.scale(context, margin!.left),
            top: ResponsiveScreenUtils.scale(context, margin!.top),
            right: ResponsiveScreenUtils.scale(context, margin!.right),
            bottom: ResponsiveScreenUtils.scale(context, margin!.bottom),
          )
        : null;

    return Container(
      width: width != null ? ResponsiveScreenUtils.scale(context, width!) : null,
      height: height != null ? ResponsiveScreenUtils.scale(context, height!) : null,
      padding: responsivePadding,
      margin: responsiveMargin,
      decoration: decoration ?? BoxDecoration(
        color: finalColor,
        borderRadius: responsiveBorderRadius != null 
            ? BorderRadius.circular(responsiveBorderRadius)
            : null,
        border: border,
        boxShadow: shadow != null ? [shadow!] : null,
      ),
      alignment: alignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// Input responsivo com tema dinâmico
class ResponsiveThemedTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool useThemeColors;
  final bool useThemeFontSize;

  const ResponsiveThemedTextField({
    Key? key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.padding,
    this.margin,
    this.useThemeColors = true,
    this.useThemeFontSize = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preferences = ResponsiveThemedWidgets.preferences;
    
    // Calcula padding responsivo
    final EdgeInsets responsivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: ResponsiveScreenUtils.scale(context, 16.0),
      vertical: ResponsiveScreenUtils.scale(context, 12.0),
    );
    
    // Calcula margin responsivo
    final EdgeInsets? responsiveMargin = margin != null
        ? EdgeInsets.only(
            left: ResponsiveScreenUtils.scale(context, margin!.left),
            top: ResponsiveScreenUtils.scale(context, margin!.top),
            right: ResponsiveScreenUtils.scale(context, margin!.right),
            bottom: ResponsiveScreenUtils.scale(context, margin!.bottom),
          )
        : null;

    Widget textField = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: useThemeFontSize && preferences != null
            ? ResponsiveScreenUtils.scale(
                context, 
                16.0 * _getFontSizeMultiplier(preferences.fontSizeLevel)
              )
            : ResponsiveScreenUtils.scale(context, 16.0),
        fontWeight: preferences?.boldText == true ? FontWeight.bold : FontWeight.normal,
        color: useThemeColors ? theme.colorScheme.onSurface : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: useThemeColors,
        fillColor: useThemeColors ? theme.colorScheme.surface : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(context, 8.0)),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
            width: preferences?.highContrast == true ? 2.0 : 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(context, 8.0)),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
            width: preferences?.highContrast == true ? 2.0 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(context, 8.0)),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: preferences?.highContrast == true ? 3.0 : 2.0,
          ),
        ),
        labelStyle: TextStyle(
          fontSize: useThemeFontSize && preferences != null
              ? ResponsiveScreenUtils.scale(
                  context, 
                  16.0 * _getFontSizeMultiplier(preferences.fontSizeLevel)
                )
              : ResponsiveScreenUtils.scale(context, 16.0),
          fontWeight: preferences?.boldText == true ? FontWeight.bold : FontWeight.normal,
          color: useThemeColors ? theme.colorScheme.onSurface : null,
        ),
        hintStyle: TextStyle(
          fontSize: useThemeFontSize && preferences != null
              ? ResponsiveScreenUtils.scale(
                  context, 
                  16.0 * _getFontSizeMultiplier(preferences.fontSizeLevel)
                )
              : ResponsiveScreenUtils.scale(context, 16.0),
          color: useThemeColors ? theme.colorScheme.onSurface.withOpacity(0.6) : null,
        ),
      ),
    );

    if (responsiveMargin != null) {
      return Container(
        margin: responsiveMargin,
        child: textField,
      );
    }

    return textField;
  }
  
  double _getFontSizeMultiplier(FontSizeLevel level) {
    switch (level) {
      case FontSizeLevel.extraSmall:
        return 0.8;
      case FontSizeLevel.small:
        return 0.9;
      case FontSizeLevel.medium:
        return 1.0;
      case FontSizeLevel.large:
        return 1.2;
      case FontSizeLevel.extraLarge:
        return 1.4;
      case FontSizeLevel.huge:
        return 1.6;
    }
  }
}
