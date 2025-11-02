import 'package:flutter/material.dart';

/// Widget de card personalizado para o FortSmart Agro
class FortSmartCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? shadowColor;
  final BorderSide? border;
  final VoidCallback? onTap;
  final bool isSelectable;
  final bool isSelected;
  final Color? selectedColor;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  const FortSmartCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.shadowColor,
    this.border,
    this.onTap,
    this.isSelectable = false,
    this.isSelected = false,
    this.selectedColor,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Usar o fundo escuro translúcido como padrão para seguir o padrão visual
    final defaultBackgroundColor = isDarkMode 
        ? const Color(0xE6232323) // fundo escuro translúcido
        : Colors.white;
    
    final defaultShadowColor = isDarkMode
        ? Colors.black.withOpacity(0.25)
        : Colors.black26;
    
    final effectiveBackgroundColor = isSelected
        ? (selectedColor ?? theme.primaryColor.withOpacity(0.1))
        : (backgroundColor ?? defaultBackgroundColor);
    
    final effectiveBorder = isSelected
        ? border ?? BorderSide(color: theme.primaryColor, width: 2.0)
        : border;

    final cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(20.0),
      child: child,
    );

    final card = Material(
      color: effectiveBackgroundColor,
      elevation: elevation ?? (isDarkMode ? 12.0 : 4.0),
      shadowColor: shadowColor ?? defaultShadowColor,
      // Definimos o borderRadius apenas no shape para evitar duplicação
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: effectiveBorder ?? BorderSide.none,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: onTap != null
            ? Ink(
                child: InkWell(
                  onTap: onTap,
                  splashFactory: InkRipple.splashFactory,
                  highlightColor: Colors.transparent,
                  // Não definimos shape nem borderRadius no InkWell para evitar o erro de asserção
                  child: cardContent,
                ),
              )
            : cardContent,
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: margin ?? const EdgeInsets.all(0),
      child: card,
    );
  }
}

/// Widget de card com cabeçalho para o FortSmart Agro
class FortSmartHeaderCard extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? body;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? headerBackgroundColor;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool divider;
  final double? width;
  final double? height;

  const FortSmartHeaderCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.body,
    this.footer,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.headerBackgroundColor,
    this.titleColor,
    this.onTap,
    this.divider = true,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final effectiveHeaderBackgroundColor = headerBackgroundColor ?? 
        (isDarkMode ? theme.primaryColor.withOpacity(0.2) : theme.primaryColor.withOpacity(0.1));
    
    final effectiveTitleColor = titleColor ?? 
        (isDarkMode ? Colors.white : theme.primaryColor);

    final headerContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: effectiveTitleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );

    final header = Container(
      decoration: BoxDecoration(
        color: effectiveHeaderBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(body == null && footer == null ? borderRadius : 0),
          bottomRight: Radius.circular(body == null && footer == null ? borderRadius : 0),
        ),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
                bottomLeft: Radius.circular(body == null && footer == null ? borderRadius : 0),
                bottomRight: Radius.circular(body == null && footer == null ? borderRadius : 0),
              ),
              child: headerContent,
            )
          : headerContent,
    );

    final bodyContent = body != null
        ? Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: body,
          )
        : null;

    final footerContent = footer != null
        ? Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: footer,
          )
        : null;

    return FortSmartCard(
      padding: EdgeInsets.zero,
      margin: margin,
      elevation: elevation,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (body != null) ...[
            if (divider) const Divider(height: 1, thickness: 1),
            bodyContent!,
          ],
          if (footer != null) ...[
            if (divider && body != null) const Divider(height: 1, thickness: 1),
            footerContent!,
          ],
        ],
      ),
    );
  }
}

/// Widget de card com status para o FortSmart Agro
class FortSmartStatusCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? content;
  final String status;
  final Color statusColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final double borderRadius;
  final VoidCallback? onTap;

  const FortSmartStatusCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.content,
    required this.status,
    required this.statusColor,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius = 12.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FortSmartCard(
      padding: EdgeInsets.zero,
      margin: margin,
      elevation: elevation,
      borderRadius: borderRadius,
      onTap: onTap,
      border: BorderSide(
        color: statusColor.withOpacity(0.5),
        width: 1.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                  ),
                ),
                Icon(
                  Icons.circle,
                  size: 10.0,
                  color: statusColor,
                ),
              ],
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 16.0),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                      if (content != null) ...[
                        const SizedBox(height: 12.0),
                        content!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
