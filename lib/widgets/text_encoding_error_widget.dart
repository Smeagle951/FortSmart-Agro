import 'package:flutter/material.dart';
import '../utils/text_encoding_helper.dart';
import 'safe_text.dart';
import 'safe_title.dart' as title_widget;

/// Widget para exibir mensagens de erro relacionadas a problemas de codificação de texto
class TextEncodingErrorWidget extends StatelessWidget {
  final String originalText;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showDetails;

  /// Construtor para o widget TextEncodingErrorWidget
  /// 
  /// [originalText] é o texto original que causou o erro
  /// [errorMessage] é a mensagem de erro específica (opcional)
  /// [onRetry] é a função a ser chamada quando o usuário clicar em "Tentar Novamente"
  /// [showDetails] indica se os detalhes técnicos devem ser exibidos
  const TextEncodingErrorWidget({
    Key? key,
    required this.originalText,
    this.errorMessage,
    this.onRetry,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tenta normalizar o texto para exibição
    final normalizedText = TextEncodingHelper.normalizeText(originalText);
    final normalizedError = errorMessage != null 
        ? TextEncodingHelper.normalizeText(errorMessage!) 
        : 'Erro de codificação de texto';
    
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: title_widget.SafeTitle(
                    'Problema de Codificação de Texto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SafeText(
              'Foi detectado um problema na codificação do texto. O aplicativo tentou corrigir automaticamente.',
              style: TextStyle(color: Colors.red.shade900),
            ),
            if (showDetails) ...[
              const SizedBox(height: 16),
              const SafeText(
                'Texto original:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: double.infinity,
                child: SafeText(
                  originalText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SafeText(
                'Texto corrigido:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: double.infinity,
                child: SafeText(
                  normalizedText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                const SafeText(
                  'Detalhes do erro:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: double.infinity,
                  child: SafeText(
                    normalizedError,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const SafeText('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: Colors.red.shade700, // backgroundColor não é suportado em flutter_map 5.0.0
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget para exibir um banner de aviso sobre problemas de codificação de texto
class TextEncodingWarningBanner extends StatelessWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onFix;

  /// Construtor para o widget TextEncodingWarningBanner
  /// 
  /// [onDismiss] é a função a ser chamada quando o usuário dispensar o aviso
  /// [onFix] é a função a ser chamada quando o usuário clicar em "Corrigir Agora"
  const TextEncodingWarningBanner({
    Key? key,
    this.onDismiss,
    this.onFix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      padding: const EdgeInsets.all(16),
      leading: Icon(
        Icons.warning_amber_rounded,
        color: Colors.amber.shade800,
        size: 32,
      ),
      content: const SafeText(
        'Foram detectados possíveis problemas de codificação de texto em alguns dados. '
        'Isso pode causar exibição incorreta de caracteres especiais e acentuação.',
      ),
      // backgroundColor: Colors.amber.shade100, // backgroundColor não é suportado em flutter_map 5.0.0
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const SafeText('Dispensar'),
        ),
        ElevatedButton(
          onPressed: onFix,
          style: ElevatedButton.styleFrom(
            // backgroundColor: Colors.amber.shade800, // backgroundColor não é suportado em flutter_map 5.0.0
            foregroundColor: Colors.white,
          ),
          child: const SafeText('Corrigir Agora'),
        ),
      ],
    );
  }
}

/// Widget para exibir um indicador de progresso durante a correção de problemas de codificação
class TextEncodingFixProgress extends StatelessWidget {
  final double progress;
  final String message;
  final String? details;
  final VoidCallback? onCancel;

  /// Construtor para o widget TextEncodingFixProgress
  /// 
  /// [progress] é o progresso da correção (0.0 a 1.0)
  /// [message] é a mensagem principal
  /// [details] são os detalhes adicionais (opcional)
  /// [onCancel] é a função a ser chamada quando o usuário clicar em "Cancelar"
  const TextEncodingFixProgress({
    Key? key,
    required this.progress,
    required this.message,
    this.details,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final normalizedMessage = TextEncodingHelper.normalizeText(message);
    final normalizedDetails = details != null 
        ? TextEncodingHelper.normalizeText(details!) 
        : null;
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            title_widget.SafeTitle(
              'Corrigindo Problemas de Codificação',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SafeText(normalizedMessage),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              // backgroundColor: Colors.grey.shade300, // backgroundColor não é suportado em flutter_map 5.0.0
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text('${(progress * 100).toInt()}%'),
            if (normalizedDetails != null) ...[
              const SizedBox(height: 12),
              SafeText(
                normalizedDetails,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: 16),
              Align(
                // alignment: Alignment.centerRight, // alignment não é suportado em Marker no flutter_map 5.0.0
                child: TextButton(
                  onPressed: onCancel,
                  child: const SafeText('Cancelar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
