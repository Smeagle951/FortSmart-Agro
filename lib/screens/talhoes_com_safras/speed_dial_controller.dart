import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortsmart_agro/enums/modo_talhao.dart';

/// Controlador e widget premium para SpeedDial de ações do talhão
/// Versão melhorada com animações fluidas, feedback háptico e design premium
class PremiumSpeedDialController extends StatefulWidget {
  final ModoTalhao modo;
  final VoidCallback onDesenhoManual;
  final VoidCallback onCaminhadaGps;
  final VoidCallback onImportarArquivo;
  final VoidCallback onCentralizarGps;
  final VoidCallback? onApagarDesenho;
  final bool podeSalvar;
  final VoidCallback? onSalvar;
  final VoidCallback? onCancelar;
  final bool mostrarBotaoSalvar;
  final Future<void>? Function() onSalvarTalhao;

  const PremiumSpeedDialController({
    Key? key,
    required this.modo,
    required this.onDesenhoManual,
    required this.onCaminhadaGps,
    required this.onImportarArquivo,
    required this.onCentralizarGps,
    this.onApagarDesenho,
    this.podeSalvar = false,
    this.onSalvar,
    this.onCancelar,
    required this.mostrarBotaoSalvar,
    required this.onSalvarTalhao,
  }) : super(key: key);
  
  @override
  State<PremiumSpeedDialController> createState() => _PremiumSpeedDialControllerState();
}

class _PremiumSpeedDialControllerState extends State<PremiumSpeedDialController> 
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _staggerController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isOpen = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Controlador principal de rotação
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Controlador de escala para o botão principal
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Controlador para animação escalonada dos itens
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isClosing) return;

    // Feedback háptico premium
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isOpen = !_isOpen;
    });

    if (_isOpen) {
      // Animação de abertura
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      _rotationController.forward();
      _staggerController.forward();
    } else {
      // Animação de fechamento
      _isClosing = true;
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      _rotationController.reverse();
      await _staggerController.reverse();
      _isClosing = false;
    }
  }

  void _executeAction(VoidCallback action) {
    // Feedback háptico suave
    HapticFeedback.lightImpact();
    _toggle().then((_) => action());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Overlay semi-transparente quando aberto
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            if (!_isOpen && _fadeAnimation.value == 0) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: GestureDetector(
                onTap: () => _toggle(),
                child: Container(
                  color: Colors.black.withOpacity(_fadeAnimation.value * 0.3),
                ),
              ),
            );
          },
        ),
        
        // Itens do SpeedDial
        ..._buildSpeedDialItems(colorScheme),
        
        // Botão principal
        _buildMainButton(theme),
      ],
    );
  }

  Widget _buildMainButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'premiumSpeedDialMain',
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 8.0,
              onPressed: _toggle,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 3.14159,
                child: Icon(
                  _isOpen ? Icons.close_rounded : Icons.add_rounded,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSpeedDialItems(ColorScheme colorScheme) {
    final actions = _getActionsForCurrentMode();
    final items = <Widget>[];

    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];
      final delay = i * 0.1;
      
      items.add(
        AnimatedBuilder(
          animation: _staggerController,
          builder: (context, child) {
            final animationValue = Curves.easeOutBack.transform(
              (_staggerController.value - delay).clamp(0.0, 1.0),
            );
            
            if (animationValue == 0 && !_isOpen) {
              return const SizedBox.shrink();
            }
            
            return Positioned(
              bottom: 80.0 + (i * 70.0),
              right: 0,
              child: Transform.scale(
                scale: animationValue,
                child: Transform.translate(
                  offset: Offset((1 - animationValue) * 50, 0),
                  child: Opacity(
                    opacity: animationValue,
                    child: _buildPremiumSpeedDialItem(action),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return items;
  }

  List<SpeedDialAction> _getActionsForCurrentMode() {
    if (widget.modo == ModoTalhao.idle) {
      return [
        SpeedDialAction(
          icon: Icons.edit_rounded,
          label: 'Desenho Manual',
          color: const Color(0xFF4CAF50),
          onTap: () => _executeAction(widget.onDesenhoManual),
          gradient: const LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        SpeedDialAction(
          icon: Icons.directions_walk_rounded,
          label: 'Caminhada GPS',
          color: const Color(0xFF42A5F5),
          onTap: () => _executeAction(widget.onCaminhadaGps),
          gradient: const LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        SpeedDialAction(
          icon: Icons.upload_file_rounded,
          label: 'Importar Arquivo',
          color: const Color(0xFF7E57C2),
          onTap: () => _executeAction(widget.onImportarArquivo),
          gradient: const LinearGradient(
            colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        SpeedDialAction(
          icon: Icons.my_location_rounded,
          label: 'Centralizar GPS',
          color: const Color(0xFF29B6F6),
          onTap: () => _executeAction(widget.onCentralizarGps),
          gradient: const LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ];
    } else {
      final actions = <SpeedDialAction>[];

      // Botão Cancelar
      if (widget.onCancelar != null) {
        actions.add(
          SpeedDialAction(
            icon: Icons.cancel_rounded,
            label: 'Cancelar',
            color: Colors.grey[600]!,
            onTap: () => _executeAction(widget.onCancelar!),
          ),
        );
      }

      // Botão Salvar
      if (widget.podeSalvar && widget.onSalvar != null) {
        actions.add(
          SpeedDialAction(
            icon: Icons.save_rounded,
            label: 'Salvar Talhão',
            color: const Color(0xFF388E3C),
            onTap: () => _executeAction(widget.onSalvar!),
            gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      }

      // Botão Apagar (apenas no modo desenho)
      if (widget.modo == ModoTalhao.desenhoManual && widget.onApagarDesenho != null) {
        actions.add(
          SpeedDialAction(
            icon: Icons.delete_rounded,
            label: 'Apagar Desenho',
            color: const Color(0xFFE53935),
            onTap: () => _executeAction(widget.onApagarDesenho!),
            gradient: const LinearGradient(
              colors: [Color(0xFFEF5350), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      }

      // Centralizar GPS (sempre disponível)
      actions.add(
        SpeedDialAction(
          icon: Icons.my_location_rounded,
          label: 'Centralizar GPS',
          color: const Color(0xFF29B6F6),
          onTap: () => _executeAction(widget.onCentralizarGps),
          gradient: const LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

      return actions;
    }
  }

  Widget _buildPremiumSpeedDialItem(SpeedDialAction action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label premium com blur e sombra
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            action.label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Botão de ação premium
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: action.gradient,
            boxShadow: [
              BoxShadow(
                color: action.color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: action.onTap,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 56,
                height: 56,
                decoration: action.gradient != null 
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: action.gradient,
                      )
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        color: action.color,
                      ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Classe para definir ações do SpeedDial
class SpeedDialAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Gradient? gradient;

  const SpeedDialAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.gradient,
  });
}