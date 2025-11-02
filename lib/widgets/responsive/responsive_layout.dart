import 'package:flutter/material.dart';
import '../../utils/responsive_screen_utils.dart';

/// Layout responsivo que se adapta ao tamanho da tela
class ResponsiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget child;

  const ResponsiveLayout({
    Key? key,
    this.mobile,
    this.tablet,
    this.desktop,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveScreenUtils.getScreenType(context);
    
    switch (screenType) {
      case ScreenType.small:
        return mobile ?? child;
      case ScreenType.medium:
        return tablet ?? child;
      case ScreenType.large:
        return desktop ?? child;
    }
  }
}

/// Grid responsivo
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.crossAxisCount,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveScreenUtils.getScreenType(context);
    
    int responsiveCrossAxisCount;
    switch (screenType) {
      case ScreenType.small:
        responsiveCrossAxisCount = crossAxisCount ?? 1;
        break;
      case ScreenType.medium:
        responsiveCrossAxisCount = crossAxisCount ?? 2;
        break;
      case ScreenType.large:
        responsiveCrossAxisCount = crossAxisCount ?? 3;
        break;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsiveCrossAxisCount,
        childAspectRatio: childAspectRatio ?? 1.0,
        crossAxisSpacing: crossAxisSpacing ?? 8.0,
        mainAxisSpacing: mainAxisSpacing ?? 8.0,
      ),
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Lista responsiva
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  const ResponsiveList({
    Key? key,
    required this.children,
    this.padding,
    this.spacing,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveSpacing = spacing != null
        ? ResponsiveScreenUtils.scale(context, spacing!)
        : ResponsiveScreenUtils.scale(context, 8.0);

    return ListView.separated(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      scrollDirection: scrollDirection,
      itemCount: children.length,
      separatorBuilder: (context, index) => ResponsiveSizedBox(
        height: scrollDirection == Axis.vertical ? responsiveSpacing : 0,
        width: scrollDirection == Axis.horizontal ? responsiveSpacing : 0,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Row responsivo
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;
  final EdgeInsets? padding;
  final bool wrap;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.padding,
    this.wrap = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveSpacing = spacing != null
        ? ResponsiveScreenUtils.scale(context, spacing!)
        : ResponsiveScreenUtils.scale(context, 8.0);

    Widget row = Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: _buildChildren(context, responsiveSpacing),
    );

    if (padding != null) {
      row = Padding(
        padding: EdgeInsets.only(
          left: ResponsiveScreenUtils.scale(context, padding!.left),
          top: ResponsiveScreenUtils.scale(context, padding!.top),
          right: ResponsiveScreenUtils.scale(context, padding!.right),
          bottom: ResponsiveScreenUtils.scale(context, padding!.bottom),
        ),
        child: row,
      );
    }

    if (wrap) {
      return Wrap(
        children: _buildChildren(context, responsiveSpacing),
      );
    }

    return row;
  }

  List<Widget> _buildChildren(BuildContext context, double spacing) {
    if (children.isEmpty) return [];
    
    final List<Widget> result = [children.first];
    
    for (int i = 1; i < children.length; i++) {
      result.add(ResponsiveSizedBox(width: spacing));
      result.add(children[i]);
    }
    
    return result;
  }
}

/// Column responsiva
class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;
  final EdgeInsets? padding;

  const ResponsiveColumn({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveSpacing = spacing != null
        ? ResponsiveScreenUtils.scale(context, spacing!)
        : ResponsiveScreenUtils.scale(context, 8.0);

    Widget column = Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: _buildChildren(context, responsiveSpacing),
    );

    if (padding != null) {
      column = Padding(
        padding: EdgeInsets.only(
          left: ResponsiveScreenUtils.scale(context, padding!.left),
          top: ResponsiveScreenUtils.scale(context, padding!.top),
          right: ResponsiveScreenUtils.scale(context, padding!.right),
          bottom: ResponsiveScreenUtils.scale(context, padding!.bottom),
        ),
        child: column,
      );
    }

    return column;
  }

  List<Widget> _buildChildren(BuildContext context, double spacing) {
    if (children.isEmpty) return [];
    
    final List<Widget> result = [children.first];
    
    for (int i = 1; i < children.length; i++) {
      result.add(ResponsiveSizedBox(height: spacing));
      result.add(children[i]);
    }
    
    return result;
  }
}

/// Stack responsivo
class ResponsiveStack extends StatelessWidget {
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit fit;
  final Clip clipBehavior;
  final EdgeInsets? padding;

  const ResponsiveStack({
    Key? key,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget stack = Stack(
      alignment: alignment,
      textDirection: textDirection,
      fit: fit,
      clipBehavior: clipBehavior,
      children: children,
    );

    if (padding != null) {
      stack = Padding(
        padding: EdgeInsets.only(
          left: ResponsiveScreenUtils.scale(context, padding!.left),
          top: ResponsiveScreenUtils.scale(context, padding!.top),
          right: ResponsiveScreenUtils.scale(context, padding!.right),
          bottom: ResponsiveScreenUtils.scale(context, padding!.bottom),
        ),
        child: stack,
      );
    }

    return stack;
  }
}

/// Divider responsivo
class ResponsiveDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;

  const ResponsiveDivider({
    Key? key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height != null ? ResponsiveScreenUtils.scale(context, height!) : null,
      thickness: thickness != null ? ResponsiveScreenUtils.scale(context, thickness!) : null,
      indent: indent != null ? ResponsiveScreenUtils.scale(context, indent!) : null,
      endIndent: endIndent != null ? ResponsiveScreenUtils.scale(context, endIndent!) : null,
      color: color,
    );
  }
}
