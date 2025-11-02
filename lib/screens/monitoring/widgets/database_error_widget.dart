import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/database_fix_service.dart';
import '../../utils/logger.dart';

/// Widget para exibir erros de banco de dados com opção de correção
class DatabaseErrorWidget extends StatefulWidget {
  final String error;
  final VoidCallback? onRetry;
  final VoidCallback? onFixDatabase;

  const DatabaseErrorWidget({
    Key? key,
    required this.error,
    this.onRetry,
    this.onFixDatabase,
  }) : super(key: key);

  @override
  State<DatabaseErrorWidget> createState() => _DatabaseErrorWidgetState();
}

class _DatabaseErrorWidgetState extends State<DatabaseErrorWidget> {
  bool _isFixing = false;
  String _fixStatus = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone de erro
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.danger,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Título
          const Text(
            'Erro de Banco de Dados',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Mensagem de erro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: Text(
              widget.error,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Status da correção
          if (_fixStatus.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fixStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Botões de ação
          Column(
            children: [
              // Botão para corrigir banco
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isFixing ? null : _fixDatabase,
                  icon: _isFixing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.build),
                  label: Text(_isFixing ? 'Corrigindo...' : 'Corrigir Banco de Dados'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botão para tentar novamente
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Informações adicionais
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dica',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Se o problema persistir, tente reinstalar o aplicativo ou entre em contato com o suporte.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Corrige a estrutura do banco de dados
  Future<void> _fixDatabase() async {
    setState(() {
      _isFixing = true;
      _fixStatus = 'Verificando estrutura do banco...';
    });

    try {
      final dbFixService = DatabaseFixService();
      
      setState(() {
        _fixStatus = 'Corrigindo tabelas...';
      });
      
      final success = await dbFixService.fixDatabaseStructure();
      
      if (success) {
        setState(() {
          _fixStatus = 'Limpando dados órfãos...';
        });
        
        await dbFixService.cleanupOrphanedData();
        
        setState(() {
          _fixStatus = 'Banco corrigido com sucesso!';
        });
        
        // Aguardar um pouco e chamar callback
        await Future.delayed(const Duration(seconds: 1));
        
        if (widget.onFixDatabase != null) {
          widget.onFixDatabase!();
        } else if (widget.onRetry != null) {
          widget.onRetry!();
        }
      } else {
        setState(() {
          _fixStatus = 'Erro ao corrigir banco. Tente novamente.';
        });
      }
    } catch (e) {
      Logger.error('❌ Erro ao corrigir banco: $e');
      setState(() {
        _fixStatus = 'Erro: $e';
      });
    } finally {
      setState(() {
        _isFixing = false;
      });
    }
  }
}
