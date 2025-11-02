import 'package:flutter/material.dart';

/// Diálogo de progresso durante a importação de dados de máquina
class MachineDataProgressDialog extends StatefulWidget {
  final String machineType;

  const MachineDataProgressDialog({
    Key? key,
    required this.machineType,
  }) : super(key: key);

  @override
  State<MachineDataProgressDialog> createState() => _MachineDataProgressDialogState();
}

class _MachineDataProgressDialogState extends State<MachineDataProgressDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _currentStep = 'Iniciando importação...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _startImport();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Inicia o processo de importação
  Future<void> _startImport() async {
    final steps = [
      'Lendo arquivo de dados...',
      'Detectando tipo de máquina...',
      'Processando pontos de trabalho...',
      'Calculando estatísticas...',
      'Gerando mapas térmicos...',
      'Finalizando importação...',
    ];

    for (int i = 0; i < steps.length; i++) {
      setState(() {
        _currentStep = steps[i];
        _progress = (i + 1) / steps.length;
      });

      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // Fechar diálogo após conclusão
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Impedir fechamento
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone animado
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value * 2 * 3.14159,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.agriculture,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Título
              const Text(
                'Importando Dados de Máquina',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tipo de máquina
              Text(
                widget.machineType,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 24),
              
              // Barra de progresso
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width * 0.6 * _progress,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Texto de progresso
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Etapa atual
              Text(
                _currentStep,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Indicador de carregamento
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
