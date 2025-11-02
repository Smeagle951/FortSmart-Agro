import 'package:flutter/material.dart';
import '../utils/text_encoding_helper.dart';
import 'safe_text.dart';

/// Widget para exibir ListTile com tratamento seguro de codificação de texto
/// 
/// Este widget garante que todos os textos exibidos no ListTile tenham a codificação correta,
/// evitando problemas com caracteres especiais e acentuação.
class SafeListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool isThreeLine;
  final bool dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;
  final bool selected;
  final Color? selectedColor;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// Construtor para o widget SafeListTile
  const SafeListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.isThreeLine = false,
    this.dense = false,
    this.visualDensity,
    this.shape,
    this.contentPadding,
    this.enabled = true,
    this.selected = false,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.onTap,
    this.onLongPress,
    this.titleStyle,
    this.subtitleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normaliza os textos para garantir a codificação correta
    final normalizedTitle = TextEncodingHelper.normalizeText(title);
    final normalizedSubtitle = subtitle != null 
        ? TextEncodingHelper.normalizeText(subtitle!) 
        : null;

    return ListTile(
      title: SafeText(
        normalizedTitle,
        style: titleStyle,
      ),
      subtitle: normalizedSubtitle != null 
          ? SafeText(
              normalizedSubtitle,
              style: subtitleStyle,
            ) 
          : null,
      leading: leading,
      trailing: trailing,
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      contentPadding: contentPadding,
      enabled: enabled,
      selected: selected,
      selectedColor: selectedColor,
      iconColor: iconColor,
      textColor: textColor,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// Widget para exibir ListTile com checkbox e tratamento seguro de codificação de texto
class SafeCheckboxListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? secondary;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool isThreeLine;
  final bool dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? contentPadding;
  final bool selected;
  final Color? activeColor;
  final Color? checkColor;
  final ListTileControlAffinity controlAffinity;
  final bool autofocus;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// Construtor para o widget SafeCheckboxListTile
  const SafeCheckboxListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.onChanged,
    this.isThreeLine = false,
    this.dense = false,
    this.visualDensity,
    this.shape,
    this.contentPadding,
    this.selected = false,
    this.activeColor,
    this.checkColor,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.autofocus = false,
    this.titleStyle,
    this.subtitleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normaliza os textos para garantir a codificação correta
    final normalizedTitle = TextEncodingHelper.normalizeText(title);
    final normalizedSubtitle = subtitle != null 
        ? TextEncodingHelper.normalizeText(subtitle!) 
        : null;

    return CheckboxListTile(
      title: SafeText(
        normalizedTitle,
        style: titleStyle,
      ),
      subtitle: normalizedSubtitle != null 
          ? SafeText(
              normalizedSubtitle,
              style: subtitleStyle,
            ) 
          : null,
      secondary: secondary,
      value: value,
      onChanged: onChanged,
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      contentPadding: contentPadding,
      selected: selected,
      activeColor: activeColor,
      checkColor: checkColor,
      controlAffinity: controlAffinity,
      autofocus: autofocus,
    );
  }
}

/// Widget para exibir ListTile com switch e tratamento seguro de codificação de texto
class SafeSwitchListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? secondary;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isThreeLine;
  final bool dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? contentPadding;
  final bool selected;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
  final ListTileControlAffinity controlAffinity;
  final bool autofocus;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// Construtor para o widget SafeSwitchListTile
  const SafeSwitchListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.onChanged,
    this.isThreeLine = false,
    this.dense = false,
    this.visualDensity,
    this.shape,
    this.contentPadding,
    this.selected = false,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.autofocus = false,
    this.titleStyle,
    this.subtitleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normaliza os textos para garantir a codificação correta
    final normalizedTitle = TextEncodingHelper.normalizeText(title);
    final normalizedSubtitle = subtitle != null 
        ? TextEncodingHelper.normalizeText(subtitle!) 
        : null;

    return SwitchListTile(
      title: SafeText(
        normalizedTitle,
        style: titleStyle,
      ),
      subtitle: normalizedSubtitle != null 
          ? SafeText(
              normalizedSubtitle,
              style: subtitleStyle,
            ) 
          : null,
      secondary: secondary,
      value: value,
      onChanged: onChanged,
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      contentPadding: contentPadding,
      selected: selected,
      activeColor: activeColor,
      activeTrackColor: activeTrackColor,
      inactiveThumbColor: inactiveThumbColor,
      inactiveTrackColor: inactiveTrackColor,
      controlAffinity: controlAffinity,
      autofocus: autofocus,
    );
  }
}

/// Widget para exibir ListTile com radio e tratamento seguro de codificação de texto
class SafeRadioListTile<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? secondary;
  final T value;
  final T groupValue;
  final ValueChanged<T?>? onChanged;
  final bool isThreeLine;
  final bool dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? contentPadding;
  final bool selected;
  final Color? activeColor;
  final ListTileControlAffinity controlAffinity;
  final bool autofocus;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// Construtor para o widget SafeRadioListTile
  const SafeRadioListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.isThreeLine = false,
    this.dense = false,
    this.visualDensity,
    this.shape,
    this.contentPadding,
    this.selected = false,
    this.activeColor,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.autofocus = false,
    this.titleStyle,
    this.subtitleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normaliza os textos para garantir a codificação correta
    final normalizedTitle = TextEncodingHelper.normalizeText(title);
    final normalizedSubtitle = subtitle != null 
        ? TextEncodingHelper.normalizeText(subtitle!) 
        : null;

    return RadioListTile<T>(
      title: SafeText(
        normalizedTitle,
        style: titleStyle,
      ),
      subtitle: normalizedSubtitle != null 
          ? SafeText(
              normalizedSubtitle,
              style: subtitleStyle,
            ) 
          : null,
      secondary: secondary,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      contentPadding: contentPadding,
      selected: selected,
      activeColor: activeColor,
      controlAffinity: controlAffinity,
      autofocus: autofocus,
    );
  }
}
