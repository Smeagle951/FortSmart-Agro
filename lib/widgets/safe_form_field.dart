import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/text_encoding_helper.dart';
import 'safe_text.dart';

/// Widget para exibir campos de formulário com tratamento seguro de codificação de texto
/// 
/// Este widget garante que todos os textos exibidos e inseridos em campos de formulário
/// tenham a codificação correta, evitando problemas com caracteres especiais e acentuação.
class SafeTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool autofocus;
  final bool readOnly;
  final bool? showCursor;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final String? restorationId;
  final bool enableIMEPersonalizedLearning;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isDense;
  final bool filled;
  final Color? fillColor;
  final Color? focusColor;
  final Color? hoverColor;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? enabledBorder;
  final InputBorder? errorBorder;
  final InputBorder? disabledBorder;
  final InputBorder? focusedErrorBorder;

  /// Construtor para o widget SafeTextField
  const SafeTextField({
    Key? key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.style,
    this.strutStyle,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.autofocus = false,
    this.readOnly = false,
    this.showCursor,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.buildCounter,
    this.scrollPhysics,
    this.autofillHints,
    this.restorationId,
    this.enableIMEPersonalizedLearning = true,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.isDense = false,
    this.filled = false,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.border,
    this.focusedBorder,
    this.enabledBorder,
    this.errorBorder,
    this.disabledBorder,
    this.focusedErrorBorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normaliza os textos para garantir a codificação correta
    final normalizedLabel = label != null 
        ? TextEncodingHelper.normalizeText(label!) 
        : null;
    final normalizedHintText = hintText != null 
        ? TextEncodingHelper.normalizeText(hintText!) 
        : null;
    final normalizedHelperText = helperText != null 
        ? TextEncodingHelper.normalizeText(helperText!) 
        : null;
    final normalizedErrorText = errorText != null 
        ? TextEncodingHelper.normalizeText(errorText!) 
        : null;
    final normalizedInitialValue = initialValue != null 
        ? TextEncodingHelper.normalizeText(initialValue!) 
        : null;

    // Cria a decoração com os textos normalizados
    final InputDecoration effectiveDecoration = decoration ?? const InputDecoration();
    final InputDecoration normalizedDecoration = effectiveDecoration.copyWith(
      labelText: normalizedLabel ?? effectiveDecoration.labelText,
      hintText: normalizedHintText ?? effectiveDecoration.hintText,
      helperText: normalizedHelperText ?? effectiveDecoration.helperText,
      errorText: normalizedErrorText ?? effectiveDecoration.errorText,
      prefix: prefix ?? effectiveDecoration.prefix,
      suffix: suffix ?? effectiveDecoration.suffix,
      prefixIcon: prefixIcon ?? effectiveDecoration.prefixIcon,
      suffixIcon: suffixIcon ?? effectiveDecoration.suffixIcon,
      isDense: isDense,
      filled: filled,
      fillColor: fillColor ?? effectiveDecoration.fillColor,
      focusColor: focusColor ?? effectiveDecoration.focusColor,
      hoverColor: hoverColor ?? effectiveDecoration.hoverColor,
      border: border ?? effectiveDecoration.border,
      focusedBorder: focusedBorder ?? effectiveDecoration.focusedBorder,
      enabledBorder: enabledBorder ?? effectiveDecoration.enabledBorder,
      errorBorder: errorBorder ?? effectiveDecoration.errorBorder,
      disabledBorder: disabledBorder ?? effectiveDecoration.disabledBorder,
      focusedErrorBorder: focusedErrorBorder ?? effectiveDecoration.focusedErrorBorder,
    );

    // Cria um novo controller se necessário para lidar com o valor inicial normalizado
    TextEditingController? effectiveController = controller;
    if (effectiveController == null && normalizedInitialValue != null) {
      effectiveController = TextEditingController(text: normalizedInitialValue);
    }

    // Adiciona um formatador para normalizar o texto durante a digitação
    final List<TextInputFormatter> effectiveFormatters = [
      _TextEncodingFormatter(),
      ...(inputFormatters ?? []),
    ];

    return TextField(
      controller: effectiveController,
      focusNode: focusNode,
      decoration: normalizedDecoration,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: style,
      strutStyle: strutStyle,
      textDirection: textDirection,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      autofocus: autofocus,
      readOnly: readOnly,
      showCursor: showCursor,
      obscuringCharacter: obscuringCharacter,
      obscureText: obscureText,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: enableSuggestions,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      maxLengthEnforcement: maxLengthEnforcement,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      inputFormatters: effectiveFormatters,
      enabled: enabled,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      buildCounter: buildCounter,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      restorationId: restorationId,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
    );
  }
}

/// Formatador de texto para normalizar a codificação durante a digitação
class _TextEncodingFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Normaliza o texto apenas se houver alteração
    if (oldValue.text != newValue.text) {
      final normalizedText = TextEncodingHelper.normalizeText(newValue.text);
      
      // Se o texto normalizado for diferente do texto original,
      // retorna um novo valor com o texto normalizado
      if (normalizedText != newValue.text) {
        return TextEditingValue(
          text: normalizedText,
          selection: newValue.selection,
          composing: newValue.composing,
        );
      }
    }
    
    // Se não houver alteração ou o texto já estiver normalizado,
    // retorna o valor original
    return newValue;
  }
}

/// Widget para exibir campos de formulário com tratamento seguro de codificação de texto
/// usando o FormField para integração com Form
class SafeFormField extends FormField<String> {
  /// Construtor para o widget SafeFormField
  SafeFormField({
    Key? key,
    String? initialValue,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    bool autovalidate = false,
    bool enabled = true,
    AutovalidateMode? autovalidateMode,
    TextEditingController? controller,
    FocusNode? focusNode,
    InputDecoration? decoration,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextDirection? textDirection,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    bool autofocus = false,
    bool readOnly = false,
    bool? showCursor,
    String obscuringCharacter = '•',
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    List<TextInputFormatter>? inputFormatters,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    Color? cursorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool enableInteractiveSelection = true,
    InputCounterWidgetBuilder? buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    String? restorationId,
    bool enableIMEPersonalizedLearning = true,
    String? label,
    String? hintText,
    String? helperText,
    String? errorText,
    Widget? prefix,
    Widget? suffix,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isDense = false,
    bool filled = false,
    Color? fillColor,
    Color? focusColor,
    Color? hoverColor,
    InputBorder? border,
    InputBorder? focusedBorder,
    InputBorder? enabledBorder,
    InputBorder? errorBorder,
    InputBorder? disabledBorder,
    InputBorder? focusedErrorBorder,
  }) : super(
    key: key,
    initialValue: TextEncodingHelper.normalizeText(initialValue ?? ''),
    onSaved: onSaved,
    validator: validator,
    enabled: enabled,
    autovalidateMode: autovalidateMode ?? (autovalidate ? AutovalidateMode.always : AutovalidateMode.disabled),
    builder: (FormFieldState<String> field) {
      final _SafeFormFieldState state = field as _SafeFormFieldState;
      
      // Normaliza os textos para garantir a codificação correta
      final normalizedLabel = label != null 
          ? TextEncodingHelper.normalizeText(label) 
          : null;
      final normalizedHintText = hintText != null 
          ? TextEncodingHelper.normalizeText(hintText) 
          : null;
      final normalizedHelperText = helperText != null 
          ? TextEncodingHelper.normalizeText(helperText) 
          : null;
      
      // Usa o erro do campo de formulário ou o erro fornecido
      final String? normalizedErrorText = field.hasError 
          ? TextEncodingHelper.normalizeText(field.errorText!) 
          : (errorText != null ? TextEncodingHelper.normalizeText(errorText) : null);
      
      // Cria a decoração com os textos normalizados
      final InputDecoration effectiveDecoration = (decoration ?? const InputDecoration())
          .copyWith(
            labelText: normalizedLabel ?? decoration?.labelText,
            hintText: normalizedHintText ?? decoration?.hintText,
            helperText: normalizedHelperText ?? decoration?.helperText,
            errorText: normalizedErrorText,
            prefix: prefix ?? decoration?.prefix,
            suffix: suffix ?? decoration?.suffix,
            prefixIcon: prefixIcon ?? decoration?.prefixIcon,
            suffixIcon: suffixIcon ?? decoration?.suffixIcon,
            isDense: isDense,
            filled: filled,
            fillColor: fillColor ?? decoration?.fillColor,
            focusColor: focusColor ?? decoration?.focusColor,
            hoverColor: hoverColor ?? decoration?.hoverColor,
            border: border ?? decoration?.border,
            focusedBorder: focusedBorder ?? decoration?.focusedBorder,
            enabledBorder: enabledBorder ?? decoration?.enabledBorder,
            errorBorder: errorBorder ?? decoration?.errorBorder,
            disabledBorder: disabledBorder ?? decoration?.disabledBorder,
            focusedErrorBorder: focusedErrorBorder ?? decoration?.focusedErrorBorder,
          );
      
      // Adiciona um formatador para normalizar o texto durante a digitação
      final List<TextInputFormatter> effectiveFormatters = [
        _TextEncodingFormatter(),
        ...(inputFormatters ?? []),
      ];
      
      return TextField(
        controller: state._effectiveController,
        focusNode: focusNode,
        decoration: effectiveDecoration,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        style: style,
        strutStyle: strutStyle,
        textDirection: textDirection,
        textAlign: textAlign,
        textAlignVertical: textAlignVertical,
        autofocus: autofocus,
        readOnly: readOnly,
        showCursor: showCursor,
        obscuringCharacter: obscuringCharacter,
        obscureText: obscureText,
        autocorrect: autocorrect,
        smartDashesType: smartDashesType,
        smartQuotesType: smartQuotesType,
        enableSuggestions: enableSuggestions,
        maxLines: maxLines,
        minLines: minLines,
        expands: expands,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
        onChanged: (value) {
          field.didChange(value);
          if (onChanged != null) {
            onChanged(value);
          }
        },
        onEditingComplete: onEditingComplete,
        onSubmitted: onSubmitted,
        inputFormatters: effectiveFormatters,
        enabled: enabled,
        cursorWidth: cursorWidth,
        cursorHeight: cursorHeight,
        cursorRadius: cursorRadius,
        cursorColor: cursorColor,
        keyboardAppearance: keyboardAppearance,
        scrollPadding: scrollPadding,
        enableInteractiveSelection: enableInteractiveSelection,
        buildCounter: buildCounter,
        scrollPhysics: scrollPhysics,
        autofillHints: autofillHints,
        restorationId: restorationId,
        enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      );
    },
  );

  @override
  _SafeFormFieldState createState() => _SafeFormFieldState();
}

class _SafeFormFieldState extends FormFieldState<String> {
  TextEditingController? _controller;
  
  TextEditingController get _effectiveController => _controller!;
  
  @override
  SafeFormField get widget => super.widget as SafeFormField;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: value);
  }
  
  @override
  void didUpdateWidget(SafeFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (value != _effectiveController.text) {
      _effectiveController.text = value ?? '';
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  @override
  void reset() {
    _effectiveController.text = widget.initialValue ?? '';
    super.reset();
  }
}
