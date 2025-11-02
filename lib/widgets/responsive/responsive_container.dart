import 'package:flutter/material.dart';
import '../../utils/responsive_screen_utils.dart';

/// Container responsivo que se adapta ao tamanho da tela
class ResponsiveContainer extends StatelessWidget {
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

  const ResponsiveContainer({
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveScreenUtils.getBalancedScale(context);
    
    return Container(
      width: width != null ? ResponsiveScreenUtils.scale(context, width!) : null,
      height: height != null ? ResponsiveScreenUtils.scale(context, height!) : null,
      padding: padding != null 
          ? EdgeInsets.only(
              left: ResponsiveScreenUtils.scale(context, padding!.left),
              top: ResponsiveScreenUtils.scale(context, padding!.top),
              right: ResponsiveScreenUtils.scale(context, padding!.right),
              bottom: ResponsiveScreenUtils.scale(context, padding!.bottom),
            )
          : null,
      margin: margin != null
          ? EdgeInsets.only(
              left: ResponsiveScreenUtils.scale(context, margin!.left),
              top: ResponsiveScreenUtils.scale(context, margin!.top),
              right: ResponsiveScreenUtils.scale(context, margin!.right),
              bottom: ResponsiveScreenUtils.scale(context, margin!.bottom),
            )
          : null,
      decoration: decoration ?? BoxDecoration(
        color: color,
        borderRadius: borderRadius != null 
            ? BorderRadius.circular(ResponsiveScreenUtils.scale(context, borderRadius!))
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

/// Card responsivo
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final Border? border;
  final BoxShadow? shadow;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.border,
    this.shadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      padding: padding,
      margin: margin,
      color: color,
      elevation: elevation,
      borderRadius: borderRadius,
      border: border,
      shadow: shadow,
      child: child,
    );
  }
}

/// Padding responsivo
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? all;
  final double? horizontal;
  final double? vertical;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const ResponsivePadding({
    Key? key,
    required this.child,
    this.padding,
    this.all,
    this.horizontal,
    this.vertical,
    this.left,
    this.top,
    this.right,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsivePadding = ResponsiveScreenUtils.getResponsivePadding(
      context,
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
    
    return Padding(
      padding: padding ?? responsivePadding,
      child: child,
    );
  }
}

/// Margin responsivo
class ResponsiveMargin extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final double? all;
  final double? horizontal;
  final double? vertical;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const ResponsiveMargin({
    Key? key,
    required this.child,
    this.margin,
    this.all,
    this.horizontal,
    this.vertical,
    this.left,
    this.top,
    this.right,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveMargin = ResponsiveScreenUtils.getResponsiveMargin(
      context,
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
    
    return Container(
      margin: margin ?? responsiveMargin,
      child: child,
    );
  }
}

/// SizedBox responsivo
class ResponsiveSizedBox extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;

  const ResponsiveSizedBox({
    Key? key,
    this.child,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width != null ? ResponsiveScreenUtils.scale(context, width!) : null,
      height: height != null ? ResponsiveScreenUtils.scale(context, height!) : null,
      child: child,
    );
  }
}
