import 'package:flutter/material.dart';
import '../utils/overflow_fix_utils.dart';

/// Mixin para correção automática de overflow em qualquer widget
mixin OverflowFixMixin<T extends StatefulWidget> on State<T> {
  
  /// Envolve o widget com correções de overflow
  Widget wrapWithOverflowFix(Widget child, {
    bool enableHorizontalScroll = true,
    bool enableVerticalScroll = true,
    EdgeInsets? padding,
  }) {
    return OverflowFixUtils.wrapWithOverflowFix(
      child,
      enableHorizontalScroll: enableHorizontalScroll,
      enableVerticalScroll: enableVerticalScroll,
      padding: padding,
    );
  }

  /// Cria um container adaptativo
  Widget buildAdaptiveContainer({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    double? borderRadius,
  }) {
    return OverflowFixUtils.adaptiveContainer(
      child: child,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
    );
  }

  /// Cria um card adaptativo
  Widget buildAdaptiveCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    double? borderRadius,
  }) {
    return OverflowFixUtils.adaptiveCard(
      child: child,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
    );
  }

  /// Cria um grid adaptativo
  Widget buildAdaptiveGrid({
    required List<Widget> children,
    int? crossAxisCount,
    double? childAspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    return OverflowFixUtils.adaptiveGrid(
      children: children,
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  /// Cria um formulário adaptativo
  Widget buildAdaptiveForm({
    required List<Widget> children,
    EdgeInsets? padding,
    bool enableScroll = true,
  }) {
    return OverflowFixUtils.adaptiveForm(
      children: children,
      padding: padding,
      enableScroll: enableScroll,
    );
  }

  /// Cria um botão adaptativo
  Widget buildAdaptiveButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsets? padding,
    double? fontSize,
    bool isFullWidth = true,
  }) {
    return OverflowFixUtils.adaptiveButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      fontSize: fontSize,
      isFullWidth: isFullWidth,
    );
  }

  /// Cria um campo de texto adaptativo
  Widget buildAdaptiveTextField({
    required String label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines,
    int? maxLength,
  }) {
    return OverflowFixUtils.adaptiveTextField(
      label: label,
      hint: hint,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      maxLines: maxLines,
      maxLength: maxLength,
    );
  }

  /// Cria um dropdown adaptativo
  Widget buildAdaptiveDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
    Widget? prefixIcon,
  }) {
    return OverflowFixUtils.adaptiveDropdown<T>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      hint: hint,
      prefixIcon: prefixIcon,
    );
  }

  /// Detecta se a tela é pequena
  bool get isSmallScreen => OverflowFixUtils.isSmallScreen(context);

  /// Detecta se a tela é média
  bool get isMediumScreen => OverflowFixUtils.isMediumScreen(context);

  /// Detecta se a tela é grande
  bool get isLargeScreen => OverflowFixUtils.isLargeScreen(context);

  /// Obtém o tamanho da fonte adaptativo
  double getAdaptiveFontSize(double baseFontSize) {
    return OverflowFixUtils.getAdaptiveFontSize(context, baseFontSize);
  }

  /// Obtém o padding adaptativo
  EdgeInsets getAdaptivePadding(EdgeInsets basePadding) {
    return OverflowFixUtils.getAdaptivePadding(context, basePadding);
  }

  /// Cria um scaffold adaptativo
  Widget buildAdaptiveScaffold({
    required String title,
    required Widget body,
    List<Widget>? actions,
    Widget? floatingActionButton,
    Color? backgroundColor,
    Color? appBarColor,
  }) {
    return OverflowFixUtils.adaptiveScaffold(
      title: title,
      body: body,
      actions: actions,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      appBarColor: appBarColor,
    );
  }
}
