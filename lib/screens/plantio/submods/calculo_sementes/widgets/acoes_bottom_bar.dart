import 'package:flutter/material.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../utils/theme_utils.dart';

/// Widget para barra de ações inferior
class AcoesBottomBar extends StatelessWidget {
  final VoidCallback onCalcular;
  final VoidCallback onSalvar;
  final VoidCallback onLimpar;
  final VoidCallback? onCriarNovaDose;
  final bool isLoading;
  final bool temResultado;

  const AcoesBottomBar({
    Key? key,
    required this.onCalcular,
    required this.onSalvar,
    required this.onLimpar,
    this.onCriarNovaDose,
    this.isLoading = false,
    this.temResultado = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (temResultado && onCriarNovaDose != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle),
              label: const Text('Criar Nova Dose'),
              onPressed: onCriarNovaDose,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.calculate),
                label: Text(isLoading ? 'Calculando...' : 'Calcular'),
                onPressed: isLoading ? null : onCalcular,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FortSmartTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                onPressed: onSalvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeUtils.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Limpar'),
                onPressed: onLimpar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
