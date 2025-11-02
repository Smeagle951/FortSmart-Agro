import 'package:flutter/material.dart';
import '../widgets/safe_text.dart';
import '../widgets/safe_title.dart';
import '../utils/text_encoding_helper.dart';

/// Widget para exibir mensagens de erro relacionadas ao banco de dados
class DatabaseErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final bool showDetails;

  /// Construtor para o widget DatabaseErrorWidget
  /// 
  /// [errorMessage] é a mensagem de erro a ser exibida
  /// [onRetry] é a função a ser chamada quando o usuário clicar em "Tentar Novamente"
  /// [showDetails] indica se os detalhes do erro devem ser exibidos
  const DatabaseErrorWidget({
    Key? key,
    required this.errorMessage,
    this.onRetry,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normaliza a mensagem de erro para garantir a codificação correta
    final normalizedError = TextEncodingHelper.normalizeText(errorMessage);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            SafeTitle(
              'Erro no Banco de Dados',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SafeText(
              'Ocorreu um problema ao acessar o banco de dados.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (showDetails) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SafeText(
                        'Detalhes do erro:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SafeText(
                        normalizedError,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const SafeText('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const SafeText('Sugestões de Solução'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SafeText('1. Reinicie o aplicativo'),
                          SizedBox(height: 8),
                          SafeText('2. Verifique o espaço disponível no dispositivo'),
                          SizedBox(height: 8),
                          SafeText('3. Faça um backup dos seus dados'),
                          SizedBox(height: 8),
                          SafeText('4. Se o problema persistir, entre em contato com o suporte'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const SafeText('Fechar'),
                      ),
                    ],
                  ),
                );
              },
              child: const SafeText(
                'O que posso fazer?',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
