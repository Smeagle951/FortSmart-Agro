import 'package:flutter/material.dart';
import '../utils/text_encoding_helper.dart';
import 'safe_text.dart';
import 'safe_title.dart' as title_widget;

/// Classe utilitária para exibir diálogos com tratamento seguro de codificação de texto
class SafeDialog {
  /// Exibe um diálogo de alerta simples
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) async {
    // Normaliza os textos para garantir a codificação correta
    final normalizedTitle = TextEncodingHelper.normalizeText(title);
    final normalizedMessage = TextEncodingHelper.normalizeText(message);
    final normalizedButtonText = TextEncodingHelper.normalizeText(buttonText);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title_widget.SafeTitle(normalizedTitle),
          content: SingleChildScrollView(
            child: SafeText(normalizedMessage),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onPressed != null) {
                  onPressed();
                }
              },
              child: SafeText(normalizedButtonText),
            ),
          ],
        );
      },
    );
  }

  /// Exibe um diálogo de confirmação com botões de sim e não
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Sim',
    String cancelText = 'Não',
    bool barrierDismissible = true,
  }) async {
    // Normaliza os textos para garantir a codificação correta
    final normalizedTitle = TextEncodingHelper.normalizeText(title);
    final normalizedMessage = TextEncodingHelper.normalizeText(message);
    final normalizedConfirmText = TextEncodingHelper.normalizeText(confirmText);
    final normalizedCancelText = TextEncodingHelper.normalizeText(cancelText);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title_widget.SafeTitle(normalizedTitle),
          content: SingleChildScrollView(
            child: SafeText(normalizedMessage),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: SafeText(normalizedCancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: SafeText(normalizedConfirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Exibe um diálogo com uma lista de opções
  static Future<T?> showOptions<T>({
    required BuildContext context,
    required String title,
    required List<DialogOption<T>> options,
    String? message,
    bool barrierDismissible = true,
  }) async {
    // Normaliza os textos para garantir a codificação correta
    final normalizedTitle = TextEncodingHelper.normalizeText(title);
    final normalizedMessage = message != null 
        ? TextEncodingHelper.normalizeText(message) 
        : null;

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title_widget.SafeTitle(normalizedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (normalizedMessage != null) ...[
                SafeText(normalizedMessage),
                const SizedBox(height: 16),
              ],
              ...options.map((option) {
                final normalizedText = TextEncodingHelper.normalizeText(option.text);
                
                return ListTile(
                  title: SafeText(normalizedText),
                  leading: option.icon,
                  onTap: () => Navigator.of(context).pop(option.value),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  /// Exibe um diálogo de entrada de texto
  static Future<String?> showTextInput({
    required BuildContext context,
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String confirmText = 'OK',
    String cancelText = 'Cancelar',
    bool barrierDismissible = true,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) async {
    // Normaliza os textos para garantir a codificação correta
    final normalizedTitle = TextEncodingHelper.normalizeText(title);
    final normalizedMessage = message != null 
        ? TextEncodingHelper.normalizeText(message) 
        : null;
    final normalizedInitialValue = initialValue != null 
        ? TextEncodingHelper.normalizeText(initialValue) 
        : null;
    final normalizedHintText = hintText != null 
        ? TextEncodingHelper.normalizeText(hintText) 
        : null;
    final normalizedConfirmText = TextEncodingHelper.normalizeText(confirmText);
    final normalizedCancelText = TextEncodingHelper.normalizeText(cancelText);

    final controller = TextEditingController(text: normalizedInitialValue);
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: title_widget.SafeTitle(normalizedTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (normalizedMessage != null) ...[
                    SafeText(normalizedMessage),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: normalizedHintText,
                      errorText: errorText,
                    ),
                    keyboardType: keyboardType,
                    maxLength: maxLength,
                    obscureText: obscureText,
                    autofocus: true,
                    onChanged: (value) {
                      if (validator != null) {
                        setState(() {
                          errorText = validator(value);
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: SafeText(normalizedCancelText),
                ),
                TextButton(
                  onPressed: () {
                    final value = controller.text;
                    if (validator != null) {
                      final error = validator(value);
                      if (error != null) {
                        setState(() {
                          errorText = error;
                        });
                        return;
                      }
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: SafeText(normalizedConfirmText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Exibe um diálogo de carregamento
  static Future<T> showLoading<T>({
    required BuildContext context,
    required Future<T> future,
    required String message,
    bool barrierDismissible = false,
  }) async {
    // Normaliza o texto para garantir a codificação correta
    final normalizedMessage = TextEncodingHelper.normalizeText(message);

    // Mostra o diálogo de carregamento
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => barrierDismissible,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: SafeText(normalizedMessage),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Aguarda a conclusão do future
      final result = await future;
      
      // Fecha o diálogo de carregamento
      Navigator.of(context, rootNavigator: true).pop();
      
      return result;
    } catch (e) {
      // Fecha o diálogo de carregamento em caso de erro
      Navigator.of(context, rootNavigator: true).pop();
      
      // Relança a exceção
      rethrow;
    }
  }

  /// Exibe um diálogo com um widget personalizado
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) async {
    // Normaliza o título para garantir a codificação correta
    final normalizedTitle = TextEncodingHelper.normalizeText(title);

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title_widget.SafeTitle(normalizedTitle),
          content: content,
          actions: actions,
        );
      },
    );
  }
}

/// Classe para representar uma opção em um diálogo de opções
class DialogOption<T> {
  final String text;
  final T value;
  final Widget? icon;

  DialogOption({
    required this.text,
    required this.value,
    this.icon,
  });
}
