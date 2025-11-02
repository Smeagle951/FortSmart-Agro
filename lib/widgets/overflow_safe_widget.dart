import 'package:flutter/material.dart';
import '../mixins/overflow_fix_mixin.dart';

/// Widget base que automaticamente corrige problemas de overflow
class OverflowSafeWidget extends StatefulWidget {
  final Widget child;
  final bool enableHorizontalScroll;
  final bool enableVerticalScroll;
  final EdgeInsets? padding;
  final bool shrinkWrap;

  const OverflowSafeWidget({
    Key? key,
    required this.child,
    this.enableHorizontalScroll = true,
    this.enableVerticalScroll = true,
    this.padding,
    this.shrinkWrap = true,
  }) : super(key: key);

  @override
  State<OverflowSafeWidget> createState() => _OverflowSafeWidgetState();
}

class _OverflowSafeWidgetState extends State<OverflowSafeWidget> with OverflowFixMixin {
  @override
  Widget build(BuildContext context) {
    return wrapWithOverflowFix(
      widget.child,
      enableHorizontalScroll: widget.enableHorizontalScroll,
      enableVerticalScroll: widget.enableVerticalScroll,
      padding: widget.padding,
    );
  }
}

/// Widget de card que automaticamente corrige overflow
class OverflowSafeCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final BoxShadow? shadow;

  const OverflowSafeCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.shadow,
  }) : super(key: key);

  @override
  State<OverflowSafeCard> createState() => _OverflowSafeCardState();
}

class _OverflowSafeCardState extends State<OverflowSafeCard> with OverflowFixMixin {
  @override
  Widget build(BuildContext context) {
    return buildAdaptiveCard(
      child: widget.child,
      padding: widget.padding,
      margin: widget.margin,
      backgroundColor: widget.backgroundColor,
      borderRadius: widget.borderRadius,
    );
  }
}

/// Widget de grid que automaticamente corrige overflow
class OverflowSafeGrid extends StatefulWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final bool shrinkWrap;

  const OverflowSafeGrid({
    Key? key,
    required this.children,
    this.crossAxisCount,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.shrinkWrap = true,
  }) : super(key: key);

  @override
  State<OverflowSafeGrid> createState() => _OverflowSafeGridState();
}

class _OverflowSafeGridState extends State<OverflowSafeGrid> with OverflowFixMixin {
  @override
  Widget build(BuildContext context) {
    return buildAdaptiveGrid(
      children: widget.children,
      crossAxisCount: widget.crossAxisCount,
      childAspectRatio: widget.childAspectRatio,
      crossAxisSpacing: widget.crossAxisSpacing,
      mainAxisSpacing: widget.mainAxisSpacing,
    );
  }
}

/// Widget de formulário que automaticamente corrige overflow
class OverflowSafeForm extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final bool enableScroll;

  const OverflowSafeForm({
    Key? key,
    required this.children,
    this.padding,
    this.enableScroll = true,
  }) : super(key: key);

  @override
  State<OverflowSafeForm> createState() => _OverflowSafeFormState();
}

class _OverflowSafeFormState extends State<OverflowSafeForm> with OverflowFixMixin {
  @override
  Widget build(BuildContext context) {
    return buildAdaptiveForm(
      children: widget.children,
      padding: widget.padding,
      enableScroll: widget.enableScroll,
    );
  }
}

/// Widget de botão que automaticamente corrige overflow
class OverflowSafeButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsets? padding;
  final double? fontSize;
  final bool isFullWidth;

  const OverflowSafeButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.fontSize,
    this.isFullWidth = true,
  }) : super(key: key);

  @override
  State<OverflowSafeButton> createState() => _OverflowSafeButtonState();
}

class _OverflowSafeButtonState extends State<OverflowSafeButton> with OverflowFixMixin {
  @override
  Widget build(BuildContext context) {
    return buildAdaptiveButton(
      text: widget.text,
      onPressed: widget.onPressed,
      icon: widget.icon,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      padding: widget.padding,
      fontSize: widget.fontSize,
      isFullWidth: widget.isFullWidth,
    );
  }
}

/// Widget de campo de texto que automaticamente corrige overflow
class OverflowSafeTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;

  const OverflowSafeTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines,
    this.maxLength,
  }) : super(key: key);

  @override
  State<OverflowSafeTextField> createState() => _OverflowSafeTextFieldState();
}

class _OverflowSafeTextFieldState extends State<OverflowSafeTextField> with OverflowFixMixin {
  @override
  Widget build(BuildContext context) {
    return buildAdaptiveTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
    );
  }
}

/// Widget de dropdown que automaticamente corrige overflow
class OverflowSafeDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final Widget? prefixIcon;

  const OverflowSafeDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.prefixIcon,
  }) : super(key: key);

  @override
  State<OverflowSafeDropdown<T>> createState() => _OverflowSafeDropdownState<T>();
}

class _OverflowSafeDropdownState<T> extends State<OverflowSafeDropdown<T>> with OverflowFixMixin {
  @override
  Widget build(BuildContext context) {
    return buildAdaptiveDropdown<T>(
      label: widget.label,
      value: widget.value,
      items: widget.items,
      onChanged: widget.onChanged,
      hint: widget.hint,
      prefixIcon: widget.prefixIcon,
    );
  }
}

/// Widget de scaffold que automaticamente corrige overflow
class OverflowSafeScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Color? appBarColor;

  const OverflowSafeScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
    this.appBarColor,
  }) : super(key: key);

  @override
  State<OverflowSafeScaffold> createState() => _OverflowSafeScaffoldState();
}

class _OverflowSafeScaffoldState extends State<OverflowSafeScaffold> with OverflowFixMixin {
  @override
  Widget build(BuildContext context) {
    return buildAdaptiveScaffold(
      title: widget.title,
      body: widget.body,
      actions: widget.actions,
      floatingActionButton: widget.floatingActionButton,
      backgroundColor: widget.backgroundColor,
      appBarColor: widget.appBarColor,
    );
  }
}
