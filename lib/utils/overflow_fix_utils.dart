import 'package:flutter/material.dart';

/// Utilitários para correção automática de overflow em telas menores
class OverflowFixUtils {
  
  /// Detecta se há overflow e aplica correções automáticas
  static Widget wrapWithOverflowFix(Widget child, {
    bool enableHorizontalScroll = true,
    bool enableVerticalScroll = true,
    EdgeInsets? padding,
    bool shrinkWrap = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: enableVerticalScroll ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: enableHorizontalScroll ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.minWidth,
                minHeight: constraints.minHeight,
              ),
              child: IntrinsicHeight(
                child: IntrinsicWidth(
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Cria um container que se adapta automaticamente ao tamanho da tela
  static Widget adaptiveContainer({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    double? borderRadius,
    BoxShadow? shadow,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          constraints: BoxConstraints(
            minHeight: constraints.minHeight,
            maxHeight: constraints.maxHeight,
          ),
          padding: padding ?? const EdgeInsets.all(16),
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
            boxShadow: shadow != null ? [shadow] : null,
          ),
          child: child,
        );
      },
    );
  }

  /// Cria um grid que se adapta ao tamanho da tela
  static Widget adaptiveGrid({
    required List<Widget> children,
    int? crossAxisCount,
    double? childAspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    bool shrinkWrap = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular número de colunas baseado na largura da tela
        final screenWidth = constraints.maxWidth;
        int calculatedCrossAxisCount = crossAxisCount ?? 2;
        
        if (screenWidth < 400) {
          calculatedCrossAxisCount = 1;
        } else if (screenWidth < 600) {
          calculatedCrossAxisCount = 2;
        } else if (screenWidth < 800) {
          calculatedCrossAxisCount = 3;
        } else {
          calculatedCrossAxisCount = 4;
        }

        return GridView.count(
          shrinkWrap: shrinkWrap,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: calculatedCrossAxisCount,
          childAspectRatio: childAspectRatio ?? 1.2,
          crossAxisSpacing: crossAxisSpacing ?? 12,
          mainAxisSpacing: mainAxisSpacing ?? 12,
          children: children,
        );
      },
    );
  }

  /// Cria um card que se adapta ao conteúdo sem overflow
  static Widget adaptiveCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    double? borderRadius,
    BoxShadow? shadow,
  }) {
    return Card(
      margin: margin ?? const EdgeInsets.all(8),
      elevation: shadow?.blurRadius ?? 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
        child: child,
      ),
    );
  }

  /// Cria um formulário que se adapta ao tamanho da tela
  static Widget adaptiveForm({
    required List<Widget> children,
    EdgeInsets? padding,
    bool enableScroll = true,
  }) {
    return Form(
      child: enableScroll
          ? SingleChildScrollView(
              padding: padding ?? const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
    );
  }

  /// Cria um botão que se adapta ao tamanho da tela
  static Widget adaptiveButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsets? padding,
    double? fontSize,
    bool isFullWidth = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon, size: fontSize != null ? fontSize * 0.8 : 16) : const SizedBox.shrink(),
            label: Text(
              text,
              style: TextStyle(
                fontSize: fontSize ?? 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? Colors.blue,
              foregroundColor: foregroundColor ?? Colors.white,
              padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Cria um campo de texto que se adapta ao tamanho da tela
  static Widget adaptiveTextField({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }

  /// Cria um dropdown que se adapta ao tamanho da tela
  static Widget adaptiveDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
    Widget? prefixIcon,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }

  /// Detecta se a tela é pequena
  static bool isSmallScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 400;
  }

  /// Detecta se a tela é média
  static bool isMediumScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 400 && screenWidth < 800;
  }

  /// Detecta se a tela é grande
  static bool isLargeScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 800;
  }

  /// Obtém o tamanho da fonte baseado no tamanho da tela
  static double getAdaptiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 400) {
      return baseFontSize * 0.9; // 10% menor para telas pequenas
    } else if (screenWidth < 600) {
      return baseFontSize; // Tamanho normal
    } else {
      return baseFontSize * 1.1; // 10% maior para telas grandes
    }
  }

  /// Obtém o padding baseado no tamanho da tela
  static EdgeInsets getAdaptivePadding(BuildContext context, EdgeInsets basePadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 400) {
      return EdgeInsets.all(basePadding.left * 0.8); // 20% menor para telas pequenas
    } else if (screenWidth < 600) {
      return basePadding; // Padding normal
    } else {
      return EdgeInsets.all(basePadding.left * 1.2); // 20% maior para telas grandes
    }
  }

  /// Cria um scaffold que se adapta automaticamente
  static Widget adaptiveScaffold({
    required String title,
    required Widget body,
    List<Widget>? actions,
    Widget? floatingActionButton,
    Color? backgroundColor,
    Color? appBarColor,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: appBarColor ?? Colors.blue,
        foregroundColor: Colors.white,
        actions: actions,
        centerTitle: true,
      ),
      body: wrapWithOverflowFix(body),
      floatingActionButton: floatingActionButton,
    );
  }
}
